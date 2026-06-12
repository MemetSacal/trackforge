# ── duel_model.py (v5) — Arkadaşla 7 günlük adım düellosu ──
# Viral döngünün motoru: düello daveti → arkadaş uygulamayı açar →
# 7 gün boyunca ikisi de her gün girer → kazanan paylaşır.
# Adım verisi step_logs'tan okunur; ayrı sayaç tutulmaz (tek doğruluk kaynağı).
import uuid
from datetime import datetime, timezone, date
from sqlalchemy import String, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from backend.app.infrastructure.db.base import Base


class DuelModel(Base):
    __tablename__ = "duels"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    challenger_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    opponent_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    start_date: Mapped[date] = mapped_column(Date, nullable=False)
    end_date: Mapped[date] = mapped_column(Date, nullable=False)
    # pending → davet gönderildi | active → kabul edildi, sayım sürüyor
    # finished → bitti | declined → reddedildi
    status: Mapped[str] = mapped_column(String, nullable=False, default="pending")
    winner_id: Mapped[str] = mapped_column(String, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )
