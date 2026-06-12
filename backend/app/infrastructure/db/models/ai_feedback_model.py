# ── ai_feedback_model.py — AI çıktılarına 👍/👎 geri bildirim ──
# Her AI önerisinin altındaki feedback bar'dan beslenir.
# Amaç: hangi modülün ne kadar beğenildiğini ölçmek; ileride
# kişiselleştirme ve prompt iyileştirme için veri biriktirmek.
import uuid
from datetime import datetime, timezone
from sqlalchemy import String, SmallInteger, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column
from backend.app.infrastructure.db.base import Base


class AIFeedbackModel(Base):
    __tablename__ = "ai_feedback"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )
    feature: Mapped[str] = mapped_column(
        String, nullable=False  # workout_plan | meal_advice | vision | recipe | ...
    )
    rating: Mapped[int] = mapped_column(
        SmallInteger, nullable=False  # 1 = 👍, -1 = 👎
    )
    comment: Mapped[str] = mapped_column(
        String(300), nullable=True  # opsiyonel kısa yorum
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )
