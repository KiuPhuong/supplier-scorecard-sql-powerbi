"""Sinh dữ liệu GIẢ LẬP: 30 nhà cung cấp + ~1.000 đơn đặt hàng (PO) cho chuỗi bán lẻ FMCG.
Chạy 1 lần:  python generate_data.py   ->  data/suppliers.csv, data/purchase_orders.csv
Mỗi nhà cung cấp có "tính cách" riêng (hay trễ, hay giao thiếu, lead time dao động) để phân tích có cái để tìm ra.
"""
import csv
import random
from datetime import date, timedelta

random.seed(11)
CATEGORIES = ["Đồ uống", "Sữa", "Thực phẩm khô", "Bánh kẹo", "Gia vị - Dầu ăn", "Hóa phẩm gia đình"]
NAMES = ["An Phát", "Bình Minh", "Cửu Long", "Đại Việt", "Hải Nam", "Hoàng Gia", "Kim Long", "Lộc Phát", "Minh Tâm", "Nam Việt",
         "Ngọc Lan", "Phú Thịnh", "Quang Huy", "Sao Mai", "Thái Bình", "Thành Công", "Thiên Phú", "Tín Nghĩa", "Trường An", "Tân Hiệp",
         "Việt Úc", "Vạn Phúc", "Xuân Hòa", "Á Châu", "Hưng Thịnh", "Đông Dương", "Mê Kông", "Sài Gòn Food", "Tây Nam", "Phương Đông"]

suppliers = []
for k, n in enumerate(NAMES, 1):
    # ~20% nhà cung cấp "kém": hay trễ, hay thiếu hàng, lead time dao động mạnh
    bad = k in (4, 9, 13, 21, 26, 28)
    mid = k in (2, 7, 16, 19, 24)
    suppliers.append({
        "supplier_id": f"NCC{k:02d}",
        "supplier_name": f"Công ty {n}",
        "category": CATEGORIES[(k - 1) % len(CATEGORIES)],
        "promised_lt": random.choice([3, 4, 5, 7]),
        "p_late": 0.45 if bad else 0.22 if mid else 0.06,
        "late_days": (2, 7) if bad else (1, 4) if mid else (1, 2),
        "p_short": 0.35 if bad else 0.15 if mid else 0.04,
        "unit_cost": random.choice([12000, 18000, 25000, 40000, 65000]),
    })

with open("data/suppliers.csv", "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["supplier_id", "supplier_name", "category", "promised_lead_time_days"])
    for s in suppliers:
        w.writerow([s["supplier_id"], s["supplier_name"], s["category"], s["promised_lt"]])

start, end = date(2026, 1, 1), date(2026, 11, 13)
AS_OF = date(2026, 11, 15)  # ngày "hôm nay" của dữ liệu
rows, po = [], 0
for s in suppliers:
    n_orders = random.randint(25, 45)
    for _ in range(n_orders):
        po += 1
        order = start + timedelta(days=random.randint(0, (end - start).days))
        promised = order + timedelta(days=s["promised_lt"])
        qty = random.choice([200, 300, 500, 800, 1000, 1500])
        late = random.random() < s["p_late"]
        recv = promised + timedelta(days=random.randint(*s["late_days"])) if late else promised - timedelta(days=random.randint(0, 1))
        got = qty
        if random.random() < s["p_short"]:
            got = int(qty * random.uniform(0.6, 0.94))
        if recv > AS_OF:  # đơn chưa về tới hôm nay
            recv, got = None, None
        rows.append([f"PO{po:05d}", s["supplier_id"], order.isoformat(), promised.isoformat(),
                     recv.isoformat() if recv else "", qty, got if got is not None else "", s["unit_cost"]])

random.shuffle(rows)
rows.sort(key=lambda r: r[2])
with open("data/purchase_orders.csv", "w", newline="", encoding="utf-8-sig") as f:
    w = csv.writer(f)
    w.writerow(["po_id", "supplier_id", "order_date", "promised_date", "received_date", "qty_ordered", "qty_received", "unit_cost"])
    w.writerows(rows)
print(f"{len(suppliers)} nhà cung cấp, {len(rows)} đơn hàng, {sum(1 for r in rows if not r[4])} đơn chưa về")
