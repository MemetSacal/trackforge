from dataclasses import dataclass
from datetime import datetime
from typing import Optional
from app.domain.entities.exercise_session import ExerciseSession  # noqa — referans için


@dataclass
class SessionExercise:
    # Domain entity — seans içindeki tek bir egzersiz kaydı
    # Bir ExerciseSession'a bağlıdır → ExerciseSession

    id: str
    session_id: str                         # FK — hangi seansa ait
    exercise_name: str                      # Zorunlu — "Squat", "Bench Press" gibi
    sets: Optional[int]                     # Kaç set yapıldı
    reps: Optional[int]                     # Set başına kaç tekrar
    weight_kg: Optional[float]              # Kullanılan ağırlık kg cinsinden
    notes: Optional[str]                    # Egzersiz notu — "Son sette zorlandım" gibi
    created_at: datetime

    # Bkz ExerciseSession