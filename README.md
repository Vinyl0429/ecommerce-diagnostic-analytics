# 🛒 E-Commerce Diagnostic Analytics: Profitability & Retention
*Phân tích chẩn đoán vận hành cho sàn thương mại điện tử toàn cầu (Xóm E-Com)*

## 📌 Bối cảnh dự án (Business Context)
Xóm E-Com là một sàn thương mại điện tử B2C quy mô toàn cầu (Doanh thu ~$2.3M/năm). Dù ghi nhận tăng trưởng doanh thu ở bề mặt, nhưng **biên lợi nhuận ròng đang có dấu hiệu suy giảm nghiêm trọng**. 
Dự án này được thực hiện nhằm bóc tách các lớp dữ liệu vận hành, tìm ra "điểm gãy" lợi nhuận và xây dựng lại chiến lược tăng trưởng bền vững.

## 🛠 Tech Stack
- **Database:** SQL Server (Window Functions, CTEs, Data Aggregation)
- **Data Visualization:** Power BI
- **Analytical Frameworks:** MECE, RFM Model, Cohort Analysis

## 📂 Cấu trúc Repository
- `/01_Dataset_Info`: Từ điển dữ liệu (Data Dictionary) và cấu trúc ERD.
- `/02_SQL_Queries`: Truy vấn SQL.
- 
## 🚀 Key Insights & Đề xuất chiến lược
1. **Discount Cannibalization:** Phát hiện "Điểm gãy lợi nhuận" ở mức giảm giá 21%. Đề xuất thiết lập trần giảm giá (Max-cap) tự động ở mức 20%.
2. **Customer Segmentation:** Đánh giá lại giá trị tập khách hàng B2B, thay đổi KPI từ "Biên lợi nhuận đơn hàng" sang "Customer Lifetime Value" (CLTV: $208/khách).
3. **RFM & Retention:** 68.79% khách hàng chỉ mua 1 lần. Đề xuất cắt 100% ngân sách Marketing cho nhóm "Lost" và dịch chuyển 65% ngân sách để Win-back nhóm "At-Risk" và "Promising".
