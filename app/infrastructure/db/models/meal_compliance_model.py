import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Text, Float, Boolean, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.db.base import Base


class MealComplianceModel(Base):
    # Spring'deki @Entity @Table(name="meal_compliance") ile aynı mantık
    __tablename__ = "meal_compliance"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
        # UUID primary key — her kayıt için benzersiz
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
        # ForeignKey = FK — users tablosunda olmayan user_id ile kayıt oluşturulamaz
    )
    date: Mapped[datetime] = mapped_column(
        Date, nullable=False
        # DATE_BASED zaman referansı — o günün kaydı
    )
    complied: Mapped[bool] = mapped_column(
        Boolean, nullable=False
        # Zorunlu — True: diyete uyuldu, False: uyulmadı
    )
    compliance_rate: Mapped[float] = mapped_column(
        Float, nullable=True
        # Opsiyonel — 0.0 ile 100.0 arası uyum yüzdesi
    )
    notes: Mapped[str] = mapped_column(
        Text, nullable=True
        # Opsiyonel — neden uymadı, ne yedi vs. uzun metin olabilir
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
        # Kayıt oluşturulunca otomatik set edilir
    )

"""
NoteModel'den farkı:
Boolean tip eklendi — complied alanı için
Float tip eklendi — compliance_rate alanı için (0.0-100.0)
content yerine notes — opsiyonel, zorunlu değil
"""