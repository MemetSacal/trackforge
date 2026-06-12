# HTTP katmanı — rapor endpoint'leri
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.report import WeeklyReportResponse, MonthlyReportResponse
from backend.app.application.services.report_service import ReportService
from backend.app.infrastructure.db.session import get_db
from backend.app.core.dependencies import get_current_user
from sqlalchemy import func as _func
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel
from backend.app.infrastructure.db.models.session_exercise_model import SessionExerciseModel
from backend.app.infrastructure.db.models.meal_compliance_model import MealComplianceModel
from backend.app.infrastructure.db.models.water_log_model import WaterLogModel
from backend.app.infrastructure.db.models.step_log_model import StepLogModel
from backend.app.infrastructure.db.models.streak_model import StreakModel
from backend.app.infrastructure.db.models.badge_model import BadgeModel
from datetime import date as _date
from sqlalchemy import select as _select

from backend.app.core.exceptions import NotFoundException
from backend.app.infrastructure.db.models.measurement_model import MeasurementModel
from backend.app.infrastructure.repositories.user_repository import UserRepository
from backend.app.application.services.gamification_service import GamificationService
from backend.app.application.services.meal_compliance_service import MealComplianceService
from backend.app.application.services.water_service import WaterService
from backend.app.application.services.sleep_service import SleepService
from backend.app.infrastructure.repositories.meal_compliance_repository import MealComplianceRepository

router = APIRouter()


def get_report_service(db: AsyncSession = Depends(get_db)) -> ReportService:
    return ReportService(db)


@router.get("/weekly", response_model=WeeklyReportResponse)
async def get_weekly_report(
    # Query parametresi — verilmezse bugünün tarihi kullanılır
    reference_date: date = Query(default=None, description="Haftadaki herhangi bir gün (varsayılan: bugün)"),
    current_user: str = Depends(get_current_user),
    service: ReportService = Depends(get_report_service),
):
    """
    Haftalık özet raporu getir.
    reference_date → o haftanın Pazartesi-Pazar aralığını döndürür.
    Örn: 2026-03-17 → 16-22 Mart 2026 haftasının raporu
    """
    # reference_date verilmemişse bugünü kullan
    if reference_date is None:
        reference_date = date.today()
    return await service.get_weekly_report(current_user, reference_date)


@router.get("/monthly", response_model=MonthlyReportResponse)
async def get_monthly_report(
    # year ve month ayrı query parametresi olarak alınır
    year: int = Query(..., ge=2020, le=2100, description="Yıl — örn: 2026"),
    month: int = Query(..., ge=1, le=12, description="Ay — 1-12 arası"),
    current_user: str = Depends(get_current_user),
    service: ReportService = Depends(get_report_service),
):
    """
    Aylık özet raporu getir.
    Örn: year=2026&month=3 → Mart 2026 raporu
    """
    return await service.get_monthly_report(current_user, year, month)

@router.get("/weekly/logs")
async def get_weekly_logs(
    reference_date: date = Query(default=None, description="Haftadaki herhangi bir gün"),
    current_user: str = Depends(get_current_user),
    service: ReportService = Depends(get_report_service),
):
    if reference_date is None:
        reference_date = date.today()
    return await service.get_weekly_logs(current_user, reference_date)



"""
DOSYA AKIŞI:
GET /reports/weekly                          → bu haftanın raporu
GET /reports/weekly?reference_date=2026-03-10 → o haftanın raporu
GET /reports/monthly?year=2026&month=3       → Mart 2026 raporu

reference_date opsiyonel — verilmezse date.today() kullanılır
year/month zorunlu — ge/le ile validasyon yapılır

Spring Boot karşılığı: @RestController + @GetMapping + @RequestParam.
"""

