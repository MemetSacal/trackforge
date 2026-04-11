import uuid
from datetime import date, datetime, time
from typing import TYPE_CHECKING
from sqlalchemy import String, Integer, Float, Date, Time, DateTime, Text, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from backend.app.infrastructure.db.models.user_model import UserModel


class SleepLogModel(Base):
    __tablename__ = "sleep_logs"

    # Primary key
    id: Mapped[str] = mapped_column(String, primary_key=True)

    # Foreign key — hangi kullanıcıya ait
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Uyku alanları
    date: Mapped[date] = mapped_column(Date, nullable=False)
    sleep_time: Mapped[time] = mapped_column(Time, nullable=True)        # Yatış saati
    wake_time: Mapped[time] = mapped_column(Time, nullable=True)         # Kalkış saati
    duration_hours: Mapped[float] = mapped_column(Float, nullable=True)  # Toplam süre
    quality_score: Mapped[int] = mapped_column(Integer, nullable=True)   # 1-10 kalite skoru
    notes: Mapped[str] = mapped_column(Text, nullable=True)

    # Zaman damgaları
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # user_model.py'deki sleep_logs ile eşleşir
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="sleep_logs")


"""
DOSYA AKIŞI:
Time tipi: saat/dakika bilgisi için — "23:30", "07:15" gibi
duration_hours: sleep_time ve wake_time'dan hesaplanabilir ama
ayrı tutuldu çünkü gece yarısını geçen uykularda hesaplama karmaşıklaşır.

Spring Boot karşılığı: @Entity + @Table + @ManyToOne anotasyonları.
"""