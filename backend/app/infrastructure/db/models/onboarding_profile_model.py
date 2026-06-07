# SQLAlchemy ORM modeli — onboarding_profile tablosunu temsil eder
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, Float, ForeignKey, UniqueConstraint, JSON, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from backend.app.infrastructure.db.models.user_model import UserModel


class OnboardingProfileModel(Base):
    __tablename__ = "onboarding_profile"

    __table_args__ = (
        UniqueConstraint("user_id", name="uq_onboarding_profile_user_id"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True)
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)
    goals: Mapped[list] = mapped_column(JSON, nullable=True, default=list)
    diet_preference: Mapped[str] = mapped_column(String, nullable=True)

    # ── YENİ: Hedef kilo ve kalori alışkanlığı ──────────
    target_weight_kg: Mapped[float] = mapped_column(Float, nullable=True)
    # Kullanıcının şu anki günlük kalori alışkanlığı
    # under_1500 / 1500_2000 / 2000_2500 / 2500_3000 / over_3000
    daily_calorie_habit: Mapped[str] = mapped_column(String, nullable=True)

    completed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now())
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now())

    user: Mapped["UserModel"] = relationship("UserModel", back_populates="onboarding_profile")