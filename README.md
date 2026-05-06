# DSS Student Risk

Hệ thống hỗ trợ cảnh báo sớm sinh viên có nguy cơ rớt môn, xây dựng từ 3 phần chính:

1. Backend `ASP.NET Core` quản lý dữ liệu, AHP, kết quả rủi ro và gửi email
2. AI API `Flask` phục vụ dự đoán Decision Tree
3. Frontend `Flutter Windows` để vận hành toàn bộ quy trình

README này mô tả đúng mã nguồn hiện tại trong repo. Hướng dẫn chi tiết hơn theo từng bước có tại [HUONG_DAN_MO_VA_CHAY_APP.md](HUONG_DAN_MO_VA_CHAY_APP.md).

## Clone repo

```powershell
git clone https://github.com/demo01-thtra/HHTRQD.git
cd HHTRQD
```

## Kiến trúc hiện tại

| Thành phần | Thư mục | Vai trò | Port mặc định |
|---|---|---|---|
| Backend API | `AHP_system_BA` | CRUD sinh viên, điểm số, AHP, risk, email | `5045` |
| AI API | `AI` + `modules` + `models` | Dự đoán Decision Tree, retrain, model info | `5001` |
| Frontend | `student_ahp_system_FE` | Dashboard và các màn hình vận hành | desktop Windows |
| Dữ liệu huấn luyện | `data` | File Excel đầu vào cho AI/notebook | - |

Lưu ý:

- Repo hiện tại không dùng `streamlit run Trang_Chu.py` làm entrypoint.
- `requirements.txt` ở thư mục gốc chỉ phản ánh phần Python cũ/thử nghiệm, không phải cách mở app hiện tại.

## Chức năng chính

- Dashboard tổng quan số lượng sinh viên theo mức rủi ro.
- Quản lý sinh viên: thêm, sửa, xóa, tìm kiếm, import Excel, export Excel.
- Quản lý dữ liệu điểm gần nhất của từng sinh viên.
- Thiết lập trọng số AHP cho 3 tiêu chí: `Test Score`, `Attendance`, `Study Hours`.
- Tính toán kết quả AHP chi tiết và phương án ưu tiên `A1`, `A2`, `A3`.
- Tính risk cho từng sinh viên hoặc toàn bộ danh sách.
- Màn hình AI Prediction để:
  - dự đoán Pass/Fail bằng Decision Tree,
  - xem thông tin mô hình,
  - chỉnh threshold và retrain mô hình.
- Gửi email cảnh báo đơn lẻ hoặc hàng loạt cho sinh viên rủi ro trung bình/cao.

## Cấu trúc thư mục

```text
HHTRQD/
├── AHP_system_BA/                # ASP.NET Core backend
├── AI/                           # Flask AI API + notebook liên quan
├── data/                         # Dữ liệu Excel đầu vào
├── models/                       # Model Decision Tree đã lưu
├── modules/                      # Module Python dùng cho AI API
├── student_ahp_system_FE/        # Flutter frontend
├── HUONG_DAN_MO_VA_CHAY_APP.md   # Hướng dẫn mở app chi tiết
├── mysql_init.sql
└── README.md
```

## Công nghệ sử dụng

| Nhóm | Công nghệ |
|---|---|
| Backend | `.NET 10`, `ASP.NET Core`, `Entity Framework Core`, `Pomelo MySQL` |
| Frontend | `Flutter`, `Provider`, `http`, `fl_chart`, `google_fonts` |
| AI API | `Python`, `Flask`, `scikit-learn`, `pandas`, `numpy`, `joblib` |
| Cơ sở dữ liệu | `MySQL` |
| Import/export | `ClosedXML`, `EPPlus`, `Excel` |
| Email | `MailKit`, `MimeKit` |

## Yêu cầu môi trường

Tài liệu này ưu tiên luồng chạy trên Windows.

1. MySQL đang chạy ở `localhost:3306`
2. `.NET SDK 10`
3. Python 3.x
4. Nếu chạy frontend từ source: cần Flutter SDK

## Cấu hình quan trọng

### Database

Backend đọc chuỗi kết nối từ `AHP_system_BA/appsettings.json`.

Theo cấu hình hiện tại, backend mong đợi một database MySQL cục bộ tên `student_project`. Nếu bạn dùng database khác, hãy sửa lại `ConnectionStrings:DefaultConnection`.

Nếu database chưa có schema, có thể chạy migration:

```powershell
dotnet ef database update --project AHP_system_BA
```

Các migration hiện có nằm trong `AHP_system_BA/Migrations`.

### Email

Màn hình gửi cảnh báo dùng `EmailSettings` trong `AHP_system_BA/appsettings.json`.

Trước khi dùng tính năng gửi email, cần cấu hình:

- `SenderEmail`
- `SenderPassword`
- `SmtpServer`
- `SmtpPort`
- `SenderName`

### AI model

AI API đọc model từ:

```text
models/decision_tree_model.pkl
```

Nếu file này thiếu, API AI sẽ không dự đoán được cho đến khi bạn train lại model.

## Cách chạy app

### Cách 1: mở nhanh bản Windows đã build sẵn

Mở terminal tại thư mục gốc repo sau khi clone.

#### Bước 1: chạy backend

```powershell
dotnet run --project AHP_system_BA\DSSStudentRisk.csproj --launch-profile http
```

Backend mặc định lắng nghe tại:

```text
http://localhost:5045
```

#### Bước 2: chạy AI API

Nếu repo đã có sẵn môi trường ảo phù hợp:

```powershell
.\.venv-1\Scripts\python.exe AI\ai_api.py
```

