"""
Trang AHP – Nhập ma trận so sánh cặp, tính trọng số, kiểm tra CR
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import streamlit as st
import pandas as pd
import numpy as np
from modules.ahp import (calculate_weights, is_consistent, create_default_matrix,
                          SAATY_SCALE, SAATY_VALUES, SAATY_LABELS, get_ri)
from modules.database import save_ahp_result, get_latest_ahp

st.set_page_config(page_title="AHP", page_icon="⚖️", layout="wide")
st.title("⚖️ Phân Tích Thứ Bậc (AHP)")
st.markdown("Nhập so sánh cặp giữa các tiêu chí theo **thang Saaty 1-9**, "
            "hệ thống sẽ tính trọng số và kiểm tra tính nhất quán (CR ≤ 0.10).")

st.divider()

# ── Chọn tiêu chí ──
st.subheader("1️⃣ Chọn tiêu chí đánh giá")

default_criteria = ['Test_Score', 'Attendance (%)', 'Study_Hours']
CRITERIA_LABELS = {
    'Test_Score': 'Điểm kiểm tra',
    'Attendance (%)': 'Chuyên cần (%)',
    'Study_Hours': 'Số giờ tự học',
    'assignment_submit_rate': 'Tỷ lệ nộp bài (%)',
    'past_failures': 'Số lần rớt trước',
    'lms_activity_score': 'Hoạt động LMS',
}

# Lấy cột số từ dữ liệu nếu có
available_criteria = list(CRITERIA_LABELS.keys())
if 'df' in st.session_state and st.session_state.df is not None:
    df = st.session_state.df
    numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
    # Thêm cột có trong data mà không ở CRITERIA_LABELS
    for col in numeric_cols:
        if col not in available_criteria:
            available_criteria.append(col)
            CRITERIA_LABELS[col] = col
    # Lọc chỉ giữ cột tồn tại trong data
    available_criteria = [c for c in available_criteria if c in numeric_cols]
    default_criteria = [c for c in default_criteria if c in available_criteria]

criteria = st.multiselect(
    "Chọn tiêu chí (3-10 tiêu chí)",
    options=available_criteria,
    default=default_criteria,
    format_func=lambda x: CRITERIA_LABELS.get(x, x),
)

n = len(criteria)
if n < 2:
    st.warning("Vui lòng chọn ít nhất 2 tiêu chí.")
    st.stop()

st.divider()

# ── Thang Saaty ──
with st.expander("📖 Thang so sánh Saaty 1-9", expanded=False):
    saaty_df = pd.DataFrame({
        'Giá trị': list(SAATY_SCALE.keys()),
        'Ý nghĩa': list(SAATY_SCALE.values()),
    })
    st.table(saaty_df)

# ── Ma trận so sánh cặp ──
st.subheader("2️⃣ Nhập ma trận so sánh cặp")
st.markdown("Chỉ cần nhập phần **tam giác trên**. Phần dưới tự động tính nghịch đảo.")

# Khởi tạo ma trận
if 'ahp_matrix' not in st.session_state or st.session_state.get('ahp_n') != n:
    st.session_state.ahp_matrix = create_default_matrix(n)
    st.session_state.ahp_n = n

matrix = st.session_state.ahp_matrix.copy()

# Hiển thị form nhập
criteria_labels = [CRITERIA_LABELS.get(c, c) for c in criteria]

for i in range(n):
    cols = st.columns(n - i)
    for j_offset, col in enumerate(cols):
        j = i + j_offset
        if i == j:
            col.markdown(f"**{criteria_labels[i][:10]}**")
        else:
            key = f"ahp_{i}_{j}"
            # Tìm index mặc định trong SAATY_VALUES
            current_val = matrix[i][j]
            default_idx = 8  # index of 1 in SAATY_VALUES
            for idx, sv in enumerate(SAATY_VALUES):
                if abs(sv - current_val) < 0.01:
                    default_idx = idx
                    break

            label_short = f"{criteria_labels[i][:6]} vs {criteria_labels[j][:6]}"
            selected = col.select_slider(
                label_short,
                options=SAATY_LABELS,
                value=SAATY_LABELS[default_idx],
                key=key,
            )
            sel_idx = SAATY_LABELS.index(selected)
            val = SAATY_VALUES[sel_idx]
            matrix[i][j] = val
            matrix[j][i] = 1.0 / val if val != 0 else 1.0

st.session_state.ahp_matrix = matrix

st.divider()

# ── Hiển thị ma trận ──
st.subheader("3️⃣ Ma trận so sánh cặp")
matrix_df = pd.DataFrame(matrix, index=criteria_labels, columns=criteria_labels)
st.dataframe(matrix_df.style.format("{:.4f}"), use_container_width=True)

st.divider()

# ── Tính trọng số ──
st.subheader("4️⃣ Kết quả AHP")

if st.button("⚙️ Tính trọng số AHP", type="primary"):
    weights, lambda_max, ci, cr = calculate_weights(matrix)
    consistent = is_consistent(cr)
    ri = get_ri(n)

    # Lưu vào session
    st.session_state.ahp_weights = weights
    st.session_state.ahp_criteria = criteria
    st.session_state.ahp_cr = cr
    st.session_state.ahp_ci = ci
    st.session_state.ahp_consistent = consistent

    # Hiển thị kết quả
    col1, col2, col3, col4 = st.columns(4)
    col1.metric("λ_max", f"{lambda_max:.4f}")
    col2.metric("CI", f"{ci:.4f}")
    col3.metric("RI", f"{ri:.2f}")
    col4.metric("CR", f"{cr:.4f}")

    if consistent:
        st.success(f"✅ CR = {cr:.4f} ≤ 0.10 → Ma trận **nhất quán**. Trọng số hợp lệ!")
    else:
        st.error(f"❌ CR = {cr:.4f} > 0.10 → Ma trận **KHÔNG nhất quán**. Cần nhập lại!")

    # Bảng trọng số
    weight_df = pd.DataFrame({
        'Tiêu chí': criteria_labels,
        'Mã cột': criteria,
        'Trọng số': weights,
        'Trọng số (%)': (weights * 100).round(2),
    }).sort_values('Trọng số', ascending=False).reset_index(drop=True)

    st.dataframe(weight_df, use_container_width=True, hide_index=True)

    # Biểu đồ trọng số
    import matplotlib.pyplot as plt
    import matplotlib
    matplotlib.use('Agg')

    fig, ax = plt.subplots(figsize=(8, 4))
    bars = ax.barh(criteria_labels, weights, color='#3498db')
    ax.set_xlabel('Trọng số')
    ax.set_title('Trọng số AHP các tiêu chí')
    for bar, w in zip(bars, weights):
        ax.text(bar.get_width() + 0.01, bar.get_y() + bar.get_height()/2,
                f'{w:.3f}', va='center')
    plt.tight_layout()
    st.pyplot(fig)
    plt.close(fig)

    # Lưu vào DB nếu nhất quán
    if consistent:
        save_ahp_result(criteria, weights, matrix, ci, cr, consistent)
        st.info("💾 Đã lưu trọng số AHP vào cơ sở dữ liệu.")

st.divider()

# ── Hiển thị trọng số đã lưu ──
with st.expander("📜 Trọng số AHP gần nhất (từ DB)", expanded=False):
    latest = get_latest_ahp()
    if latest:
        st.json({
            'Tiêu chí': latest['criteria'],
            'Trọng số': [round(w, 4) for w in latest['weights'].tolist()],
            'CI': round(latest['ci'], 4),
            'CR': round(latest['cr'], 4),
            'Nhất quán': latest['is_consistent'],
        })
    else:
        st.info("Chưa có trọng số AHP nào được lưu.")
