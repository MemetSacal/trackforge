# AI endpoint'leri — Claude API entegrasyonu
from datetime import date
from fastapi import APIRouter, Depends, HTTPException, File, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.ai import (
    WeeklySummaryRequest, WeeklySummaryResponse,
    WorkoutPlanRequest, WorkoutPlanResponse,
    MealAdviceRequest, MealAdviceResponse,
    RecipeRequest, RecipeResponse,
    CalorieVisionResponse,
)
from backend.app.application.services.report_service import ReportService
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.db.models.measurement_model import MeasurementModel
from backend.app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository
from backend.app.infrastructure.repositories.user_repository import UserRepository
from backend.app.core.dependencies import get_current_user, get_current_user_premium
from backend.app.core.ai_rate_limiter import (
    check_vision_limit,
    check_weekly_summary_limit,
    check_meal_advice_limit,
    check_workout_plan_limit,
    record_usage,
)
from backend.app.ai.analyzers.weekly_analyzer import generate_weekly_summary
from backend.app.ai.analyzers.calorie_vision_analyzer import analyze_food_calories
from backend.app.ai.generators.workout_generator import generate_workout_plan
from backend.app.ai.generators.meal_advisor import generate_meal_advice
from backend.app.ai.generators.recipe_generator import generate_recipe
from backend.app.ai.generators.cycle_advisor import generate_cycle_advice
from backend.app.application.schemas.ai import CycleAdviceRequest, CycleAdviceResponse
from backend.app.ai.generators.calorie_bank_advisor import generate_calorie_bank_advice
from backend.app.infrastructure.repositories.meal_compliance_repository import MealComplianceRepository
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel
from datetime import date as date_module
from backend.app.infrastructure.db.models.meal_compliance_model import MealComplianceModel

router = APIRouter()


def get_report_service(db: AsyncSession = Depends(get_db)) -> ReportService:
    return ReportService(db)


# ── POST /ai/weekly-summary ──────────────────────────────
@router.post("/weekly-summary", response_model=WeeklySummaryResponse)
async def get_weekly_ai_summary(
    data: WeeklySummaryRequest,
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
    report_service: ReportService = Depends(get_report_service),
):
    """Haftalık verileri analiz edip AI özeti üret."""
    current_user, is_premium = user_info
    if not is_premium:
        await check_weekly_summary_limit(current_user, db)
    try:
        reference_date = date.fromisoformat(data.reference_date)
        report = await report_service.get_weekly_report(current_user, reference_date)

        user_repo = UserRepository(db)
        user = await user_repo.get_by_id(current_user)
        user_name = user.full_name if user else "Kullanıcı"

        summary = await generate_weekly_summary(report, user_name)

        await record_usage(current_user, db, "weekly_summary")
        await db.commit()

        return WeeklySummaryResponse(
            week_start=str(report.week_start),
            week_end=str(report.week_end),
            summary=summary,
        )
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI özeti oluşturulamadı: {str(e)}")


