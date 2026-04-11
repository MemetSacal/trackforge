from datetime import date
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from backend.app.domain.entities.exercise_session import ExerciseSession
from backend.app.domain.entities.session_exercise import SessionExercise
from backend.app.domain.interfaces.i_exercise_session_repository import IExerciseSessionRepository
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel


class ExerciseSessionRepository(IExerciseSessionRepository):
    # IExerciseSessionRepository interface'inin PostgreSQL + SQLAlchemy implementasyonu

    def __init__(self, session: AsyncSession):
        # Session dışarıdan inject edilir — dependency injection
        self.session = session

    async def create(self, exercise_session: ExerciseSession) -> ExerciseSession:
        db_obj = ExerciseSessionModel(
            id=exercise_session.id,
            user_id=exercise_session.user_id,
            date=exercise_session.date,
            duration_minutes=exercise_session.duration_minutes,
            calories_burned=exercise_session.calories_burned,
            notes=exercise_session.notes,
            created_at=exercise_session.created_at,
        )
        self.session.add(db_obj)
        await self.session.flush()  # DB'ye yazar ama commit etmez
        return self._to_entity(db_obj)

    async def get_by_id(self, session_id: str) -> Optional[ExerciseSession]:
        # SELECT * FROM exercise_sessions WHERE id = ?
        result = await self.session.execute(
            select(ExerciseSessionModel).where(ExerciseSessionModel.id == session_id)
        )
        db_obj = result.scalar_one_or_none()
        return self._to_entity(db_obj) if db_obj else None

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[ExerciseSession]:
        # SELECT * FROM exercise_sessions WHERE user_id = ? AND date BETWEEN ? AND ? ORDER BY date
        result = await self.session.execute(
            select(ExerciseSessionModel).where(
                ExerciseSessionModel.user_id == user_id,
                ExerciseSessionModel.date >= from_date,
                ExerciseSessionModel.date <= to_date
            ).order_by(ExerciseSessionModel.date)
        )
        return [self._to_entity(row) for row in result.scalars().all()]

    async def update(self, exercise_session: ExerciseSession) -> ExerciseSession:
        result = await self.session.execute(
            select(ExerciseSessionModel).where(ExerciseSessionModel.id == exercise_session.id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return None
        # id, user_id, date değişmez — sadece içerik alanları güncellenir
        db_obj.duration_minutes = exercise_session.duration_minutes
        db_obj.calories_burned = exercise_session.calories_burned
        db_obj.notes = exercise_session.notes
        await self.session.flush()
        return self._to_entity(db_obj)

    async def delete(self, session_id: str) -> bool:
        result = await self.session.execute(
            select(ExerciseSessionModel).where(ExerciseSessionModel.id == session_id)
        )
        db_obj = result.scalar_one_or_none()
        if not db_obj:
            return False
        await self.session.delete(db_obj)
        # cascade="all, delete-orphan" sayesinde
        # bağlı tüm SessionExercise kayıtları da otomatik silinir
        await self.session.flush()
        return True

    def _to_entity(self, db_obj: ExerciseSessionModel) -> ExerciseSession:
        # ExerciseSessionModel → ExerciseSession domain entity dönüşümü
        return ExerciseSession(
            id=db_obj.id,
            user_id=db_obj.user_id,
            date=db_obj.date,
            duration_minutes=db_obj.duration_minutes,
            calories_burned=db_obj.calories_burned,
            notes=db_obj.notes,
            created_at=db_obj.created_at,
        )

"""
Genel akış:
DB → ExerciseSessionModel → _to_entity() → ExerciseSession → Servis katmanı

Diğer repository'lerden kritik farkı:
delete() içinde cascade="all, delete-orphan" devreye girer
Manuel olarak session_exercises'i silmek gerekmez — SQLAlchemy halleder
"""