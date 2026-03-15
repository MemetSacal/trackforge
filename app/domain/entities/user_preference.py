from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List


@dataclass
class UserPreference:
    id: str
    user_id: str                                # One-to-one — her kullanıcı için tek kayıt

    # Yemek tercihleri
    liked_foods: List[str] = field(default_factory=list)      # Sevilen yiyecekler
    disliked_foods: List[str] = field(default_factory=list)   # Sevilmeyen yiyecekler
    allergies: List[str] = field(default_factory=list)         # Alerjiler

    # Sağlık bilgileri
    diseases: List[str] = field(default_factory=list)          # Hastalıklar
    blood_type: Optional[str] = None                           # Kan grubu — "A+", "0-" vs
    blood_values: Optional[dict] = None                        # Kan değerleri — JSON

    # Hedef ve antrenman
    workout_location: Optional[str] = None                     # "gym", "home", "outdoor"
    fitness_goal: Optional[str] = None                         # "weight_loss", "muscle_gain" vs

    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
UserPreference entity'si diğerlerinden farklı:
- One-to-one ilişki — user_id üzerinde UNIQUE constraint var bir dip not constraint = verinin uymak zorunda olduğu kural.
- Yani constraint’ler aslında veri bütünlüğünün bodyguard’larıdır. 🛡️
- List alanlar DB'de JSON olarak saklanır
- blood_values dict tipi — {"hemoglobin": 14.5, "glucose": 95} gibi

Spring Boot karşılığı: @Entity + @OneToOne ilişkisi.
"""