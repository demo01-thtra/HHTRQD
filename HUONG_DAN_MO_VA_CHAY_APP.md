# Hướng Dẫn Mở Và Chạy App

Tài liệu này áp dụng cho repo `HHTRQD`.

## 0. Clone repo

```powershell
git clone https://github.com/demo01-thtra/HHTRQD.git
cd HHTRQD
```

## 1. Thực tế repo đang chạy theo kiến trúc nào

Repo hiện tại không còn là app Streamlit chạy bằng `streamlit run Trang_Chu.py`.

App đang chạy theo 3 phần:

1. `AHP_system_BA`: backend `ASP.NET Core` chạy ở `http://localhost:5045`
2. `AI\ai_api.py`: AI API `Flask` chạy ở `http://localhost:5001`
3. `student_ahp_system_FE`: frontend `Flutter` cho Windows

Frontend gọi trực tiếp:

- `http://localhost:5045/api/...`
- `http://localhost:5001/api/ai/...`

## 2. Những gì cần có trước khi chạy

Máy cần có các thành phần sau:

1. Windows
2. MySQL đang chạy ở cổng `3306`
3. `.NET SDK 10`
4. Python để chạy `AI\ai_api.py`
5. Nếu muốn chạy frontend từ source: cần cài Flutter SDK

## 3. Cấu hình đang dùng trong repo

### Backend .NET

- Project: `AHP_system_BA\DSSStudentRisk.csproj`
- Target framework: `net10.0`
- Port mặc định: `5045`

### Database

Backend đang đọc chuỗi kết nối trong `AHP_system_BA\appsettings.json`:

```json
"DefaultConnection": "server=localhost;port=3306;database=student_project;user=thtra;password=thtra"
```

Nghĩa là MySQL cần chạy và có database `student_project`.

### AI API

- File chạy: `AI\ai_api.py`
- Port mặc định: `5001`
- Model đang dùng: `models\decision_tree_model.pkl`

### Frontend

- Source: `student_ahp_system_FE`
- File exe đã build sẵn:

```text
student_ahp_system_FE\build\windows\x64\runner\Debug\dssstudentfe.exe
```

## 4. Cách mở nhanh app đã build sẵn

Mở 3 cửa sổ terminal tại thư mục gốc repo sau khi clone.

### Bước 1: chạy backend .NET

```powershell
dotnet run --project AHP_system_BA\DSSStudentRisk.csproj --launch-profile http
```

Khi chạy đúng sẽ có dòng gần giống:

```text
Now listening on: http://localhost:5045
```

### Bước 2: chạy AI API

Nếu muốn dùng đúng môi trường đã có sẵn trong repo:

```powershell
.\.venv-1\Scripts\python.exe AI\ai_api.py
```

Khi chạy đúng sẽ có dòng gần giống:

```text
Running on http://127.0.0.1:5001
```

### Bước 3: mở frontend Windows

```powershell
.\student_ahp_system_FE\build\windows\x64\runner\Debug\dssstudentfe.exe
```

## 5. Cách chạy frontend từ source Flutter

Chỉ dùng cách này nếu muốn debug hoặc chỉnh giao diện.

```powershell
cd student_ahp_system_FE
flutter pub get
flutter run -d windows
```

Lưu ý: backend `5045` và AI API `5001` vẫn phải chạy trước.

## 6. Cách kiểm tra app đã chạy đúng chưa

Sau khi bật backend và AI API, có thể kiểm tra nhanh:

### Kiểm tra backend

Mở trình duyệt:

```text
http://localhost:5045/api/student
```

Nếu chạy đúng sẽ trả về JSON danh sách sinh viên.

### Kiểm tra AI API

Mở trình duyệt:

```text
http://localhost:5001/api/ai/model-info
```

Nếu chạy đúng sẽ trả về JSON thông tin mô hình.

## 7. Cách mở project để chỉnh sửa

### Nếu sửa backend .NET

- Mở thư mục `AHP_system_BA`
- Có thể dùng Visual Studio hoặc VS Code

### Nếu sửa AI API Python

- Mở file `AI\ai_api.py`
- Các module tính toán nằm trong `modules\`

### Nếu sửa frontend Flutter

- Mở thư mục `student_ahp_system_FE`
- Entry chính là `student_ahp_system_FE\lib\main.dart`

## 8. Những điểm README cũ đang không còn đúng

`README.md` hiện tại còn mô tả một phiên bản cũ, cụ thể:

1. Ghi rằng giao diện là Streamlit
2. Ghi lệnh chạy là `streamlit run Trang_Chu.py`
3. Ghi dữ liệu dùng SQLite
4. Ghi cấu trúc thư mục có `Trang_Chu.py`, `pages/`, `test_pipeline.py`

Các điểm trên không phản ánh app đang chạy trong repo hiện tại.

## 9. Lỗi thường gặp

### MySQL chưa chạy

Biểu hiện:

- Backend không lên
- API lỗi kết nối database

Cách xử lý:

- Bật dịch vụ MySQL
- Kiểm tra đúng cổng `3306`
- Kiểm tra database `student_project`

### AI API không lên

Biểu hiện:

- Frontend mở được nhưng phần dự đoán AI lỗi

Cách xử lý:

- Chạy lại:

```powershell
.\.venv-1\Scripts\python.exe AI\ai_api.py
```

### Frontend mở nhưng không có dữ liệu

Nguyên nhân thường là backend `5045` hoặc AI API `5001` chưa chạy.

## 10. Lệnh chạy đã kiểm tra thực tế

Các lệnh dưới đây đã được kiểm tra chạy được trong repo này:

```powershell
dotnet run --project AHP_system_BA\DSSStudentRisk.csproj --launch-profile http
.\.venv-1\Scripts\python.exe AI\ai_api.py
.\student_ahp_system_FE\build\windows\x64\runner\Debug\dssstudentfe.exe
```
