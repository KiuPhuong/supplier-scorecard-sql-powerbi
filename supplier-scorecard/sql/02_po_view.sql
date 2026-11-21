-- BƯỚC 2: LÀM SẠCH + TÍNH CỜ CHO TỪNG ĐƠN
-- Mỗi đơn đã về là 1 dòng, kèm các cờ 0/1 trả lời 3 câu hỏi:
--   Giao đúng hạn không?  Giao đủ hàng không?  Cả hai (OTIF)?
-- Quy ước: "đủ hàng" = nhận >= 95% số lượng đặt.

DROP VIEW IF EXISTS v_po;
CREATE VIEW v_po AS
SELECT
    p.po_id,
    p.supplier_id,
    s.supplier_name,
    s.category,
    p.order_date,
    p.promised_date,
    p.received_date,
    p.qty_ordered,
    p.qty_received,
    p.unit_cost,
    CAST(julianday(p.received_date) - julianday(p.order_date) AS INTEGER)    AS lead_time_days,   -- đặt -> nhận
    CASE WHEN p.received_date > p.promised_date
         THEN CAST(julianday(p.received_date) - julianday(p.promised_date) AS INTEGER)
         ELSE 0 END                                                          AS delay_days,       -- số ngày trễ
    CASE WHEN p.received_date <= p.promised_date THEN 1 ELSE 0 END           AS on_time,
    ROUND(1.0 * p.qty_received / p.qty_ordered, 4)                           AS fill_rate,
    CASE WHEN p.qty_received >= 0.95 * p.qty_ordered THEN 1 ELSE 0 END       AS in_full,
    CASE WHEN p.received_date <= p.promised_date
          AND p.qty_received >= 0.95 * p.qty_ordered THEN 1 ELSE 0 END       AS otif
FROM purchase_orders p
JOIN suppliers s ON s.supplier_id = p.supplier_id
WHERE p.received_date IS NOT NULL;      -- chỉ tính đơn đã về
