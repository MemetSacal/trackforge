from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context
from app.core.config import get_settings
from app.infrastructure.db.base import Base
from app.infrastructure.db.models import user_model # noqa
from app.infrastructure.db.models import measurement_model # noqa
from app.infrastructure.db.models import note_model # noqa
from app.infrastructure.db.models import meal_compliance_model  # noqa

# Alembic config objesi — alembic.ini dosyasını okur
config = context.config

# Python logging ayarlarını alembic.ini den yükle
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Hangi modelleri takip edeceğimizi söylüyoruz
# Buraya import edilen her model otomatik migration'a dahil olur
from app.infrastructure.db.models import user_model  # noqa
target_metadata = Base.metadata

settings = get_settings()


def run_migrations_offline() -> None:
    # DB bağlantısı olmadan SQL script üretir
    url = settings.DATABASE_URL.replace("asyncpg", "psycopg2")
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
    )
    with context.begin_transaction():
        context.run_migrations()


def run_migrations_online() -> None:
    # DB ye direkt bağlanıp migration uygular
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = settings.DATABASE_URL.replace(
        "asyncpg", "psycopg2"
    )
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )
    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
        )
        with context.begin_transaction():
            context.run_migrations()


if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()

"""
Burada env.py dosyasını oluşturunca ilk migrationsu oluşturmak için alembic revision --autogenerate -m "create users table"
komutunu terminalde kullandık bu sayede versions içinde bir table oluşturduk

Sonrasında alembic upgrade head diyerek oluşturduğumuz table ı PostgreSQL de oluşturmuş olduk 
pgAdmin de bunu doğrulayabiliriz:
Tarayıcıda http://localhost:5050 aç → TrackForge → Databases → trackforge_db → Schemas → public → Tables → users 
burada ki local bağlantı ve mail şifresini ise docker-compose.yml dosyasında tanımlamıştık zaten PostgreSQL i Dockerdan alıyoruz 

# noqa → "no quality assurance" demek. Linter'a "bu satırı kontrol etme, uyarı verme" diyoruz.
env.py'deki import'larda şunu görürsün:
pythonfrom app.infrastructure.db.models import user_model  # noqa
Bu import'u sadece Alembic'in modeli "görmesi" için yapıyoruz, user_model'i kodda hiç kullanmıyoruz. Normalde linter "import ettin ama kullanmıyorsun" diye uyarı verir. # noqa ile o uyarıyı susturuyoruz.
Kısacası — kullanılmayan import uyarısını bastırmak için. 
"""