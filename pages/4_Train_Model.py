"""
Trang Train Model – Huấn luyện Decision Tree, đánh giá, tune threshold
"""
import sys, os
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), '..'))

import streamlit as st
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib
matplotlib.use('Agg')

from modules.ml_model import (
    create_binary_label, train_decision_tree, get_feature_importance,
    get_tree_rules, plot_decision_tree, save_model, predict_proba_fail
)
from modules.database import save_model_info

st.set_page_config(page_title="Train Model", page_icon="🌳", layout="wide")
st.title("🌳 Huấn Luyện Mô Hình Decision Tree")

if 'df' not in st.session_state or st.session_state.df is None:
    st.warning("⚠️ Chưa có dữ liệu. Vui lòng vào trang **Dữ Liệu** để nhập.")
    st.stop()

df = st.session_state.df.copy()

st.divider()

# ── 1. Tạo nhãn ──
st.subheader("1️⃣ Tạo nhãn (Target)")
st.markdown("Nhãn nhị phân: **1 = rớt môn**, **0 = không rớt**")

col1, col2 = st.columns(2)
with col1:
    score_col = st.selectbox("Cột điểm", [c for c in df.select_dtypes(include=[np.number]).columns],
                             index=0 if 'Test_Score' not in df.columns
                             else list(df.select_dtypes(include=[np.number]).columns).index('Test_Score')
                             if 'Test_Score' in df.select_dtypes(include=[np.number]).columns else 0)
    score_thresh = st.number_input("Ngưỡng rớt (điểm <)", value=4.0, step=0.5)

with col2:
    attend_col = st.selectbox("Cột chuyên cần",
                              [c for c in df.select_dtypes(include=[np.number]).columns],
                              index=1 if 'Attendance (%)' not in df.columns
                              else list(df.select_dtypes(include=[np.number]).columns).index('Attendance (%)')
                              if 'Attendance (%)' in df.select_dtypes(include=[np.number]).columns else 1)
    attend_thresh = st.number_input("Ngưỡng rớt (chuyên cần <)", value=50.0, step=5.0)

# Tạo nhãn
df['fail_label'] = create_binary_label(df, score_col, attend_col, score_thresh, attend_thresh)

label_counts = df['fail_label'].value_counts()
c1, c2, c3 = st.columns(3)
c1.metric("Tổng mẫu", len(df))
c2.metric("Không rớt (0)", label_counts.get(0, 0))
c3.metric("Rớt (1)", label_counts.get(1, 0))

st.divider()

# ── 2. Chọn features ──
st.subheader("2️⃣ Chọn Features")

numeric_cols = [c for c in df.select_dtypes(include=[np.number]).columns if c != 'fail_label']
default_feats = [c for c in ['Test_Score', 'Attendance (%)', 'Study_Hours'] if c in numeric_cols]

features = st.multiselect("Chọn features cho mô hình", numeric_cols,
                          default=default_feats if default_feats else numeric_cols[:3])

if len(features) < 1:
    st.warning("Chọn ít nhất 1 feature.")
    st.stop()

st.divider()

# ── 3. Tham số mô hình ──
st.subheader("3️⃣ Tham số Decision Tree")

col1, col2, col3, col4 = st.columns(4)
with col1:
    max_depth = st.slider("max_depth", 1, 15, 5)
with col2:
    min_samples_leaf = st.slider("min_samples_leaf", 1, 50, 5)
with col3:
    test_size = st.slider("test_size", 0.1, 0.4, 0.2, 0.05)
with col4:
    ccp_alpha = st.number_input("ccp_alpha (pruning)", 0.0, 0.1, 0.0, 0.005, format="%.3f")

use_class_weight = st.checkbox("Dùng class_weight='balanced' (khuyên dùng khi dữ liệu mất cân bằng)", value=True)

st.divider()

# ── 4. Train ──
st.subheader("4️⃣ Huấn luyện & Đánh giá")

