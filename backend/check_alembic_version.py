"""
TrackForge — DB Tanı Scripti (deploy onarımı için)
═══════════════════════════════════════════════════
Render External Database URL ile çalıştır. Çıktıyı Claude'a yapıştır.

Kontrol ettikleri:
  1. alembic_version tablosundaki revizyon(lar)
  2. Kritik tabloların varlığı (ai_usage_logs, blood_values, chat_messages, duels...)
  3. users tablosunda is_premium kolonu var mı (PRO bug'ının kaynağı)
  4. Varsa: kaç premium kullanıcı var

KULLANIM:
  - Aşağıdaki DATABASE_URL'i Render External Database URL ile değiştir
    VEYA ortam değişkeni olarak ver.
  - Çalıştır:  python check_alembic_version.py
"""
import os
import sys

# ── Bağlantı ──
# Render > Database > "External Database URL" değerini buraya yapıştır
# (postgres:// ile başlıyorsa script otomatik düzeltir)
DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://trackforge:GPdMTFyFV88rXkcZBhMccSWu0YmTOlPU@dpg-d8eqomjeo5us73cpc6l0-a.oregon-postgres.render.com/trackforge_db")

if "BURAYA" in DATABASE_URL:
    print("⚠ DATABASE_URL ayarlanmadı. Script içindeki DATABASE_URL'i Render")
    print("  External Database URL ile değiştir veya ortam değişkeni ver.")
    sys.exit(1)

# psycopg2 senkron sürücü kullanır; asyncpg/+asyncpg ekini temizle
url = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
url = url.replace("postgres://", "postgresql://")

try:
    import psycopg2
except ImportError:
    print("psycopg2 gerekli:  pip install psycopg2-binary")
    sys.exit(1)

conn = psycopg2.connect(url)
cur = conn.cursor()


def section(title):
    print("\n" + "═" * 50)
    print(title)
    print("═" * 50)


# ── 1. alembic_version ──
section("1) alembic_version tablosu")
try:
    cur.execute("SELECT version_num FROM alembic_version;")
    rows = cur.fetchall()
    print(f"  {len(rows)} satır:")
    for r in rows:
        print(f"    - {r[0]}")
    if len(rows) > 1:
        print("  ⚠ BİRDEN FAZLA SATIR — bu deploy'u blokluyor (çift head kalıntısı)")
except Exception as e:
    print(f"  HATA: {e}")


# ── 2. Kritik tablolar ──
section("2) Kritik tabloların varlığı")
tables_to_check = [
    "users", "ai_usage_logs", "blood_values", "chat_messages",
    "duels", "exercise_catalog", "ai_jobs", "session_exercises",
    "weekly_notes", "file_uploads",
]
cur.execute("""
    SELECT table_name FROM information_schema.tables
    WHERE table_schema = 'public';
""")
existing = {r[0] for r in cur.fetchall()}
for tname in tables_to_check:
    mark = "✓ VAR" if tname in existing else "✗ YOK"
    print(f"  {mark}  {tname}")


# ── 3. users.is_premium kolonu (PRO bug kaynağı) ──
section("3) users.is_premium kolonu (PRO sorununun kaynağı)")
cur.execute("""
    SELECT column_name, data_type FROM information_schema.columns
    WHERE table_name = 'users';
""")
user_cols = {r[0]: r[1] for r in cur.fetchall()}
if "is_premium" in user_cols:
    print(f"  ✓ is_premium VAR  (tip: {user_cols['is_premium']})")
    try:
        cur.execute("SELECT COUNT(*) FROM users WHERE is_premium = true;")
        prem = cur.fetchone()[0]
        cur.execute("SELECT COUNT(*) FROM users;")
        total = cur.fetchone()[0]
        print(f"  Premium kullanıcı: {prem} / {total}")
    except Exception as e:
        print(f"  (sayım hatası: {e})")
else:
    print("  ✗ is_premium YOK — PRO bug'ının sebebi BU.")
    print("    Kod is_premium okuyor ama kolon DB'de yok → herkes free sanılıyor.")


# ── 4. session_exercises.completed (eski hata kaynağı) ──
section("4) session_exercises.completed kolonu")
cur.execute("""
    SELECT column_name FROM information_schema.columns
    WHERE table_name = 'session_exercises';
""")
se_cols = {r[0] for r in cur.fetchall()}
if "session_exercises" not in existing:
    print("  (session_exercises tablosu yok)")
elif "completed" in se_cols:
    print("  ✓ completed kolonu VAR")
else:
    print("  ✗ completed kolonu YOK")


section("BİTTİ — yukarıdaki tüm çıktıyı Claude'a yapıştır")
cur.close()
conn.close()
