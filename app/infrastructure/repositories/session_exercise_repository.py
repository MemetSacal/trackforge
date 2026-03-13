from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from app.domain.entities.session_exercise import SessionExercise
from app.domain.interfaces.i_session_exercise_repository import ISessionExerciseRepository
from app.infrastructure.db.models.session_exercise_model import SessionExerciseModel


class SessionExerciseRepository(ISessionExerciseRepository):
    # ISessionExerciseRepository interface'inin PostgreSQL + SQLAlchemy implementasyonu

    def __init__(self, session: AsyncSession):
        self.session = session

    async def create(self, exercise: SessionExercise) -> SessionExercise:
        db_obj = SessionExerciseModel(
            id=exercise.id,
            session_id=exercise.session_id,
            exercise_name=exercise.exercise_name,
            sets=exercise.sets,
            reps=exercise.reps,
            weight_kg=exercise.weight_kg,
            notes=exercise.notes,
            created_at=exercise.created_at,
        )
        self.session.add(db_obj)
        await self.session.flush()
        return self._to_entity(db_obj)

    async def get_by_id(self, exercise_id: str) -> Optional[SessionExercise]:
        # SELECT * FROM session_exercises WHERE id = ?
        result = await self.session.execute(
            select(SessionExerciseModel).where(SessionExerciseModel.id == exercise_id)
        )
        db_obj = result.scalar_one_or_none()
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_session_id(self, session_id: str) -> list[SessionExercise]:
        # SELECT * FROM session_exercises WHERE session_id = ? ORDER BY created_at
        result = await self.session.execute(
            select(SessionExerciseModel).where(
                SessionExerciseModel.session_id == session_id
            ).order_by(SessionExerciseModel.created_at)  # Eklenme sırasına göre listele
        )
        return [self._to_entity(row) for row in result.scalars().all()]

    async def update(self, exercise: SessionExercise) -> SessionExercise:
        result = await self.session.execute(
            select(SessionExerciseModel).where(SessionExerciseModel.id == exercise.id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return None
        # session_id ve exercise_name değişmez — sadece detaylar güncellenir
        db_obj.exercise_name = exercise.exercise_name
        db_obj.sets = exercise.sets
        db_obj.reps = exercise.reps
        db_obj.weight_kg = exercise.weight_kg
        db_obj.notes = exercise.notes
        await self.session.flush()
        return self._to_entity(db_obj)

    async def delete(self, exercise_id: str) -> bool:
        result = await self.session.execute(
            select(SessionExerciseModel).where(SessionExerciseModel.id == exercise_id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return False
        await self.session.delete(db_obj)
        await self.session.flush()
        return True

    def _to_entity(self, db_obj: SessionExerciseModel) -> SessionExercise:
        # SessionExerciseModel → SessionExercise domain entity dönüşümü
        return SessionExercise(
            id=db_obj.id,
            session_id=db_obj.session_id,
            exercise_name=db_obj.exercise_name,
            sets=db_obj.sets,
            reps=db_obj.reps,
            weight_kg=db_obj.weight_kg,
            notes=db_obj.notes,
            created_at=db_obj.created_at,
        )

"""
Genel akış:
DB → SessionExerciseModel → _to_entity() → SessionExercise → Servis katmanı

ExerciseSessionRepository'den farkı:
cascade yok — tek egzersiz silinince sadece kendisi silinir
get_by_session_id var — bir seansın tüm egzersizlerini getirmek için
"""