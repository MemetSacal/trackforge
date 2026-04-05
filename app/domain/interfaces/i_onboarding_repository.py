from abc import ABC, abstractmethod
from typing import Optional

from app.domain.entities.onboarding_profile import OnboardingProfile


class IOnboardingRepository(ABC):

    @abstractmethod
    async def create(self, profile: OnboardingProfile) -> OnboardingProfile:
        pass

    @abstractmethod
    async def get_by_user_id(self, user_id: str) -> Optional[OnboardingProfile]:
        pass

    @abstractmethod
    async def update(self, profile: OnboardingProfile) -> OnboardingProfile:
        pass


"""
DOSYA AKIŞI:
Onboarding one-to-one olduğu için:
- get_by_user_id: user_id ile doğrudan sorgula
- delete yok — kullanıcı silinince CASCADE ile otomatik silinir
- update: is_completed, goals, diet_preference güncellenebilir

Spring Boot karşılığı: JpaRepository extend eden interface.
"""