# ── POST /ai/workout-plan ────────────────────────────────
@router.post("/workout-plan", response_model=WorkoutPlanResponse)
async def get_workout_plan(
    data: WorkoutPlanRequest,
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Lokasyon ve hedefe göre haftalık antrenman planı üret."""
    current_user, is_premium = user_info
    if not is_premium:
        await check_workout_plan_limit(current_user, db)
    try:
        plan = await generate_workout_plan(
            workout_location=data.workout_location,
            fitness_goal=data.fitness_goal,
            fitness_level=data.fitness_level,
            available_days=data.available_days,
        )

        await record_usage(current_user, db, "workout_plan")
        await db.commit()

        return WorkoutPlanResponse(**plan)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Antrenman planı oluşturulamadı: {str(e)}")


# ── POST /ai/meal-advice ─────────────────────────────────
@router.post("/meal-advice", response_model=MealAdviceResponse)
async def get_meal_advice(
    data: MealAdviceRequest,
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Kullanıcı tercihlerine göre diyet tavsiyesi üret."""
    current_user, is_premium = user_info
    if not is_premium:
        await check_meal_advice_limit(current_user, db)
    try:
        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(current_user)

        if not prefs:
            raise HTTPException(
                status_code=400,
                detail="Diyet tavsiyesi için önce kullanıcı tercihlerini (/preferences) doldurun."
            )

        result = await db.execute(
            select(MeasurementModel)
            .where(MeasurementModel.user_id == current_user)
            .order_by(MeasurementModel.date.desc())
            .limit(1)
        )
        last_measurement = result.scalar_one_or_none()
        weight_kg = last_measurement.weight_kg if last_measurement else None

        advice = await generate_meal_advice(
            liked_foods=prefs.liked_foods or [],
            disliked_foods=prefs.disliked_foods or [],
            allergies=prefs.allergies or [],
            diseases=prefs.diseases or [],
            blood_values=prefs.blood_values or {},
            fitness_goal=prefs.fitness_goal or "maintenance",
            calorie_target=data.calorie_target,
            height_cm=prefs.height_cm,
            age=prefs.age,
            gender=prefs.gender,
            activity_level=prefs.activity_level,
            weight_kg=weight_kg,
        )

        await record_usage(current_user, db, "meal_advice")
        await db.commit()

        return MealAdviceResponse(**advice)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Diyet tavsiyesi oluşturulamadı: {str(e)}")


# ── POST /ai/recipe ──────────────────────────────────────
@router.post("/recipe", response_model=RecipeResponse)
async def get_recipe_suggestion(
    data: RecipeRequest,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Tarif önerisi — limit yok."""
    try:
        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(current_user)

        from backend.app.application.services.report_service import ReportService
        from datetime import date as date_module
        report_service = ReportService(db)
        weekly_bank_balance = None
        daily_calorie_target = None
        try:
            report = await report_service.get_weekly_report(current_user, date_module.today())
            weekly_bank_balance = report.calorie_balance
            if prefs:
                result = await db.execute(
                    select(MeasurementModel)
                    .where(MeasurementModel.user_id == current_user)
                    .order_by(MeasurementModel.date.desc())
                    .limit(1)
                )
                last_m = result.scalar_one_or_none()
                weight_kg = last_m.weight_kg if last_m else None
                if prefs.height_cm and prefs.age and prefs.gender and weight_kg:
                    if prefs.gender == 'male':
                        bmr = 10 * weight_kg + 6.25 * prefs.height_cm - 5 * prefs.age + 5
                    else:
                        bmr = 10 * weight_kg + 6.25 * prefs.height_cm - 5 * prefs.age - 161
                    multipliers = {
                        'sedentary': 1.2, 'light': 1.375, 'moderate': 1.55,
                        'active': 1.725, 'very_active': 1.9
                    }
                    m = multipliers.get(prefs.activity_level or 'moderate', 1.55)
                    daily_calorie_target = round(bmr * m)
        except Exception:
            pass

        recipe = await generate_recipe(
            available_ingredients=data.available_ingredients or [],
            liked_foods=prefs.liked_foods if prefs else [],
            disliked_foods=prefs.disliked_foods if prefs else [],
            allergies=prefs.allergies if prefs else [],
            meal_type=data.meal_type,
            calorie_limit=data.calorie_limit,
            craving=data.craving,
            weekly_bank_balance=weekly_bank_balance,
            daily_calorie_target=daily_calorie_target,
        )
        return RecipeResponse(**recipe)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Tarif oluşturulamadı: {str(e)}")


# ── POST /ai/calorie-from-photo ──────────────────────────
@router.post("/calorie-from-photo", response_model=CalorieVisionResponse)
async def get_calories_from_photo(
    file: UploadFile = File(..., description="Yemek fotoğrafı (JPEG, PNG, WebP)"),
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Yemek fotoğrafından kalori ve makro değerlerini hesapla — Claude Vision."""
    current_user, is_premium = user_info
    if not is_premium:
        await check_vision_limit(current_user, db)
    try:
        allowed_types = ["image/jpeg", "image/png", "image/webp"]
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=f"Desteklenmeyen dosya tipi. İzin verilenler: {', '.join(allowed_types)}"
            )

        image_data = await file.read()

        if len(image_data) > 5 * 1024 * 1024:
            raise HTTPException(
                status_code=400,
                detail="Fotoğraf boyutu 5MB'dan büyük olamaz."
            )

        result = await analyze_food_calories(image_data, file.content_type)

        await record_usage(current_user, db, "vision")
        await db.commit()

        return CalorieVisionResponse(**result)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kalori analizi yapılamadı: {str(e)}")


# ── POST /ai/cycle-advice ────────────────────────────────
@router.post("/cycle-advice", response_model=CycleAdviceResponse)
async def get_cycle_advice(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Mevcut döngü fazına göre AI diyet ve antrenman tavsiyesi üret — limit yok."""
    from backend.app.application.services.cycle_service import CycleService
    cycle_service = CycleService(db)
    cycle = await cycle_service.get_current(current_user)

    if not cycle:
        raise HTTPException(
            status_code=400,
            detail="Önce regl döngüsü kaydı oluşturun (/cycle endpoint'i)."
        )

    pref_repo = UserPreferenceRepository(db)
    prefs = await pref_repo.get_by_user_id(current_user)

    result = await db.execute(
        select(MeasurementModel)
        .where(MeasurementModel.user_id == current_user)
        .order_by(MeasurementModel.date.desc())
        .limit(1)
    )
    last_measurement = result.scalar_one_or_none()
    weight_kg = last_measurement.weight_kg if last_measurement else None

    try:
        advice = await generate_cycle_advice(
            current_phase=cycle.current_phase or "",
            current_day=cycle.current_day or 1,
            cycle_length_days=cycle.cycle_length_days or 28,
            period_length_days=cycle.period_length_days or 5,
            fitness_goal=prefs.fitness_goal if prefs else None,
            liked_foods=prefs.liked_foods if prefs else [],
            disliked_foods=prefs.disliked_foods if prefs else [],
            allergies=prefs.allergies if prefs else [],
            weight_kg=weight_kg,
            height_cm=prefs.height_cm if prefs else None,
            age=prefs.age if prefs else None,
            activity_level=prefs.activity_level if prefs else None,
        )
        return CycleAdviceResponse(**advice)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Döngü tavsiyesi oluşturulamadı: {str(e)}")


# ── POST /ai/calorie-bank-advice ─────────────────────────
@router.post("/calorie-bank-advice")
async def get_calorie_bank_advice(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Bugünkü kalori bankası durumunu analiz edip kişisel tavsiye üret — limit yok."""
    try:
        today = date_module.today()

        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(current_user)

        result = await db.execute(
            select(MeasurementModel)
            .where(MeasurementModel.user_id == current_user)
            .order_by(MeasurementModel.date.desc())
            .limit(1)
        )
        last_measurement = result.scalar_one_or_none()
        weight_kg = last_measurement.weight_kg if last_measurement else None

        mc_result = await db.execute(
            select(MealComplianceModel)
            .where(
                MealComplianceModel.user_id == current_user,
                MealComplianceModel.date == today,
            )
        )
        mc = mc_result.scalar_one_or_none()

        ex_result = await db.execute(
            select(ExerciseSessionModel)
            .where(
                ExerciseSessionModel.user_id == current_user,
                ExerciseSessionModel.date == today,
            )
        )
        sessions = ex_result.scalars().all()
        calories_burned = sum(
            s.calories_burned for s in sessions if s.calories_burned is not None
        )

        from backend.app.infrastructure.db.models.measurement_model import MeasurementModel as MM
        hist_result = await db.execute(
            select(MM)
            .where(MM.user_id == current_user)
            .order_by(MM.date.desc())
            .limit(8)
        )
        measurements = hist_result.scalars().all()
        avg_weekly_loss = None
        if len(measurements) >= 2:
            first = measurements[-1]
            last = measurements[0]
            weeks = max((last.date - first.date).days / 7, 1)
            if first.weight_kg and last.weight_kg:
                avg_weekly_loss = abs(first.weight_kg - last.weight_kg) / weeks

        advice = await generate_calorie_bank_advice(
            fitness_goal=prefs.fitness_goal if prefs else "maintenance",
            daily_target=mc.calories_target if mc and mc.calories_target else 2000,
            calories_consumed=mc.calories_consumed if mc and mc.calories_consumed else 0,
            calories_burned=calories_burned,
            weekly_bank=mc.weekly_bank_balance if mc and mc.weekly_bank_balance else 0,
            age=prefs.age if prefs else None,
            gender=prefs.gender if prefs else None,
            weight_kg=weight_kg,
            target_weight_kg=prefs.target_weight_kg if prefs and hasattr(prefs, 'target_weight_kg') else None,
            daily_calorie_habit=prefs.daily_calorie_habit if prefs and hasattr(prefs, 'daily_calorie_habit') else None,
            avg_weekly_loss_kg=avg_weekly_loss,
        )
        return advice

    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kalori bankası tavsiyesi oluşturulamadı: {str(e)}")


"""
DOSYA AKIŞI:
POST /ai/weekly-summary      → Free: 1/hafta  | Premium: sınırsız
POST /ai/workout-plan        → Free: 2/hafta  | Premium: sınırsız
POST /ai/meal-advice         → Free: 2/hafta  | Premium: sınırsız
POST /ai/calorie-from-photo  → Free: 3/gün    | Premium: sınırsız
POST /ai/recipe              → limit yok
POST /ai/cycle-advice        → limit yok
POST /ai/calorie-bank-advice → limit yok

Rate limit aşılınca 429 döner — Flutter bu response'u yakalayıp
"PRO'ya geç" dialog'unu gösterir.

Spring Boot karşılığı: @RestController + @PostMapping + @RequestPart.
"""