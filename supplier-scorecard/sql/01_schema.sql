-- BƯỚC 1: TẠO BẢNG
-- 2 bảng: nhà cung cấp (danh mục) và đơn đặt hàng (giao dịch).
-- received_date / qty_received để trống (NULL) nghĩa là đơn chưa về.

DROP TABLE IF EXISTS purchase_orders;
DROP TABLE IF EXISTS suppliers;

CREATE TABLE suppliers (
    supplier_id              TEXT PRIMARY KEY,
    supplier_name            TEXT,
    category                 TEXT,      -- nhóm hàng chính
    promised_lead_time_days  INTEGER    -- lead time nhà cung cấp cam kết
);

CREATE TABLE purchase_orders (
    po_id          TEXT PRIMARY KEY,
    supplier_id    TEXT REFERENCES suppliers (supplier_id),
    order_date     DATE,                -- ngày đặt
    promised_date  DATE,                -- ngày nhà cung cấp hẹn giao
    received_date  DATE,                -- ngày nhận thực tế (NULL = chưa về)
    qty_ordered    INTEGER,
    qty_received   INTEGER,
    unit_cost      INTEGER              -- đơn giá nhập (đồng)
);
