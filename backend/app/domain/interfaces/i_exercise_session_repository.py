from abc import ABC, abstractmethod
from datetime import date
from typing import Optional
from backend.app.domain.entities.exercise_session import ExerciseSession


class IExerciseSessionRepository(ABC):
    # Abstract repository interface — egzersiz seansı DB işlemleri

    @abstractmethod
    async def create(self, session: ExerciseSession) -> ExerciseSession:
        pass

    @abstractmethod
    async def get_by_id(self, session_id: str) -> Optional[ExerciseSession]:
        pass

    @abstractmethod
    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[ExerciseSession]:
        pass

    @abstractmethod
    async def update(self, session: ExerciseSession) -> ExerciseSession:
        pass

    @abstractmethod
    async def delete(self, session_id: str) -> bool:
        # Seans silinince içindeki session_exercises da silinmeli — CASCADE
        pass