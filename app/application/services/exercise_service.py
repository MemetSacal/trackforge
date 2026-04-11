import uuid
from datetime import date, datetime, timezone
from typing import Optional

from app.domain.entities.exercise_session import ExerciseSession
from app.domain.entities.session_exercise import SessionExercise
from app.domain.interfaces.i_exercise_session_repository import IExerciseSessionRepository
from app.domain.interfaces.i_session_exercise_repository import ISessionExerciseRepository
from app.core.exceptions import NotFoundException, BadRequestException


class ExerciseService:
    # Egzersiz seans ve egzersiz işlemlerinin iş mantığı burada
    # İki repository inject edilir — session ve exercise

    def __init__(
        self,
        session_repository: IExerciseSessionRepository,
        exercise_repository: ISessionExerciseRepository,
    ):
        # İki repository dışarıdan inject edilir
        self.session_repository = session_repository
        self.exercise_repository = exercise_repository

    # ── SEANS İŞLEMLERİ ─────────────────────────────────────────

    async def create_session(self, user_id: str, data) -> ExerciseSession:
        # Yeni egzersiz seansı oluştur
        session = ExerciseSession(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=data.date,
            duration_minutes=data.duration_minutes,
            calories_burned=data.calories_burned,
            notes=data.notes,
            created_at=datetime.now(timezone.utc),
        )
        return await self.session_repository.create(session)

    async def get_session(self, user_id: str, session_id: str) -> ExerciseSession:
        # Seansı getir ve sahiplik kontrol et
        session = await self.session_repository.get_by_id(session_id)
        if not session:
            raise NotFoundException("Seans bulunamadı")
        if session.user_id != user_id:
            raise NotFoundException("Seans bulunamadı")  # Güvenlik gereği 404
        return session

    async def get_sessions_by_date_range(
        self, user_id: str, from_date: date, to_date: date
    ) -> list[ExerciseSession]:
        if from_date > to_date:
            raise BadRequestException("Başlangıç tarihi bitiş tarihinden büyük olamaz")
        return await self.session_repository.get_by_date_range(user_id, from_date, to_date)

    async def update_session(self, user_id: str, session_id: str, data) -> ExerciseSession:
        # Seansı getir, sahiplik kontrol et, güncelle
        existing = await self.session_repository.get_by_id(session_id)
        if not existing:
            raise NotFoundException("Seans bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Seans bulunamadı")

        # Sadece gönderilen alanları güncelle
        existing.duration_minutes = data.duration_minutes if data.duration_minutes is not None else existing.duration_minutes
        existing.calories_burned = data.calories_burned if data.calories_burned is not None else existing.calories_burned
        existing.notes = data.notes if data.notes is not None else existing.notes
        return await self.session_repository.update(existing)

    async def delete_session(self, user_id: str, session_id: str) -> bool:
        existing = await self.session_repository.get_by_id(session_id)
        if not existing:
            raise NotFoundException("Seans bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Seans bulunamadı")
        # cascade="all, delete-orphan" sayesinde
        # seansa bağlı tüm egzersizler de otomatik silinir
        return await self.session_repository.delete(session_id)

    # ── EGZERSİZ İŞLEMLERİ ──────────────────────────────────────

    async def add_exercise(
        self, user_id: str, session_id: str, data
    ) -> SessionExercise:
        # Önce seansın var olduğunu ve bu kullanıcıya ait olduğunu kontrol et
        session = await self.session_repository.get_by_id(session_id)
        if not session:
            raise NotFoundException("Seans bulunamadı")
        if session.user_id != user_id:
            raise NotFoundException("Seans bulunamadı")

        # Seansa yeni egzersiz ekle
        exercise = SessionExercise(
            id=str(uuid.uuid4()),
            session_id=session_id,
            exercise_name=data.exercise_name,
            sets=data.sets,
            reps=data.reps,
            weight_kg=data.weight_kg,
            notes=data.notes,
            created_at=datetime.now(timezone.utc),
        )
        return await self.exercise_repository.create(exercise)

    async def get_exercises(self, user_id: str, session_id: str) -> list[SessionExercise]:
        # Seansın bu kullanıcıya ait olduğunu kontrol et
        session = await self.session_repository.get_by_id(session_id)
        if not session:
            raise NotFoundException("Seans bulunamadı")
        if session.user_id != user_id:
            raise NotFoundException("Seans bulunamadı")
        return await self.exercise_repository.get_by_session_id(session_id)

    async def update_exercise(
        self, user_id: str, exercise_id: str, data
    ) -> SessionExercise:
        # Egzersizi getir
        existing = await self.exercise_repository.get_by_id(exercise_id)
        if not existing:
            raise NotFoundException("Egzersiz bulunamadı")

        # Egzersizin ait olduğu seansın bu kullanıcıya ait olduğunu kontrol et
        session = await self.session_repository.get_by_id(existing.session_id)
        if not session or session.user_id != user_id:
            raise NotFoundException("Egzersiz bulunamadı")

        # Sadece gönderilen alanları güncelle
        existing.exercise_name = data.exercise_name if data.exercise_name is not None else existing.exercise_name
        return await self.exercise_repository.update(existing)

    async def delete_exercise(self, user_id: str, exercise_id: str) -> bool:
        existing = await self.exercise_repository.get_by_id(exercise_id)
        if not existing:
            raise NotFoundException("Egzersiz bulunamadı")

        session = await self.session_repository.get_by_id(existing.session_id)
        if not session or session.user_id != user_id:
            raise NotFoundException("Egzersiz bulunamadı")

        return await self.exercise_repository.delete(exercise_id)