# Kullanıcı seviye ve XP takibi — one-to-one
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import String, Integer, DateTime, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from app.infrastructure.db.models.user_model import UserModel


class UserLevelModel(Base):
    __tablename__ = "user_levels"

    __table_args__ = (
        UniqueConstraint("user_id", name="uq_user_levels_user_id"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True)

    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Mevcut seviye — 1'den başlar
    level: Mapped[int] = mapped_column(Integer, default=1, nullable=False)

    # Toplam XP puanı
    xp: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Seviye unvanı — Beginner / Active / Fit / Athlete / Champion
    level_title: Mapped[str] = mapped_column(String, default="Beginner", nullable=False)

    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    user: Mapped["UserModel"] = relationship("UserModel", back_populates="user_level")


"""
DOSYA AKIŞI:
UserLevelModel one-to-one — her kullanıcı için tek kayıt.
XP kazanma olayları gamification_service.py'de tetiklenir.

Seviye eşikleri:
  1 Beginner  →    0 XP
  2 Active    →  500 XP
  3 Fit       → 1500 XP
  4 Athlete   → 3000 XP
  5 Champion  → 6000 XP

XP kazanma kaynakları:
  Antrenman seansı  → +50 XP
  Su hedefi         → +20 XP
  Uyku logu         → +15 XP
  Rozet kazanma     → +100 XP
  Haftalık rapor    → +10 XP

Spring Boot karşılığı: @Entity + @OneToOne
"""