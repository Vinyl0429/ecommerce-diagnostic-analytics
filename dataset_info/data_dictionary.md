## 1. THÔNG TIN TẬP DỮ LIỆU & KIẾN TRÚC (DATA DICTIONARY)

Hệ thống dữ liệu của Xóm E-Com được tôi quy hoạch và mô hình hóa theo cấu trúc **Star Schema (Sơ đồ hình sao)**, lấy bảng sự kiện (Fact Table) làm trung tâm, kết nối với các bảng danh mục (Dimension Tables) nhằm tối ưu hóa hiệu suất truy vấn.

| Tên Bảng (Table) | Tên Cột (Column) | Kiểu Dữ Liệu | Loại Khóa | Ý Nghĩa Chức Năng (Description) |
| :--- | :--- | :--- | :---: | :--- |
| **Fact_Sales** | `row_id` | INT | **PK** | Định danh duy nhất cho từng dòng dữ liệu. |
| *(Sự kiện giao dịch)* | `order_id` | NVARCHAR | - | Mã định danh của đơn hàng. |
| | `order_date` | DATE | FK | Ngày ghi nhận giao dịch. |
| | `customer_id` | NVARCHAR | FK | Liên kết định danh khách hàng tới bảng Dim_Customer. |
| | `product_code` | NVARCHAR | FK | Liên kết thông tin sản phẩm tới bảng Dim_Product. |
| | `region_code` | NVARCHAR | FK | Liên kết thông tin khu vực tới bảng Dim_Region. |
| | `segment` | NVARCHAR | - | Phân khúc mua hàng tại thời điểm giao dịch. |
| | `quantity` | INT | - | Số lượng sản phẩm trên mỗi dòng đơn hàng. |
| | `sales` | DECIMAL | - | Doanh thu thuần ghi nhận. |
| | `discount` | DECIMAL | - | Tỷ lệ chiết khấu áp dụng cho sản phẩm. |
| | `profit` | DECIMAL | - | Lợi nhuận ròng thực tế. |
| | | | | |
| **Dim_Product** | `product_code` | NVARCHAR | **PK** | Mã định danh duy nhất của sản phẩm. |
| *(Thông tin Sản phẩm)* | `product` | NVARCHAR | - | Tên định danh chi tiết của sản phẩm. |
| | `category` | NVARCHAR | - | Ngành hàng lớn. |
| | `subcategory` | NVARCHAR | - | Ngành hàng phụ. |
| | | | | |
| **Dim_Customer**| `customer_id` | NVARCHAR | **PK** | Mã định danh duy nhất của khách hàng. |
| *(Thông tin Khách hàng)*| `first_name` / `last_name` | NVARCHAR | - | Họ và tên khách hàng. |
| | `birth_date` | DATE | - | Ngày tháng năm sinh. |
| | `gender` | NVARCHAR | - | Giới tính. |
| | `marital_status`| NVARCHAR | - | Tình trạng hôn nhân. |
| | `email_address` | NVARCHAR | - | Địa chỉ email liên hệ. |
| | `annual_income` | INT | - | Mức thu nhập hàng năm. |
| | `education_level` | NVARCHAR | - | Trình độ học vấn. |
| | `occupation` | NVARCHAR | - | Nghề nghiệp. |
| | `home_owner` | NVARCHAR | - | Tình trạng sở hữu nhà ở. |
| | | | | |
| **Dim_Region** | `region_code` | NVARCHAR | **PK** | Mã định danh duy nhất của vùng địa lý. |
| *(Thông tin Khu vực)* | `market` | NVARCHAR | - | Thị trường mục tiêu. |
| | `region` / `country` | NVARCHAR | - | Khu vực và Quốc gia. |
| | `state` / `city`| NVARCHAR | - | Tỉnh/Bang và Thành phố chi tiết. |
| | `country_latitude` / `longitude` | DECIMAL | - | Tọa độ địa lý. |

---

## 2. QUY TRÌNH KIỂM ĐỊNH VÀ LÀM SẠCH DỮ LIỆU (DATA QUALITY & CLEANING)

Trước khi tiến hành phân tích chẩn đoán, toàn bộ tập dữ liệu đã được kiểm tra tính toàn vẹn (Data Integrity) thông qua các truy vấn SQL. Trong quá trình rà soát **Khóa ngoại**, tôi đã phát hiện và xử lý các điểm bất thường sau:

*   **Vấn đề:** Tồn tại các bản ghi giao dịch (Sales) chứa mã sản phẩm (`PPP000002`, `PPP000010`) và mã khu vực (`RRR0001`) không khớp với bất kỳ dữ liệu nào trong các bảng Dimension tương ứng (`Dim_Product`, `Dim_Region`). Điều này tạo ra các "dữ liệu mồ côi" (Orphaned records) có thể gây sai lệch khi Drill-down.
*   **Đánh giá bản chất:** Dựa trên các phép kiểm định, lỗi này được phân loại thuộc nhóm **MCAR (Missing Completely At Random)**.
*   **Mức độ tác động:** Tổng số dòng dữ liệu bị ảnh hưởng chiếm **chưa tới 1%** (<1%) tổng quy mô tập dữ liệu. Đồng thời, giá trị đo lường (`sales`, `profit`) từ các đơn hàng này rất nhỏ, không đủ sức nặng để làm thay đổi trọng số của bức tranh lợi nhuận tổng thể.
*   **Hướng xử lý:** Quyết định Loại bỏ hoàn toàn đối với các bản ghi chứa mã `PPP000002`, `PPP000010`, và `RRR0001` ra khỏi bảng Fact để đảm bảo độ chính xác tuyệt đối khi phân tích.
