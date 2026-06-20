from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional, List


# ── SESSION EXERCISE SCHEMAS ─────────────────────────────────────

class SessionExerciseCreateRequest(BaseModel):
    # Seans içine egzersiz ekleme isteği
    exercise_name: str = Field(..., min_length=1)   # Zorunlu — "Squat", "Bench Press" gibi
    sets: Optional[int] = Field(None, ge=1)         # Kaç set — en az 1
    reps: Optional[int] = Field(None, ge=1)         # Kaç tekrar — en az 1
    weight_kg: Optional[float] = Field(None, ge=0)  # Ağırlık — 0 veya üzeri
    notes: Optional[str] = None                     # Opsiyonel not
    muscle_groups: Optional[List[str]] = None        # v8.1 FIX (TC-005) — "Göğüs", "Triceps" vb.


class SessionExerciseUpdateRequest(BaseModel):
    exercise_name: Optional[str] = Field(None, min_length=1)
    sets: Optional[int] = Field(None, ge=1)
    reps: Optional[int] = Field(None, ge=1)
    weight_kg: Optional[float] = Field(None, ge=0)
    notes: Optional[str] = None
    completed: Optional[bool] = None
    muscle_groups: Optional[List[str]] = None        # v8.1 FIX (TC-005)


class SessionExerciseResponse(BaseModel):
    id: str
    session_id: str
    exercise_name: str
    sets: Optional[int]
    reps: Optional[int]
    weight_kg: Optional[float]
    notes: Optional[str]
    completed: bool = False
    created_at: datetime
    muscle_groups: Optional[List[str]] = None         # v8.1 FIX (TC-005) — eskiden response'ta hiç yoktu

    class Config:
        from_attributes = True


# ── EXERCISE SESSION SCHEMAS ─────────────────────────────────────

class ExerciseSessionCreateRequest(BaseModel):
    # Yeni egzersiz seansı oluşturma isteği
    date: date                                          # Zorunlu — hangi güne ait
    duration_minutes: Optional[int] = Field(None, ge=1)  # Süre — en az 1 dakika
    calories_burned: Optional[float] = Field(None, ge=0) # Kalori — 0 veya üzeri
    notes: Optional[str] = None                           # Seans notu
    source: str = "manual"                                 # v4: 'manual' | 'ai_plan'


class ExerciseSessionUpdateRequest(BaseModel):
    # Seans güncelleme isteği — date güncellenemez
    duration_minutes: Optional[int] = Field(None, ge=1)
    calories_burned: Optional[float] = Field(None, ge=0)
    notes: Optional[str] = None
    is_completed: Optional[bool] = None   # #19


class ExerciseSessionResponse(BaseModel):
    # API'den dönecek seans verisi — egzersizler de dahil
    id: str
    user_id: str
    date: date
    duration_minutes: Optional[int]
    calories_burned: Optional[float]
    notes: Optional[str]
    source: str = "manual"
    is_completed: bool = False             # #19
    created_at: datetime
    exercises: list[SessionExerciseResponse] = []

    class Config:
        from_attributes = True

"""
ExerciseSessionResponse içinde exercises listesi var.
Yani seans getirilince egzersizler de otomatik döner.
lazy="selectin" sayesinde ayrı sorgu yazmak gerekmez.
"""