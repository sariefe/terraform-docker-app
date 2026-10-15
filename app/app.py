import os
import time
import psycopg2
from flask import Flask

app = Flask(__name__)

def get_conn():
    return psycopg2.connect(
        host=os.environ["DB_HOST"],
        dbname=os.environ["DB_NAME"],
        user=os.environ["DB_USER"],
        password=os.environ["DB_PASSWORD"],
    )

def run(sql, fetch=False):
    conn = get_conn()
    try:
        with conn, conn.cursor() as cur:
            cur.execute(sql)
            return cur.fetchone() if fetch else None
    finally:
        conn.close()

def init_db():
    for _ in range(10):
        try:
            run("CREATE TABLE IF NOT EXISTS visits (id SERIAL PRIMARY KEY, ts TIMESTAMP DEFAULT now())")
            return
        except psycopg2.OperationalError:
            time.sleep(2)
    raise RuntimeError("Veritabanına bağlanılamadı")

@app.route("/")
def index():
    run("INSERT INTO visits DEFAULT VALUES")
    count = run("SELECT count(*) FROM visits", fetch=True)[0]
    return f"Toplam ziyaret: {count}\n"

init_db()
