import uuid
from datetime import datetime, timezone
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.db.base import Base

# lambda olmadan Python bu kodu dosya yüklenirken bir kere çalıştırır ve o anki tarihi default olarak sabitler. Yani tüm kayıtlar aynı tarihi alır.
# Mapped aslında SQLAlchemy'nin type hint sistemi — mapping'i biz yazmıyoruz, Base sınıfı hallediyor.

class UserModel(Base):
    # Spring'deki @Entity @Table(name="users") ile aynı mantık
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
        # UUID primary key — her kullanıcı için benzersiz
    )
    email: Mapped[str] = mapped_column(
        String, unique=True, nullable=False
        # Unique — aynı email ile iki kayıt olamaz
    )
    password_hash: Mapped[str] = mapped_column(
        String, nullable=False
        # DB'ye hiçbir zaman düz şifre gitmez, sadece hash
    )
    full_name: Mapped[str] = mapped_column(
        String, nullable=False
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
        # Kayıt oluşturulunca otomatik set edilir
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
        # Kayıt güncellenince otomatik güncellenir
    )