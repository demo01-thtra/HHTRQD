"""
Risk Engine - Kết hợp AHP + Decision Tree
Tính điểm rủi ro kết hợp từ trọng số AHP và xác suất từ cây quyết định.

Công thức: final_score = alpha * p_fail + (1 - alpha) * ahp_score
Ngưỡng: Cao ≥ 0.61, Trung bình ≥ 0.31, Thấp < 0.31
"""
import numpy as np
import pandas as pd

# === Tham số chuẩn (đồng bộ với ai_api.py và RiskService.cs) ===
STUDY_HOURS_MAX = 12.0
THRESHOLD_HIGH = 0.61
THRESHOLD_MEDIUM = 0.31

FEATURES = ["Test_Score", "Attendance (%)", "Study_Hours"]
FEATURE_LABELS = {
    "Test_Score": "Điểm kiểm tra",
    "Attendance (%)": "Chuyên cần",
    "Study_Hours": "Giờ tự học",
}

RISK_LABELS_VI = {"high": "Cao", "medium": "Trung bình", "low": "Thấp"}
RISK_LABELS_EN = {"high": "High Risk", "medium": "Medium Risk", "low": "Low Risk"}

# Hàm chuyển đổi: giá trị gốc → điểm rủi ro (0-1, cao = nguy hiểm)
RISK_TRANSFORMS = {
    'Test_Score': lambda x: 1 - x / 10.0,
    'Attendance (%)': lambda x: 1 - x / 100.0,
    'Study_Hours': lambda x: 1 - min(x, STUDY_HOURS_MAX) / STUDY_HOURS_MAX,
    'assignment_submit_rate': lambda x: 1 - x / 100.0,
    'past_failures': lambda x: min(x / 3.0, 1.0),
    'lms_activity_score': lambda x: 1 - x / 100.0,
}


# ── Streamlit (DataFrame-based) Functions ──

def normalize_to_risk(series, column_name):
    """
    Chuẩn hóa giá trị cột thành rủi ro (0-1, cao hơn = rủi ro hơn).
    Nếu cột có hàm chuyển đổi riêng thì dùng, không thì min-max đảo ngược.
    """
    if column_name in RISK_TRANSFORMS:
        return series.apply(RISK_TRANSFORMS[column_name]).clip(0, 1)

    min_val = series.min()
    max_val = series.max()
    if max_val - min_val == 0:
        return pd.Series(0.5, index=series.index)
    return (1 - (series - min_val) / (max_val - min_val)).clip(0, 1)


def calculate_ahp_score(df, criteria_columns, ahp_weights):
    """
    Tính điểm rủi ro AHP cho từng sinh viên.
    ahp_score = Σ(w_i × risk_i)
    """
    risk_details = pd.DataFrame(index=df.index)

    for col in criteria_columns:
        risk_details[f'{col}_risk'] = normalize_to_risk(df[col], col)

    ahp_score = np.zeros(len(df))
    for i, col in enumerate(criteria_columns):
        ahp_score += ahp_weights[i] * risk_details[f'{col}_risk'].values

    return np.clip(ahp_score, 0, 1), risk_details


def calculate_final_score(p_fail, ahp_score, alpha=0.0):
    """
    Kết hợp xác suất rớt từ Decision Tree với điểm rủi ro AHP.
    final_score = alpha * p_fail + (1 - alpha) * ahp_score
    Mặc định alpha=0.0 (pure AHP) – giống hệ thống production.
    """
    return np.clip(alpha * np.array(p_fail) + (1 - alpha) * np.array(ahp_score), 0, 1)


def classify_risk_level(final_score, high_thresh=None, medium_thresh=None, lang="vi"):
    """
    Phân loại mức rủi ro.
    Hỗ trợ cả scalar và array/Series.
    Ngưỡng mặc định: >= 0.61 → Cao, >= 0.31 → Trung bình, < 0.31 → Thấp.
    lang: "vi" = tiếng Việt, "en" = tiếng Anh (API, đồng bộ backend C#)
    """
    high_thresh = high_thresh if high_thresh is not None else THRESHOLD_HIGH
    medium_thresh = medium_thresh if medium_thresh is not None else THRESHOLD_MEDIUM
    labels = RISK_LABELS_VI if lang == "vi" else RISK_LABELS_EN

    if isinstance(final_score, (list, np.ndarray, pd.Series)):
        scores = pd.Series(final_score)
        levels = pd.Series(labels["low"], index=scores.index)
        levels[scores >= medium_thresh] = labels["medium"]
        levels[scores >= high_thresh] = labels["high"]
        return levels

    if final_score >= high_thresh:
        return labels["high"]
    elif final_score >= medium_thresh:
        return labels["medium"]
    return labels["low"]


def get_top_risk_factors(risk_details, ahp_weights, criteria_columns, student_idx, top_n=3):
    """Trả về top N tiêu chí AHP tác động mạnh nhất cho 1 sinh viên (DataFrame-based)"""
    contributions = {}
    for i, col in enumerate(criteria_columns):
        risk_col = f'{col}_risk'
        if risk_col in risk_details.columns:
            contributions[col] = ahp_weights[i] * risk_details.loc[student_idx, risk_col]

    sorted_factors = sorted(contributions.items(), key=lambda x: x[1], reverse=True)
    return sorted_factors[:top_n]


def generate_warning_reason(top_factors):
    """Sinh lý do cảnh báo từ các tiêu chí tác động mạnh nhất"""
    CRITERIA_LABELS = {
        'Test_Score': 'Điểm kiểm tra thấp',
        'Attendance (%)': 'Tỷ lệ chuyên cần thấp',
        'Study_Hours': 'Số giờ tự học ít',
        'assignment_submit_rate': 'Tỷ lệ nộp bài thấp',
        'past_failures': 'Có nhiều lần rớt trước đó',
        'lms_activity_score': 'Ít hoạt động trên LMS',
    }
    reasons = []
    for factor_name, score in top_factors:
        label = CRITERIA_LABELS.get(factor_name, factor_name)
        reasons.append(f"• {label} (đóng góp: {score:.2f})")
    return "\n".join(reasons)


def suggest_intervention(risk_level, top_factors):
    """Gợi ý can thiệp dựa trên mức rủi ro và tiêu chí"""
    high_labels = ('Cao', 'High Risk')
    medium_labels = ('Trung bình', 'Medium Risk')
    low_labels = ('Thấp', 'Low Risk')

    if risk_level in low_labels:
        return "Sinh viên không có nguy cơ rớt môn. Tiếp tục duy trì!"

    suggestions = []
    if risk_level in high_labels:
        suggestions.append("🔴 CẦN CAN THIỆP NGAY:")
        suggestions.append("  - Liên hệ cố vấn học tập")
        suggestions.append("  - Thông báo phụ huynh")
        suggestions.append("  - Xếp lịch phụ đạo")
    elif risk_level in medium_labels:
        suggestions.append("🟡 CẦN THEO DÕI:")
        suggestions.append("  - Nhắc nhở sinh viên")
        suggestions.append("  - Tư vấn học tập")

    for factor_name, _ in top_factors:
        if 'Attendance' in factor_name or factor_name == 'Attendance (%)':
            suggestions.append("  - Nhắc chuyên cần, kiểm tra lý do vắng")
        elif 'Test_Score' in factor_name or factor_name == 'Test_Score':
            suggestions.append("  - Hỗ trợ ôn tập, phụ đạo kiến thức")
        elif 'Study_Hours' in factor_name or factor_name == 'Study_Hours':
            suggestions.append("  - Hướng dẫn phương pháp tự học")
        elif 'assignment_submit_rate' in factor_name:
            suggestions.append("  - Nhắc nộp bài đầy đủ")

    return "\n".join(suggestions)


# ── Scalar API Functions (used by ai_api.py) ──

def normalize_to_risk_scalar(test_score, attendance, study_hours):
    """Chuyển điểm gốc → dict giá trị rủi ro (0-1), giá trị cao = rủi ro cao."""
    return {
        "Test_Score": 1 - test_score / 10.0,
        "Attendance (%)": 1 - attendance / 100.0,
        "Study_Hours": 1 - min(study_hours, STUDY_HOURS_MAX) / STUDY_HOURS_MAX,
    }


def get_top_risk_factors_scalar(risk_values, weights, features, top_n=3):
    """Lấy top yếu tố rủi ro theo trọng số AHP (dict-based, cho API)."""
    factors = sorted(
        risk_values.items(),
        key=lambda x: weights[features.index(x[0])] * x[1],
        reverse=True
    )
    return [(k, weights[features.index(k)] * v) for k, v in factors[:top_n]]
