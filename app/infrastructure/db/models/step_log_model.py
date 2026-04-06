import uuid
from datetime import datetime, timezone, date
from sqlalchemy import String, DateTime, Date, Integer, Float, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.db.base import Base


class StepLogModel(Base):
    __tablename__ = "step_logs"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    date: Mapped[date] = mapped_column(Date, nullable=False)
    step_count: Mapped[int] = mapped_column(Integer, nullable=False)
    target_steps: Mapped[int] = mapped_column(Integer, default=10000)
    distance_km: Mapped[float] = mapped_column(Float, nullable=True)
    calories_burned: Mapped[float] = mapped_column(Float, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )

    # ── İlişki ──
    user: Mapped["UserModel"] = relationship(
        "UserModel", back_populates="step_logs"
    )


"""
DOSYA AKIŞI:
StepLogModel adım sayar kayıtlarını tutar.
Spring Boot karşılığı: @Entity + @Table(name="step_logs")
"""