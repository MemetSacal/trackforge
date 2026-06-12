# ── AI endpoint'leri (v2) — Claude API entegrasyonu ──
#
# v2 DEĞİŞİKLİKLERİ:
#   1. TÜM endpoint'lerde sunucu tarafı kota (recipe, cycle, bank dahil —
#      eskiden limitsizlerdi). Premium da artık sonlu limitli.
#   2. build_user_context() her üretim çağrısına eklenir — modüller
#      birbirinden habersiz çalışmayı bırakır (silo çözümü).
#   3. 24 saatlik yanıt cache'i (workout + meal): aynı girdiyle tekrar
#      basılan buton Claude'a gitmez, KOTA TÜKETMEZ. force_new ile aşılır.
#   4. Her yanıta "quota" bilgisi gömülür — Flutter lokal sayacı
#      sunucuyla senkronlar.
#   5. POST /ai/feedback — 👍/👎 geri bildirim toplama.
#   6. Workout planında revizyon modu (previous_plan + revision_request).

import hashlib
import json
import uuid
from datetime import date, datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, File, Form, UploadFile
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.ai import (
    WeeklySummaryRequest, WeeklySummaryResponse,
    WorkoutPlanRequest, WorkoutPlanResponse,
    MealAdviceRequest, MealAdviceResponse,
    RecipeRequest, RecipeResponse,
    CalorieVisionResponse,
    CycleAdviceRequest, CycleAdviceResponse,
    AIFeedbackRequest, AIFeedbackResponse,
)
from backend.app.application.services.report_service import ReportService
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.db.models.measurement_model import MeasurementModel
from backend.app.infrastructure.db.models.ai_cache_model import AIResponseCacheModel
from backend.app.infrastructure.db.models.ai_feedback_model import AIFeedbackModel
from backend.app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository
from backend.app.infrastructure.repositories.user_repository import UserRepository
from backend.app.core.dependencies import get_current_user, get_current_user_premium
from backend.app.core.ai_rate_limiter import check_quota, consume_and_status
from backend.app.ai.context_builder import build_user_context, detect_plateau
from backend.app.ai.analyzers.weekly_analyzer import generate_weekly_summary
from backend.app.ai.analyzers.calorie_vision_analyzer import analyze_food_calories, analyze_fridge_ingredients, analyze_food_text
from backend.app.ai.generators.workout_generator import generate_workout_plan
from backend.app.ai.generators.meal_advisor import generate_meal_advice
from backend.app.ai.generators.recipe_generator import generate_recipe
from backend.app.ai.generators.cycle_advisor import generate_cycle_advice
from backend.app.ai.generators.calorie_bank_advisor import generate_calorie_bank_advice
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel
from backend.app.infrastructure.db.models.meal_compliance_model import MealComplianceModel
from backend.app.infrastructure.db.models.exercise_catalog_model import ExerciseCatalogModel

router = APIRouter()

CACHE_TTL_HOURS = 24  # workout + meal yanıtları için


def get_report_service(db: AsyncSession = Depends(get_db)) -> ReportService:
    return ReportService(db)


# ── Cache yardımcıları ───────────────────────────────────
def _input_hash(payload: dict) -> str:
    raw = json.dumps(payload, sort_keys=True, ensure_ascii=False, default=str)
    return hashlib.sha256(raw.encode()).hexdigest()


async def _cache_get(db: AsyncSession, user_id: str, feature: str, h: str) -> dict | None:
    cutoff = datetime.now(timezone.utc) - timedelta(hours=CACHE_TTL_HOURS)
    row = (await db.execute(
        select(AIResponseCacheModel)
        .where(AIResponseCacheModel.user_id == user_id,
               AIResponseCacheModel.feature == feature,
               AIResponseCacheModel.input_hash == h,
               AIResponseCacheModel.created_at >= cutoff)
        .order_by(AIResponseCacheModel.created_at.desc())
        .limit(1)
    )).scalar_one_or_none()
    return json.loads(row.response_json) if row else None


