from datetime import datetime
from typing import Optional, List, Dict, Any

from pydantic import BaseModel


# ── İstek şemaları ──

class UserPreferenceCreate(BaseModel):
    liked_foods: List[str] = []
    disliked_foods: List[str] = []
    allergies: List[str] = []
    diseases: List[str] = []
    blood_type: Optional[str] = None          # "A+", "B-", "0+", "AB+" vs
    blood_values: Optional[Dict[str, Any]] = None
    workout_location: Optional[str] = None    # "gym", "home", "outdoor"
    fitness_goal: Optional[str] = None        # "weight_loss", "muscle_gain", "maintenance"


class UserPreferenceUpdate(BaseModel):
    # Tüm alanlar opsiyonel — partial update
    liked_foods: Optional[List[str]] = None
    disliked_foods: Optional[List[str]] = None
    allergies: Optional[List[str]] = None
    diseases: Optional[List[str]] = None
    blood_type: Optional[str] = None
    blood_values: Optional[Dict[str, Any]] = None
    workout_location: Optional[str] = None
    fitness_goal: Optional[str] = None


# ── Yanıt şeması ──

class UserPreferenceResponse(BaseModel):
    id: str
    user_id: str
    liked_foods: List[str]
    disliked_foods: List[str]
    allergies: List[str]
    diseases: List[str]
    blood_type: Optional[str] = None
    blood_values: Optional[Dict[str, Any]] = None
    workout_location: Optional[str] = None
    fitness_goal: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


"""
DOSYA AKIŞI:
Dict[str, Any] → blood_values için esnek yapı
{"hemoglobin": 14.5, "glucose": 95, "vitamin_d": 32.0} gibi

List[str] → liked_foods, allergies vs için
["tavuk", "yumurta", "yulaf"] gibi

Spring Boot karşılığı: DTO sınıfları.
"""