-- BƯỚC 4: CÁC GÓC NHÌN ĐỂ TRẢ LỜI CÂU HỎI KINH DOANH
-- Mỗi view là một bảng sẵn sàng kéo vào Power BI.

-- 4a. Xếp hạng + phân hạng rủi ro (ngưỡng A >= 90, B >= 75 là quy ước, có thể chỉnh)
DROP VIEW IF EXISTS v_ranking;
CREATE VIEW v_ranking AS
SELECT
    RANK() OVER (ORDER BY score DESC) AS rank_no,
    s.*,
    CASE WHEN score >= 90 THEN 'A - Tốt'
         WHEN score >= 75 THEN 'B - Cần theo dõi'
         ELSE                  'C - Rủi ro cao' END AS tier
FROM v_scorecard s;

-- 4b. Nguyên tắc 80/20: bao nhiêu nhà cung cấp gây ra phần lớn đơn trễ?
DROP VIEW IF EXISTS v_pareto_late;
CREATE VIEW v_pareto_late AS
WITH late AS (
    SELECT supplier_id, supplier_name, COUNT(*) AS late_orders
    FROM v_po WHERE on_time = 0
    GROUP BY supplier_id, supplier_name
),
tot AS (SELECT SUM(late_orders) AS t FROM late)
SELECT
    ROW_NUMBER() OVER (ORDER BY late_orders DESC, supplier_id)                       AS rank_no,
    supplier_id, supplier_name, late_orders,
    ROUND(100.0 * late_orders / t, 1)                                                AS pct_of_late_orders,
    ROUND(100.0 * SUM(late_orders) OVER (ORDER BY late_orders DESC, supplier_id) / t, 1) AS cumulative_pct
FROM late, tot;

-- 4c. Xu hướng OTIF theo tháng đặt hàng
-- (SQL Server: dùng FORMAT(order_date,'yyyy-MM') thay cho strftime)
DROP VIEW IF EXISTS v_monthly_trend;
CREATE VIEW v_monthly_trend AS
SELECT
    strftime('%Y-%m', order_date)       AS month,
    COUNT(*)                            AS orders,
    ROUND(100.0 * AVG(on_time), 1)      AS on_time_pct,
    ROUND(100.0 * AVG(otif), 1)         AS otif_pct,
    ROUND(AVG(1.0 * lead_time_days), 1) AS avg_lead_time_days
FROM v_po
GROUP BY strftime('%Y-%m', order_date);

-- 4d. Theo nhóm hàng
DROP VIEW IF EXISTS v_category;
CREATE VIEW v_category AS
SELECT
    category,
    COUNT(*)                                        AS orders,
    ROUND(100.0 * AVG(otif), 1)                     AS otif_pct,
    ROUND(100.0 * SUM(qty_received) / SUM(qty_ordered), 1) AS fill_rate_pct,
    ROUND(AVG(1.0 * delay_days), 2)                 AS avg_delay_days
FROM v_po
GROUP BY category;

-- 4e. Đơn chưa về: đơn nào có nguy cơ trễ? (mốc "hôm nay" của dữ liệu: 2026-11-15)
-- Kèm hạng và tỷ lệ đúng hạn lịch sử của nhà cung cấp để biết đơn nào cần gọi hỏi trước.
DROP VIEW IF EXISTS v_open_orders;
CREATE VIEW v_open_orders AS
SELECT
    p.po_id, p.supplier_id, s.supplier_name, p.order_date, p.promised_date,
    p.qty_ordered, p.qty_ordered * p.unit_cost AS order_value_vnd,
    r.tier AS supplier_tier, r.on_time_pct AS supplier_on_time_pct,
    CASE WHEN p.promised_date < '2026-11-15' THEN 'Quá hạn'
         WHEN r.tier LIKE 'C%'                THEN 'Trong hạn - nguy cơ cao'
         ELSE                                      'Trong hạn' END AS status,
    CASE WHEN p.promised_date < '2026-11-15'
         THEN CAST(julianday('2026-11-15') - julianday(p.promised_date) AS INTEGER) ELSE 0 END AS days_overdue
FROM purchase_orders p
JOIN suppliers s  ON s.supplier_id = p.supplier_id
JOIN v_ranking r  ON r.supplier_id = p.supplier_id
WHERE p.received_date IS NULL;
