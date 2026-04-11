from abc import ABC, abstractmethod
from typing import Optional
from backend.app.domain.entities.session_exercise import SessionExercise


class ISessionExerciseRepository(ABC):
    # Abstract repository interface — seans içindeki egzersiz DB işlemleri

    @abstractmethod
    async def create(self, exercise: SessionExercise) -> SessionExercise:
        pass

    @abstractmethod
    async def get_by_id(self, exercise_id: str) -> Optional[SessionExercise]:
        pass

    @abstractmethod
    async def get_by_session_id(self, session_id: str) -> list[SessionExercise]:
        # Bir seansın tüm egzersizlerini getir
        pass

    @abstractmethod
    async def update(self, exercise: SessionExercise) -> SessionExercise:
        pass

    @abstractmethod
    async def delete(self, exercise_id: str) -> bool:
        pass