Nếu chưa có môi trường Python, tạo mới:

```powershell
py -m venv .venv-ai
.\.venv-ai\Scripts\activate
pip install -r AI\requirements.txt
python AI\ai_api.py
```

AI API mặc định lắng nghe tại:

```text
http://localhost:5001
```

#### Bước 3: mở frontend Windows

```powershell
.\student_ahp_system_FE\build\windows\x64\runner\Debug\dssstudentfe.exe
```

### Cách 2: chạy frontend từ source Flutter

Chỉ dùng cách này nếu cần debug hoặc chỉnh sửa giao diện:

```powershell
cd student_ahp_system_FE
flutter pub get
flutter run -d windows
```

Lưu ý: backend `5045` và AI API `5001` vẫn phải chạy trước.

## Kiểm tra nhanh sau khi chạy

### Kiểm tra backend

Mở:

```text
http://localhost:5045/api/student
```

Nếu đúng sẽ trả về JSON danh sách sinh viên.

### Kiểm tra AI API

Mở:

```text
http://localhost:5001/api/ai/model-info
```

Nếu đúng sẽ trả về JSON thông tin mô hình Decision Tree.

## Các màn hình chính trên frontend

- `Dashboard`
- `Quản lý sinh viên`
- `Thiết lập AHP`
- `Báo cáo AHP`
- `AI dự đoán nguy cơ`
- `Gửi cảnh báo`

Trong luồng AHP còn có các màn hình con như:

- so sánh tiêu chí,
- đánh giá phương án,
- kết quả cuối cùng.

## Các API chính

### Student

Base route: `api/student`

- `GET /api/student`: lấy toàn bộ sinh viên kèm performance
- `POST /api/student`: tạo sinh viên
- `PUT /api/student/{id}`: cập nhật sinh viên
- `DELETE /api/student/{id}`: xóa sinh viên và dữ liệu liên quan
- `POST /api/student/students-excel-json`: import Excel vào DB
- `GET /api/student/export-excel`: export danh sách sinh viên ra Excel

### Performance

Base route: `api/performance`

- `GET /api/performance`: lấy điểm gần nhất của từng sinh viên
- `GET /api/performance/{studentId}`: lấy điểm gần nhất theo sinh viên
- `POST /api/performance`: thêm bản ghi điểm

### AHP

Base route: `api/ahp`

- `POST /api/ahp`: lưu trọng số tiêu chí AHP
- `POST /api/ahp/criteria`: tính ma trận tiêu chí
- `POST /api/ahp/alternative`: tính trọng số phương án
- `GET /api/ahp/final`: lấy kết quả cuối cùng `A1/A2/A3`
- `GET /api/ahp/report`: lấy báo cáo AHP chi tiết

### Risk

Base route: `api/risk`

- `POST /api/risk/{studentId}`: tính risk cho 1 sinh viên
- `POST /api/risk/calculate-all`: tính risk cho toàn bộ sinh viên
- `GET /api/risk/results`: lấy kết quả risk
- `GET /api/risk/top-risk`: top sinh viên rủi ro cao
- `GET /api/risk/summary`: thống kê số lượng risk theo mức

### Notification

Base route: `api/notification`

- `POST /api/notification/send`: gửi email cho 1 sinh viên
- `POST /api/notification/send-batch`: gửi email hàng loạt

### AI API

Base route: `api/ai`

- `POST /api/ai/predict`: dự đoán 1 sinh viên
- `POST /api/ai/predict-batch`: dự đoán nhiều sinh viên
- `GET /api/ai/model-info`: thông tin mô hình
- `GET /api/ai/thresholds`: đọc threshold hiện tại
- `POST /api/ai/retrain`: retrain model theo threshold mới

## Ghi chú triển khai

- Frontend đang gọi thẳng các URL `http://localhost:5045` và `http://localhost:5001` trong `student_ahp_system_FE/lib/Services`.
- Backend `api/risk` có cơ chế fallback sang AHP-only nếu AI API không phản hồi.
- AI API dùng chung dữ liệu trong `data` và model trong `models`.
- Các notebook trong `AI` phục vụ phân tích/train thử nghiệm, không phải entrypoint của app runtime.

## Lỗi thường gặp

### Backend không lên

Nguyên nhân thường gặp:

- MySQL chưa chạy
- sai connection string
- database chưa tạo schema

Cách xử lý:

- kiểm tra MySQL ở `3306`
- sửa `AHP_system_BA/appsettings.json`
- chạy:

```powershell
dotnet ef database update --project AHP_system_BA
```

### Frontend mở được nhưng không có dữ liệu

Thường là do backend `5045` chưa chạy hoặc không kết nối được database.

### Chức năng AI dự đoán không hoạt động

Thường là do AI API `5001` chưa chạy hoặc model `models/decision_tree_model.pkl` không tồn tại.

### Gửi email lỗi

Kiểm tra lại `EmailSettings` trong `AHP_system_BA/appsettings.json`, đặc biệt là tài khoản gửi và app password.

## Tệp hướng dẫn bổ sung

- Hướng dẫn mở app chi tiết: [HUONG_DAN_MO_VA_CHAY_APP.md](HUONG_DAN_MO_VA_CHAY_APP.md)
- Backend project: [AHP_system_BA/DSSStudentRisk.csproj](AHP_system_BA/DSSStudentRisk.csproj)
- Frontend entry: [student_ahp_system_FE/lib/main.dart](student_ahp_system_FE/lib/main.dart)
- AI API entry: [AI/ai_api.py](AI/ai_api.py)
