from abc import ABC, abstractmethod
from typing import Optional

from app.domain.entities.user_preference import UserPreference


class IUserPreferenceRepository(ABC):

    @abstractmethod
    async def create(self, preference: UserPreference) -> UserPreference:
        pass

    @abstractmethod
    async def get_by_user_id(self, user_id: str) -> Optional[UserPreference]:
        # user_id ile doğrudan getir — id değil, çünkü one-to-one
        pass

    @abstractmethod
    async def update(self, preference: UserPreference) -> UserPreference:
        pass

    @abstractmethod
    async def delete(self, user_id: str) -> bool:
        pass


"""
DOSYA AKIŞI:
Diğer repository'lerden farkı:
- get_by_date / get_by_date_range yok — tarih bazlı değil
- get_by_user_id var — one-to-one olduğu için id yerine user_id ile sorguluyoruz
- delete de user_id ile yapılır

Spring Boot karşılığı: JpaRepository extend eden interface.
"""