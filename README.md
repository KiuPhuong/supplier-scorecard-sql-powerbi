# Supplier Scorecard: SQL + Power BI

Dashboard Power BI chấm điểm và theo dõi hiệu suất **30 nhà cung cấp (NCC)** theo OTIF, tỷ lệ giao đúng hạn và lead time. Số liệu được tính sẵn bằng SQL trong thư mục [`supplier-scorecard/`](supplier-scorecard/), sau đó đưa vào Power BI để trực quan hóa.

> Dữ liệu là giả lập (1.047 đơn đặt hàng, 6 nhóm hàng FMCG, 01/2026 đến 11/2026).

## Cấu trúc repo

```
supplier-scorecard-sql-powerbi/
├── supplier-scorecard/              # Phần SQL: tính điểm, xếp hạng, xuất CSV
└── supplier-scorecard-powerbi.pbix  # Dashboard Power BI
```

## Phần SQL 

Thư mục `supplier-scorecard/` chứa 4 file SQL, dữ liệu mẫu và script chạy tự động. Phần này tính OTIF, fill rate, độ ổn định lead time, điểm 0-100, xếp hạng A/B/C, Pareto đơn trễ và hàng an toàn, rồi xuất ra các file CSV trong `outputs/` làm nguồn cho dashboard. Phương pháp tính chi tiết xem tại [`supplier-scorecard/README.md`](supplier-scorecard/README.md).

## Kết quả chính

- OTIF toàn bộ 74,9%, giao đúng hạn 82,5%.
- 6 NCC hạng C (20%) gây ra 56% số đơn trễ và 72% giá trị hàng giao thiếu.
- NCC hạng C cần hàng an toàn gấp khoảng 4 lần NCC hạng A.
- Trong 8 đơn đang chờ, 2 đơn (27,6 triệu đồng) thuộc NCC hạng C, cần gọi hỏi tiến độ trước.

## Dashboard Power BI

Dashboard một trang (1920×1080) trả lời 3 câu hỏi: **NCC nào kéo hiệu suất xuống, đơn trễ tập trung ở đâu, và đơn nào đang chờ cần xử lý ngay.**

<img width="860" height="482" alt="Screenshot 2026-11-21 163331" src="https://github.com/user-attachments/assets/609b2b75-a652-455e-b7e6-c8e4b17a1a55" />

### Bố cục

| Vùng | Thành phần | Nguồn dữ liệu | Ý nghĩa |
|---|---|---|---|
| **Tiêu đề** | Thông điệp chính: *"6 nhà cung cấp (20%) gây ra 56% số đơn trễ"*, kèm dòng phụ về kỳ dữ liệu | Văn bản | Đưa kết luận lên đầu để người xem nắm ngay |
| **Bộ lọc** | Lọc theo Hạng (A/B/C) và Nhóm hàng (dropdown) | `ranking` | Xem riêng nhóm NCC rủi ro hoặc từng ngành hàng |
| **Thẻ KPI** | OTIF %, On-time %, Đơn trễ, Lead time trung bình | `po`, `pareto_late` | Bốn chỉ số tổng quan toàn bộ đơn hàng |
| **Xếp hạng NCC** | Biểu đồ cột ngang: điểm 0-100 từng NCC, tô màu theo hạng | `ranking` | Nhìn nhanh NCC nào điểm thấp |
| **Pareto đơn trễ** | Cột đỏ là số đơn trễ của từng NCC, đường là % tích lũy | `pareto_late` | Cho thấy nhóm nhỏ NCC gây ra phần lớn đơn trễ |
| **Xu hướng** | Biểu đồ đường: OTIF % theo tháng | `monthly_trend` | Theo dõi hiệu suất theo thời gian |
| **Đơn đang chờ** | Bảng: mã đơn, NCC, giá trị đơn (VND), trạng thái; dòng "Trong hạn - nguy cơ cao" tô nền cam | `open_orders` | Chỉ ra đơn chưa về cần theo dõi trước |

### Cách đọc

1. Xem **4 thẻ KPI** để biết mức OTIF và tỷ lệ đúng hạn chung.
2. Xem **biểu đồ xếp hạng** để tìm NCC điểm thấp, rồi lọc Hạng = C để tập trung vào nhóm rủi ro cao.
3. Đối chiếu với **Pareto** để thấy nhóm này chiếm bao nhiêu % đơn trễ.
4. Xem **xu hướng theo tháng** (tháng 11 chưa đầy đủ vì các đơn trễ chưa về).
5. Cuối cùng xem **bảng đơn đang chờ**, ưu tiên các dòng tô cam.

### Mô hình dữ liệu

6 bảng import từ `supplier-scorecard/outputs/`: `ranking`, `po`, `pareto_late`, `monthly_trend`, `category`, `open_orders`. Các measure DAX nằm trong bảng `po`: `OTIF %`, `On-time %`, `Avg lead time`.

## Cách chạy

**Yêu cầu:** Python 3 và Power BI Desktop.

1. Clone repo:
   ```bash
   git clone https://github.com/KiuPhuong/supplier-scorecard-sql-powerbi.git
   cd supplier-scorecard-sql-powerbi/supplier-scorecard
   ```
2. Tạo các file kết quả (bước này có thể bỏ qua vì `outputs/` đã có sẵn CSV):
   ```bash
   python run_sql.py
   ```
3. Mở `supplier-scorecard-powerbi.pbix` bằng Power BI Desktop. Nếu báo lỗi nguồn dữ liệu, vào **Transform data → Data source settings**, trỏ lại tới thư mục `supplier-scorecard/outputs/` rồi chọn **Refresh**.

## Công nghệ

SQL · Python · Power BI (DAX)
