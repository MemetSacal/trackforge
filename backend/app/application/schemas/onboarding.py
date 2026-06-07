from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, Field

VALID_GOALS = [
    "weight_loss", "maintain_weight", "gain_weight", "muscle_gain",
    "change_diet", "meal_planning", "stress_management", "stay_active"
]

VALID_DIET_PREFERENCES = ["normal", "vegetarian", "vegan", "gluten_free"]

# Günlük kalori alışkanlığı seçenekleri
VALID_CALORIE_HABITS = [
    "under_1500",    # 1500 altı
    "1500_2000",     # 1500-2000
    "2000_2500",     # 2000-2500
    "2500_3000",     # 2500-3000
    "over_3000",     # 3000 üzeri
]


class OnboardingCreateRequest(BaseModel):
    goals: List[str] = Field(default=[], description="Max 3 hedef")
    diet_preference: Optional[str] = None


class OnboardingUpdateRequest(BaseModel):
    goals: Optional[List[str]] = None
    diet_preference: Optional[str] = None
    # ── YENİ alanlar ──
    target_weight_kg: Optional[float] = Field(None, ge=30, le=300, description="Hedef kilo")
    daily_calorie_habit: Optional[str] = Field(None, description="Günlük kalori alışkanlığı aralığı")


class OnboardingCompleteRequest(BaseModel):
    goals: List[str] = Field(..., description="Max 3 hedef")
    diet_preference: Optional[str] = None
    # ── YENİ alanlar ──
    target_weight_kg: Optional[float] = Field(None, ge=30, le=300)
    daily_calorie_habit: Optional[str] = Field(None, description="under_1500 / 1500_2000 / 2000_2500 / 2500_3000 / over_3000")


class OnboardingResponse(BaseModel):
    id: str
    user_id: str
    is_completed: bool
    goals: List[str]
    diet_preference: Optional[str] = None
    target_weight_kg: Optional[float] = None      # ← YENİ
    daily_calorie_habit: Optional[str] = None      # ← YENİ
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True