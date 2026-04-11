# SQLAlchemy ORM modeli — onboarding_profile tablosunu temsil eder
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import String, Boolean, DateTime, ForeignKey, UniqueConstraint, JSON, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from backend.app.infrastructure.db.models.user_model import UserModel


class OnboardingProfileModel(Base):
    __tablename__ = "onboarding_profile"

    # One-to-one — her kullanıcı için tek onboarding kaydı
    __table_args__ = (
        UniqueConstraint("user_id", name="uq_onboarding_profile_user_id"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True)

    # FK — CASCADE: kullanıcı silinince onboarding da silinir
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Onboarding tamamlandı mı? — Flutter buna göre akışı gösterir/gizler
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Hedefler — max 3 seçim, JSON array olarak saklanır
    # ["weight_loss", "muscle_gain", "stress_management"] gibi
    goals: Mapped[list] = mapped_column(JSON, nullable=True, default=list)

    # Diyet tercihi — normal/vegetarian/vegan/gluten_free
    diet_preference: Mapped[str] = mapped_column(String, nullable=True)

    # Onboarding ne zaman tamamlandı
    completed_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=True)

    # Zaman damgaları
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # user_model.py'deki onboarding_profile ile eşleşir — one-to-one
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="onboarding_profile")


"""
DOSYA AKIŞI:
OnboardingProfileModel one-to-one ilişki — her kullanıcı için tek kayıt.
is_completed = False → Flutter her girişte onboarding ekranlarını gösterir
is_completed = True  → bir daha gösterilmez

goals JSON örnek: ["weight_loss", "muscle_gain"]
Desteklenen goal değerleri:
  weight_loss / maintain_weight / gain_weight / muscle_gain /
  change_diet / meal_planning / stress_management / stay_active

Spring Boot karşılığı: @Entity + @OneToOne
"""