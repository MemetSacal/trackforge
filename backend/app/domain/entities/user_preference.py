from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List


@dataclass
class UserPreference:
    id: str
    user_id: str

    # Fiziksel profil — BMR/TDEE hesabı için
    height_cm: Optional[float] = None           # Boy (cm)
    age: Optional[int] = None                   # Yaş
    gender: Optional[str] = None                # "male" / "female"
    activity_level: Optional[str] = None        # "sedentary" / "light" / "moderate" / "active" / "very_active"

    # Yemek tercihleri
    liked_foods: List[str] = field(default_factory=list)
    disliked_foods: List[str] = field(default_factory=list)
    allergies: List[str] = field(default_factory=list)

    # Sağlık bilgileri
    diseases: List[str] = field(default_factory=list)
    blood_type: Optional[str] = None
    blood_values: Optional[dict] = None

    # Hedef ve antrenman
    workout_location: Optional[str] = None
    fitness_goal: Optional[str] = None

    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
height_cm + age + gender + activity_level eklendi.
Bu 4 alan + body_measurements'taki kilo → BMR/TDEE hesabı yapılabilir.
AI'a kalori hedefi otomatik hesaplanıp gönderilebilir.

Spring Boot karşılığı: @Entity sınıfı ama JPA anotasyonu olmadan.
"""