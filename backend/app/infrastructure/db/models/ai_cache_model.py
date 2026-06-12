# ── ai_cache_model.py — Sunucu tarafı AI yanıt cache'i ──
# SORUN: Aynı girdiyle arka arkaya basılan "oluştur" butonu (çift tık,
#   timeout sonrası retry, sabırsızlık) her seferinde Claude'a gidiyordu
#   → gereksiz maliyet + kullanıcının kotasının boşa yanması.
# ÇÖZÜM: (user, feature, input_hash) için 24 saatlik cache.
#   Cache isabetinde Claude'a GİDİLMEZ ve kota TÜKETİLMEZ.
#   Kullanıcı bilinçli olarak yeni plan isterse force_new=true gönderir.
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Text, DateTime, ForeignKey, Index
from sqlalchemy.orm import Mapped, mapped_column
from backend.app.infrastructure.db.base import Base


class AIResponseCacheModel(Base):
    __tablename__ = "ai_response_cache"
    __table_args__ = (
        Index("ix_ai_cache_lookup", "user_id", "feature", "input_hash"),
    )

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    feature: Mapped[str] = mapped_column(String, nullable=False)
    input_hash: Mapped[str] = mapped_column(String(64), nullable=False)
    response_json: Mapped[str] = mapped_column(Text, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )
