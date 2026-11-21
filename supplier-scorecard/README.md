# Chấm điểm nhà cung cấp bằng SQL: OTIF, Lead Time và hàng an toàn

> Nhà cung cấp giao trễ hoặc thiếu hàng là nguyên nhân hàng đầu gây hết hàng trên kệ. Project này dùng SQL để đo hiệu suất 30 nhà cung cấp, xếp hạng rủi ro và tính cần giữ thêm bao nhiêu hàng an toàn cho nhà cung cấp kém.

**Dữ liệu là giả lập** (1.047 đơn đặt hàng, 30 nhà cung cấp, 6 nhóm hàng FMCG, từ 01/2026 đến 11/2026), tạo bằng `generate_data.py`. Có thể thay bằng dữ liệu thật cùng cấu trúc cột.

## Kết quả chính

| Chỉ số | Giá trị |
|---|---|
| Đơn đã về | 1.039 (8 đơn còn đang chờ) |
| Đơn giao đúng hạn | 82,5% (182 đơn trễ) |
| OTIF (đúng hạn và đủ hàng) | 74,9% |

| Hạng | Số NCC | Đúng hạn | OTIF | Hàng an toàn trung bình |
|---|---|---|---|---|
| A - Tốt (điểm >= 90) | 13 | 95,3% | 92,4% | 84 đơn vị |
| B - Cần theo dõi (>= 75) | 11 | 82,9% | 76,8% | 126 đơn vị |
| C - Rủi ro cao (< 75) | 6 | 54,6% | 35,2% | **341 đơn vị** |

1. **6 nhà cung cấp hạng C (20% tổng số) gây ra 56% số đơn trễ** (102/182) và **72% giá trị hàng giao thiếu** (478 / 664 triệu đồng).
2. Muốn đạt mức phục vụ 95%, nhà cung cấp hạng C cần hàng an toàn **gấp khoảng 4 lần** hạng A, vì lead time dao động mạnh (độ lệch chuẩn 2-3 ngày so với dưới 1 ngày).
3. Trong 8 đơn đang chờ, **2 đơn (27,6 triệu đồng) thuộc nhà cung cấp hạng C** (NCC28), nên cần gọi hỏi tiến độ trước.
4. Đây không phải "80/20" kinh điển: 6 nhà cung cấp mới chiếm 56% đơn trễ, phải 8 nhà cung cấp mới chạm 2/3. Kết luận đúng là *tập trung vào nhóm nhỏ này mang lại hiệu quả lớn nhất*, không cần nói quá.

Lưu ý khi đọc: số liệu tháng 11 chưa đầy đủ (mới 41 đơn về, các đơn trễ chưa về nên chưa được tính). Chênh lệch giữa các nhóm hàng trong dữ liệu mẫu (ví dụ Bánh kẹo OTIF 62,9%, Gia vị 92,2%) phản ánh nhà cung cấp nào được gán vào nhóm nào trong dữ liệu giả lập, không nên kết luận về ngành.

## Cách tính (4 file SQL, chạy theo thứ tự)

| File | Làm gì |
|---|---|
| `01_schema.sql` | Tạo 2 bảng: `suppliers`, `purchase_orders` |
| `02_po_view.sql` | Với mỗi đơn đã về, tính 3 cờ 0/1: đúng hạn, đủ hàng (nhận >= 95% số đặt), OTIF (cả hai), cùng số ngày trễ và lead time |
| `03_scorecard.sql` | Gom theo nhà cung cấp, tính điểm 0-100 và hàng an toàn |
| `04_insights.sql` | Xếp hạng A/B/C, Pareto đơn trễ, xu hướng tháng, theo nhóm hàng, đơn đang chờ |

**Điểm = 50% OTIF + 30% fill rate + 20% độ ổn định lead time.** Trọng số là giả định của mình (OTIF quan trọng nhất vì phản ánh trực tiếp việc hàng có về đúng và đủ), có thể chỉnh trong `03_scorecard.sql`.

