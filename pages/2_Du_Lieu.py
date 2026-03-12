"""
Trang Dữ Liệu – Import, xem, kiểm tra dữ liệu sinh viên
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import streamlit as st
import pandas as pd
import numpy as np

DATA_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'data')

st.set_page_config(page_title="Dữ Liệu", page_icon="📁", layout="wide")
st.title("📁 Quản Lý Dữ Liệu")

# ── Tab chọn nguồn ──
tab1, tab2, tab3 = st.tabs(["📤 Upload File", "📂 Dữ liệu có sẵn", "🔧 Tạo dữ liệu mẫu"])

with tab1:
    st.subheader("Upload file CSV hoặc Excel")
    uploaded = st.file_uploader("Chọn file dữ liệu", type=['csv', 'xlsx', 'xls'])
    if uploaded:
        try:
            if uploaded.name.endswith('.csv'):
                df = pd.read_csv(uploaded)
            else:
                df = pd.read_excel(uploaded)
            st.session_state.df = df
            st.success(f"✅ Đã tải {len(df)} dòng, {len(df.columns)} cột")
        except Exception as e:
            st.error(f"Lỗi đọc file: {e}")

with tab2:
    st.subheader("Chọn file từ thư mục data/")
    if os.path.exists(DATA_DIR):
        files = [f for f in os.listdir(DATA_DIR)
                 if f.endswith(('.csv', '.xlsx', '.xls'))]
        if files:
            selected_file = st.selectbox("Chọn file", files)
            if st.button("📂 Tải dữ liệu", key="load_existing"):
                fpath = os.path.join(DATA_DIR, selected_file)
                try:
                    if selected_file.endswith('.csv'):
                        df = pd.read_csv(fpath)
                    else:
                        df = pd.read_excel(fpath)
                    st.session_state.df = df
                    st.success(f"✅ Đã tải {len(df)} dòng từ {selected_file}")
                except Exception as e:
                    st.error(f"Lỗi: {e}")
        else:
            st.info("Không có file dữ liệu trong thư mục data/")
    else:
        st.warning("Thư mục data/ chưa tồn tại.")

with tab3:
    st.subheader("Tạo dữ liệu mẫu (synthetic)")
    st.markdown("Tạo dữ liệu giả lập với đầy đủ các cột cần thiết cho hệ thống.")
    n_samples = st.number_input("Số sinh viên", 100, 5000, 500, step=100)
    n_classes = st.number_input("Số lớp", 1, 20, 5)

    if st.button("🔧 Tạo dữ liệu mẫu"):
        np.random.seed(42)
        classes = [f"CNTT{i+1}" for i in range(n_classes)]
        data = {
            'Name': [f"SV_{i+1:04d}" for i in range(n_samples)],
            'Class': np.random.choice(classes, n_samples),
            'Test_Score': np.clip(np.random.normal(5.5, 2.0, n_samples), 0, 10).round(1),
            'Attendance (%)': np.clip(np.random.normal(80, 12, n_samples), 30, 100).round(1),
            'Study_Hours': np.clip(np.random.normal(4, 1.8, n_samples), 0.5, 8).round(1),
        }
        df = pd.DataFrame(data)
        # Tạo thêm cột phụ (tương quan với các cột chính)
        df['assignment_submit_rate'] = np.clip(
            0.3 * df['Test_Score'] * 10 + 0.4 * df['Study_Hours'] * 12
            + np.random.normal(0, 10, n_samples), 20, 100
        ).round(1)
        df['past_failures'] = np.clip(
            np.where(df['Test_Score'] < 4, np.random.choice([1, 2, 3], n_samples),
                     np.random.choice([0, 0, 0, 1], n_samples)),
            0, 4
        )
        df['lms_activity_score'] = np.clip(
            df['Study_Hours'] * 12 + np.random.normal(5, 8, n_samples), 5, 100
        ).round(1)

        st.session_state.df = df
        st.success(f"✅ Đã tạo {n_samples} sinh viên mẫu với {len(df.columns)} cột")

st.divider()

# ── Hiển thị dữ liệu ──
if 'df' in st.session_state and st.session_state.df is not None:
    df = st.session_state.df

    st.subheader("📋 Xem dữ liệu")
    st.dataframe(df.head(50), use_container_width=True, hide_index=True)
    st.caption(f"Hiển thị 50/{len(df)} dòng đầu tiên")

    st.divider()

    # ── Thống kê ──
    col1, col2 = st.columns(2)
    with col1:
        st.subheader("📊 Thống kê mô tả")
        numeric_cols = df.select_dtypes(include=[np.number]).columns.tolist()
        if numeric_cols:
            st.dataframe(df[numeric_cols].describe().round(2), use_container_width=True)

    with col2:
        st.subheader("🔍 Kiểm tra dữ liệu")
        missing = df.isnull().sum()
        missing_df = pd.DataFrame({
            'Cột': missing.index,
            'Số thiếu': missing.values,
            'Tỷ lệ (%)': (missing.values / len(df) * 100).round(1)
        })
        st.dataframe(missing_df, use_container_width=True, hide_index=True)

        duplicates = df.duplicated().sum()
        st.metric("Số dòng trùng lặp", duplicates)

    st.divider()

    # ── Thông tin cột ──
    st.subheader("📋 Thông tin các cột")
    col_info = pd.DataFrame({
        'Cột': df.columns,
        'Kiểu': df.dtypes.astype(str).values,
        'Không null': df.notnull().sum().values,
        'Null': df.isnull().sum().values,
    })
    st.dataframe(col_info, use_container_width=True, hide_index=True)

    # ── Cột số sẵn có ──
    st.subheader("📌 Các cột số có thể dùng làm tiêu chí")
    st.info(f"Các cột số: **{', '.join(numeric_cols)}**")
else:
    st.info("👆 Vui lòng tải dữ liệu từ một trong các tab bên trên.")
