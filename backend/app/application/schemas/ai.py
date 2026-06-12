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
    summary: str
    quota: Optional[Dict[str, Any]] = None  # v2: kalan hak bilgisi                    # Claude'un ürettiği Türkçe özet metin


# ── Antrenman planı request ──
class WorkoutPlanRequest(BaseModel):
    workout_location: str = Field(..., description="home / gym / outdoor")
    fitness_goal: str = Field(..., description="weight_loss / muscle_gain / maintenance")
    fitness_level: str = Field(default="intermediate", description="beginner / intermediate / advanced")
    available_days: int = Field(default=4, ge=1, le=7)
    # ── v2 alanları ──
    force_new: bool = Field(default=False, description="True ise cache atlanır, yeni plan üretilir (kota tüketir)")
    previous_plan: Optional[Dict[str, Any]] = Field(None, description="Revizyon modu: mevcut plan")
    revision_request: Optional[str] = Field(None, max_length=300, description="Revizyon modu: kullanıcının değişiklik isteği")


# ── Antrenman planı response ──
class WorkoutPlanResponse(BaseModel):
    plan_title: str
    weekly_schedule: List[Dict[str, Any]]   # her gün: day_of_week (1-7) + day (Türkçe etiket)
    weekly_notes: str
    quota: Optional[Dict[str, Any]] = None  # v2: kalan hak bilgisi — client lokal sayacı senkronlar


# ── Diyet tavsiyesi request ──
class MealAdviceRequest(BaseModel):
    calorie_target: Optional[int] = Field(None, gt=0)


# ── Diyet tavsiyesi response ──
class MealAdviceResponse(BaseModel):
    summary: str
    weekly_plan: Optional[Dict[str, Any]] = None           # v2 FIX: şemada yoktu — response_model bu alanı sessizce budayabiliyordu
    shopping_list: Optional[List[Dict[str, Any]]] = None  # v2: plan→alışveriş listesi
    quota: Optional[Dict[str, Any]] = None                # v2: kalan hak bilgisi
    daily_calorie_target: int
    macros: Dict[str, Any]
    recommended_foods: List[str]
    foods_to_avoid: List[str]
    meal_suggestions: Dict[str, str]
    warnings: List[str]


# ── Tarif önerisi request ──
class RecipeRequest(BaseModel):
    available_ingredients: List[str] = Field(default=[])  # min_length kaldırıldı
    meal_type: str = Field(default="dinner")
    calorie_limit: Optional[int] = Field(None, gt=0)
    craving: Optional[str] = None


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
    detected_ingredients: Optional[List[str]] = None  # v3: buzdolabı fotoğrafından tespit edilenler
    quota: Optional[Dict[str, Any]] = None            # v2: kalan hak bilgisi

# ── Kalori Vision request ──
class CalorieVisionResponse(BaseModel):
    food_items: List[Dict[str, Any]]
    total_calories: int
    macros: Dict[str, Any]
    confidence: str
    notes: Optional[str] = None
    quota: Optional[Dict[str, Any]] = None  # v2: kalan hak bilgisi

# ── ai_schema_cycle_additions.py ────────────────────────
class CycleAdviceRequest(BaseModel):
    pass  # Tüm bilgiler token'dan ve DB'den çekiliyor, body gerekmez

class CycleAdviceDietResponse(BaseModel):
    focus_nutrients: List[str]
    recommended_foods: List[str]
    foods_to_limit: List[str]
    calorie_adjustment: str
    meal_tip: str

class CycleAdviceWorkoutResponse(BaseModel):
    recommended_types: List[str]
    intensity: str
    duration_minutes: int
    workout_tip: str
    avoid: List[str]

class CycleAdviceResponse(BaseModel):
    phase_summary: str
    energy_level: str
    diet_advice: CycleAdviceDietResponse
    workout_advice: CycleAdviceWorkoutResponse
    wellness_tips: List[str]

# ── AI Feedback (v2) ─────────────────────────────────────
class AIFeedbackRequest(BaseModel):
    feature: str = Field(..., description="workout_plan / meal_advice / vision / recipe / weekly_summary / cycle_advice / calorie_bank")
    rating: int = Field(..., ge=-1, le=1, description="1 = beğendim, -1 = beğenmedim")
    comment: Optional[str] = Field(None, max_length=300)


class AIFeedbackResponse(BaseModel):
    message: str


"""
DOSYA AKIŞI:
Her AI özelliği için ayrı Request/Response çifti var.
MealAdviceRequest ve WorkoutPlanRequest kullanıcı tercihlerini
user_preferences tablosundan otomatik çeker — kullanıcı tekrar girmez.
RecipeRequest: malzeme listesi zorunlu (min_length=1).

Spring Boot karşılığı: DTO sınıfları.
"""