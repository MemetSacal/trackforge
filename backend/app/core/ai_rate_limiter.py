# ── ai_rate_limiter.py — Backend AI kota kontrolü (v2) ──
#
# v2 DEĞİŞİKLİKLERİ:
#   1. TÜM AI endpoint'leri kapsama alındı (recipe, cycle_advice,
#      calorie_bank dahil) — eskiden bu üçü tamamen limitsizdi,
#      maliyet açısından açık kapıydı.
#   2. Premium artık "sınırsız" değil — yüksek ama SONLU limit.
#      Modifiye APK / kötüye kullanım maliyet bombasını engeller.
#   3. 429 yanıtı yapılandırılmış detail döner (error_code, used,
#      limit, resets_in_days) — Flutter string parse etmez.
#   4. get_quota_status() → her başarılı AI yanıtına kalan hak
#      bilgisi eklenir, client lokal sayacını sunucuyla senkronlar.
#
# Esas otorite BURASI'dır; Flutter'daki rate_limiter.dart sadece
# UX iyileştirmesidir (butonu önceden griye çekmek).

import uuid
from datetime import date, timedelta

from fastapi import HTTPException
from sqlalchemy import select, func
from sqlalchemy.ext.asyncio import AsyncSession

# ── Kota tablosu: feature -> (free_limit, premium_limit, periyot) ──
# Periyot: "daily" | "weekly"
QUOTAS: dict[str, tuple[int, int, str]] = {
    "vision":          (3,   20, "daily"),
    "weekly_summary":  (1,    3, "weekly"),
    "meal_advice":     (2,   10, "weekly"),
    "workout_plan":    (2,   10, "weekly"),
    "recipe":          (3,   30, "weekly"),   # v2: eskiden limitsizdi
    "cycle_advice":    (3,   15, "weekly"),   # v2: eskiden limitsizdi
    "calorie_bank":    (3,   15, "daily"),    # v2: eskiden limitsizdi
    "ai_feedback":     (50, 200, "daily"),    # feedback spam koruması
    "fridge_recipe":   (2,   15, "weekly"),   # v3: buzdolabı foto→tarif (vision + üretim = 2 AI çağrısı, ayrı kota)
    "text_calorie":    (5,   30, "daily"),    # v6: yazıyla/sesle öğün girişi (görsel yok → ucuz → cömert)
    "chat":            (15, 100, "daily"),    # v1.1: sohbet asistanı (Haiku, ucuz → cömert ama sınırlı; saçma soru kendi hakkını yer)
}


def _week_start(d: date) -> date:
    """Haftanın başlangıç günü (Pazartesi)."""
    return d - timedelta(days=d.weekday())


def _period_bounds(period: str) -> tuple[date, date, int]:
    """(start, end, resets_in_days) döndürür."""
    today = date.today()
    if period == "daily":
        return today, today, 1
    start = _week_start(today)
    return start, today, 7 - today.weekday()


async def _count_usage(db: AsyncSession, user_id: str, feature: str,
                       start: date, end: date) -> int:
    from backend.app.infrastructure.db.models.ai_usage_model import AIUsageModel
    result = await db.execute(
        select(func.count()).where(
            AIUsageModel.user_id == user_id,
            AIUsageModel.feature == feature,
            AIUsageModel.used_at >= start,
            AIUsageModel.used_at <= end,
        )
    )
    return result.scalar() or 0


async def get_quota_status(db: AsyncSession, user_id: str,
                           is_premium: bool, feature: str) -> dict:
    """Mevcut kullanım durumunu döndürür — AI yanıtlarına gömülür.

    Dönen yapı Flutter'daki RateLimiter.syncFromServer ile birebir uyumlu:
      {"feature": ..., "used": 2, "limit": 3, "remaining": 1,
       "period": "weekly", "resets_in_days": 4}
    """
    free_limit, premium_limit, period = QUOTAS[feature]
    limit = premium_limit if is_premium else free_limit
    start, end, resets = _period_bounds(period)
    used = await _count_usage(db, user_id, feature, start, end)
    return {
        "feature": feature,
        "used": used,
        "limit": limit,
        "remaining": max(limit - used, 0),
        "period": period,
        "resets_in_days": resets,
    }


async def check_quota(db: AsyncSession, user_id: str,
                      is_premium: bool, feature: str) -> dict:
    """Kota kontrolü — aşıldıysa yapılandırılmış 429 fırlatır.

    Geçerse mevcut durumu döndürür (henüz tüketmeden);
    tüketim record_usage() ile, AI çağrısı BAŞARILI olduktan sonra yapılır.
    Böylece Claude hatası kullanıcının hakkını yakmaz.
    """
    status = await get_quota_status(db, user_id, is_premium, feature)
    if status["used"] >= status["limit"]:
        period_label = "günlük" if status["period"] == "daily" else "haftalık"
        raise HTTPException(
            status_code=429,
            detail={
                "error_code": "QUOTA_EXCEEDED",
                "feature": feature,
                "used": status["used"],
                "limit": status["limit"],
                "period": status["period"],
                "resets_in_days": status["resets_in_days"],
                "is_premium": is_premium,
                "message_tr": (
                    f"Bu özelliğin {period_label} limiti doldu "
                    f"({status['used']}/{status['limit']})."
                    + ("" if is_premium else " PRO ile limitini artırabilirsin.")
                ),
            },
        )
    return status


async def record_usage(db: AsyncSession, user_id: str, feature: str) -> None:
    """Kullanım kaydı ekle — yalnızca başarılı AI çağrısından sonra çağrılır."""
    from backend.app.infrastructure.db.models.ai_usage_model import AIUsageModel
    record = AIUsageModel(
        id=str(uuid.uuid4()),
        user_id=user_id,
        feature=feature,
        used_at=date.today(),
    )
    db.add(record)
    await db.flush()


async def consume_and_status(db: AsyncSession, user_id: str,
                             is_premium: bool, feature: str) -> dict:
    """record_usage + güncel durum tek çağrıda — endpoint sonunda kullanılır."""
    await record_usage(db, user_id, feature)
    return await get_quota_status(db, user_id, is_premium, feature)


# ── ESKİ API (geriye dönük uyumluluk) ─────────────────────
# Eski check_*_limit fonksiyonlarını çağıran kod kalmışsa kırılmasın.
# Yeni kod check_quota() kullanmalı.

async def check_vision_limit(user_id: str, db: AsyncSession) -> None:
    await check_quota(db, user_id, False, "vision")

async def check_weekly_summary_limit(user_id: str, db: AsyncSession) -> None:
    await check_quota(db, user_id, False, "weekly_summary")

async def check_meal_advice_limit(user_id: str, db: AsyncSession) -> None:
    await check_quota(db, user_id, False, "meal_advice")

async def check_workout_plan_limit(user_id: str, db: AsyncSession) -> None:
    await check_quota(db, user_id, False, "workout_plan")
