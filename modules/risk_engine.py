"""
Risk Engine - Kết hợp AHP + Decision Tree
Tính điểm rủi ro kết hợp từ trọng số AHP và xác suất từ cây quyết định.

Công thức: final_score = alpha * p_fail + (1 - alpha) * ahp_score
Ngưỡng mặc định: Cao ≥ 0.75, Trung bình ≥ 0.55, Thấp < 0.55
"""
import numpy as np
import pandas as pd

# Hàm chuyển đổi: giá trị gốc → điểm rủi ro (0-1, cao = nguy hiểm)
RISK_TRANSFORMS = {
    'Test_Score': lambda x: 1 - x / 10.0,
    'Attendance (%)': lambda x: 1 - x / 100.0,
    'Study_Hours': lambda x: 1 - min(x, 8.0) / 8.0,
    'assignment_submit_rate': lambda x: 1 - x / 100.0,
    'past_failures': lambda x: min(x / 3.0, 1.0),
    'lms_activity_score': lambda x: 1 - x / 100.0,
}


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


def calculate_final_score(p_fail, ahp_score, alpha=0.7):
    """
    Kết hợp xác suất rớt từ Decision Tree với điểm rủi ro AHP.
    final_score = alpha * p_fail + (1 - alpha) * ahp_score
    """
    return np.clip(alpha * np.array(p_fail) + (1 - alpha) * np.array(ahp_score), 0, 1)


def classify_risk_level(final_score, high_thresh=0.75, medium_thresh=0.55):
    """
    Phân loại mức rủi ro:
        Cao: final_score ≥ 0.75
        Trung bình: 0.55 ≤ final_score < 0.75
        Thấp: final_score < 0.55
    """
    if isinstance(final_score, (list, np.ndarray, pd.Series)):
        scores = pd.Series(final_score)
        return scores.apply(
            lambda x: 'Cao' if x >= high_thresh
            else ('Trung bình' if x >= medium_thresh else 'Thấp')
        )
    if final_score >= high_thresh:
        return 'Cao'
    elif final_score >= medium_thresh:
        return 'Trung bình'
    return 'Thấp'


def get_top_risk_factors(risk_details, ahp_weights, criteria_columns, student_idx, top_n=3):
    """Trả về top N tiêu chí AHP tác động mạnh nhất cho 1 sinh viên"""
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
    suggestions = []
    if risk_level == 'Cao':
        suggestions.append("🔴 CẦN CAN THIỆP NGAY:")
        suggestions.append("  - Liên hệ cố vấn học tập")
        suggestions.append("  - Thông báo phụ huynh")
        suggestions.append("  - Xếp lịch phụ đạo")
    elif risk_level == 'Trung bình':
        suggestions.append("🟡 CẦN THEO DÕI:")
        suggestions.append("  - Nhắc nhở sinh viên")
        suggestions.append("  - Tư vấn học tập")

    for factor_name, _ in top_factors:
        if factor_name == 'Attendance (%)':
            suggestions.append("  - Nhắc chuyên cần, kiểm tra lý do vắng")
        elif factor_name == 'Test_Score':
            suggestions.append("  - Hỗ trợ ôn tập, phụ đạo kiến thức")
        elif factor_name == 'Study_Hours':
            suggestions.append("  - Hướng dẫn phương pháp tự học")
        elif factor_name == 'assignment_submit_rate':
            suggestions.append("  - Nhắc nộp bài đầy đủ")

    return "\n".join(suggestions)
