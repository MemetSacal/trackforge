# ── blood_value_model.py (v1.1) — Kan değeri geçmişi ──
# prefs.blood_values tek anlık değer tutuyordu; bu tablo ZAMAN SERİSİ:
# her tahlil tarihi ayrı satır. "Demir Ocak'ta 60, Mart'ta 85'e çıktı"
# gibi trend takibi + AI/PDF rapora geçmiş girişi sağlar.
import uuid
from datetime import datetime, timezone, date
from sqlalchemy import String, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from backend.app.infrastructure.db.base import Base


class BloodValueModel(Base):
    __tablename__ = "blood_values"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    # Standart anahtar: hemoglobin, ferritin, vitamin_d, vitamin_b12,
    # iron, tsh, glucose, hba1c, cholesterol_total, hdl, ldl, triglycerides
    marker: Mapped[str] = mapped_column(String, nullable=False)
    value: Mapped[float] = mapped_column(Float, nullable=False)
    unit: Mapped[str] = mapped_column(String, nullable=True)   # mg/dL, ng/mL vb.
    test_date: Mapped[date] = mapped_column(Date, nullable=False, index=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
