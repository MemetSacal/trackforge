# HTTP katmanı — rapor endpoint'leri
from datetime import date

from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.report import WeeklyReportResponse, MonthlyReportResponse
from backend.app.application.services.report_service import ReportService
from backend.app.infrastructure.db.session import get_db
from backend.app.core.dependencies import get_current_user
from datetime import date as _date, timedelta as _timedelta
from sqlalchemy import select as _select
from backend.app.core.exceptions import NotFoundException
from backend.app.infrastructure.db.models.measurement_model import MeasurementModel
from backend.app.infrastructure.repositories.user_repository import UserRepository
from backend.app.application.services.gamification_service import GamificationService
from backend.app.application.services.meal_compliance_service import MealComplianceService
from backend.app.application.services.water_service import WaterService
from backend.app.application.services.sleep_service import SleepService
from backend.app.infrastructure.repositories.meal_compliance_repository import MealComplianceRepository
from sqlalchemy import func as _func
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel
from backend.app.infrastructure.db.models.session_exercise_model import SessionExerciseModel
from backend.app.infrastructure.db.models.meal_compliance_model import MealComplianceModel
from backend.app.infrastructure.db.models.water_log_model import WaterLogModel
from backend.app.infrastructure.db.models.step_log_model import StepLogModel
from backend.app.infrastructure.db.models.sleep_log_model import SleepLogModel as _SleepLogModel
from backend.app.infrastructure.db.models.streak_model import StreakModel
from backend.app.infrastructure.db.models.badge_model import BadgeModel
from fastapi.responses import Response
from backend.app.application.services.health_report_pdf import build_health_report
from backend.app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository
from backend.app.ai.context_builder import detect_plateau
from datetime import datetime as _dt, time as _time, timezone as _tz

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
    t = _time(23, 59, 59) if end else _time(0, 0, 0)
    return _dt.combine(d, t, tzinfo=_tz.utc)


# ═════════════════════════════════════════════════════════
# ── v7: GET /reports/health-report.pdf ──
# Doktor/diyetisyen randevusuna götürülecek tek sayfalık özet.
# AI yok, kota yok — saf agregasyon. Türkçe font repo'da gömülü.
# ═════════════════════════════════════════════════════════

