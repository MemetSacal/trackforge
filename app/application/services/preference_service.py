from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.preference import (
    UserPreferenceCreate, UserPreferenceUpdate, UserPreferenceResponse
)
from app.core.exceptions import NotFoundException, ConflictException
from app.domain.entities.user_preference import UserPreference
from app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository


class PreferenceService:

    def __init__(self, db: AsyncSession):
        self.repo = UserPreferenceRepository(db)
        self.db = db

    # ── Yardımcı: entity → response ──
    def _to_response(self, entity: UserPreference) -> UserPreferenceResponse:
        return UserPreferenceResponse(
            id=entity.id,
            user_id=entity.user_id,
            # Fiziksel profil
            height_cm=entity.height_cm,
            age=entity.age,
            gender=entity.gender,
            activity_level=entity.activity_level,
            # Yemek tercihleri
            liked_foods=entity.liked_foods,
            disliked_foods=entity.disliked_foods,
            allergies=entity.allergies,
            diseases=entity.diseases,
            blood_type=entity.blood_type,
            blood_values=entity.blood_values,
            workout_location=entity.workout_location,
            fitness_goal=entity.fitness_goal,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )

    async def create(self, user_id: str, data: UserPreferenceCreate) -> UserPreferenceResponse:
        # Zaten tercih kaydı var mı kontrol et — one-to-one
        existing = await self.repo.get_by_user_id(user_id)
        if existing:
            raise ConflictException("Kullanıcı tercihleri zaten mevcut. Güncelleme için PUT kullanın.")

        entity = UserPreference(
            id="",
            user_id=user_id,
            # Fiziksel profil
            height_cm=data.height_cm,
            age=data.age,
            gender=data.gender,
            activity_level=data.activity_level,
            # Yemek tercihleri
            liked_foods=data.liked_foods,
            disliked_foods=data.disliked_foods,
            allergies=data.allergies,
            diseases=data.diseases,
            blood_type=data.blood_type,
            blood_values=data.blood_values,
            workout_location=data.workout_location,
            fitness_goal=data.fitness_goal,
        )
        created = await self.repo.create(entity)
        await self.db.commit()
        return self._to_response(created)

    async def get(self, user_id: str) -> UserPreferenceResponse:
        entity = await self.repo.get_by_user_id(user_id)
        if not entity:
            raise NotFoundException("Kullanıcı tercihleri bulunamadı.")
        return self._to_response(entity)

    async def update(self, user_id: str, data: UserPreferenceUpdate) -> UserPreferenceResponse:
        entity = await self.repo.get_by_user_id(user_id)
        if not entity:
            raise NotFoundException("Kullanıcı tercihleri bulunamadı.")

        # Partial update — None ise eskiyi koru
        # Fiziksel profil
        entity.height_cm = data.height_cm if data.height_cm is not None else entity.height_cm
        entity.age = data.age if data.age is not None else entity.age
        entity.gender = data.gender if data.gender is not None else entity.gender
        entity.activity_level = data.activity_level if data.activity_level is not None else entity.activity_level
        # Yemek tercihleri
        entity.liked_foods = data.liked_foods if data.liked_foods is not None else entity.liked_foods
        entity.disliked_foods = data.disliked_foods if data.disliked_foods is not None else entity.disliked_foods
        entity.allergies = data.allergies if data.allergies is not None else entity.allergies
        entity.diseases = data.diseases if data.diseases is not None else entity.diseases
        entity.blood_type = data.blood_type if data.blood_type is not None else entity.blood_type
        entity.blood_values = data.blood_values if data.blood_values is not None else entity.blood_values
        entity.workout_location = data.workout_location if data.workout_location is not None else entity.workout_location
        entity.fitness_goal = data.fitness_goal if data.fitness_goal is not None else entity.fitness_goal

        updated = await self.repo.update(entity)
        await self.db.commit()
        return self._to_response(updated)

    async def delete(self, user_id: str) -> None:
        deleted = await self.repo.delete(user_id)
        if not deleted:
            raise NotFoundException("Kullanıcı tercihleri bulunamadı.")
        await self.db.commit()


"""
DOSYA AKIŞI:
PreferenceService diğerlerinden farklı:
- date parametresi yok — one-to-one olduğu için tarih bazlı değil
- get() → sadece user_id ile tek kayıt getirir
- create() → zaten varsa 409 ConflictException fırlatır
- height_cm, age, gender, activity_level eklendi — BMR/TDEE hesabı için

Spring Boot karşılığı: @Service anotasyonlu class.
"""