# ═════════════════════════════════════════════════════════
# ── v4: GET /reports/dashboard-summary ──
# SORUN: Dashboard açılışta 6 AYRI istek atıyordu (me, gamification,
#   weekly, son ölçüm, bugünkü öğün/su/uyku) → 6 round-trip, mobilde
#   yavaş açılış + pil + Render'da 6 kat istek yükü.
# ÇÖZÜM: Hepsi tek endpoint'te. Alt nesnelerin şekilleri, tekil
#   endpoint'lerin döndürdükleriyle BİREBİR aynı (aynı servisler ve
#   şemalar kullanılıyor) — mobil parse kodu hiç değişmeden çalışır.
# ═════════════════════════════════════════════════════════




@router.get("/dashboard-summary")
async def get_dashboard_summary(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    report_service: ReportService = Depends(get_report_service),
):
    today = _date.today()

    # ── Kullanıcı (auth /me ile aynı şekil) ──
    user = await UserRepository(db).get_by_id(user_id)
    user_block = {
        "id": user.id, "email": user.email, "full_name": user.full_name,
        "created_at": user.created_at, "is_premium": user.is_premium,
    } if user else None

    # ── Gamification özeti ──
    try:
        gamification = await GamificationService(db).get_summary(user_id)
    except Exception:
        gamification = None

    # ── Haftalık rapor ──
    try:
        weekly = await report_service.get_weekly_report(user_id, today)
    except Exception:
        weekly = None

    # ── Son ölçüm ──
    row = (await db.execute(
        _select(MeasurementModel)
        .where(MeasurementModel.user_id == user_id)
        .order_by(MeasurementModel.date.desc())
        .limit(1)
    )).scalar_one_or_none()
    latest_measurement = {
        "id": row.id, "user_id": row.user_id, "date": row.date,
        "weight_kg": row.weight_kg, "body_fat_pct": row.body_fat_pct,
        "muscle_mass_kg": row.muscle_mass_kg, "waist_cm": row.waist_cm,
        "chest_cm": row.chest_cm, "hip_cm": row.hip_cm,
        "arm_cm": row.arm_cm, "leg_cm": row.leg_cm,
        "created_at": row.created_at,
    } if row else None

    # ── Bugünün kayıtları — tekil endpoint'lerle aynı servisler.
    # Kayıt yoksa servisler NotFound fırlatır → null döneriz
    # (mobil zaten try/null deseniyle çalışıyordu, davranış aynı).
    async def _safe(coro):
        try:
            return await coro
        except (NotFoundException, Exception):
            return None

    meal_today = await _safe(
        MealComplianceService(MealComplianceRepository(db), db).get_by_date(user_id, today))
    water_today = await _safe(WaterService(db).get_by_date(user_id, today))
    sleep_today = await _safe(SleepService(db).get_by_date(user_id, today))

    return {
        "user": user_block,
        "gamification": gamification,
        "weekly": weekly,
        "latest_measurement": latest_measurement,
        "meal_today": meal_today,
        "water_today": water_today,
        "sleep_today": sleep_today,
    }


# ═════════════════════════════════════════════════════════
# ── v5: GET /reports/wrapped — Yıl Özeti ("TrackForge Wrapped") ──
# Spotify Wrapped mantığı: yılın tüm verisi paylaşılabilir,
# gurur duyulacak kartlara dönüşür. AI çağrısı YOK — saf agregasyon,
# kotasız ve bedava. Paylaşılan her kart organik tanıtımdır.
# ═════════════════════════════════════════════════════════

