from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional, List


@dataclass
class OnboardingProfile:
    id: str
    user_id: str

    # Onboarding tamamlandı mı?
    is_completed: bool = False

    # Hedefler — max 3 seçim
    # weight_loss / maintain_weight / gain_weight / muscle_gain /
    # change_diet / meal_planning / stress_management / stay_active
    goals: List[str] = field(default_factory=list)

    # Diyet tercihi — normal/vegetarian/vegan/gluten_free
    diet_preference: Optional[str] = None

    # Onboarding tamamlanma zamanı
    completed_at: Optional[datetime] = None

    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
OnboardingProfile entity'si Flutter'ın ilk kurulum akışını yönetir.
is_completed = False → Flutter onboarding ekranlarını gösterir
is_completed = True  → direkt dashboard'a yönlendirir

goals max 3 seçim — Flutter'da checkbox listesi olarak gösterilir.
diet_preference → meal_advisor.py'e gönderilir, AI buna göre tarif önerir.

Spring Boot karşılığı: @Entity sınıfı ama JPA anotasyonu olmadan.
"""