@router.get("/health-report.pdf")
async def get_health_report_pdf(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    since = _date.today() - _timedelta(weeks=4)

    user = await UserRepository(db).get_by_id(user_id)
    prefs_e = await UserPreferenceRepository(db).get_by_user_id(user_id)
    prefs = {
        "age": getattr(prefs_e, "age", None),
        "gender": getattr(prefs_e, "gender", None),
        "height_cm": getattr(prefs_e, "height_cm", None),
        "fitness_goal": getattr(prefs_e, "fitness_goal", None),
        "allergies": getattr(prefs_e, "allergies", None) or [],
        "diseases": getattr(prefs_e, "diseases", None) or [],
    } if prefs_e else {}

    m_rows = (await db.execute(
        _select(MeasurementModel)
        .where(MeasurementModel.user_id == user_id)
        .order_by(MeasurementModel.date.desc())
        .limit(10)
    )).scalars().all()
    measurements = [{
        "date": str(m.date), "weight_kg": m.weight_kg,
        "body_fat_pct": m.body_fat_pct, "waist_cm": m.waist_cm,
    } for m in m_rows]

    sessions = (await db.execute(
        _select(ExerciseSessionModel).where(
            ExerciseSessionModel.user_id == user_id,
            ExerciseSessionModel.date >= since,
        )
    )).scalars().all()
    s_ids = [x.id for x in sessions]
    exercises = []
    if s_ids:
        exercises = (await db.execute(
            _select(SessionExerciseModel).where(
                SessionExerciseModel.session_id.in_(s_ids))
        )).scalars().all()
    freq = {}
    for e in exercises:
        n = (e.exercise_name or "").strip()
        if n:
            freq[n] = freq.get(n, 0) + 1
    top = sorted(freq, key=freq.get, reverse=True)
    workout = {
        "sessions": len(sessions),
        "plan_sessions": sum(1 for x in sessions if getattr(x, "source", "manual") == "ai_plan"),
        "free_sessions": sum(1 for x in sessions if getattr(x, "source", "manual") != "ai_plan"),
        "minutes": sum(x.duration_minutes or 0 for x in sessions),
        "calories": round(sum(x.calories_burned or 0 for x in sessions)),
        "top_exercises": top,
    }

    mc_rows = (await db.execute(
        _select(MealComplianceModel).where(
            MealComplianceModel.user_id == user_id,
            MealComplianceModel.date >= since,
        )
    )).scalars().all()
    usable = [m for m in mc_rows if m.calories_consumed is not None]
    cal_vals = [m.calories_consumed for m in usable if m.calories_consumed]
    nutrition = {
        "tracked_days": len(usable),
        "complied_days": sum(1 for m in usable if m.complied),
        "deviated_days": sum(1 for m in usable if not m.complied),
        "no_data_days": max(((_date.today() - since).days + 1) - len(usable), 0),
        "avg_calories": round(sum(cal_vals) / len(cal_vals)) if cal_vals else None,
    }

    plateau = await detect_plateau(db, user_id)

    pdf_bytes = build_health_report({
        "user": {"full_name": user.full_name if user else None},
        "prefs": prefs,
        "measurements": measurements,
        "workout": workout,
        "nutrition": nutrition,
        "fasting_mode": getattr(prefs_e, "fasting_mode", False) if prefs_e else False,
        "plateau": plateau,
    })

    return Response(
        content=pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": 'attachment; filename="trackforge_saglik_raporu.pdf"'},
    )


# ═════════════════════════════════════════════════════════
# ── v1.1: GET /reports/insights — Veri Korelasyonları ──
# Kullanıcının kendisi hakkında bilmediği örüntüler:
# "az uyuduğun günlerde adımın düşüyor", "antrenman yaptığın
# günlerde diyete daha çok uyuyorsun" gibi. AI YOK, saf istatistik
# (kotasız, bedava). Yeterli veri yoksa o içgörü atlanır.
# ═════════════════════════════════════════════════════════


@router.get("/insights")
async def get_insights(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    since = _date.today() - _timedelta(weeks=8)

    # Verileri tarihe göre topla
    sleeps = (await db.execute(
        _select(_SleepLogModel).where(
            _SleepLogModel.user_id == user_id,
            _SleepLogModel.date >= since,
        )
    )).scalars().all()
    steps = (await db.execute(
        _select(StepLogModel).where(
            StepLogModel.user_id == user_id,
            StepLogModel.date >= since,
        )
    )).scalars().all()
    meals = (await db.execute(
        _select(MealComplianceModel).where(
            MealComplianceModel.user_id == user_id,
            MealComplianceModel.date >= since,
        )
    )).scalars().all()

    # Tarih -> değer sözlükleri
    sleep_by_date = {s.date: s.duration_hours for s in sleeps if s.duration_hours is not None}
    steps_by_date = {s.date: s.step_count for s in steps if s.step_count is not None}
    # meal_compliance.date datetime olabilir → date'e indir
    meal_by_date = {}
    for m in meals:
        d = m.date.date() if hasattr(m.date, "date") else m.date
        if m.calories_consumed is not None:
            meal_by_date[d] = m.complied

    insights = []

    # ── İçgörü 1: Uyku ↔ Adım ──
    # Az uyunan günler (<6.5 sa) vs iyi uyunan günler (>=7.5 sa) adım ortalaması
    common_sleep_steps = [(sleep_by_date[d], steps_by_date[d])
                          for d in sleep_by_date if d in steps_by_date]
    if len(common_sleep_steps) >= 6:
        low = [st for sl, st in common_sleep_steps if sl < 6.5]
        high = [st for sl, st in common_sleep_steps if sl >= 7.5]
        if len(low) >= 2 and len(high) >= 2:
            avg_low = sum(low) / len(low)
            avg_high = sum(high) / len(high)
            if avg_high > avg_low * 1.15:  # anlamlı fark (%15+)
                diff_pct = round((avg_high - avg_low) / avg_low * 100)
                insights.append({
                    "icon": "😴",
                    "title": "Uyku ve hareketin bağlantılı",
                    "text": f"İyi uyuduğun günlerde (%{diff_pct} daha fazla) ortalama "
                            f"{int(avg_high)} adım atıyorsun; az uyuduğunda {int(avg_low)}'e düşüyor.",
                })

    # ── İçgörü 2: Antrenman günü ↔ Beslenme uyumu ──
    # (antrenman = o gün adım yüksek veya seans var — basit proxy: adım >= 8000)
    if len(meal_by_date) >= 6:
        active_days_complied = []
        rest_days_complied = []
        for d, complied in meal_by_date.items():
            st = steps_by_date.get(d, 0)
            if st >= 8000:
                active_days_complied.append(1 if complied else 0)
            else:
                rest_days_complied.append(1 if complied else 0)
        if len(active_days_complied) >= 2 and len(rest_days_complied) >= 2:
            rate_active = sum(active_days_complied) / len(active_days_complied)
            rate_rest = sum(rest_days_complied) / len(rest_days_complied)
            if abs(rate_active - rate_rest) >= 0.2:
                if rate_active > rate_rest:
                    insights.append({
                        "icon": "🔥",
                        "title": "Hareketli günler seni disiplinli yapıyor",
                        "text": f"Aktif günlerinde diyete uyma oranın %{int(rate_active*100)}, "
                                f"hareketsiz günlerde %{int(rate_rest*100)}. Hareket motivasyonu besliyor!",
                    })
                else:
                    insights.append({
                        "icon": "🍽️",
                        "title": "Dinlenme günlerinde dikkat",
                        "text": f"Hareketsiz günlerinde diyete uyma oranın %{int(rate_rest*100)}, "
                                f"aktif günlerde %{int(rate_active*100)}. Dinlenme günü = serbest değil 😊",
                    })

    # ── İçgörü 3: Genel uyum trendi (yeterli veri yoksa motive edici fallback) ──
    if meal_by_date:
        overall = sum(1 for c in meal_by_date.values() if c) / len(meal_by_date)
        if overall >= 0.7:
            insights.append({
                "icon": "🏆",
                "title": "Beslenme disiplinin güçlü",
                "text": f"Son 8 haftada kayıt girdiğin günlerin %{int(overall*100)}'inde "
                        f"hedefini tutturmuşsun. Bu istikrar harika.",
            })

    return {
        "insights": insights,
        "has_enough_data": len(insights) > 0,
        "hint": (
            None if insights else
            "Daha fazla içgörü için uyku, adım ve beslenme verisi girmeye devam et — "
            "birkaç hafta sonra örüntülerini göstereceğim 📊"
        ),
    }
