import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Text, Integer, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.db.base import Base


class FileUploadModel(Base):
    # Spring'deki @Entity @Table(name="file_uploads") ile aynı mantık
    __tablename__ = "file_uploads"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
        # UUID primary key — her dosya için benzersiz
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
        # FK — users tablosunda olmayan user_id ile kayıt oluşturulamaz
    )
    file_type: Mapped[str] = mapped_column(
        String, nullable=False
        # "photo" veya "diet_plan" — dosyanın kategorisi
    )
    original_filename: Mapped[str] = mapped_column(
        String, nullable=False
        # Kullanıcının yüklediği orijinal dosya adı — "benim_fotom.jpg" gibi
    )
    stored_filename: Mapped[str] = mapped_column(
        String, nullable=False
        # Disk'te saklanan dosya adı — UUID ile rename edilmiş hali
        # Güvenlik için orijinal adı kullanmıyoruz
    )
    file_path: Mapped[str] = mapped_column(
        String, nullable=False
        # Dosyanın disk'teki tam yolu — "uploads/photos/uuid.jpg" gibi
    )
    mime_type: Mapped[str] = mapped_column(
        String, nullable=False
        # "image/jpeg", "image/png", "application/pdf" vs.
    )
    file_size_bytes: Mapped[int] = mapped_column(
        Integer, nullable=False
        # Dosya boyutu byte cinsinden — 10MB = 10_485_760 byte
    )
    description: Mapped[str] = mapped_column(
        Text, nullable=True
        # Opsiyonel açıklama — "Mart ayı diyet planı" gibi
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
        # Yükleme zamanı — otomatik set edilir
    )

"""
Diğer modellerden farkı:
Boolean veya Float yok — dosya metadata'sı string/int ağırlıklı
stored_filename ayrı tutuldu — güvenlik gereği orijinal adı disk'e yazmıyoruz
file_path ayrı tutuldu — ileride S3'e geçince bu path değişecek
"""