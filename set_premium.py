from sqlalchemy import create_engine, text
import os

engine = create_engine(os.environ['DATABASE_URL'])
with engine.connect() as conn:
    conn.execute(text("UPDATE users SET is_premium = true WHERE email = 'memetsacal@icloud.com'"))
    result = conn.execute(text('SELECT email, is_premium FROM users'))
    for row in result:
        print(row)
    conn.commit()