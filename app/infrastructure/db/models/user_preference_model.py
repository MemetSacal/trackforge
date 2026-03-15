import uuid
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import String, DateTime, JSON, ForeignKey, UniqueConstraint, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from app.infrastructure.db.models.user_model import UserModel


class UserPreferenceModel(Base):
    __tablename__ = "user_preferences"

    # One-to-one olduğunu DB seviyesinde de garantile
    __table_args__ = (
        UniqueConstraint("user_id", name="uq_user_preferences_user_id"),
    )

    id: Mapped[str] = mapped_column(String, primary_key=True)

    # FK + UNIQUE — her kullanıcı için sadece bir tercih kaydı olabilir
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Yemek tercihleri — PostgreSQL'de JSON olarak saklanır
    liked_foods: Mapped[list] = mapped_column(JSON, nullable=True, default=list)
    disliked_foods: Mapped[list] = mapped_column(JSON, nullable=True, default=list)
    allergies: Mapped[list] = mapped_column(JSON, nullable=True, default=list)

    # Sağlık bilgileri
    diseases: Mapped[list] = mapped_column(JSON, nullable=True, default=list)
    blood_type: Mapped[str] = mapped_column(String, nullable=True)
    blood_values: Mapped[dict] = mapped_column(JSON, nullable=True)      # {"hemoglobin": 14.5}

    # Hedef ve antrenman
    workout_location: Mapped[str] = mapped_column(String, nullable=True)
    fitness_goal: Mapped[str] = mapped_column(String, nullable=True)

    # Zaman damgaları
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # user_model.py'deki preference ile eşleşir — one-to-one
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="preference")


"""
DOSYA AKIŞI:
UniqueConstraint → DB seviyesinde one-to-one garantisi.
JSON tip → PostgreSQL'de native JSON kolonu — liste ve dict saklanabilir.
liked_foods örnek: ["tavuk", "yulaf", "yumurta"]
blood_values örnek: {"hemoglobin": 14.5, "glucose": 95, "vitamin_d": 32}

Spring Boot karşılığı: @Entity + @OneToOne + @Column(columnDefinition="json")
"""