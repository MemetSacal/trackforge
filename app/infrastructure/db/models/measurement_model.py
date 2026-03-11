import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from app.infrastructure.db.base import Base


class MeasurementModel(Base):
    # Spring'deki @Entity @Table(name="body_measurements") ile aynı mantık
    __tablename__ = "body_measurements"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
        # FK — hangi kullanıcıya ait olduğunu belirtir
    )
    date: Mapped[datetime] = mapped_column(
        Date, nullable=False
        # DATE_BASED zaman referansı — hafta bu tarihten hesaplanır, saklanmaz
    )

    # Tüm ölçüm alanları nullable — kullanıcı hepsini girmek zorunda değil
    weight_kg: Mapped[float] = mapped_column(Float, nullable=True)
    body_fat_pct: Mapped[float] = mapped_column(Float, nullable=True)
    muscle_mass_kg: Mapped[float] = mapped_column(Float, nullable=True)
    waist_cm: Mapped[float] = mapped_column(Float, nullable=True)
    chest_cm: Mapped[float] = mapped_column(Float, nullable=True)
    hip_cm: Mapped[float] = mapped_column(Float, nullable=True)
    arm_cm: Mapped[float] = mapped_column(Float, nullable=True)
    leg_cm: Mapped[float] = mapped_column(Float, nullable=True)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )