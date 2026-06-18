import os
from sqlalchemy import create_engine, text

# 1. Ortam değişkeni yoksa Render External URL'ini varsayılan olarak kullan
DATABASE_URL = os.environ.get(
    "DATABASE_URL",
    "postgresql://trackforge:GPdMTFyFV88rXkcZBhMccSWu0YmTOlPU@dpg-d8eqomjeo5us73cpc6l0-a.oregon-postgres.render.com/trackforge_db"
)

# 2. SQLAlchemy ve psycopg2 için eski 'postgres://' veya async takılarını temizle
url = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")
url = url.replace("postgres://", "postgresql://")

# 3. Engine oluştur ve çalıştır
engine = create_engine(url)

with engine.connect() as conn:
    # SQL sorgusunu çalıştır ve transaction'ı commit et
    conn.execute(text("UPDATE users SET is_premium = true WHERE email = 'memetsacal@icloud.com'"))
    conn.commit()
    print("✓ Kullanıcı başarıyla PREMIUM yapıldı.")

    # Güncel durumu kontrol et
    result = conn.execute(text("SELECT email, is_premium FROM users WHERE email = 'memetsacal@icloud.com'"))
    for row in result:
        print(f"Güncel Durum -> Email: {row[0]}, Premium: {row[1]}")