async def _cache_put(db: AsyncSession, user_id: str, feature: str, h: str, response: dict) -> None:
    db.add(AIResponseCacheModel(
        id=str(uuid.uuid4()),
        user_id=user_id,
        feature=feature,
        input_hash=h,
        response_json=json.dumps(response, ensure_ascii=False, default=str),
    ))
    await db.flush()


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
    await check_quota(db, current_user, is_premium, "weekly_summary")
    try:
        reference_date = date.fromisoformat(data.reference_date)
        report = await report_service.get_weekly_report(current_user, reference_date)

        user_repo = UserRepository(db)
        user = await user_repo.get_by_id(current_user)
        user_name = user.full_name if user else "Kullanıcı"

        context = await build_user_context(db, current_user)
        summary = await generate_weekly_summary(report, user_name, user_context=context)

        quota = await consume_and_status(db, current_user, is_premium, "weekly_summary")
        await db.commit()

        return WeeklySummaryResponse(
            week_start=str(report.week_start),
            week_end=str(report.week_end),
            summary=summary,
            quota=quota,
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
    """Lokasyon ve hedefe göre haftalık antrenman planı üret.

    v2: Cache kontrolü ÖNCE yapılır — isabet varsa Claude'a gidilmez
    ve kota tüketilmez. Kullanıcı bilinçli yeni plan isterse force_new
    gönderir veya revizyon modunu kullanır.
    """
    current_user, is_premium = user_info

    h = _input_hash({
        "loc": data.workout_location, "goal": data.fitness_goal,
        "level": data.fitness_level, "days": data.available_days,
    })
    is_revision = bool(data.previous_plan and data.revision_request)

    if not data.force_new and not is_revision:
        cached = await _cache_get(db, current_user, "workout_plan", h)
        if cached:
            from backend.app.core.ai_rate_limiter import get_quota_status
            cached["quota"] = await get_quota_status(db, current_user, is_premium, "workout_plan")
            return WorkoutPlanResponse(**cached)

    await check_quota(db, current_user, is_premium, "workout_plan")
    try:
        context = await build_user_context(db, current_user)

        # v5: lokasyona uygun katalog — AI sadece bunlardan seçer
        cat_rows = (await db.execute(
            select(ExerciseCatalogModel).where(
                ExerciseCatalogModel.location.in_([data.workout_location, "any"])
            )
        )).scalars().all()
        catalog = [{"name": c.name, "muscle_groups": c.muscle_groups} for c in cat_rows]

        plan = await generate_workout_plan(
            workout_location=data.workout_location,
            fitness_goal=data.fitness_goal,
            fitness_level=data.fitness_level,
            available_days=data.available_days,
            user_context=context,
            previous_plan=data.previous_plan,
            revision_request=data.revision_request,
            catalog=catalog,
        )

        await _cache_put(db, current_user, "workout_plan", h, plan)
        quota = await consume_and_status(db, current_user, is_premium, "workout_plan")
        await db.commit()

        return WorkoutPlanResponse(**plan, quota=quota)
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
    """Kullanıcı tercihlerine göre 7 günlük diyet planı üret."""
    current_user, is_premium = user_info

    pref_repo = UserPreferenceRepository(db)
    prefs = await pref_repo.get_by_user_id(current_user)
    if not prefs:
        raise HTTPException(
            status_code=400,
            detail="Diyet tavsiyesi için önce kullanıcı tercihlerini (/preferences) doldurun."
        )

    h = _input_hash({"target": data.calorie_target, "goal": prefs.fitness_goal})
    cached = await _cache_get(db, current_user, "meal_advice", h)
    if cached:
        from backend.app.core.ai_rate_limiter import get_quota_status
        cached["quota"] = await get_quota_status(db, current_user, is_premium, "meal_advice")
        return MealAdviceResponse(**cached)

    await check_quota(db, current_user, is_premium, "meal_advice")
    try:
        result = await db.execute(
            select(MeasurementModel)
            .where(MeasurementModel.user_id == current_user)
            .order_by(MeasurementModel.date.desc())
            .limit(1)
        )
        last_measurement = result.scalar_one_or_none()
        weight_kg = last_measurement.weight_kg if last_measurement else None

        context = await build_user_context(db, current_user)
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
            user_context=context,
        )

        await _cache_put(db, current_user, "meal_advice", h, advice)
        quota = await consume_and_status(db, current_user, is_premium, "meal_advice")
        await db.commit()

        return MealAdviceResponse(**advice, quota=quota)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Diyet tavsiyesi oluşturulamadı: {str(e)}")


