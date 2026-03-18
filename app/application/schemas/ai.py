# AI endpoint'lerinin request/response şemaları
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


# ── Haftalık özet request ──
class WeeklySummaryRequest(BaseModel):
    # reference_date → o haftanın raporu çekilir, Claude'a gönderilir
    reference_date: str = Field(..., description="Tarih formatı: YYYY-MM-DD")


# ── Haftalık özet response ──
class WeeklySummaryResponse(BaseModel):
    week_start: str
    week_end: str
    summary: str                    # Claude'un ürettiği Türkçe özet metin


# ── Antrenman planı request ──
class WorkoutPlanRequest(BaseModel):
    workout_location: str = Field(..., description="home / gym / outdoor")
    fitness_goal: str = Field(..., description="weight_loss / muscle_gain / maintenance")
    fitness_level: str = Field(default="intermediate", description="beginner / intermediate / advanced")
    available_days: int = Field(default=4, ge=1, le=7)


# ── Antrenman planı response ──
class WorkoutPlanResponse(BaseModel):
    plan_title: str
    weekly_schedule: List[Dict[str, Any]]
    weekly_notes: str


# ── Diyet tavsiyesi request ──
class MealAdviceRequest(BaseModel):
    calorie_target: Optional[int] = Field(None, gt=0)


# ── Diyet tavsiyesi response ──
class MealAdviceResponse(BaseModel):
    summary: str
    daily_calorie_target: int
    macros: Dict[str, Any]
    recommended_foods: List[str]
    foods_to_avoid: List[str]
    meal_suggestions: Dict[str, str]
    warnings: List[str]


# ── Tarif önerisi request ──
class RecipeRequest(BaseModel):
    available_ingredients: List[str] = Field(..., min_length=1)
    meal_type: str = Field(default="dinner", description="breakfast / lunch / dinner / snack")
    calorie_limit: Optional[int] = Field(None, gt=0)


# ── Tarif önerisi response ──
class RecipeResponse(BaseModel):
    recipe_name: str
    description: str
    ingredients: List[Dict[str, Any]]
    steps: List[Dict[str, Any]]
    nutrition: Dict[str, Any]
    prep_time_minutes: int
    cook_time_minutes: int
    servings: int
    tips: Optional[str] = None


"""
DOSYA AKIŞI:
Her AI özelliği için ayrı Request/Response çifti var.
MealAdviceRequest ve WorkoutPlanRequest kullanıcı tercihlerini
user_preferences tablosundan otomatik çeker — kullanıcı tekrar girmez.
RecipeRequest: malzeme listesi zorunlu (min_length=1).

Spring Boot karşılığı: DTO sınıfları.
"""