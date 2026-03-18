# AI endpoint'leri — Claude API entegrasyonu
from datetime import date
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.ai import (
    WeeklySummaryRequest, WeeklySummaryResponse,
    WorkoutPlanRequest, WorkoutPlanResponse,
    MealAdviceRequest, MealAdviceResponse,
    RecipeRequest, RecipeResponse,
)
from app.application.services.report_service import ReportService
from app.infrastructure.db.session import get_db
from app.infrastructure.db.models.measurement_model import MeasurementModel
from app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository
from app.infrastructure.repositories.user_repository import UserRepository
from app.core.dependencies import get_current_user
from app.ai.analyzers.weekly_analyzer import generate_weekly_summary
from app.ai.generators.workout_generator import generate_workout_plan
from app.ai.generators.meal_advisor import generate_meal_advice
from app.ai.generators.recipe_generator import generate_recipe

router = APIRouter()


def get_report_service(db: AsyncSession = Depends(get_db)) -> ReportService:
    return ReportService(db)


@router.post("/weekly-summary", response_model=WeeklySummaryResponse)
async def get_weekly_ai_summary(
    data: WeeklySummaryRequest,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
    report_service: ReportService = Depends(get_report_service),
):
    """Haftalık verileri analiz edip AI özeti üret."""
    try:
        # Haftalık raporu çek
        reference_date = date.fromisoformat(data.reference_date)
        report = await report_service.get_weekly_report(current_user, reference_date)

        # Kullanıcı adını getir
        user_repo = UserRepository(db)
        user = await user_repo.get_by_id(current_user)
        user_name = user.full_name if user else "Kullanıcı"

        # Claude'a gönder, özet al
        summary = await generate_weekly_summary(report, user_name)

        return WeeklySummaryResponse(
            week_start=str(report.week_start),
            week_end=str(report.week_end),
            summary=summary,
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"AI özeti oluşturulamadı: {str(e)}")


@router.post("/workout-plan", response_model=WorkoutPlanResponse)
async def get_workout_plan(
    data: WorkoutPlanRequest,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Lokasyon ve hedefe göre haftalık antrenman planı üret."""
    try:
        plan = await generate_workout_plan(
            workout_location=data.workout_location,
            fitness_goal=data.fitness_goal,
            fitness_level=data.fitness_level,
            available_days=data.available_days,
        )
        return WorkoutPlanResponse(**plan)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Antrenman planı oluşturulamadı: {str(e)}")


@router.post("/meal-advice", response_model=MealAdviceResponse)
async def get_meal_advice(
    data: MealAdviceRequest,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Kullanıcı tercihlerine göre diyet tavsiyesi üret."""
    try:
        # Kullanıcı tercihlerini getir
        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(current_user)

        if not prefs:
            raise HTTPException(
                status_code=400,
                detail="Diyet tavsiyesi için önce kullanıcı tercihlerini (/preferences) doldurun."
            )

        # Son ölçümden kiloyu çek — BMR hesabı için
        result = await db.execute(
            select(MeasurementModel)
            .where(MeasurementModel.user_id == current_user)
            .order_by(MeasurementModel.date.desc())
            .limit(1)
        )
        last_measurement = result.scalar_one_or_none()
        weight_kg = last_measurement.weight_kg if last_measurement else None

        # Claude'a gönder — fiziksel profil de dahil
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
        return MealAdviceResponse(**advice)
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Diyet tavsiyesi oluşturulamadı: {str(e)}")


@router.post("/recipe", response_model=RecipeResponse)
async def get_recipe_suggestion(
    data: RecipeRequest,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Malzeme listesine göre sağlıklı tarif öner."""
    try:
        # Kullanıcı tercihlerini getir (opsiyonel)
        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(current_user)

        recipe = await generate_recipe(
            available_ingredients=data.available_ingredients,
            liked_foods=prefs.liked_foods if prefs else [],
            disliked_foods=prefs.disliked_foods if prefs else [],
            allergies=prefs.allergies if prefs else [],
            meal_type=data.meal_type,
            calorie_limit=data.calorie_limit,
        )
        return RecipeResponse(**recipe)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Tarif oluşturulamadı: {str(e)}")


"""
DOSYA AKIŞI:
POST /ai/weekly-summary  → haftalık rapor + Claude → Türkçe özet
POST /ai/workout-plan    → lokasyon + hedef → antrenman planı
POST /ai/meal-advice     → user_preferences + son ölçüm kilosu → BMR/TDEE hesaplamalı diyet tavsiyesi
POST /ai/recipe          → malzeme listesi + tercihler → tarif

meal-advice yenilikleri:
  - Son ölçümden kilo otomatik çekilir
  - BMR (Mifflin-St Jeor) + TDEE hesaplanır
  - Fiziksel profil Claude'a gönderilir → daha doğru kalori önerisi

Spring Boot karşılığı: @RestController + @PostMapping.
"""