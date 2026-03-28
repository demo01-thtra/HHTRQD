"""
Trang Can Thiệp – Ghi nhận, theo dõi các hành động can thiệp cho sinh viên
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import streamlit as st
import pandas as pd

from modules.database import (
    add_intervention, get_interventions, update_intervention, delete_intervention
)

st.set_page_config(page_title="Can Thiệp", page_icon="📝", layout="wide")
st.title("📝 Quản Lý Can Thiệp")
st.markdown("Ghi nhận hành động can thiệp: nhắc chuyên cần, tư vấn, phụ đạo, liên hệ phụ huynh...")

st.divider()

# ── Tab ──
tab1, tab2, tab3 = st.tabs(["➕ Thêm can thiệp", "📋 Lịch sử can thiệp", "✏️ Cập nhật trạng thái"])

INTERVENTION_TYPES = [
    "Nhắc chuyên cần",
    "Nhắc nộp bài",
    "Tư vấn học tập",
    "Phụ đạo/Kèm cặp",
    "Liên hệ phụ huynh",
    "Theo dõi lại (1-2 tuần)",
    "Chuyển cố vấn học tập",
    "Khác",
]

STATUS_OPTIONS = [
    "Chưa thực hiện",
    "Đang thực hiện",
    "Đã hoàn thành",
    "Không thể liên lạc",
]

with tab1:
    st.subheader("➕ Thêm can thiệp mới")

    # Lấy danh sách sinh viên từ risk_results hoặc df
    student_list = []
    class_map = {}
    if 'risk_results' in st.session_state and st.session_state.risk_results is not None:
        df_src = st.session_state.risk_results
        for _, row in df_src.iterrows():
            name = row.get('Name', '')
            if name and name not in student_list:
                student_list.append(name)
                class_map[name] = row.get('Class', '')
    elif 'df' in st.session_state and st.session_state.df is not None:
        df_src = st.session_state.df
        for _, row in df_src.iterrows():
            name = row.get('Name', '')
            if name and name not in student_list:
                student_list.append(name)
                class_map[name] = row.get('Class', '')

    if not student_list:
        st.info("Chưa có dữ liệu sinh viên. Vui lòng nhập dữ liệu ở trang Dữ Liệu.")
    else:
        with st.form("add_intervention_form"):
            sv_name = st.selectbox("Chọn sinh viên", student_list)
            int_type = st.selectbox("Loại can thiệp", INTERVENTION_TYPES)
            description = st.text_area("Ghi chú chi tiết",
                                        placeholder="Ví dụ: Đã gọi điện nhắc sinh viên đi học đầy đủ...")

            submitted = st.form_submit_button("💾 Lưu can thiệp", type="primary")
            if submitted:
                cls = class_map.get(sv_name, '')
                add_intervention(sv_name, cls, int_type, description)
                st.success(f"✅ Đã lưu can thiệp cho **{sv_name}**")
                st.rerun()

with tab2:
    st.subheader("📋 Lịch sử can thiệp")

    # Lọc
    filter_col1, filter_col2 = st.columns(2)
    with filter_col1:
        filter_student = st.text_input("🔍 Tìm theo tên sinh viên", "")
    with filter_col2:
        filter_status = st.multiselect("Lọc theo trạng thái", STATUS_OPTIONS, default=STATUS_OPTIONS)

    all_interventions = get_interventions()

    if not all_interventions.empty:
        filtered = all_interventions.copy()
        if filter_student:
            filtered = filtered[filtered['student_name'].str.contains(filter_student, case=False, na=False)]
        if filter_status:
            filtered = filtered[filtered['status'].isin(filter_status)]

        # Color coding
        def color_status(val):
            colors = {
                'Chưa thực hiện': 'background-color: #fff3cd',
                'Đang thực hiện': 'background-color: #cce5ff',
                'Đã hoàn thành': 'background-color: #d4edda',
                'Không thể liên lạc': 'background-color: #f8d7da',
            }
            return colors.get(val, '')

        st.dataframe(
            filtered.style.map(color_status, subset=['status']),
            use_container_width=True, hide_index=True, height=400,
        )

        st.metric("Tổng can thiệp", len(filtered))

        # Thống kê
        st.subheader("📊 Thống kê can thiệp")
        stats_col1, stats_col2 = st.columns(2)
        with stats_col1:
            st.markdown("**Theo loại:**")
            st.dataframe(
                all_interventions['intervention_type'].value_counts().reset_index()
                .rename(columns={'intervention_type': 'Loại', 'count': 'Số lượng'}),
                use_container_width=True, hide_index=True,
            )
        with stats_col2:
            st.markdown("**Theo trạng thái:**")
            st.dataframe(
                all_interventions['status'].value_counts().reset_index()
                .rename(columns={'status': 'Trạng thái', 'count': 'Số lượng'}),
                use_container_width=True, hide_index=True,
            )
    else:
        st.info("Chưa có lịch sử can thiệp nào.")

with tab3:
    st.subheader("✏️ Cập nhật trạng thái can thiệp")

    all_ints = get_interventions()
    if not all_ints.empty:
        pending = all_ints[all_ints['status'] != 'Đã hoàn thành']
        if not pending.empty:
            options = []
            for _, row in pending.iterrows():
                options.append(
                    f"[ID:{row['id']}] {row['student_name']} - "
                    f"{row['intervention_type']} ({row['status']})"
                )

            selected = st.selectbox("Chọn can thiệp cần cập nhật", range(len(options)),
                                     format_func=lambda i: options[i])

            selected_row = pending.iloc[selected]

            with st.form("update_form"):
                new_status = st.selectbox("Trạng thái mới", STATUS_OPTIONS,
                                           index=STATUS_OPTIONS.index(selected_row['status'])
                                           if selected_row['status'] in STATUS_OPTIONS else 0)
                result = st.text_area("Kết quả/Ghi chú",
                                       value=selected_row.get('result', '') or '',
                                       placeholder="Kết quả sau can thiệp...")

                col_btn1, col_btn2 = st.columns(2)
                with col_btn1:
                    update_btn = st.form_submit_button("💾 Cập nhật", type="primary")
                with col_btn2:
                    delete_btn = st.form_submit_button("🗑️ Xóa can thiệp")

                if update_btn:
                    update_intervention(int(selected_row['id']), new_status, result)
                    st.success("✅ Đã cập nhật!")
                    st.rerun()
                if delete_btn:
                    delete_intervention(int(selected_row['id']))
                    st.warning("🗑️ Đã xóa can thiệp.")
                    st.rerun()
        else:
            st.success("✅ Tất cả can thiệp đã hoàn thành!")
    else:
        st.info("Chưa có can thiệp nào.")