@router.get("/wrapped")
async def get_wrapped(
    year: int = None,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    year = year or _date.today().year
    y_start, y_end = _date(year, 1, 1), _date(year, 12, 31)

    # ── Antrenman ──
    sessions = (await db.execute(
        _select(ExerciseSessionModel).where(
            ExerciseSessionModel.user_id == user_id,
            ExerciseSessionModel.date >= y_start,
            ExerciseSessionModel.date <= y_end,
        )
    )).scalars().all()
    session_ids = [s.id for s in sessions]
    total_sessions = len(sessions)
    total_workout_minutes = sum(s.duration_minutes or 0 for s in sessions)
    total_workout_calories = round(sum(s.calories_burned or 0 for s in sessions))

    exercises = []
    if session_ids:
        exercises = (await db.execute(
            _select(SessionExerciseModel).where(
                SessionExerciseModel.session_id.in_(session_ids)
            )
        )).scalars().all()
    completed_exercises = sum(1 for e in exercises if getattr(e, "completed", False))

    # En sevilen egzersiz — yıl boyunca en çok yapılan
    freq = {}
    for e in exercises:
        n = (e.exercise_name or "").strip()
        if n:
            freq[n] = freq.get(n, 0) + 1
    favorite_exercise = max(freq, key=freq.get) if freq else None
    favorite_exercise_count = freq.get(favorite_exercise, 0) if favorite_exercise else 0

    # ── Adımlar ──
    steps_row = (await db.execute(
        _select(
            _func.coalesce(_func.sum(StepLogModel.step_count), 0),
            _func.coalesce(_func.sum(StepLogModel.distance_km), 0.0),
        ).where(
            StepLogModel.user_id == user_id,
            StepLogModel.date >= y_start,
            StepLogModel.date <= y_end,
        )
    )).one()
    total_steps, total_distance_km = int(steps_row[0]), round(float(steps_row[1]), 1)

    # ── Su ──
    water_ml = (await db.execute(
        _select(_func.coalesce(_func.sum(WaterLogModel.amount_ml), 0)).where(
            WaterLogModel.user_id == user_id,
            WaterLogModel.date >= y_start,
            WaterLogModel.date <= y_end,
        )
    )).scalar_one()
    total_water_liters = round(water_ml / 1000, 1)

    # ── Beslenme (3 durumlu mantıkla) ──
    meal_rows = (await db.execute(
        _select(MealComplianceModel).where(
            MealComplianceModel.user_id == user_id,
            MealComplianceModel.date >= y_start,
            MealComplianceModel.date <= y_end,
        )
    )).scalars().all()
    usable = [m for m in meal_rows if m.calories_consumed is not None]
    complied_days = sum(1 for m in usable if m.complied)
    tracked_days = len(usable)

    # ── Kilo yolculuğu ──
    m_rows = (await db.execute(
        _select(MeasurementModel).where(
            MeasurementModel.user_id == user_id,
            MeasurementModel.date >= y_start,
            MeasurementModel.date <= y_end,
            MeasurementModel.weight_kg.isnot(None),
        ).order_by(MeasurementModel.date.asc())
    )).scalars().all()
    weight_start = m_rows[0].weight_kg if m_rows else None
    weight_end = m_rows[-1].weight_kg if m_rows else None
    weight_change = round(weight_end - weight_start, 1) if (weight_start and weight_end) else None

    # ── Streak + rozetler ──
    longest_streak = (await db.execute(
        _select(_func.coalesce(_func.max(StreakModel.longest_streak), 0)).where(
            StreakModel.user_id == user_id
        )
    )).scalar_one()
    badges_earned = (await db.execute(
        _select(_func.count(BadgeModel.id)).where(
            BadgeModel.user_id == user_id,
            BadgeModel.earned_at >= sa_dt(y_start),
            BadgeModel.earned_at <= sa_dt(y_end, end=True),
        )
    )).scalar_one()

    return {
        "year": year,
        "total_sessions": total_sessions,
        "total_workout_minutes": total_workout_minutes,
        "total_workout_calories": total_workout_calories,
        "completed_exercises": completed_exercises,
        "favorite_exercise": favorite_exercise,
        "favorite_exercise_count": favorite_exercise_count,
        "total_steps": total_steps,
        "total_distance_km": total_distance_km,
        "total_water_liters": total_water_liters,
        "complied_days": complied_days,
        "tracked_days": tracked_days,
        "weight_start_kg": weight_start,
        "weight_end_kg": weight_end,
        "weight_change_kg": weight_change,
        "longest_streak": int(longest_streak),
        "badges_earned": int(badges_earned),
    }


def sa_dt(d: _date, end: bool = False):
    """date → timezone'lu datetime (gün başı/sonu) — earned_at karşılaştırması için."""
    from datetime import datetime as _dt, time as _time, timezone as _tz
    t = _time(23, 59, 59) if end else _time(0, 0, 0)
    return _dt.combine(d, t, tzinfo=_tz.utc)
