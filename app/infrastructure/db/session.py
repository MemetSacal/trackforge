from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker #Aynı PyCharm indexleme sorunu, kodu etkilemiyor
from app.core.config import get_settings

settings = get_settings()

# Async engine oluştur — veritabanına bağlantı kapısı
engine = create_async_engine(
    settings.DATABASE_URL,
    echo=True,  # Geliştirme ortamında SQL sorgularını terminale yazdırır
    pool_size=10,  # Aynı anda max 10 bağlantı açık tutulur
    max_overflow=20,  # Gerekirse 20 ekstra bağlantıya kadar çıkabilir
)

# Session factory — her request için yeni bir oturum üretir
AsyncSessionLocal = async_sessionmaker(
    bind=engine,
    class_=AsyncSession,
    expire_on_commit=False,  # Commit sonrası objeleri bellekten silme
)


async def get_db():
    # Her API isteği için bir session açar, istek bitince kapatır
    async with AsyncSessionLocal() as session:
        try:
            yield session
            await session.commit()
        except Exception:
            await session.rollback()
            raise