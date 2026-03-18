from datetime import datetime
from typing import Optional, List, Dict, Any
from pydantic import BaseModel, Field


class UserPreferenceCreate(BaseModel):
    # Fiziksel profil
    height_cm: Optional[float] = Field(None, gt=0, le=300, description="Boy (cm)")
    age: Optional[int] = Field(None, gt=0, le=120, description="Yaş")
    gender: Optional[str] = Field(None, description="male / female")
    activity_level: Optional[str] = Field(None, description="sedentary / light / moderate / active / very_active")

    # Yemek tercihleri
    liked_foods: List[str] = []
    disliked_foods: List[str] = []
    allergies: List[str] = []
    diseases: List[str] = []
    blood_type: Optional[str] = None
    blood_values: Optional[Dict[str, Any]] = None
    workout_location: Optional[str] = None
    fitness_goal: Optional[str] = None


class UserPreferenceUpdate(BaseModel):
    # Fiziksel profil
    height_cm: Optional[float] = Field(None, gt=0, le=300)
    age: Optional[int] = Field(None, gt=0, le=120)
    gender: Optional[str] = None
    activity_level: Optional[str] = None

    # Diğer alanlar
    liked_foods: Optional[List[str]] = None
    disliked_foods: Optional[List[str]] = None
    allergies: Optional[List[str]] = None
    diseases: Optional[List[str]] = None
    blood_type: Optional[str] = None
    blood_values: Optional[Dict[str, Any]] = None
    workout_location: Optional[str] = None
    fitness_goal: Optional[str] = None


class UserPreferenceResponse(BaseModel):
    id: str
    user_id: str
    height_cm: Optional[float] = None
    age: Optional[int] = None
    gender: Optional[str] = None
    activity_level: Optional[str] = None
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
height_cm, age, gender, activity_level tüm şemalara eklendi.
Bunlar AI'a gönderilirken BMR hesabında kullanılır.

Spring Boot karşılığı: DTO sınıfları.
"""