if st.button("🚀 Train Decision Tree", type="primary"):
    X = df[features].copy()
    y = df['fail_label'].copy()

    # Kiểm tra đủ mẫu cho cả 2 class
    if y.nunique() < 2:
        st.error("Dữ liệu chỉ có 1 class. Không thể train. Hãy điều chỉnh ngưỡng nhãn.")
        st.stop()

    class_weight = 'balanced' if use_class_weight else None

    model, metrics, split_data = train_decision_tree(
        X, y, max_depth=max_depth, min_samples_leaf=min_samples_leaf,
        class_weight=class_weight, random_state=42,
        test_size=test_size, ccp_alpha=ccp_alpha
    )

    # Lưu vào session
    st.session_state.trained_model = model
    st.session_state.model_features = features
    st.session_state.model_metrics = metrics
    st.session_state.split_data = split_data

    # ── Metrics ──
    st.markdown("#### 📐 Kết quả đánh giá")
    mc1, mc2, mc3, mc4 = st.columns(4)
    mc1.metric("Accuracy", f"{metrics['accuracy']:.4f}")
    mc2.metric("Precision", f"{metrics['precision']:.4f}")
    mc3.metric("Recall", f"{metrics['recall']:.4f}")
    mc4.metric("F1-Score", f"{metrics['f1']:.4f}")

    # ── Confusion Matrix ──
    st.markdown("#### 📊 Confusion Matrix")
    cm = metrics['confusion_matrix']
    fig_cm, ax_cm = plt.subplots(figsize=(5, 4))
    im = ax_cm.imshow(cm, cmap='Blues')
    labels = ['Không rớt (0)', 'Rớt (1)']
    ax_cm.set_xticks([0, 1])
    ax_cm.set_yticks([0, 1])
    ax_cm.set_xticklabels(labels)
    ax_cm.set_yticklabels(labels)
    ax_cm.set_xlabel('Dự đoán')
    ax_cm.set_ylabel('Thực tế')
    ax_cm.set_title('Confusion Matrix')
    for i in range(2):
        for j in range(2):
            ax_cm.text(j, i, str(cm[i][j]), ha='center', va='center',
                       color='white' if cm[i][j] > cm.max()/2 else 'black', fontsize=14)
    plt.tight_layout()
    st.pyplot(fig_cm)
    plt.close(fig_cm)

    # ── Classification Report ──
    st.markdown("#### 📋 Classification Report")
    report = metrics['classification_report']
    report_df = pd.DataFrame(report).transpose()
    st.dataframe(report_df.style.format("{:.4f}"), use_container_width=True)

    # ── Feature Importance ──
    st.markdown("#### 🏆 Tầm quan trọng features")
    fi = get_feature_importance(model, features)
    fig_fi, ax_fi = plt.subplots(figsize=(8, 3))
    bars = ax_fi.barh(fi['Tiêu chí'], fi['Tầm quan trọng'], color='#2ecc71')
    ax_fi.set_xlabel('Importance')
    ax_fi.set_title('Feature Importance')
    for bar, v in zip(bars, fi['Tầm quan trọng']):
        ax_fi.text(bar.get_width() + 0.005, bar.get_y() + bar.get_height()/2,
                   f'{v:.3f}', va='center')
    plt.tight_layout()
    st.pyplot(fig_fi)
    plt.close(fig_fi)

    # ── Cấu trúc cây ──
    st.markdown("#### 🌲 Cấu trúc cây quyết định")
    rules = get_tree_rules(model, features)
    st.code(rules, language='text')

    # ── Vẽ cây ──
    st.markdown("#### 🎨 Hình ảnh cây quyết định")
    fig_tree = plot_decision_tree(model, features, figsize=(20, 10))
    st.pyplot(fig_tree)
    plt.close(fig_tree)

    # ── Lưu model ──
    model_path = save_model(model)
    st.success(f"💾 Mô hình đã lưu tại: {model_path}")

    # Lưu thông tin vào DB
    save_model_info(
        features=features,
        accuracy=metrics['accuracy'],
        precision_val=metrics['precision'],
        recall_val=metrics['recall'],
        f1_val=metrics['f1'],
        max_depth=max_depth,
        min_samples_leaf=min_samples_leaf,
    )

st.divider()

# ── 5. Threshold Tuning ──
st.subheader("5️⃣ Điều chỉnh ngưỡng quyết định (Threshold)")
st.markdown("""
Ngưỡng mặc định **0.5** thường không tối ưu. Với hệ thống cảnh báo sớm, 
nên ưu tiên **Recall** (không bỏ sót sinh viên rủi ro) hoặc giới hạn số cảnh báo 
ở mức cố vấn/giảng viên xử lý nổi.
""")

if 'split_data' in st.session_state and 'trained_model' in st.session_state:
    model = st.session_state.trained_model
    split = st.session_state.split_data
    y_test = split['y_test']
    y_proba = split['y_proba']

    if y_proba.shape[1] == 2:
        proba_fail = y_proba[:, 1]
    else:
        proba_fail = y_proba[:, 0]

    from sklearn.metrics import precision_recall_curve, f1_score as sk_f1

    precisions, recalls, thresholds = precision_recall_curve(y_test, proba_fail)

    fig_pr, ax_pr = plt.subplots(figsize=(8, 4))
    ax_pr.plot(thresholds, precisions[:-1], label='Precision', color='#3498db')
    ax_pr.plot(thresholds, recalls[:-1], label='Recall', color='#e74c3c')
    ax_pr.axvline(x=0.5, color='gray', linestyle='--', alpha=0.5, label='Threshold = 0.5')
    ax_pr.set_xlabel('Threshold')
    ax_pr.set_ylabel('Score')
    ax_pr.set_title('Precision vs Recall theo Threshold')
    ax_pr.legend()
    plt.tight_layout()
    st.pyplot(fig_pr)
    plt.close(fig_pr)

    custom_threshold = st.slider("Chọn threshold", 0.0, 1.0, 0.5, 0.05)
    y_pred_custom = (proba_fail >= custom_threshold).astype(int)
    from sklearn.metrics import classification_report as sk_report
    st.code(sk_report(y_test, y_pred_custom, target_names=['Không rớt', 'Rớt']), language='text')
else:
    st.info("Hãy train mô hình trước để xem biểu đồ threshold.")