**Hàng an toàn = 1,65 x độ lệch chuẩn lead time x nhu cầu mỗi ngày** (1,65 tương ứng mức phục vụ 95%). Cột `extra_stock_if_3d_delay` trả lời câu hỏi "nếu nhà cung cấp trễ thêm 3 ngày thì cần thêm bao nhiêu hàng".

## Cách chạy

**Cách 1 (nhanh nhất):** `python run_sql.py` rồi xem thư mục `outputs/`. Script chỉ nạp CSV và chạy 4 file SQL theo thứ tự.

**Cách 2 (không cần Python):** mở `outputs/supplier_scorecard.db` bằng [DB Browser for SQLite](https://sqlitebrowser.org), vào tab *Execute SQL* và chạy thử `SELECT * FROM v_ranking;`. Nếu báo lỗi `no such function: SQRT` (một số bản DB Browser cũ không có hàm này), hãy dùng các file CSV trong `outputs/` hoặc chạy Cách 1.

**SQL Server / PostgreSQL:** chỉ cần đổi 3 chỗ (đã ghi chú trong file): `STDEV()` thay cho công thức `SQRT` ở bước 3, `FORMAT(order_date,'yyyy-MM')` thay cho `strftime`, và `DATEDIFF` thay cho `julianday`.

## Dựng dashboard Power BI 1 trang

Import 6 file trong `outputs/`: `ranking.csv`, `po.csv`, `pareto_late.csv`, `monthly_trend.csv`, `category.csv`, `open_orders.csv`.

- **Thẻ số** (Card): OTIF %, % đúng hạn, số đơn trễ.
- **Biểu đồ cột ngang**: điểm từng nhà cung cấp từ `ranking.csv`, tô màu theo cột `tier`.
- **Biểu đồ Pareto**: cột `late_orders` kèm đường `cumulative_pct` từ `pareto_late.csv`.
- **Biểu đồ đường**: `otif_pct` theo `month` từ `monthly_trend.csv`.
- **Bảng đơn đang chờ** từ `open_orders.csv`, tô đỏ dòng có `status` là nguy cơ cao.

## Giải thích trong 1 phút

> "Em làm bảng chấm điểm 30 nhà cung cấp bằng SQL, dựa trên 3 chỉ số: giao đúng hạn, giao đủ hàng và độ ổn định lead time. Kết quả cho thấy 6 nhà cung cấp, tức 20%, gây ra 56% số đơn trễ và 72% giá trị hàng giao thiếu. Em cũng tính được những nhà cung cấp này cần hàng an toàn gấp khoảng 4 lần nhà cung cấp tốt. Từ đó em đề xuất ưu tiên làm việc với nhóm này, và theo dõi sát các đơn đang chờ của họ. Dữ liệu em dùng là giả lập, nhưng em đã kiểm tra chéo kết quả SQL bằng một cách tính độc lập."

## Câu hỏi nhà tuyển dụng có thể hỏi

- **Vì sao trọng số 50/30/20?** Đó là giả định của em. OTIF là chỉ số cốt lõi nên em cho nặng nhất. Doanh nghiệp khác có thể ưu tiên khác, và em chỉnh được ngay trong SQL.
- **Vì sao "đủ hàng" là 95%?** Là ngưỡng dung sai thường gặp trong thực tế. Có thể đổi thành 100% nếu doanh nghiệp yêu cầu nghiêm hơn.
- **Hạn chế?** Dữ liệu giả lập; chưa tính đến mùa vụ (Tết, khuyến mãi); lead time dùng độ lệch chuẩn nên coi như phân phối đều; chỉ xét theo nhà cung cấp chứ chưa theo từng mặt hàng (SKU).

## Cấu trúc

```
sql/01..04_*.sql        # toàn bộ logic nằm ở đây
data/                   # suppliers.csv, purchase_orders.csv
outputs/                # file .db và các CSV cho Power BI
generate_data.py        # sinh dữ liệu giả lập
run_sql.py              # chạy tự động (không bắt buộc)
```
