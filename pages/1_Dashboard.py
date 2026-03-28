"""
Trang Dashboard – Tổng quan hệ thống cảnh báo
Hiển thị phân bố rủi ro, thống kê theo lớp, theo mức cảnh báo
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')

st.set_page_config(page_title="Dashboard", page_icon="📊", layout="wide")
st.title("📊 Dashboard Tổng Quan")

# Kiểm tra dữ liệu
if 'risk_results' not in st.session_state or st.session_state.risk_results is None:
    st.info("⏳ Chưa có kết quả cảnh báo. Vui lòng hoàn thành các bước:")
    st.markdown("""
    1. **Dữ Liệu** – Nhập dữ liệu sinh viên
    2. **AHP** – Thiết lập trọng số tiêu chí
    3. **Train Model** – Huấn luyện mô hình
    4. **Cảnh Báo** – Tính điểm rủi ro (bấm nút tính toán)
    """)
    st.stop()

df_risk = st.session_state.risk_results

st.divider()

# ── Metric cards ──
col1, col2, col3, col4 = st.columns(4)
total = len(df_risk)
high = len(df_risk[df_risk['Mức rủi ro'] == 'Cao'])
medium = len(df_risk[df_risk['Mức rủi ro'] == 'Trung bình'])
low = len(df_risk[df_risk['Mức rủi ro'] == 'Thấp'])

col1.metric("Tổng sinh viên", total)
col2.metric("🔴 Rủi ro Cao", high, delta=f"{high/total*100:.1f}%" if total > 0 else "0%")
col3.metric("🟡 Rủi ro TB", medium, delta=f"{medium/total*100:.1f}%" if total > 0 else "0%")
col4.metric("🟢 Rủi ro Thấp", low, delta=f"{low/total*100:.1f}%" if total > 0 else "0%")

st.divider()

# ── Biểu đồ ──
chart_col1, chart_col2 = st.columns(2)

with chart_col1:
    st.subheader("Phân bố mức rủi ro")
    risk_counts = df_risk['Mức rủi ro'].value_counts()
    colors = {'Cao': '#e74c3c', 'Trung bình': '#f39c12', 'Thấp': '#27ae60'}
    fig1, ax1 = plt.subplots(figsize=(6, 4))
    labels = risk_counts.index.tolist()
    ax1.pie(risk_counts.values, labels=labels,
            colors=[colors.get(l, '#999') for l in labels],
            autopct='%1.1f%%', startangle=90, textprops={'fontsize': 12})
    ax1.set_title('Tỷ lệ sinh viên theo mức rủi ro', fontsize=13)
    st.pyplot(fig1)
    plt.close(fig1)

with chart_col2:
    st.subheader("Phân bố theo lớp")
    if 'Class' in df_risk.columns:
        class_risk = df_risk.groupby(['Class', 'Mức rủi ro']).size().unstack(fill_value=0)
        for level in ['Cao', 'Trung bình', 'Thấp']:
            if level not in class_risk.columns:
                class_risk[level] = 0
        class_risk = class_risk[['Cao', 'Trung bình', 'Thấp']]

        fig2, ax2 = plt.subplots(figsize=(6, 4))
        class_risk.plot(kind='bar', stacked=True, ax=ax2,
                        color=['#e74c3c', '#f39c12', '#27ae60'])
        ax2.set_title('Số sinh viên theo lớp và mức rủi ro', fontsize=13)
        ax2.set_xlabel('Lớp')
        ax2.set_ylabel('Số sinh viên')
        ax2.legend(title='Mức rủi ro')
        plt.xticks(rotation=45, ha='right')
        plt.tight_layout()
        st.pyplot(fig2)
        plt.close(fig2)
    else:
        st.info("Không có cột 'Class' trong dữ liệu.")

st.divider()

# ── Phân bố điểm rủi ro ──
st.subheader("Phân bố điểm rủi ro (Final Score)")
fig3, ax3 = plt.subplots(figsize=(10, 4))
ax3.hist(df_risk['final_score'], bins=30, color='#3498db', edgecolor='white', alpha=0.8)
ax3.axvline(x=0.61, color='red', linestyle='--', label='Ngưỡng Cao (0.61)')
ax3.axvline(x=0.31, color='orange', linestyle='--', label='Ngưỡng TB (0.31)')
ax3.set_xlabel('Final Score')
ax3.set_ylabel('Số sinh viên')
ax3.set_title('Phân bố Final Score (α × p_fail + (1-α) × ahp_score)')
ax3.legend()
plt.tight_layout()
st.pyplot(fig3)
plt.close(fig3)

st.divider()

# ── Top sinh viên rủi ro cao ──
st.subheader("🔴 Top 10 sinh viên rủi ro cao nhất")
top_risk = df_risk.nlargest(10, 'final_score')
display_cols = ['Name', 'Class', 'final_score', 'p_fail', 'ahp_score', 'Mức rủi ro']
display_cols = [c for c in display_cols if c in top_risk.columns]
st.dataframe(
    top_risk[display_cols].style.format({
        'final_score': '{:.3f}', 'p_fail': '{:.3f}', 'ahp_score': '{:.3f}'
    }),
    use_container_width=True, hide_index=True,
)
