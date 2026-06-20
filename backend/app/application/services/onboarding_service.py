from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.onboarding import (
    OnboardingCreateRequest, OnboardingUpdateRequest,
    OnboardingCompleteRequest, OnboardingResponse
)
from backend.app.core.exceptions import NotFoundException, ConflictException
from backend.app.domain.entities.onboarding_profile import OnboardingProfile
from backend.app.infrastructure.repositories.onboarding_repository import OnboardingRepository
from backend.app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository


class OnboardingService:

    def __init__(self, db: AsyncSession):
        self.repo = OnboardingRepository(db)
        self.db = db

    def _to_response(self, entity: OnboardingProfile) -> OnboardingResponse:
        return OnboardingResponse(
            id=entity.id,
            user_id=entity.user_id,
            is_completed=entity.is_completed,
            goals=entity.goals,
            diet_preference=entity.diet_preference,
            target_weight_kg=getattr(entity, 'target_weight_kg', None),
            daily_calorie_habit=getattr(entity, 'daily_calorie_habit', None),
            completed_at=entity.completed_at,
            created_at=entity.created_at,
        )

    async def create(self, user_id: str, data: OnboardingCreateRequest) -> OnboardingResponse:
        existing = await self.repo.get_by_user_id(user_id)
        if existing:
            raise ConflictException("Onboarding kaydı zaten mevcut.")

        entity = OnboardingProfile(
            id="",
            user_id=user_id,
            is_completed=False,
            goals=data.goals,
            diet_preference=data.diet_preference,
        )
        created = await self.repo.create(entity)
        await self.db.commit()
        return self._to_response(created)

    async def get(self, user_id: str) -> OnboardingResponse:
        entity = await self.repo.get_by_user_id(user_id)
        if not entity:
            raise NotFoundException("Onboarding kaydı bulunamadı.")
        return self._to_response(entity)

    async def update(self, user_id: str, data: OnboardingUpdateRequest) -> OnboardingResponse:
        entity = await self.repo.get_by_user_id(user_id)
        if not entity:
            raise NotFoundException("Onboarding kaydı bulunamadı.")

        if data.goals is not None:
            entity.goals = data.goals
        if data.diet_preference is not None:
            entity.diet_preference = data.diet_preference
        if data.target_weight_kg is not None:
            entity.target_weight_kg = data.target_weight_kg
        if data.daily_calorie_habit is not None:
            entity.daily_calorie_habit = data.daily_calorie_habit

        updated = await self.repo.update(entity)
        await self.db.commit()
        return self._to_response(updated)

    async def complete(self, user_id: str, data: OnboardingCompleteRequest) -> OnboardingResponse:
        entity = await self.repo.get_by_user_id(user_id)
        if not entity:
            raise NotFoundException("Onboarding kaydı bulunamadı.")

        entity.goals = data.goals
        entity.diet_preference = data.diet_preference
        entity.target_weight_kg = data.target_weight_kg
        entity.daily_calorie_habit = data.daily_calorie_habit
        entity.is_completed = True
        entity.completed_at = datetime.now(timezone.utc)

        updated = await self.repo.update(entity)

        # ── Preferences senkronizasyonu ──────────────────
        await self._sync_to_preferences(user_id, data)

        await self.db.commit()
        return self._to_response(updated)

    async def _sync_to_preferences(self, user_id: str, data: OnboardingCompleteRequest):
        """
        Onboarding verilerini user_preferences tablosuna yazar.
        Bu sayede AI koç, diyet tavsiyeleri ve kalori bankası
        onboarding'deki verileri otomatik okur.
        """
        pref_repo = UserPreferenceRepository(self.db)
        prefs = await pref_repo.get_by_user_id(user_id)
        if not prefs:
            return

        # fitness_goal — goals listesinin ilk elemanından belirle
        goal_map = {
            "weight_loss":     "weight_loss",
            "gain_weight":     "weight_gain",   # FIX #4: "kilo almak" muscle_gain'e yanlış mapleniyor
            "build_muscle":    "muscle_gain",   # "kas kazanmak" → muscle_gain (bu doğruydu)
            "muscle_gain":     "muscle_gain",
            "maintain_weight": "maintenance",
            "change_diet":     "health",
            "stay_active":     "health",
        }
        if data.goals:
            primary_goal = data.goals[0]
            mapped_goal = goal_map.get(primary_goal, "maintenance")
            prefs.fitness_goal = mapped_goal

        # target_weight_kg → preferences'a yaz (yeni alan eklenecek)
        if data.target_weight_kg is not None:
            if hasattr(prefs, 'target_weight_kg'):
                prefs.target_weight_kg = data.target_weight_kg

        # diet_preference → disliked_foods ve allergies güncelle
        if data.diet_preference:
            if data.diet_preference == "vegetarian":
                prefs.disliked_foods = list(set((prefs.disliked_foods or []) + ["et", "tavuk", "balık"]))
            elif data.diet_preference == "vegan":
                prefs.disliked_foods = list(set((prefs.disliked_foods or []) + ["et", "tavuk", "balık", "süt", "yumurta"]))
            elif data.diet_preference == "gluten_free":
                prefs.allergies = list(set((prefs.allergies or []) + ["gluten", "buğday"]))
            prefs.diet_preference = data.diet_preference

        # daily_calorie_habit → kalori bankası için sakla
        if data.daily_calorie_habit and hasattr(prefs, 'daily_calorie_habit'):
            prefs.daily_calorie_habit = data.daily_calorie_habit

        await pref_repo.update(prefs)