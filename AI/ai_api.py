from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import numpy as np
import pandas as pd
import os
import sys

# Thêm thư mục gốc vào sys.path để import modules/
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from sklearn.tree import DecisionTreeClassifier
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score

from modules.ahp import calculate_weights
from modules.risk_engine import (
    normalize_to_risk_scalar, classify_risk_level,
    get_top_risk_factors_scalar, generate_warning_reason, suggest_intervention,
    FEATURES, FEATURE_LABELS
)
from modules.ml_model import get_decision_path_for_student

app = Flask(__name__)
CORS(app)

# Load model (shared path with Streamlit training)
MODEL_PATH = os.path.join(os.path.dirname(__file__), "..", "models", "decision_tree_model.pkl")
model = None
if os.path.exists(MODEL_PATH):
    model = joblib.load(MODEL_PATH)
else:
    print(f"⚠️  Model file not found: {MODEL_PATH}")
    print("   Hãy chạy train_model.ipynb trước để tạo model!")

features = FEATURES

# Data path
DATA_PATH = os.path.join(os.path.dirname(__file__), "..", "data", "1k_Data điểm.xlsx")

# Default label thresholds (ngưỡng phân loại Rớt)
current_thresholds = {
    "scoreHard": 4.0,       # Điểm < X → rớt nặng
    "attendHard": 65.0,     # Chuyên cần < X% → rớt nặng
    "studyHard": 2.0,       # Giờ học < X → rớt nặng
    "scoreAttend": [5.0, 75.0],   # Điểm < X AND Chuyên cần < Y% → rớt kết hợp
    "scoreStudy": [5.5, 2.5],     # Điểm < X AND Giờ học < Y → rớt kết hợp
    "attendStudy": [70.0, 3.0],   # Chuyên cần < X% AND Giờ học < Y → rớt kết hợp
}

# Default AHP weights (fallback nếu không truyền từ backend)
default_ahp_matrix = np.array([[1, 3, 5], [1/3, 1, 3], [1/5, 1/3, 1]])
default_weights, _, _, _ = calculate_weights(default_ahp_matrix)


def get_ahp_weights(data):
    """Lấy AHP weights từ request body (do backend truyền từ DB), fallback về default."""
    w = data.get("ahpWeights")
    if w and "testWeight" in w and "attendanceWeight" in w and "studyWeight" in w:
        return np.array([w["testWeight"], w["attendanceWeight"], w["studyWeight"]])
    return default_weights


@app.route("/api/ai/predict", methods=["POST"])
def predict():
    if model is None:
        return jsonify({"error": "Model chưa được load. Chạy train_model.ipynb trước!"}), 503

    data = request.get_json()
    test_score = float(data.get("testScore", 0))
    attendance = float(data.get("attendance", 0))
    study_hours = float(data.get("studyHours", 0))
    alpha = float(data.get("alpha", 0.0))

    # Lấy AHP weights từ backend DB (hoặc fallback default)
    ahp_weights = get_ahp_weights(data)

    X = np.array([[test_score, attendance, study_hours]])

    # 1. Decision Tree -> Pass/Fail + p_fail
    dt_prediction = "Fail" if int(model.predict(X)[0]) == 1 else "Pass"
    p_fail = float(model.predict_proba(X)[0][1])

    # 2. AHP -> ahp_score (risk level) - dùng module risk_engine
    risk_values = normalize_to_risk_scalar(test_score, attendance, study_hours)
    ahp_score = float(np.clip(
        sum(ahp_weights[i] * risk_values[features[i]] for i in range(len(features))), 0, 1
    ))

    # 3. Final score
    final_score = float(np.clip(alpha * p_fail + (1 - alpha) * ahp_score, 0, 1))

    # 4. Risk level (dùng tiếng Anh cho API, đồng bộ backend C#)
    risk_level = classify_risk_level(final_score, lang="en")

    # 5. Decision path (rules) - dùng module ml_model (cần DataFrame)
    X_df = pd.DataFrame([[test_score, attendance, study_hours]], columns=features)
    rules = get_decision_path_for_student(model, X_df, features)

    # 6. Top risk factors - dùng module risk_engine
    top_factors_weighted = get_top_risk_factors_scalar(risk_values, ahp_weights, features)

    # 7. Suggestion - dùng module risk_engine
    suggestion = suggest_intervention(risk_level, top_factors_weighted)

    # Warning reason - dùng module risk_engine
    warning_reason = generate_warning_reason(top_factors_weighted[:3])

    # Feature importance from DT (Gini importance)
    feat_importance = {features[i]: round(float(model.feature_importances_[i]), 4) for i in range(len(features))}

    return jsonify({
        "testScore": test_score,
        "attendance": attendance,
        "studyHours": study_hours,
        "dtPrediction": dt_prediction,
        "pFail": round(p_fail, 4),
        "ahpScore": round(ahp_score, 4),
        "finalScore": round(final_score, 4),
        "riskLevel": risk_level,
        "rules": rules,
        "topFactors": [{"name": n, "weight": round(w, 4)} for n, w in top_factors_weighted],
        "warningReason": warning_reason,
        "suggestion": suggestion,
        "ahpWeights": {features[i]: round(float(ahp_weights[i]), 4) for i in range(len(features))},
        "featureImportance": feat_importance,
        "modelInfo": {
            "depth": int(model.get_depth()),
            "nLeaves": int(model.get_n_leaves()),
            "alpha": alpha
        }
    })


