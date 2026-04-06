import uuid
from datetime import datetime, timezone, date
from sqlalchemy import String, DateTime, Date, Integer, Text, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.db.base import Base


class MenstrualCycleModel(Base):
    __tablename__ = "menstrual_cycles"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    cycle_start_date: Mapped[date] = mapped_column(Date, nullable=False)
    cycle_length_days: Mapped[int] = mapped_column(Integer, default=28)
    period_length_days: Mapped[int] = mapped_column(Integer, default=5)
    notes: Mapped[str] = mapped_column(Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )

    # ── İlişki ──
    user: Mapped["UserModel"] = relationship(
        "UserModel", back_populates="menstrual_cycles"
    )


"""
DOSYA AKIŞI:
MenstrualCycleModel regl döngüsü kayıtlarını tutar.
Spring Boot karşılığı: @Entity + @Table(name="menstrual_cycles")
"""