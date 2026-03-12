# 🎓 Hệ Thống Hỗ Trợ Quyết Định Cảnh Báo Sớm Sinh Viên Có Nguy Cơ Rớt Môn

## DSS Lai 2 Tầng: AHP + Decision Tree

---

## 📋 Mục Lục

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Kiến trúc hệ thống](#2-kiến-trúc-hệ-thống)
3. [Công nghệ sử dụng](#3-công-nghệ-sử-dụng)
4. [Cấu trúc thư mục](#4-cấu-trúc-thư-mục)
5. [Mô hình lý thuyết](#5-mô-hình-lý-thuyết)
6. [Chi tiết các module](#6-chi-tiết-các-module)
7. [Giao diện ứng dụng (7 trang)](#7-giao-diện-ứng-dụng-7-trang)
8. [Quy trình sử dụng](#8-quy-trình-sử-dụng)
9. [Hướng dẫn cài đặt và chạy](#9-hướng-dẫn-cài-đặt-và-chạy)
10. [Notebook phân tích (AI/)](#10-notebook-phân-tích-ai)
11. [Kết luận](#11-kết-luận)

---

## 1. Tổng Quan Hệ Thống

### 1.1 Bài toán

Trong môi trường giáo dục đại học, việc phát hiện sớm sinh viên có nguy cơ rớt môn là rất quan trọng. Hệ thống này xây dựng một **DSS (Decision Support System – Hệ thống hỗ trợ quyết định)** giúp:

- **Dự báo** sinh viên có khả năng rớt môn dựa trên dữ liệu lịch sử
- **Đánh giá** mức độ rủi ro thông qua trọng số chuyên gia
- **Cảnh báo sớm** để giảng viên / cố vấn học tập can thiệp kịp thời
- **Theo dõi** quá trình can thiệp và kết quả

### 1.2 Phương pháp tiếp cận: DSS lai 2 tầng

Hệ thống kết hợp **2 phương pháp** bổ trợ cho nhau:

| Tầng | Phương pháp | Vai trò |
|------|-------------|---------|
| **Tầng 1** | **AHP** (Analytic Hierarchy Process) | Trả lời: *"Tiêu chí nào quan trọng hơn theo chuyên gia?"* |
| **Tầng 2** | **Decision Tree** (Cây Quyết Định) | Trả lời: *"Từ dữ liệu lịch sử, sinh viên nào có khả năng rớt?"* |

**Lý do kết hợp:**
- AHP đơn thuần chỉ dựa trên chủ quan chuyên gia → thiếu cơ sở dữ liệu
- Decision Tree đơn thuần chỉ dựa trên dữ liệu → thiếu nghiệp vụ chuyên gia
- **Lai 2 tầng** = lấy ưu điểm cả hai: vừa có cơ sở dữ liệu, vừa tích hợp ý kiến chuyên gia

---

## 2. Kiến Trúc Hệ Thống

```
┌─────────────────────────────────────────────────────────┐
│                    GIAO DIỆN (Streamlit)                │
│  Trang_Chu.py → 7 trang trong pages/                   │
├─────────────────────────────────────────────────────────┤
│                    LOGIC NGHIỆP VỤ                      │
│  ┌──────────┐  ┌──────────┐  ┌──────────────────────┐  │
│  │  AHP     │  │ ML Model │  │    Risk Engine        │  │
│  │ (ahp.py) │  │(ml_model)│  │  (risk_engine.py)     │  │
│  │          │  │          │  │                        │  │
│  │ Trọng số │  │ p_fail   │──│→ final_score =        │  │
│  │ chuyên   │──│ xác suất │  │  0.7×p_fail +         │  │
│  │ gia      │  │ rớt môn  │  │  0.3×ahp_score        │  │
│  └──────────┘  └──────────┘  └──────────────────────┘  │
├─────────────────────────────────────────────────────────┤
│                    DỮ LIỆU                              │
│  ┌────────────────┐  ┌──────────────┐  ┌────────────┐  │
│  │ Excel/CSV Data │  │ SQLite DB    │  │ Model .pkl │  │
│  │ (data/)        │  │ (database.db)│  │ (models/)  │  │
│  └────────────────┘  └──────────────┘  └────────────┘  │
└─────────────────────────────────────────────────────────┘
```

---

## 3. Công Nghệ Sử Dụng

| Thành phần | Công nghệ | Phiên bản |
|------------|-----------|-----------|
| Ngôn ngữ | Python | 3.x |
| Giao diện web | Streamlit | ≥ 1.30 |
| Machine Learning | scikit-learn (DecisionTreeClassifier) | ≥ 1.3 |
| Xử lý dữ liệu | pandas, numpy | |
| Trực quan hóa | matplotlib, seaborn | |
| Cơ sở dữ liệu | SQLite | |
| Lưu mô hình | joblib | |
| Đọc Excel | openpyxl | |
| Notebook | Jupyter (ipykernel) | |

---

## 4. Cấu Trúc Thư Mục

```
demo1/
├── Trang_Chu.py                  # Entry point – Streamlit app
├── requirements.txt              # Danh sách thư viện
├── test_pipeline.py              # Integration test
│
├── modules/                      # Backend logic
│   ├── __init__.py
│   ├── ahp.py                   # Module AHP (Saaty 1-9)
│   ├── ml_model.py              # Module Decision Tree
│   ├── risk_engine.py           # Module kết hợp AHP + DT
│   └── database.py              # Module SQLite
│
├── pages/                        # 7 trang Streamlit
│   ├── 1_Dashboard.py           # Tổng quan biểu đồ
│   ├── 2_Du_Lieu.py             # Quản lý dữ liệu
│   ├── 3_AHP.py                 # Thiết lập trọng số AHP
│   ├── 4_Train_Model.py         # Huấn luyện mô hình
│   ├── 5_Canh_Bao.py            # Danh sách cảnh báo
│   ├── 6_Chi_Tiet_SV.py         # Chi tiết sinh viên
│   └── 7_Can_Thiep.py           # Quản lý can thiệp
│
├── AI/                           # Jupyter Notebooks
│   ├── train_model.ipynb         # Huấn luyện + AHP + Risk Engine
│   ├── train_model_output.ipynb  # Bản có output
│   └── predict.ipynb             # Dự đoán DSS cho sinh viên mới
│
├── data/                         # Dữ liệu
│   ├── 1k_Data điểm.xlsx        # 1000 sinh viên (dữ liệu gốc)
│   ├── 1k_Data_diem_labeled.xlsx # Dữ liệu đã gán nhãn + điểm rủi ro
│   └── dss_database.db          # SQLite DB (can thiệp, AHP, model)
│
└── models/                       # Mô hình đã lưu
    └── decision_tree_model.pkl   # Decision Tree đã train
```

---

## 5. Mô Hình Lý Thuyết

### 5.1 AHP – Analytic Hierarchy Process (Saaty, 1980)

**Mục đích:** Tính trọng số ưu tiên cho các tiêu chí dựa trên ý kiến chuyên gia.

**Quy trình:**

1. **Xác định tiêu chí đánh giá** (ví dụ: Điểm kiểm tra, Chuyên cần, Giờ tự học)
2. **So sánh cặp** theo thang Saaty 1-9:

| Giá trị | Ý nghĩa |
|---------|---------|
| 1 | Quan trọng bằng nhau |
| 3 | Quan trọng hơn vừa phải |
| 5 | Quan trọng hơn nhiều |
| 7 | Rất quan trọng hơn |
| 9 | Cực kỳ quan trọng hơn |
| 2, 4, 6, 8 | Giá trị trung gian |

3. **Tính trọng số** bằng phương pháp eigenvector (vector riêng):
   - Tìm giá trị riêng lớn nhất λ_max của ma trận so sánh cặp
   - Trọng số = vector riêng tương ứng λ_max, chuẩn hóa tổng = 1

4. **Kiểm tra tính nhất quán:**
   - CI (Consistency Index) = (λ_max − n) / (n − 1)
   - CR (Consistency Ratio) = CI / RI
   - **CR ≤ 0.10** → Ma trận nhất quán, trọng số hợp lệ
   - **CR > 0.10** → Cần đánh giá lại ma trận so sánh cặp

**Ví dụ kết quả AHP (3 tiêu chí):**

| Tiêu chí | Trọng số |
|----------|----------|
| Test_Score | 0.637 |
| Attendance (%) | 0.258 |
| Study_Hours | 0.105 |
| **CR** | **0.0332** (nhất quán ✅) |

### 5.2 Decision Tree – Cây Quyết Định

**Mục đích:** Học từ dữ liệu lịch sử để dự đoán sinh viên có rớt môn hay không.

**Cấu hình mô hình:**
- **Phân loại nhị phân:** 0 = Không rớt, 1 = Rớt
- **Tiêu chí Gini** để chọn thuộc tính phân chia
- **class_weight = 'balanced'** để cân bằng dữ liệu mất cân đối
- **max_depth = 5** để tránh overfitting
- **min_samples_leaf = 5** để đảm bảo lá có đủ mẫu

**Tiêu chí gán nhãn nhị phân:**
- **Rớt (1):** `Test_Score < 4.0` HOẶC `Attendance < 50%`
- **Không rớt (0):** Ngược lại

**Ưu điểm của Decision Tree:**
- **White-box model:** Dễ hiểu, dễ giải thích cho giảng viên
- **Trích xuất luật:** Có thể in ra các quy tắc if-then
- **Decision path:** Hiển thị đường đi quyết định cho từng sinh viên

### 5.3 Risk Engine – Kết hợp 2 tầng

**Công thức kết hợp:**

```
final_score = α × p_fail + (1 − α) × ahp_score
```

Trong đó:
- **p_fail** = Xác suất rớt từ Decision Tree (predict_proba)
- **ahp_score** = Điểm rủi ro AHP = Σ(w_i × risk_i)
- **α = 0.7** (trọng số cho mô hình dữ liệu, có thể điều chỉnh)
- **risk_i** = Giá trị rủi ro chuẩn hóa (0-1) cho từng tiêu chí

**Cách tính risk_i (chuẩn hóa rủi ro):**

| Tiêu chí | Công thức chuẩn hóa | Ý nghĩa |
|----------|---------------------|---------|
| Test_Score | 1 − score/10 | Điểm thấp → rủi ro cao |
| Attendance (%) | 1 − attendance/100 | Vắng nhiều → rủi ro cao |
| Study_Hours | 1 − hours/8 | Học ít → rủi ro cao |

**Ngưỡng phân loại 3 mức cảnh báo:**

| Mức | Điều kiện | Màu | Hành động |
|-----|-----------|-----|-----------|
| 🔴 **Cao** | final_score ≥ 0.75 | Đỏ | Can thiệp ngay |
| 🟡 **Trung bình** | 0.55 ≤ final_score < 0.75 | Vàng | Theo dõi, tư vấn |
| 🟢 **Thấp** | final_score < 0.55 | Xanh | Bình thường |

---

## 6. Chi Tiết Các Module

### 6.1 `modules/ahp.py`

| Hàm | Mô tả |
|-----|-------|
| `calculate_weights(matrix)` | Tính trọng số bằng eigenvector → trả về (weights, λ_max, CI, CR) |
| `is_consistent(cr)` | Kiểm tra CR ≤ 0.10 |
| `create_default_matrix(n)` | Tạo ma trận đơn vị n×n |
| `get_ri(n)` | Lấy Random Index cho n tiêu chí |

Hằng số: `RI_TABLE`, `SAATY_SCALE`, `SAATY_VALUES`, `SAATY_LABELS`

### 6.2 `modules/ml_model.py`

| Hàm | Mô tả |
|-----|-------|
| `create_binary_label(df)` | Tạo nhãn 0/1 từ điểm và chuyên cần |
| `train_decision_tree(X, y, ...)` | Huấn luyện Decision Tree → (model, metrics, split_data) |
| `get_feature_importance(model, features)` | DataFrame tầm quan trọng các tiêu chí |
| `get_tree_rules(model, features)` | Xuất cây dạng text (if-then rules) |
| `get_decision_path_for_student(model, X, features)` | Đường đi quyết định cho 1 sinh viên |
| `plot_decision_tree(model, features)` | Vẽ cây quyết định đồ họa |
| `save_model(model)` / `load_model()` | Lưu/tải mô hình (.pkl) |
| `predict_proba_fail(model, X)` | Xác suất rớt (class=1) cho từng mẫu |

### 6.3 `modules/risk_engine.py`

| Hàm | Mô tả |
|-----|-------|
| `normalize_to_risk(series, col)` | Chuẩn hóa giá trị → rủi ro 0-1 |
| `calculate_ahp_score(df, criteria, weights)` | Tính điểm AHP = Σ(w_i × risk_i) |
| `calculate_final_score(p_fail, ahp_score, α)` | Kết hợp: α×p_fail + (1-α)×ahp_score |
| `classify_risk_level(score)` | Phân loại Cao / Trung bình / Thấp |
| `get_top_risk_factors(...)` | Top N tiêu chí tác động mạnh nhất |
| `generate_warning_reason(factors)` | Sinh lý do cảnh báo bằng text |
| `suggest_intervention(level, factors)` | Gợi ý hành động can thiệp |

### 6.4 `modules/database.py`

**Database:** SQLite (`data/dss_database.db`)

| Bảng | Mô tả |
|------|-------|
| `interventions` | Lưu hành động can thiệp (tên SV, loại, trạng thái, kết quả) |
| `ahp_history` | Lịch sử ma trận AHP (trọng số, CI, CR, nhất quán) |
| `model_history` | Lịch sử huấn luyện mô hình (accuracy, F1, tham số) |

Các hàm CRUD: `add_intervention()`, `get_interventions()`, `update_intervention()`, `delete_intervention()`, `save_ahp_result()`, `get_latest_ahp()`, `save_model_info()`, `get_latest_model_info()`

---

## 7. Giao Diện Ứng Dụng (7 Trang)

### Trang chủ (`Trang_Chu.py`)
- Giới thiệu hệ thống DSS lai 2 tầng
- Hướng dẫn quy trình 7 bước
- Trạng thái hiện tại (dữ liệu / AHP / mô hình)

### Trang 1: 📊 Dashboard (`1_Dashboard.py`)
- **Metric cards:** Tổng SV, số rủi ro Cao / TB / Thấp
- **Pie chart:** Tỷ lệ phân bố mức rủi ro
- **Bar chart:** Số SV theo lớp và mức rủi ro (stacked)
- **Histogram:** Phân bố final_score với 2 ngưỡng
- **Top 10:** Sinh viên rủi ro cao nhất

### Trang 2: 📁 Dữ Liệu (`2_Du_Lieu.py`)
- **Upload:** Tải CSV/Excel từ máy
- **Dữ liệu có sẵn:** Chọn file từ thư mục `data/`
- **Tạo mẫu:** Sinh dữ liệu synthetic (100-5000 SV, nhiều cột)
- **Thống kê:** Mô tả, kiểm tra missing, duplicate, kiểu dữ liệu

### Trang 3: ⚖️ AHP (`3_AHP.py`)
- **Chọn tiêu chí:** 3-10 tiêu chí từ dữ liệu
- **Nhập so sánh cặp:** Slider với thang Saaty 1-9
- **Tính trọng số:** Eigenvector, CI, CR
- **Kiểm tra nhất quán:** CR ≤ 0.10
- **Lưu DB:** Tự động lưu khi nhất quán
- **Biểu đồ:** Bar chart trọng số

### Trang 4: 🌳 Train Model (`4_Train_Model.py`)
- **Tạo nhãn nhị phân:** Tùy chỉnh ngưỡng điểm/chuyên cần
- **Chọn features:** Từ các cột số
- **Tune tham số:** max_depth, min_samples_leaf, test_size, ccp_alpha
- **Huấn luyện:** DecisionTreeClassifier (balanced)
- **Đánh giá:** Accuracy, Precision, Recall, F1, Confusion Matrix
- **Feature Importance:** Biểu đồ tầm quan trọng
- **Tree Visualization:** Vẽ cây quyết định
- **Threshold Tuning:** Precision-Recall curve, chọn ngưỡng tối ưu

### Trang 5: ⚠️ Cảnh Báo (`5_Canh_Bao.py`)
- **Tính điểm rủi ro:** Kết hợp p_fail + ahp_score → final_score
- **Lọc:** Theo mức rủi ro (Cao/TB/Thấp), theo lớp
- **2 đợt cảnh báo:** Đầu kỳ (tuần 4) và sau giữa kỳ (tuần 9)
- **Bảng màu:** Đỏ/vàng/xanh theo mức rủi ro
- **Xuất CSV:** Tải danh sách cảnh báo

### Trang 6: 👤 Chi Tiết SV (`6_Chi_Tiet_SV.py`)
- **Chọn sinh viên:** Dropdown theo tên
- **3 gauge:** p_fail, ahp_score, final_score
- **Rule path:** Đường đi quyết định trong cây
- **Top 3 AHP factors:** Biểu đồ tiêu chí tác động mạnh nhất
- **Lý do cảnh báo:** Text giải thích
- **Đề xuất can thiệp:** Gợi ý hành động cụ thể
- **Lịch sử can thiệp:** Các lần can thiệp trước đó

### Trang 7: 📝 Can Thiệp (`7_Can_Thiep.py`)
- **Thêm can thiệp:** Chọn SV, loại, mô tả
- **Danh sách:** Bảng tất cả can thiệp (lọc, tìm kiếm)
- **Cập nhật trạng thái:** Chưa thực hiện → Đang thực hiện → Hoàn thành
- **Thống kê:** Số can thiệp theo trạng thái
- **Bảng màu:** Theo trạng thái (xanh/vàng/đỏ)

---

## 8. Quy Trình Sử Dụng

```
Bước 1: Nhập dữ liệu        → Trang "Dữ Liệu"
    ↓
Bước 2: Thiết lập AHP        → Trang "AHP"
    ↓
Bước 3: Huấn luyện mô hình   → Trang "Train Model"
    ↓
Bước 4: Xem tổng quan        → Trang "Dashboard"
    ↓
Bước 5: Danh sách cảnh báo   → Trang "Cảnh Báo"
    ↓
Bước 6: Xem chi tiết SV      → Trang "Chi Tiết SV"
    ↓
Bước 7: Ghi nhận can thiệp   → Trang "Can Thiệp"
```

---

## 9. Hướng Dẫn Cài Đặt và Chạy

### 9.1 Yêu cầu

- Python 3.8 trở lên
- pip (Python package manager)

### 9.2 Cài đặt

```bash
# Clone repository
git clone https://github.com/BTdemo01/HoTroRaQuyetDinh.git
cd HoTroRaQuyetDinh

# Cài đặt thư viện
pip install -r requirements.txt
```

### 9.3 Chạy ứng dụng

```bash
# Chạy Streamlit app
streamlit run Trang_Chu.py
```

Ứng dụng sẽ mở trên trình duyệt tại: **http://localhost:8501**

### 9.4 Chạy test

```bash
python test_pipeline.py
```

---

## 10. Notebook Phân Tích (AI/)

Thư mục `AI/` chứa 3 Jupyter Notebook phân tích chi tiết:

### `train_model.ipynb`
Notebook đầy đủ 12 bước:
1. Import thư viện + modules
2. Đọc dữ liệu (1000 SV)
3. Tạo nhãn nhị phân (Rớt/Không rớt)
4. Chia Train/Test (80/20)
5. Huấn luyện Decision Tree (balanced)
6. Đánh giá (Confusion Matrix, Classification Report)
7. Cấu trúc cây + Threshold Tuning
8. Feature Importance + Precision-Recall curve
9. AHP – Tính trọng số Saaty
10. Risk Engine – Kết hợp AHP + DT
11. So sánh 3 phương pháp (AHP-only vs DT-only vs Hybrid)
12. Lưu mô hình + xuất dữ liệu

### `train_model_output.ipynb`
Bản sao của `train_model.ipynb` với output đã chạy sẵn, tiện cho việc xem kết quả mà không cần chạy lại.

### `predict.ipynb`
Notebook dự đoán cho sinh viên mới:
- Load mô hình đã train + trọng số AHP
- Hàm `predict_student_dss()` tính p_fail, ahp_score, final_score
- Demo test 8 trường hợp đa dạng
- Nhập điểm thủ công để dự đoán

---

## 11. Kết Luận

### Ưu điểm của hệ thống

1. **Mô hình lai:** Kết hợp cả dữ liệu (Decision Tree) và chuyên gia (AHP), khắc phục nhược điểm của từng phương pháp đơn lẻ
2. **Minh bạch (Explainable AI):** Decision Tree là white-box model, có thể giải thích lý do dự đoán cho từng sinh viên
3. **Tùy chỉnh:** Chuyên gia có thể thay đổi trọng số AHP, ngưỡng phân loại, tham số mô hình
4. **Đầy đủ quy trình:** Từ nhập dữ liệu → phân tích → cảnh báo → can thiệp → theo dõi kết quả
5. **Giao diện thân thiện:** Streamlit với biểu đồ trực quan, bảng màu dễ đọc

### Hạn chế và hướng phát triển

- Có thể mở rộng thêm nhiều tiêu chí (điểm quá trình, hoạt động LMS, ...)
- Tích hợp thêm các mô hình ML khác (Random Forest, Gradient Boosting)
- Kết nối với hệ thống quản lý đào tạo thực tế
- Thêm tính năng gửi email/SMS cảnh báo tự động

---

## 👥 Thông Tin

- **Đồ án môn học:** Hệ thống hỗ trợ quyết định
- **Công nghệ chính:** Python, Streamlit, scikit-learn, AHP
- **Repository:** [https://github.com/BTdemo01/HoTroRaQuyetDinh](https://github.com/BTdemo01/HoTroRaQuyetDinh)

---

*© 2025 – Hệ thống DSS lai AHP + Decision Tree*