@app.route("/api/ai/predict-batch", methods=["POST"])
def predict_batch():
    """Predict for multiple students at once."""
    if model is None:
        return jsonify({"error": "Model chưa được load. Chạy train_model.ipynb trước!"}), 503

    data = request.get_json()
    students = data.get("students", [])
    alpha = float(data.get("alpha", 0.0))

    # Lấy AHP weights từ backend DB (hoặc fallback default)
    ahp_weights = get_ahp_weights(data)

    results = []

    for s in students:
        test_score = float(s.get("testScore", 0))
        attendance = float(s.get("attendance", 0))
        study_hours = float(s.get("studyHours", 0))
        student_id = s.get("studentId")

        X = np.array([[test_score, attendance, study_hours]])
        dt_prediction = "Fail" if int(model.predict(X)[0]) == 1 else "Pass"
        p_fail = float(model.predict_proba(X)[0][1])

        risk_values = normalize_to_risk_scalar(test_score, attendance, study_hours)
        ahp_score = float(np.clip(
            sum(ahp_weights[i] * risk_values[features[i]] for i in range(len(features))), 0, 1
        ))
        final_score = float(np.clip(alpha * p_fail + (1 - alpha) * ahp_score, 0, 1))
        risk_level = classify_risk_level(final_score, lang="en")

        results.append({
            "studentId": student_id,
            "dtPrediction": dt_prediction,
            "pFail": round(p_fail, 4),
            "ahpScore": round(ahp_score, 4),
            "finalScore": round(final_score, 4),
            "riskLevel": risk_level,
        })

    return jsonify({"results": results})


@app.route("/api/ai/model-info", methods=["GET"])
def model_info():
    if model is None:
        return jsonify({"error": "Model chưa được load. Chạy train_model.ipynb trước!"}), 503

    feat_importance = {features[i]: round(float(model.feature_importances_[i]), 4) for i in range(len(features))}
    return jsonify({
        "modelType": "DecisionTreeClassifier",
        "depth": int(model.get_depth()),
        "nLeaves": int(model.get_n_leaves()),
        "features": features,
        "featureImportance": feat_importance,
        "criterion": "gini",
        "dtDescription": "Decision Tree phân loại Pass/Fail bằng cách học các quy tắc if-else từ dữ liệu huấn luyện. "
                         "Tại mỗi nút, cây chọn đặc trưng và ngưỡng tối ưu (Gini) để chia dữ liệu, "
                         "tạo thành các nhánh quyết định đến khi đạt kết luận cuối cùng.",
        "trainingInfo": {
            "labelRule": "Fail nếu: Test<4.0, Attend<65%, Study<1.5h, "
                         "hoặc kết hợp: (Test<5.0 & Attend<75%), (Test<5.5 & Study<2h), (Attend<70% & Study<2.5h)",
            "maxDepth": 5,
            "classWeight": "balanced"
        }
    })


