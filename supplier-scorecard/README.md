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
| C - Rủi ro cao (< 75) | 6 | 54,6% | 35,2% | 341 đơn vị |

1. **6 nhà cung cấp hạng C (20% tổng số) gây ra 56% số đơn trễ** (102/182) và **72% giá trị hàng giao thiếu** (478 / 664 triệu đồng).
2. Muốn đạt mức phục vụ 95%, nhà cung cấp hạng C cần hàng an toàn gấp khoảng 4 lần hạng A, vì lead time dao động mạnh (độ lệch chuẩn 2-3 ngày so với dưới 1 ngày).
3. Trong 8 đơn đang chờ, 2 đơn (27,6 triệu đồng) thuộc nhà cung cấp hạng C (NCC28), nên cần gọi hỏi tiến độ trước.
4. Đây không phải "80/20" kinh điển: 6 nhà cung cấp mới chiếm 56% đơn trễ, phải 8 nhà cung cấp mới chạm 2/3. Kết luận đúng là *tập trung vào nhóm nhỏ này mang lại hiệu quả lớn nhất*.

Lưu ý khi đọc: số liệu tháng 11 chưa đầy đủ (mới 41 đơn về, các đơn trễ chưa về nên chưa được tính). Chênh lệch giữa các nhóm hàng trong dữ liệu mẫu (ví dụ Bánh kẹo OTIF 62,9%, Gia vị 92,2%) phản ánh nhà cung cấp nào được gán vào nhóm nào trong dữ liệu giả lập, không nên kết luận về ngành.

## Cách tính (4 file SQL, chạy theo thứ tự)

| File | Mục tiêu |
|---|---|
| `01_schema.sql` | Tạo 2 bảng: `suppliers`, `purchase_orders` |
| `02_po_view.sql` | Với mỗi đơn đã về, tính 3 cờ 0/1: đúng hạn, đủ hàng (nhận >= 95% số đặt), OTIF (cả hai), cùng số ngày trễ và lead time |
| `03_scorecard.sql` | Gom theo nhà cung cấp, tính điểm 0-100 và hàng an toàn |
| `04_insights.sql` | Xếp hạng A/B/C, Pareto đơn trễ, xu hướng tháng, theo nhóm hàng, đơn đang chờ |

**Điểm = 50% OTIF + 30% fill rate + 20% độ ổn định lead time.** Trọng số là giả định của mình (OTIF quan trọng nhất vì phản ánh trực tiếp việc hàng có về đúng và đủ), có thể chỉnh trong `03_scorecard.sql`.

**Hàng an toàn = 1,65 x độ lệch chuẩn lead time x nhu cầu mỗi ngày** (1,65 tương ứng mức phục vụ 95%). Cột `extra_stock_if_3d_delay` trả lời câu hỏi "nếu nhà cung cấp trễ thêm 3 ngày thì cần thêm bao nhiêu hàng".

## Cách chạy

`python run_sql.py` rồi xem thư mục `outputs/`. Script chỉ nạp CSV và chạy 4 file SQL theo thứ tự.

