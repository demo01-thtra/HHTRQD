"""
HỆ THỐNG HỖ TRỢ QUYẾT ĐỊNH CẢNH BÁO SỚM
SINH VIÊN CÓ NGUY CƠ RỚT MÔN

DSS lai 2 tầng: AHP (trọng số nghiệp vụ) + Decision Tree (dự báo)
"""
import streamlit as st
import os
import sys

# Đảm bảo import modules hoạt động
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from modules.database import init_db

# Khởi tạo database
init_db()

st.set_page_config(
    page_title="DSS Cảnh Báo Sớm",
    page_icon="🎓",
    layout="wide",
    initial_sidebar_state="expanded",
)

# ── CSS ──
st.markdown("""
<style>
    .main-header {
        font-size: 2rem;
        font-weight: bold;
        color: #1f4e79;
        text-align: center;
        margin-bottom: 0.5rem;
    }
    .sub-header {
        font-size: 1.1rem;
        color: #555;
        text-align: center;
        margin-bottom: 2rem;
    }
    .step-card {
        background: #f8f9fa;
        border-left: 4px solid #1f77b4;
        padding: 1rem;
        margin: 0.5rem 0;
        border-radius: 0 8px 8px 0;
    }
    .metric-card {
        background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
        color: white;
        padding: 1.5rem;
        border-radius: 12px;
        text-align: center;
    }
</style>
""", unsafe_allow_html=True)

# ── Header ──
st.markdown('<div class="main-header">🎓 Hệ Thống Hỗ Trợ Quyết Định</div>', unsafe_allow_html=True)
st.markdown('<div class="sub-header">Cảnh Báo Sớm Sinh Viên Có Nguy Cơ Rớt Môn<br>'
            '<b>AHP</b> (trọng số chuyên gia) + <b>Decision Tree</b> (dự báo từ dữ liệu)</div>',
            unsafe_allow_html=True)

st.divider()

# ── Giới thiệu ──
col1, col2 = st.columns(2)
with col1:
    st.markdown("### 🔍 AHP – Trọng số nghiệp vụ")
    st.markdown("""
    - So sánh cặp tiêu chí theo **thang Saaty 1-9**
    - Tính trọng số ưu tiên bằng phương pháp eigenvector
    - Kiểm tra tính nhất quán (CR ≤ 0.10)
    - **Trả lời:** *"Tiêu chí nào quan trọng hơn theo chuyên gia?"*
    """)

with col2:
    st.markdown("### 🌳 Decision Tree – Dự báo dữ liệu")
    st.markdown("""
    - Phân loại nhị phân: **rớt / không rớt**
    - White-box model: dễ hiểu, dễ giải thích
    - Đánh giá: Confusion Matrix, Precision, Recall, F1
    - **Trả lời:** *"Từ dữ liệu lịch sử, sinh viên nào có khả năng rớt?"*
    """)

st.divider()

# ── Hướng dẫn sử dụng ──
st.markdown("### 📋 Quy trình sử dụng hệ thống")

steps = [
    ("📁 Bước 1: Nhập dữ liệu", "Import file Excel/CSV chứa dữ liệu sinh viên → trang **Dữ Liệu**"),
    ("⚖️ Bước 2: Thiết lập AHP", "Nhập ma trận so sánh cặp, tính trọng số tiêu chí → trang **AHP**"),
    ("🌳 Bước 3: Huấn luyện mô hình", "Chọn features, tune tham số, train Decision Tree → trang **Train Model**"),
    ("📊 Bước 4: Xem Dashboard", "Tổng quan phân bố rủi ro theo lớp, theo mức → trang **Dashboard**"),
    ("⚠️ Bước 5: Danh sách cảnh báo", "Xem sinh viên có nguy cơ cao, lọc theo mức → trang **Cảnh Báo**"),
    ("👤 Bước 6: Chi tiết sinh viên", "Xem p_fail, ahp_score, rule path, lý do → trang **Chi Tiết SV**"),
    ("📝 Bước 7: Can thiệp", "Ghi nhận hành động can thiệp, theo dõi kết quả → trang **Can Thiệp**"),
]
for title, desc in steps:
    st.markdown(f'<div class="step-card"><b>{title}</b><br>{desc}</div>', unsafe_allow_html=True)

st.divider()

# ── Trạng thái hiện tại ──
st.markdown("### 📌 Trạng thái hệ thống")
c1, c2, c3 = st.columns(3)
with c1:
    if 'df' in st.session_state and st.session_state.df is not None:
        st.success(f"✅ Dữ liệu: {len(st.session_state.df)} sinh viên")
    else:
        st.warning("⏳ Chưa nhập dữ liệu")
with c2:
    if 'ahp_weights' in st.session_state and st.session_state.ahp_weights is not None:
        st.success("✅ Trọng số AHP đã thiết lập")
    else:
        st.warning("⏳ Chưa thiết lập AHP")
with c3:
    if 'trained_model' in st.session_state and st.session_state.trained_model is not None:
        st.success("✅ Mô hình đã huấn luyện")
    else:
        st.warning("⏳ Chưa huấn luyện mô hình")

st.divider()
st.caption("© 2025 – Hệ thống DSS lai AHP + Decision Tree | Đồ án môn học")
