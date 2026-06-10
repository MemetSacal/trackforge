# ── ai_rate_limiter.py — Backend AI rate limit kontrolü ──
from datetime import date, timedelta
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func
from fastapi import HTTPException

# ── Limit sabitleri (Flutter rate_limiter.dart ile senkron) ──
VISION_DAILY_LIMIT    = 3   # calorie-from-photo: 3/gün
WEEKLY_ANALYSIS_LIMIT = 1   # weekly-summary: 1/hafta
MEAL_ADVICE_LIMIT     = 2   # meal-advice: 2/hafta
WORKOUT_PLAN_LIMIT    = 2   # workout-plan: 2/hafta


def _week_start(d: date) -> date:
    """Haftanın başlangıç günü (Pazartesi)."""
    return d - timedelta(days=d.weekday())


async def check_vision_limit(user_id: str, db: AsyncSession) -> None:
    """Günlük vision limitini kontrol et. Aşıldıysa 429 fırlat."""
    from backend.app.infrastructure.db.models.meal_compliance_model import MealComplianceModel
    # Vision kullanım sayısını ayrı bir tabloda tutmak yerine
    # basitlik için PostgreSQL'de JSON veya ayrı tablo eklemek gerekir.
    # Şimdilik: kullanım sayısını ai_usage tablosunda tutacağız.
    await _check_limit(user_id, db, "vision", VISION_DAILY_LIMIT, "daily")


async def check_weekly_summary_limit(user_id: str, db: AsyncSession) -> None:
    await _check_limit(user_id, db, "weekly_summary", WEEKLY_ANALYSIS_LIMIT, "weekly")


async def check_meal_advice_limit(user_id: str, db: AsyncSession) -> None:
    await _check_limit(user_id, db, "meal_advice", MEAL_ADVICE_LIMIT, "weekly")


async def check_workout_plan_limit(user_id: str, db: AsyncSession) -> None:
    await _check_limit(user_id, db, "workout_plan", WORKOUT_PLAN_LIMIT, "weekly")


async def record_usage(user_id: str, db: AsyncSession, feature: str) -> None:
    """Kullanım kaydı ekle."""
    from backend.app.infrastructure.db.models.ai_usage_model import AIUsageModel
    import uuid
    record = AIUsageModel(
        id=str(uuid.uuid4()),
        user_id=user_id,
        feature=feature,
        used_at=date.today(),
    )
    db.add(record)
    await db.flush()


async def _check_limit(
    user_id: str,
    db: AsyncSession,
    feature: str,
    limit: int,
    period: str,  # "daily" | "weekly"
) -> None:
    from backend.app.infrastructure.db.models.ai_usage_model import AIUsageModel

    today = date.today()
    if period == "daily":
        start = today
        end   = today
    else:  # weekly
        start = _week_start(today)
        end   = today

    result = await db.execute(
        select(func.count()).where(
            AIUsageModel.user_id == user_id,
            AIUsageModel.feature == feature,
            AIUsageModel.used_at >= start,
            AIUsageModel.used_at <= end,
        )
    )
    count = result.scalar() or 0

    if count >= limit:
        period_label = "günlük" if period == "daily" else "haftalık"
        raise HTTPException(
            status_code=429,
            detail=f"{period_label} limit aşıldı ({count}/{limit}). PRO'ya geç veya bekle.",
        )