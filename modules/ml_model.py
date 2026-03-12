"""
Module ML - Decision Tree Classifier
Huấn luyện và đánh giá mô hình cây quyết định cho dự báo rớt môn
"""
import numpy as np
import pandas as pd
from sklearn.tree import DecisionTreeClassifier, export_text, plot_tree
from sklearn.model_selection import train_test_split
from sklearn.metrics import (
    accuracy_score, classification_report,
    confusion_matrix, f1_score, precision_score, recall_score
)
import joblib
import matplotlib.pyplot as plt
import os

MODEL_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'models')
os.makedirs(MODEL_DIR, exist_ok=True)
DEFAULT_MODEL_PATH = os.path.join(MODEL_DIR, 'decision_tree_model.pkl')


def create_binary_label(df, score_col='Test_Score', attendance_col='Attendance (%)',
                        score_threshold=4.0, attendance_threshold=50.0):
    """
    Tạo nhãn nhị phân: 1 = rớt, 0 = không rớt
    Sinh viên rớt nếu điểm < ngưỡng HOẶC chuyên cần < ngưỡng
    """
    fail = (df[score_col] < score_threshold) | (df[attendance_col] < attendance_threshold)
    return fail.astype(int)


def train_decision_tree(X, y, max_depth=5, min_samples_leaf=5,
                        class_weight='balanced', random_state=42,
                        test_size=0.2, ccp_alpha=0.0):
    """
    Huấn luyện Decision Tree Classifier (nhị phân: rớt/không rớt)
    """
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=test_size, random_state=random_state, stratify=y
    )

    model = DecisionTreeClassifier(
        max_depth=max_depth,
        min_samples_leaf=min_samples_leaf,
        class_weight=class_weight,
        random_state=random_state,
        criterion='gini',
        ccp_alpha=ccp_alpha
    )
    model.fit(X_train, y_train)

    y_pred = model.predict(X_test)
    y_proba = model.predict_proba(X_test)

    report = classification_report(y_test, y_pred, output_dict=True, zero_division=0)
    metrics = {
        'accuracy': accuracy_score(y_test, y_pred),
        'precision': precision_score(y_test, y_pred, average='weighted', zero_division=0),
        'recall': recall_score(y_test, y_pred, average='weighted', zero_division=0),
        'f1': f1_score(y_test, y_pred, average='weighted', zero_division=0),
        'confusion_matrix': confusion_matrix(y_test, y_pred),
        'classification_report': report,
    }

    split_data = {
        'X_train': X_train, 'X_test': X_test,
        'y_train': y_train, 'y_test': y_test,
        'y_pred': y_pred, 'y_proba': y_proba,
    }
    return model, metrics, split_data


def get_feature_importance(model, feature_names):
    """Trả về DataFrame feature importance sắp xếp giảm dần"""
    return pd.DataFrame({
        'Tiêu chí': feature_names,
        'Tầm quan trọng': model.feature_importances_
    }).sort_values('Tầm quan trọng', ascending=False).reset_index(drop=True)


def get_tree_rules(model, feature_names):
    """Xuất luật cây quyết định dạng text"""
    return export_text(model, feature_names=list(feature_names),
                       class_names=['Không rớt', 'Rớt'])


def get_decision_path_for_student(model, X_single, feature_names):
    """Lấy đường đi quyết định cho 1 sinh viên cụ thể"""
    node_indicator = model.decision_path(X_single)
    feature = model.tree_.feature
    threshold = model.tree_.threshold

    node_index = node_indicator.indices[
        node_indicator.indptr[0]:node_indicator.indptr[1]
    ]

    rules = []
    for node_id in node_index:
        if feature[node_id] >= 0:
            feat_name = feature_names[feature[node_id]]
            thresh = threshold[node_id]
            value = X_single.iloc[0, feature[node_id]]
            if value <= thresh:
                rules.append(f"{feat_name} = {value:.2f} ≤ {thresh:.2f}")
            else:
                rules.append(f"{feat_name} = {value:.2f} > {thresh:.2f}")
    return rules


def plot_decision_tree(model, feature_names, figsize=(20, 10)):
    """Vẽ cây quyết định và trả về figure"""
    fig, ax = plt.subplots(figsize=figsize)
    plot_tree(model, feature_names=list(feature_names),
              class_names=['Không rớt', 'Rớt'],
              filled=True, rounded=True, fontsize=9, ax=ax)
    plt.tight_layout()
    return fig


def save_model(model, path=None):
    """Lưu mô hình"""
    path = path or DEFAULT_MODEL_PATH
    joblib.dump(model, path)
    return path


def load_model(path=None):
    """Tải mô hình đã lưu"""
    path = path or DEFAULT_MODEL_PATH
    if os.path.exists(path):
        return joblib.load(path)
    return None


def predict_proba_fail(model, X):
    """Trả về xác suất rớt (class=1) cho từng mẫu"""
    proba = model.predict_proba(X)
    if proba.shape[1] == 2:
        return proba[:, 1]
    return proba[:, 0]
