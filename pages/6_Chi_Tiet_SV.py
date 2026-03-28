"""
Trang Chi Tiết Sinh Viên – Hồ sơ rủi ro cá nhân
Hiện p_fail, ahp_score, final_score, rule path, top tiêu chí AHP, gợi ý can thiệp
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')

from modules.ml_model import get_decision_path_for_student
from modules.risk_engine import get_top_risk_factors, generate_warning_reason, suggest_intervention

st.set_page_config(page_title="Chi Tiết SV", page_icon="👤", layout="wide")
st.title("👤 Chi Tiết Sinh Viên")

if 'risk_results' not in st.session_state or st.session_state.risk_results is None:
    st.warning("⚠️ Chưa có kết quả cảnh báo. Vui lòng vào trang **Cảnh Báo** để tính toán.")
    st.stop()

df_risk = st.session_state.risk_results
model = st.session_state.trained_model
features = st.session_state.model_features

st.divider()

# ── Chọn sinh viên ──
search_options = []
for idx, row in df_risk.iterrows():
    name = row.get('Name', f'SV_{idx}')
    cls = row.get('Class', '')
    risk = row.get('Mức rủi ro', '')
    icon = '🔴' if risk == 'Cao' else ('🟡' if risk == 'Trung bình' else '🟢')
    search_options.append(f"{icon} {name} - {cls} [{risk}]")

selected_idx = st.selectbox("🔍 Chọn sinh viên", range(len(search_options)),
                             format_func=lambda i: search_options[i])

student = df_risk.iloc[selected_idx]

st.divider()

# ── Thông tin cơ bản ──
st.subheader("📋 Thông tin sinh viên")
info_cols = st.columns(4)
info_cols[0].metric("Họ tên", student.get('Name', 'N/A'))
info_cols[1].metric("Lớp", student.get('Class', 'N/A'))

# Hiện các cột số
numeric_info = {k: v for k, v in student.items()
                if isinstance(v, (int, float, np.integer, np.floating))
                and k not in ['p_fail', 'ahp_score', 'final_score', 'fail_label']}
for i, (col_name, val) in enumerate(numeric_info.items()):
    if i + 2 < len(info_cols):
        info_cols[i + 2].metric(col_name, f"{val:.1f}" if isinstance(val, float) else str(val))
    else:
        break

st.divider()

# ── Điểm rủi ro ──
st.subheader("📊 Điểm rủi ro")
risk_level = student.get('Mức rủi ro', 'N/A')

score_cols = st.columns(4)
score_cols[0].metric("p_fail (DT)", f"{student['p_fail']:.4f}",
                      help="Xác suất rớt môn từ Decision Tree")
score_cols[1].metric("ahp_score", f"{student['ahp_score']:.4f}",
                      help="Điểm rủi ro có trọng số AHP")
score_cols[2].metric("final_score", f"{student['final_score']:.4f}",
                      help="Điểm kết hợp = 0.7×p_fail + 0.3×ahp_score")

risk_color = {'Cao': '🔴', 'Trung bình': '🟡', 'Thấp': '🟢'}
icon = risk_color.get(risk_level, '⚪')
score_cols[3].metric("Mức rủi ro", f"{icon} {risk_level}")

# ── Gauge chart ──
fig_gauge, axes = plt.subplots(1, 3, figsize=(12, 3))
scores = [('p_fail', student['p_fail']), ('ahp_score', student['ahp_score']),
          ('final_score', student['final_score'])]
colors_map = [(0.61, 'red'), (0.31, 'orange'), (0, 'green')]

for ax, (label, val) in zip(axes, scores):
    color = 'green'
    for thresh, c in colors_map:
        if val >= thresh:
            color = c
            break
    ax.barh(0, val, color=color, height=0.3, alpha=0.8)
    ax.barh(0, 1 - val, left=val, color='#eee', height=0.3)
    ax.set_xlim(0, 1)
    ax.set_yticks([])
    ax.set_title(f'{label} = {val:.3f}', fontsize=11)
    ax.axvline(x=0.61, color='red', linestyle=':', alpha=0.5)
    ax.axvline(x=0.31, color='orange', linestyle=':', alpha=0.5)

plt.tight_layout()
st.pyplot(fig_gauge)
plt.close(fig_gauge)

st.divider()

# ── Decision Tree Path ──
st.subheader("🌲 Đường đi quyết định (Rule Path)")
try:
    X_single = pd.DataFrame([student[features].values], columns=features)
    rules = get_decision_path_for_student(model, X_single, features)
    if rules:
        for i, rule in enumerate(rules, 1):
            st.markdown(f"**Bước {i}:** {rule}")
    else:
        st.info("Không có rule path.")
except Exception as e:
    st.error(f"Lỗi trích xuất rule path: {e}")

st.divider()

# ── Top tiêu chí AHP tác động mạnh nhất ──
st.subheader("⚖️ Top tiêu chí AHP tác động mạnh nhất")

if ('risk_details' in st.session_state and
        st.session_state.risk_details is not None and
        'risk_criteria' in st.session_state and
        'risk_weights' in st.session_state):

    risk_details = st.session_state.risk_details
    criteria = st.session_state.risk_criteria
    weights = st.session_state.risk_weights

    top_factors = get_top_risk_factors(risk_details, weights, criteria,
                                       df_risk.index[selected_idx], top_n=3)

    # Biểu đồ
    if top_factors:
        CRITERIA_LABELS = {
            'Test_Score': 'Điểm kiểm tra',
            'Attendance (%)': 'Chuyên cần',
            'Study_Hours': 'Giờ tự học',
            'assignment_submit_rate': 'Nộp bài',
            'past_failures': 'Số lần rớt',
            'lms_activity_score': 'LMS',
        }
        factor_names = [CRITERIA_LABELS.get(f[0], f[0]) for f in top_factors]
        factor_scores = [f[1] for f in top_factors]

        fig_f, ax_f = plt.subplots(figsize=(6, 3))
        bars = ax_f.barh(factor_names, factor_scores, color=['#e74c3c', '#f39c12', '#27ae60'])
        ax_f.set_xlabel('Đóng góp rủi ro (w_i × risk_i)')
        ax_f.set_title('Top 3 tiêu chí tác động mạnh nhất')
        for bar, v in zip(bars, factor_scores):
            ax_f.text(bar.get_width() + 0.005, bar.get_y() + bar.get_height()/2,
                       f'{v:.3f}', va='center')
        plt.tight_layout()
        st.pyplot(fig_f)
        plt.close(fig_f)

        # Lý do cảnh báo
        st.markdown("#### ❗ Lý do cảnh báo")
        reason = generate_warning_reason(top_factors)
        st.markdown(reason)

        # Gợi ý can thiệp
        st.markdown("#### 💡 Gợi ý can thiệp")
        suggestion = suggest_intervention(risk_level, top_factors)
        st.markdown(suggestion)
else:
    st.info("Chưa có dữ liệu AHP risk details.")

st.divider()

# ── Lịch sử can thiệp ──
st.subheader("📝 Lịch sử can thiệp")
from modules.database import get_interventions
student_name = student.get('Name', '')
if student_name:
    interventions = get_interventions(student_name)
    if not interventions.empty:
        st.dataframe(interventions, use_container_width=True, hide_index=True)
    else:
        st.info("Chưa có lịch sử can thiệp cho sinh viên này.")
