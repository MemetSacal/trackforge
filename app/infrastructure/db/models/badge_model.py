# Kazanılan rozetler — her rozet bir kez kazanılır
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import String, Text, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from app.infrastructure.db.models.user_model import UserModel


class BadgeModel(Base):
    __tablename__ = "badges"

    id: Mapped[str] = mapped_column(String, primary_key=True)

    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Rozet anahtarı — "first_workout", "7_day_water" gibi
    badge_key: Mapped[str] = mapped_column(String, nullable=False)

    # Rozet adı — "İlk Antrenman", "7 Gün Su Hedefi" gibi
    badge_name: Mapped[str] = mapped_column(String, nullable=False)

    # Rozet açıklaması
    description: Mapped[str] = mapped_column(Text, nullable=True)

    # Ne zaman kazanıldı
    earned_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["UserModel"] = relationship("UserModel", back_populates="badges")


"""
DOSYA AKIŞI:
Her rozet bir kez kazanılır — aynı badge_key iki kez eklenemez.
Rozet kontrolü gamification_service.py'de yapılır.

Desteklenen badge_key değerleri:
  first_workout    → İlk antrenman seansı
  7_day_water      → 7 gün su hedefi
  30_day_water     → 30 gün su hedefi
  weight_loss_5kg  → 5 kg kilo kaybı
  weight_loss_10kg → 10 kg kilo kaybı
  first_photo      → İlk fotoğraf yükleme
  streak_warrior   → 7 gün egzersiz serisi

Spring Boot karşılığı: @Entity + @ManyToOne
"""