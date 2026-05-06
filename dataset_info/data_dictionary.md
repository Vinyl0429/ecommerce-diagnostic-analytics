## THÔNG TIN TẬP DỮ LIỆU & KIẾN TRÚC (DATA DICTIONARY)

Hệ thống dữ liệu của Xóm E-Com được quy hoạch và mô hình hóa theo cấu trúc **Star Schema (Sơ đồ hình sao)**, lấy bảng `Fact_Sales` làm trung tâm kết nối với 4 bảng danh mục (Dimensions) nhằm tối ưu hóa hiệu suất truy vấn (Query Performance). Tập dữ liệu bao gồm hơn 12,000 khách hàng và hàng chục nghìn bản ghi giao dịch (2020 - 2023).

| Tên Bảng (Table) | Tên Cột (Column) | Kiểu Dữ Liệu | Loại Khóa | Ý Nghĩa Chức Năng (Description) |
| :--- | :--- | :--- | :---: | :--- |
| **Fact_Sales** | `order_id` | VARCHAR | **PK** | Mã định danh duy nhất cho mỗi đơn hàng. |
| *(Sự kiện giao dịch)* | `order_date` | DATE | FK | Ngày ghi nhận giao dịch, liên kết với Dim_Date. |
| | `customer_id` | VARCHAR | FK | Liên kết định danh khách hàng tới bảng Dim_Customer. |
| | `product_code` | VARCHAR | FK | Liên kết thông tin sản phẩm tới bảng Dim_Product. |
| | `region_code` | VARCHAR | FK | Liên kết thông tin khu vực tới bảng Dim_Region. |
| | `sales` | DECIMAL | - | Doanh thu thuần ghi nhận trên từng dòng sản phẩm. |
| | `profit` | DECIMAL | - | Lợi nhuận ròng thực tế (Biến cơ sở để tìm "điểm gãy"). |
| | `discount` | DECIMAL | - | Tỷ lệ chiết khấu áp dụng cho sản phẩm (0% - 80%). |
| | | | | |
| **Dim_Product** | `product_code` | VARCHAR | **PK** | Mã định danh duy nhất của sản phẩm. |
| *(Thông tin Sản phẩm)* | `category` | VARCHAR | - | Ngành hàng lớn (Ví dụ: Body Care, Make up). |
| | `subcategory` | VARCHAR | - | Ngành hàng phụ (Ví dụ: Nail Care Products). |
| | | | | |
| **Dim_Customer**| `customer_id` | VARCHAR | **PK** | Mã định danh duy nhất của khách hàng. |
| *(Thông tin Khách hàng)*| `segment` | VARCHAR | - | Phân khúc hành vi (Consumer, Corporate, Self-Employed). |
| | `annual_income`| DECIMAL | - | Thu nhập hàng năm của khách hàng. |
| | | | | |
| **Dim_Region** | `region_code` | VARCHAR | **PK** | Mã định danh duy nhất của vùng địa lý. |
| *(Thông tin Khu vực)* | `market` | VARCHAR | - | Thị trường mục tiêu (APAC, Europe, USCA, LATAM, Africa). |
| | `country`/`state`| VARCHAR | - | Quốc gia và Tỉnh/Bang chi tiết hỗ trợ biểu đồ Geographic Drill-down. |
| | | | | |
| **Dim_Date** | `date_actual` | DATE | **PK** | Chuỗi ngày liên tục (Sinh tự động qua CTE trong SQL). |
| *(Trục Thời gian)*| `year` / `month` | INT | - | Trích xuất thời gian phục vụ tính toán YoY/MoM. |

*(Ghi chú: PK = Primary Key / Khóa chính; FK = Foreign Key / Khóa ngoại)*
