from datetime import datetime
from typing import Optional, List

from pydantic import BaseModel, Field


# Desteklenen hedef değerleri
VALID_GOALS = [
    "weight_loss", "maintain_weight", "gain_weight", "muscle_gain",
    "change_diet", "meal_planning", "stress_management", "stay_active"
]

# Desteklenen diyet tercihleri
VALID_DIET_PREFERENCES = ["normal", "vegetarian", "vegan", "gluten_free"]


class OnboardingCreateRequest(BaseModel):
    # Adım 1 — Hedefler (max 3)
    goals: List[str] = Field(default=[], max_length=3, description="Max 3 hedef seçilebilir")

    # Adım 4 — Diyet tercihi
    diet_preference: Optional[str] = Field(None, description="normal/vegetarian/vegan/gluten_free")


class OnboardingUpdateRequest(BaseModel):
    # Kısmi güncelleme — tüm alanlar opsiyonel
    goals: Optional[List[str]] = Field(None, max_length=3)
    diet_preference: Optional[str] = None
    # is_completed ayrıca complete() endpoint'i ile set edilir


class OnboardingCompleteRequest(BaseModel):
    # Onboarding tamamlandı — tüm adımların verisi birlikte gönderilir
    goals: List[str] = Field(..., max_length=3)
    diet_preference: Optional[str] = None


class OnboardingResponse(BaseModel):
    id: str
    user_id: str
    is_completed: bool
    goals: List[str]
    diet_preference: Optional[str] = None
    completed_at: Optional[datetime] = None
    created_at: Optional[datetime] = None

    class Config:
        from_attributes = True


"""
DOSYA AKIŞI:
OnboardingCreateRequest → POST /onboarding (register sonrası ilk kayıt)
OnboardingUpdateRequest → PUT /onboarding (adım adım güncelleme)
OnboardingCompleteRequest → POST /onboarding/complete (son adımda tamamla)
OnboardingResponse → her endpoint'in döndürdüğü yanıt

Flutter akışı:
  1. Register → POST /onboarding (boş kayıt oluştur)
  2. Her adımda → PUT /onboarding (goals, diet_preference güncelle)
  3. Son adımda → POST /onboarding/complete (is_completed = True)

Spring Boot karşılığı: DTO sınıfları.
"""