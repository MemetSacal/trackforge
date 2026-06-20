from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional
from backend.app.domain.entities.exercise_session import ExerciseSession  # noqa — referans için


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
    completed: bool = False                 # v5 FIX: tamamlanma — zincirin kopuk halkasıydı
    muscle_groups: Optional[list] = field(default_factory=list)
    # v8.1 FIX (TC-005): DB kolonu zaten vardı ama entity/repository/şema
    # zincirinin hiçbir halkasında taşınmıyordu — kas grubu grafiği hep boştu.


    # Bkz ExerciseSession