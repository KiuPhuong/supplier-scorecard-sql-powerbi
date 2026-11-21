-- BƯỚC 3: BẢNG CHẤM ĐIỂM NHÀ CUNG CẤP (1 dòng / nhà cung cấp)
-- Điểm (0-100) = 50% OTIF + 30% fill rate + 20% độ ổn định lead time.
-- Độ ổn định = 1 - (độ lệch chuẩn lead time / lead time trung bình), tối thiểu 0.
-- Hàng an toàn thêm = 1.65 x độ lệch chuẩn lead time x nhu cầu/ngày (mức phục vụ 95%).
-- Lưu ý: SQL Server dùng STDEV(lead_time_days) thay cho công thức SQRT bên dưới.

DROP VIEW IF EXISTS v_scorecard;
CREATE VIEW v_scorecard AS
WITH period AS (                         -- số ngày của toàn bộ dữ liệu, để tính nhu cầu/ngày
    SELECT julianday(MAX(received_date)) - julianday(MIN(order_date)) + 1 AS days FROM v_po
),
agg AS (
    SELECT
        supplier_id, supplier_name, category,
        COUNT(*)                                          AS total_orders,
        SUM(1 - on_time)                                  AS late_orders,
        AVG(1.0 * on_time)                                AS on_time_rate,
        AVG(1.0 * otif)                                   AS otif_rate,
        1.0 * SUM(qty_received) / SUM(qty_ordered)        AS fill_rate,
        AVG(1.0 * lead_time_days)                         AS avg_lead_time,
        AVG(1.0 * lead_time_days * lead_time_days)
          - AVG(1.0 * lead_time_days) * AVG(1.0 * lead_time_days) AS lt_variance,
        SUM(qty_ordered - qty_received)                   AS short_units,
        SUM((qty_ordered - qty_received) * unit_cost)     AS short_value,
        SUM(qty_received) AS total_received
    FROM v_po
    GROUP BY supplier_id, supplier_name, category
),
calc AS (
    SELECT a.*,
           SQRT(CASE WHEN lt_variance < 0 THEN 0 ELSE lt_variance END) AS lt_stdev,
           total_received / (SELECT days FROM period)                   AS daily_demand
    FROM agg a
)
SELECT
    supplier_id, supplier_name, category, total_orders, late_orders,
    ROUND(100 * on_time_rate, 1)  AS on_time_pct,
    ROUND(100 * otif_rate, 1)     AS otif_pct,
    ROUND(100 * fill_rate, 1)     AS fill_rate_pct,
    ROUND(avg_lead_time, 1)       AS avg_lead_time_days,
    ROUND(lt_stdev, 2)            AS lead_time_stdev,
    ROUND(100 * (0.5 * otif_rate + 0.3 * fill_rate
          + 0.2 * (1 - CASE WHEN lt_stdev / avg_lead_time > 1 THEN 1 ELSE lt_stdev / avg_lead_time END)), 1) AS score,
    ROUND(1.65 * lt_stdev * daily_demand)  AS safety_stock_units,
    ROUND(3 * daily_demand)                AS extra_stock_if_3d_delay,
    short_value                            AS short_value_vnd
FROM calc;