@app.route("/api/ai/thresholds", methods=["GET"])
def get_thresholds():
    """Trả về ngưỡng label hiện tại."""
    return jsonify(current_thresholds)


@app.route("/api/ai/retrain", methods=["POST"])
def retrain():
    """
    Retrain model với ngưỡng label mới do người dùng chọn.
    Body: { scoreHard, attendHard, studyHard, scoreAttend: [s,a], scoreStudy: [s,h], attendStudy: [a,h] }
    """
    global model, current_thresholds

    data = request.get_json()

    # Cập nhật thresholds từ request
    th = {
        "scoreHard": float(data.get("scoreHard", current_thresholds["scoreHard"])),
        "attendHard": float(data.get("attendHard", current_thresholds["attendHard"])),
        "studyHard": float(data.get("studyHard", current_thresholds["studyHard"])),
        "scoreAttend": [
            float(data.get("scoreAttend", current_thresholds["scoreAttend"])[0]),
            float(data.get("scoreAttend", current_thresholds["scoreAttend"])[1]),
        ],
        "scoreStudy": [
            float(data.get("scoreStudy", current_thresholds["scoreStudy"])[0]),
            float(data.get("scoreStudy", current_thresholds["scoreStudy"])[1]),
        ],
        "attendStudy": [
            float(data.get("attendStudy", current_thresholds["attendStudy"])[0]),
            float(data.get("attendStudy", current_thresholds["attendStudy"])[1]),
        ],
    }

    # Đọc dữ liệu
    if not os.path.exists(DATA_PATH):
        return jsonify({"error": f"Data file not found: {DATA_PATH}"}), 404

    df = pd.read_excel(DATA_PATH)

    # Tạo label mới với ngưỡng tùy chỉnh
    def create_label(row):
        score = row["Test_Score"]
        attend = row["Attendance (%)"]
        study = row["Study_Hours"]
        if score < th["scoreHard"]: return 1
        if attend < th["attendHard"]: return 1
        if study < th["studyHard"]: return 1
        if score < th["scoreAttend"][0] and attend < th["scoreAttend"][1]: return 1
        if score < th["scoreStudy"][0] and study < th["scoreStudy"][1]: return 1
        if attend < th["attendStudy"][0] and study < th["attendStudy"][1]: return 1
        return 0

    df["fail_label"] = df.apply(create_label, axis=1)
    n_fail = int((df["fail_label"] == 1).sum())
    n_pass = int((df["fail_label"] == 0).sum())

    if n_fail == 0 or n_pass == 0:
        return jsonify({
            "error": f"Ngưỡng không hợp lệ: Fail={n_fail}, Pass={n_pass}. Cần cả hai lớp!"
        }), 400

    # Train model
    X = df[features]
    y = df["fail_label"]
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    new_model = DecisionTreeClassifier(
        max_depth=5, min_samples_leaf=5,
        class_weight="balanced", random_state=42, criterion="gini"
    )
    new_model.fit(X_train, y_train)

    accuracy = float(accuracy_score(y_test, new_model.predict(X_test)))

    # Lưu model
    joblib.dump(new_model, MODEL_PATH)
    model = new_model
    current_thresholds.update(th)

    feat_importance = {
        features[i]: round(float(model.feature_importances_[i]), 4)
        for i in range(len(features))
    }

    return jsonify({
        "success": True,
        "accuracy": round(accuracy, 4),
        "depth": int(model.get_depth()),
        "nLeaves": int(model.get_n_leaves()),
        "featureImportance": feat_importance,
        "labelDistribution": {"fail": n_fail, "pass": n_pass},
        "thresholds": th,
    })


if __name__ == "__main__":
    print("=" * 50)
    print("  AI API Server - DSS AHP + Decision Tree")
    if model is not None:
        print(f"  Model depth: {int(model.get_depth())}, Leaves: {int(model.get_n_leaves())}")
    else:
        print("  ⚠️  Model chưa load! Chạy train_model.ipynb trước.")
    print(f"  AHP weights: {dict(zip(features, np.round(default_weights, 4)))}")
    print("=" * 50)
    import sys as _sys
    debug_mode = "--debug" in _sys.argv
    app.run(host="0.0.0.0", port=5001, debug=debug_mode)