# ── POST /ai/recipe ──────────────────────────────────────
@router.post("/recipe", response_model=RecipeResponse)
async def get_recipe_suggestion(
    data: RecipeRequest,
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Tarif önerisi — v2: artık kotalı (eskiden limitsizdi)."""
    current_user, is_premium = user_info
    await check_quota(db, current_user, is_premium, "recipe")
    try:
        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(current_user)

        report_service = ReportService(db)
        weekly_bank_balance = None
        daily_calorie_target = None
        try:
            report = await report_service.get_weekly_report(current_user, date.today())
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

        context = await build_user_context(db, current_user)
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
            user_context=context,
        )

        await consume_and_status(db, current_user, is_premium, "recipe")
        await db.commit()
        return RecipeResponse(**recipe)
    except HTTPException:
        raise
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
    await check_quota(db, current_user, is_premium, "vision")
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

        quota = await consume_and_status(db, current_user, is_premium, "vision")
        await db.commit()

        return CalorieVisionResponse(**result, quota=quota)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kalori analizi yapılamadı: {str(e)}")


# ── POST /ai/cycle-advice ────────────────────────────────
@router.post("/cycle-advice", response_model=CycleAdviceResponse)
async def get_cycle_advice(
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Mevcut döngü fazına göre AI tavsiyesi — v2: artık kotalı."""
    current_user, is_premium = user_info
    await check_quota(db, current_user, is_premium, "cycle_advice")

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
        await consume_and_status(db, current_user, is_premium, "cycle_advice")
        await db.commit()
        return CycleAdviceResponse(**advice)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Döngü tavsiyesi oluşturulamadı: {str(e)}")


# ── POST /ai/calorie-bank-advice ─────────────────────────
@router.post("/calorie-bank-advice")
async def get_calorie_bank_advice(
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Bugünkü kalori bankası analizi — v2: artık kotalı."""
    current_user, is_premium = user_info
    await check_quota(db, current_user, is_premium, "calorie_bank")
    try:
        today = date.today()

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

        hist_result = await db.execute(
            select(MeasurementModel)
            .where(MeasurementModel.user_id == current_user)
            .order_by(MeasurementModel.date.desc())
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
        await consume_and_status(db, current_user, is_premium, "calorie_bank")
        await db.commit()
        return advice

    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kalori bankası tavsiyesi oluşturulamadı: {str(e)}")


# ── POST /ai/calorie-from-text (v6 YENİ) ─────────────────
from pydantic import BaseModel as _BaseModel


class TextCalorieRequest(_BaseModel):
    description: str


@router.post("/calorie-from-text", response_model=CalorieVisionResponse)
async def get_calories_from_text(
    data: TextCalorieRequest,
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Serbest metinden kalori analizi (v6).

    "2 yumurta, bir dilim ekmek, çay" → kalori + makro.
    Klavye dikte tuşuyla sesli giriş bedavaya gelir.
    Vision ile aynı yanıt şekli — mobil tek render kodu kullanır.
    """
    current_user, is_premium = user_info
    desc = (data.description or "").strip()
    if len(desc) < 3:
        raise HTTPException(status_code=400, detail="Ne yediğini kısaca tarif et (örn: 2 yumurta, bir dilim ekmek).")
    if len(desc) > 500:
        raise HTTPException(status_code=400, detail="Tarif çok uzun — 500 karakteri geçme.")

    await check_quota(db, current_user, is_premium, "text_calorie")
    try:
        result = await analyze_food_text(desc)
        quota = await consume_and_status(db, current_user, is_premium, "text_calorie")
        await db.commit()
        return CalorieVisionResponse(**result, quota=quota)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Kalori analizi yapılamadı: {str(e)}")


# ── POST /ai/recipe-from-photo (v3 YENİ) ─────────────────
@router.post("/recipe-from-photo", response_model=RecipeResponse)
async def get_recipe_from_photo(
    file: UploadFile = File(..., description="Buzdolabı/kiler fotoğrafı"),
    meal_type: str = Form(default="dinner"),
    craving: str = Form(default=None),
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """Buzdolabı fotoğrafından tarif üret (v3).

    İki aşamalı: (1) vision malzemeleri çıkarır,
    (2) recipe_generator o malzemelerle + kullanıcı bağlamıyla tarif yazar.
    İki AI çağrısı olduğu için ayrı (daha sıkı) kotası var: fridge_recipe.
    """
    current_user, is_premium = user_info
    await check_quota(db, current_user, is_premium, "fridge_recipe")
    try:
        allowed_types = ["image/jpeg", "image/png", "image/webp"]
        if file.content_type not in allowed_types:
            raise HTTPException(
                status_code=400,
                detail=f"Desteklenmeyen dosya tipi. İzin verilenler: {', '.join(allowed_types)}"
            )
        image_data = await file.read()
        if len(image_data) > 5 * 1024 * 1024:
            raise HTTPException(status_code=400, detail="Fotoğraf boyutu 5MB'dan büyük olamaz.")

        # Aşama 1: malzeme tespiti
        ingredients = await analyze_fridge_ingredients(image_data, file.content_type)
        if not ingredients:
            raise HTTPException(
                status_code=422,
                detail="Fotoğrafta tanınabilir malzeme bulunamadı. Daha aydınlık ve yakın bir kare dene."
            )

        # Aşama 2: tespit edilen malzemelerle tarif
        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(current_user)
        context = await build_user_context(db, current_user)

        recipe = await generate_recipe(
            available_ingredients=ingredients,
            liked_foods=prefs.liked_foods if prefs else [],
            disliked_foods=prefs.disliked_foods if prefs else [],
            allergies=prefs.allergies if prefs else [],
            meal_type=meal_type,
            craving=craving,
            user_context=context,
        )

        quota = await consume_and_status(db, current_user, is_premium, "fridge_recipe")
        await db.commit()

        return RecipeResponse(**recipe, detected_ingredients=ingredients, quota=quota)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Fotoğraftan tarif oluşturulamadı: {str(e)}")


# ── GET /ai/plateau-status (v3 YENİ) ─────────────────────
@router.get("/plateau-status")
async def get_plateau_status(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Plato kontrolü — AI çağrısı YOK, sadece ölçüm analizi (kotasız, anlık).

    Mobil taraf bunu haftalık özet ekranında banner olarak gösterir;
    kullanıcı abonelikten soğumadan proaktif yakalanır."""
    plateau = await detect_plateau(db, user_id)
    if not plateau:
        return {"is_plateau": False}
    return {
        "is_plateau": True,
        **plateau,
        "message_tr": (
            f"Kilon {plateau['weeks']} haftadır {plateau['weight_kg']} kg civarında sabit. "
            f"Bu çok normal bir plato — haftalık AI analizinden kırma önerileri alabilirsin 💪"
        ),
    }


# ── POST /ai/feedback (v2 YENİ) ──────────────────────────
@router.post("/feedback", response_model=AIFeedbackResponse)
async def submit_ai_feedback(
    data: AIFeedbackRequest,
    user_info: tuple = Depends(get_current_user_premium),
    db: AsyncSession = Depends(get_db),
):
    """AI çıktısına 👍/👎 geri bildirim kaydet.

    Bu veri zamanla altın değerinde olacak: hangi modül beğeniliyor,
    hangi prompt iyileştirilmeli, kişiselleştirme nereden başlamalı.
    """
    current_user, is_premium = user_info
    if data.rating == 0:
        raise HTTPException(status_code=400, detail="rating 1 veya -1 olmalı")
    await check_quota(db, current_user, is_premium, "ai_feedback")  # spam koruması

    db.add(AIFeedbackModel(
        user_id=current_user,
        feature=data.feature,
        rating=data.rating,
        comment=data.comment,
    ))
    from backend.app.core.ai_rate_limiter import record_usage
    await record_usage(db, current_user, "ai_feedback")
    await db.commit()
    return AIFeedbackResponse(message="Geri bildirim kaydedildi, teşekkürler!")


"""
DOSYA AKIŞI (v2):
POST /ai/weekly-summary      → Free: 1/hafta  | PRO: 3/hafta
POST /ai/workout-plan        → Free: 2/hafta  | PRO: 10/hafta  (+24h cache, +revizyon modu)
POST /ai/meal-advice         → Free: 2/hafta  | PRO: 10/hafta  (+24h cache, +shopping_list)
POST /ai/calorie-from-photo  → Free: 3/gün    | PRO: 20/gün
POST /ai/recipe              → Free: 3/hafta  | PRO: 30/hafta  (v2: eskiden limitsizdi)
POST /ai/cycle-advice        → Free: 3/hafta  | PRO: 15/hafta  (v2: eskiden limitsizdi)
POST /ai/calorie-bank-advice → Free: 3/gün    | PRO: 15/gün    (v2: eskiden limitsizdi)
POST /ai/feedback            → 👍/👎 toplama (v2 yeni)

Kota aşımında 429 + yapılandırılmış detail (error_code, used, limit,
resets_in_days) döner. Cache isabetinde kota TÜKETİLMEZ.
Her başarılı yanıt "quota" alanıyla kalan hakkı bildirir.
"""
