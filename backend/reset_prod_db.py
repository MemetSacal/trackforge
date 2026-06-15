"""
TrackForge — Prod DB Sıfırlama Scripti
═══════════════════════════════════════════════════
DB'nin İÇİNİ boşaltır (DROP SCHEMA public CASCADE + yeniden oluştur).
Tüm tablolar + alembic_version kalıntısı gider. DB'nin KENDİSİ silinmez,
DATABASE_URL değişmez, Render ayarların bozulmaz.

⚠️ Bu tüm verileri siler! Sadece test verisi olduğu için güvenli.

KULLANIM (check_alembic_version.py ile AYNI şekilde):
  - DATABASE_URL'i Render External Database URL ile değiştir (aşağıda)
  - PyCharm'dan çalıştır
"""
import os
import sys

# ── Render External Database URL'i buraya yapıştır ──
# (check_alembic_version.py'de kullandığın AYNI URL)
DATABASE_URL = os.environ.get("DATABASE_URL", "postgresql://trackforge:GPdMTFyFV88rXkcZBhMccSWu0YmTOlPU@dpg-d8eqomjeo5us73cpc6l0-a.oregon-postgres.render.com/trackforge_db")

if "BURAYA" in DATABASE_URL:
    print("⚠ DATABASE_URL ayarlanmadı. check_alembic_version.py'deki URL'in")
    print("  AYNISINI buraya yapıştır.")
    sys.exit(1)

url = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
url = url.replace("postgres://", "postgresql://")

try:
    import psycopg2
except ImportError:
    print("pip install psycopg2-binary")
    sys.exit(1)

print("Bağlanılıyor...")
conn = psycopg2.connect(url)
conn.autocommit = True
cur = conn.cursor()

# Önce mevcut tablo sayısını göster
cur.execute("SELECT count(*) FROM pg_tables WHERE schemaname='public';")
before = cur.fetchone()[0]
print(f"ÖNCE: public şemasında {before} tablo var")

# ── Güvenlik onayı ──
print("\n⚠️  Bu işlem TÜM tabloları ve verileri SİLECEK.")
ans = input("Devam etmek için 'EVET SIFIRLA' yaz: ").strip()
if ans != "EVET SIFIRLA":
    print("İptal edildi, hiçbir şey değişmedi.")
    conn.close()
    sys.exit(0)

# ── Sıfırla ──
print("\nSıfırlanıyor...")
cur.execute("DROP SCHEMA public CASCADE;")
cur.execute("CREATE SCHEMA public;")
# Render'da default yetkiler (genelde gerekmez ama garanti)
cur.execute("GRANT ALL ON SCHEMA public TO public;")

# Doğrula
cur.execute("SELECT count(*) FROM pg_tables WHERE schemaname='public';")
after = cur.fetchone()[0]
print(f"SONRA: public şemasında {after} tablo var")

if after == 0:
    print("\n✓ DB tertemiz. Şimdi backend'i (baseline migration ile) deploy et.")
    print("  Deploy sırasında 'alembic upgrade head' çalışıp 26 tabloyu kuracak.")
else:
    print("\n⚠ Beklenmedik: hâlâ tablo var. Claude'a danış.")

cur.close()
conn.close()