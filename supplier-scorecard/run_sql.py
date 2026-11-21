"""Chạy 4 file SQL theo thứ tự, nạp 2 file CSV vào SQLite, xuất mọi view (v_*) ra outputs/*.csv.
Bạn có thể bỏ qua file này và tự chạy các file .sql trong DB Browser for SQLite / SSMS / pgAdmin."""
import csv, glob, os, sqlite3

db = sqlite3.connect("outputs/supplier_scorecard.db")
db.executescript(open("sql/01_schema.sql", encoding="utf-8").read())

def load(table, path):
    with open(path, encoding="utf-8-sig") as f:
        r = csv.reader(f)
        cols = next(r)
        rows = [[v if v != "" else None for v in row] for row in r]
    db.executemany(f"INSERT INTO {table} ({','.join(cols)}) VALUES ({','.join('?' * len(cols))})", rows)

load("suppliers", "data/suppliers.csv")
load("purchase_orders", "data/purchase_orders.csv")
for f in sorted(glob.glob("sql/0[234]_*.sql")):
    db.executescript(open(f, encoding="utf-8").read())
db.commit()

for (view,) in db.execute("SELECT name FROM sqlite_master WHERE type='view' AND name LIKE 'v_%'").fetchall():
    cur = db.execute(f"SELECT * FROM {view}" + (" ORDER BY rank_no" if view in ("v_ranking", "v_pareto_late") else ""))
    with open(f"outputs/{view[2:]}.csv", "w", newline="", encoding="utf-8-sig") as out:
        w = csv.writer(out); w.writerow([d[0] for d in cur.description]); w.writerows(cur.fetchall())
    print("xuất", view)
