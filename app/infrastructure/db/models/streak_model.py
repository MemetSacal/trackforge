# Streak (seri) takibi — su, egzersiz, uyku kategorileri için
from datetime import datetime, date
from typing import TYPE_CHECKING
from sqlalchemy import String, Integer, Date, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from app.infrastructure.db.models.user_model import UserModel


class StreakModel(Base):
    __tablename__ = "streaks"

    id: Mapped[str] = mapped_column(String, primary_key=True)

    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Streak türü — water / exercise / sleep
    streak_type: Mapped[str] = mapped_column(String, nullable=False)

    # Mevcut seri — her gün hedef tutunca artar, tutunmazsa sıfırlanır
    current_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # En uzun seri — hiç sıfırlanmaz, rekor tutar
    longest_streak: Mapped[int] = mapped_column(Integer, default=0, nullable=False)

    # Son güncelleme tarihi — bu güne göre streak koptu mu kontrol edilir
    last_updated: Mapped[date] = mapped_column(Date, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )

    user: Mapped["UserModel"] = relationship("UserModel", back_populates="streaks")


"""
DOSYA AKIŞI:
Her kullanıcı için her streak_type'dan bir kayıt olur.
Örn: user_id=X için water, exercise, sleep — 3 ayrı streak kaydı.

current_streak nasıl artar?
  - Su: günlük hedef tutulunca +1
  - Egzersiz: o gün seans oluşturulunca +1
  - Uyku: uyku logu girilip quality_score >= 6 olunca +1

Streak kopar mı?
  - last_updated'dan bu yana 1 günden fazla geçtiyse current_streak = 0
  - longest_streak hiç sıfırlanmaz

Spring Boot karşılığı: @Entity + @ManyToOne
"""