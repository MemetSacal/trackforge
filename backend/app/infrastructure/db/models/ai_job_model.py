# ── ai_job_model.py (v7) — Arka plan AI işleri ──
# SORUN: Workout/diyet planı üretimi 30-60 sn sürüyor; kullanıcı
#   spinner'a bakmak zorunda, istek timeout'a düşebiliyor, ekrandan
#   çıkarsa sonuç kayboluyordu (kota yanmıştı!).
# ÇÖZÜM: İstek anında job kaydı açılır, üretim asyncio task'ta
#   arka planda koşar, mobil 2.5 sn'de bir durumu yoklar (poll).
#   Sonuç DB'de durur — kullanıcı ekrandan çıksa bile kaybolmaz.
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Text, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from backend.app.infrastructure.db.base import Base


class AIJobModel(Base):
    __tablename__ = "ai_jobs"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    feature: Mapped[str] = mapped_column(String, nullable=False)  # workout_plan | meal_advice
    # pending → kuyruğa alındı | running → üretiliyor
    # done → result_json hazır | error → error_message dolu
    status: Mapped[str] = mapped_column(String, nullable=False, default="pending")
    result_json: Mapped[str] = mapped_column(Text, nullable=True)
    error_message: Mapped[str] = mapped_column(String(500), nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
