"""
Trang Cảnh Báo – Danh sách sinh viên theo mức rủi ro
Kết hợp AHP score + Decision Tree p_fail → final_score → 3 mức cảnh báo
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import streamlit as st
import pandas as pd
import numpy as np

from modules.risk_engine import (
    calculate_ahp_score, calculate_final_score, classify_risk_level
)
from modules.ml_model import predict_proba_fail

st.set_page_config(page_title="Cảnh Báo", page_icon="⚠️", layout="wide")
st.title("⚠️ Danh Sách Cảnh Báo Sinh Viên")

# ── Kiểm tra điều kiện ──
missing = []
if 'df' not in st.session_state or st.session_state.df is None:
    missing.append("Dữ liệu (trang Dữ Liệu)")
if 'ahp_weights' not in st.session_state or st.session_state.ahp_weights is None:
    missing.append("Trọng số AHP (trang AHP)")
if 'trained_model' not in st.session_state or st.session_state.trained_model is None:
    missing.append("Mô hình Decision Tree (trang Train Model)")

if missing:
    st.warning("⚠️ Chưa đủ dữ liệu để tính cảnh báo. Cần hoàn thành:")
    for m in missing:
        st.markdown(f"  - {m}")
    st.stop()

df = st.session_state.df.copy()
model = st.session_state.trained_model
features = st.session_state.model_features
ahp_weights = st.session_state.ahp_weights
ahp_criteria = st.session_state.ahp_criteria

st.divider()

# ── Cấu hình ──
st.subheader("⚙️ Cấu hình tính điểm rủi ro")
col1, col2, col3 = st.columns(3)
with col1:
    alpha = st.slider("Hệ số α (trọng số DT)", 0.0, 1.0, 0.0, 0.05,
                       help="final_score = α × p_fail + (1-α) × ahp_score")
with col2:
    high_thresh = st.number_input("Ngưỡng Cao ≥", 0.0, 1.0, 0.61, 0.05)
with col3:
    medium_thresh = st.number_input("Ngưỡng TB ≥", 0.0, 1.0, 0.31, 0.05)

# ── Chọn đợt cảnh báo ──
st.subheader("📅 Đợt cảnh báo")
wave = st.radio(
    "Chọn đợt",
    ["Đợt 1: Cảnh báo sớm (chỉ dùng chuyên cần, giờ học, nộp bài)",
     "Đợt 2: Sau giữa kỳ (thêm điểm kiểm tra)"],
    index=1,
)
wave_num = 1 if "Đợt 1" in wave else 2

st.divider()

# ── Tính toán ──
if st.button("🔄 Tính điểm rủi ro & Cảnh báo", type="primary"):
    # Lọc features theo đợt
    if wave_num == 1:
        wave_features = [f for f in features if f not in ['Test_Score', 'midterm_score']]
        wave_criteria = [c for c in ahp_criteria if c not in ['Test_Score', 'midterm_score']]
        if not wave_features:
            wave_features = features
        if not wave_criteria:
            wave_criteria = ahp_criteria
    else:
        wave_features = features
        wave_criteria = ahp_criteria

    # Tính p_fail từ Decision Tree
    X_all = df[features].copy()
    # Nếu có cột không tồn tại, fill NaN
    for f in features:
        if f not in df.columns:
            X_all[f] = 0
    p_fail = predict_proba_fail(model, X_all)

    # Tính AHP score
    # Lấy trọng số cho criteria đang dùng
    weights_for_calc = []
    criteria_for_calc = []
    for i, c in enumerate(ahp_criteria):
        if c in wave_criteria and c in df.columns:
            weights_for_calc.append(ahp_weights[i])
            criteria_for_calc.append(c)

    if weights_for_calc:
        w_arr = np.array(weights_for_calc)
        w_arr = w_arr / w_arr.sum()  # Re-normalize
        ahp_score, risk_details = calculate_ahp_score(df, criteria_for_calc, w_arr)
    else:
        ahp_score = np.zeros(len(df))
        risk_details = pd.DataFrame(index=df.index)

    # Tính final_score
    final_score = calculate_final_score(p_fail, ahp_score, alpha)

    # Phân loại mức rủi ro
    risk_level = classify_risk_level(final_score, high_thresh, medium_thresh)

    # Tạo DataFrame kết quả
    df_result = df.copy()
    df_result['p_fail'] = p_fail
    df_result['ahp_score'] = ahp_score
    df_result['final_score'] = final_score
    df_result['Mức rủi ro'] = risk_level.values if hasattr(risk_level, 'values') else risk_level

    # Lưu vào session
    st.session_state.risk_results = df_result
    st.session_state.risk_details = risk_details
    st.session_state.risk_criteria = criteria_for_calc
    st.session_state.risk_weights = w_arr if weights_for_calc else ahp_weights

    st.success("✅ Đã tính xong điểm rủi ro cho tất cả sinh viên!")

    # ── Hiển thị kết quả ──
    st.rerun()

# ── Hiển thị bảng cảnh báo ──
if 'risk_results' in st.session_state and st.session_state.risk_results is not None:
    df_risk = st.session_state.risk_results

    # Metrics
    total = len(df_risk)
    high_count = len(df_risk[df_risk['Mức rủi ro'] == 'Cao'])
    med_count = len(df_risk[df_risk['Mức rủi ro'] == 'Trung bình'])
    low_count = len(df_risk[df_risk['Mức rủi ro'] == 'Thấp'])

    c1, c2, c3, c4 = st.columns(4)
    c1.metric("Tổng SV", total)
    c2.metric("🔴 Cao", high_count)
    c3.metric("🟡 Trung bình", med_count)
    c4.metric("🟢 Thấp", low_count)

    st.divider()

    # Lọc
    filter_level = st.multiselect("Lọc theo mức rủi ro", ['Cao', 'Trung bình', 'Thấp'],
                                   default=['Cao', 'Trung bình', 'Thấp'])
    if 'Class' in df_risk.columns:
        classes = df_risk['Class'].unique().tolist()
        filter_class = st.multiselect("Lọc theo lớp", classes, default=classes)
        filtered = df_risk[
            (df_risk['Mức rủi ro'].isin(filter_level)) &
            (df_risk['Class'].isin(filter_class))
        ]
    else:
        filtered = df_risk[df_risk['Mức rủi ro'].isin(filter_level)]

    # Sắp xếp theo final_score giảm dần
    filtered = filtered.sort_values('final_score', ascending=False)

    # Hiển thị
    display_cols = ['Name', 'Class', 'Test_Score', 'Attendance (%)', 'Study_Hours',
                    'p_fail', 'ahp_score', 'final_score', 'Mức rủi ro']
    display_cols = [c for c in display_cols if c in filtered.columns]

    def color_risk(val):
        if val == 'Cao':
            return 'background-color: #ffcccc; color: #c0392b; font-weight: bold'
        elif val == 'Trung bình':
            return 'background-color: #fff3cd; color: #856404; font-weight: bold'
        return 'background-color: #d4edda; color: #155724'

    st.subheader(f"📋 Danh sách cảnh báo ({len(filtered)} sinh viên)")
    styled = filtered[display_cols].style.map(
        color_risk, subset=['Mức rủi ro']
    ).format({
        'p_fail': '{:.3f}', 'ahp_score': '{:.3f}', 'final_score': '{:.3f}'
    })
    st.dataframe(styled, use_container_width=True, hide_index=True, height=500)

    # Export
    csv = filtered[display_cols].to_csv(index=False).encode('utf-8-sig')
    st.download_button("📥 Xuất CSV", csv, "canh_bao_sinh_vien.csv", "text/csv")
