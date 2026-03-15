import uuid
from datetime import datetime
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.user_preference import UserPreference
from app.domain.interfaces.i_user_preference_repository import IUserPreferenceRepository
from app.infrastructure.db.models.user_preference_model import UserPreferenceModel


class UserPreferenceRepository(IUserPreferenceRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Entity → Model ──
    def _to_model(self, entity: UserPreference) -> UserPreferenceModel:
        return UserPreferenceModel(
            id=entity.id,
            user_id=entity.user_id,
            liked_foods=entity.liked_foods,
            disliked_foods=entity.disliked_foods,
            allergies=entity.allergies,
            diseases=entity.diseases,
            blood_type=entity.blood_type,
            blood_values=entity.blood_values,
            workout_location=entity.workout_location,
            fitness_goal=entity.fitness_goal,
            created_at=entity.created_at,
        )

    # ── Model → Entity ──
    def _to_entity(self, model: UserPreferenceModel) -> UserPreference:
        return UserPreference(
            id=model.id,
            user_id=model.user_id,
            liked_foods=model.liked_foods or [],
            disliked_foods=model.disliked_foods or [],
            allergies=model.allergies or [],
            diseases=model.diseases or [],
            blood_type=model.blood_type,
            blood_values=model.blood_values,
            workout_location=model.workout_location,
            fitness_goal=model.fitness_goal,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    async def create(self, preference: UserPreference) -> UserPreference:
        preference.id = str(uuid.uuid4())
        preference.created_at = datetime.utcnow()
        model = self._to_model(preference)
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def get_by_user_id(self, user_id: str) -> Optional[UserPreference]:
        # user_id ile sorgula — one-to-one olduğu için tek kayıt döner
        result = await self.db.execute(
            select(UserPreferenceModel).where(
                UserPreferenceModel.user_id == user_id
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def update(self, preference: UserPreference) -> UserPreference:
        result = await self.db.execute(
            select(UserPreferenceModel).where(
                UserPreferenceModel.user_id == preference.user_id
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None
        # Tüm alanları güncelle
        model.liked_foods = preference.liked_foods
        model.disliked_foods = preference.disliked_foods
        model.allergies = preference.allergies
        model.diseases = preference.diseases
        model.blood_type = preference.blood_type
        model.blood_values = preference.blood_values
        model.workout_location = preference.workout_location
        model.fitness_goal = preference.fitness_goal
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def delete(self, user_id: str) -> bool:
        result = await self.db.execute(
            select(UserPreferenceModel).where(
                UserPreferenceModel.user_id == user_id
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return False
        await self.db.delete(model)
        await self.db.flush()
        return True


"""
DOSYA AKIŞI:
Diğer repository'lerden farkı:
- get_by_user_id: id yerine user_id ile sorgular
- _to_entity'de "or []" — DB'den None gelirse boş liste döndür
- delete de user_id ile yapılır, log_id değil

Spring Boot karşılığı: @Repository anotasyonlu class.
"""