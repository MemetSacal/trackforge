# ── ai_usage_model.py ──
from sqlalchemy import Column, String, Date
from backend.app.infrastructure.db.base import Base


class AIUsageModel(Base):
    __tablename__ = "ai_usage_logs"

    id       = Column(String, primary_key=True)
    user_id  = Column(String, nullable=False, index=True)
    feature  = Column(String, nullable=False)   # vision / weekly_summary / meal_advice / workout_plan
    used_at  = Column(Date,   nullable=False, index=True)