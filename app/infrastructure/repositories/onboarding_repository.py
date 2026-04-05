import uuid
from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.onboarding_profile import OnboardingProfile
from app.domain.interfaces.i_onboarding_repository import IOnboardingRepository
from app.infrastructure.db.models.onboarding_profile_model import OnboardingProfileModel


class OnboardingRepository(IOnboardingRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Entity → Model ──
    def _to_model(self, entity: OnboardingProfile) -> OnboardingProfileModel:
        return OnboardingProfileModel(
            id=entity.id,
            user_id=entity.user_id,
            is_completed=entity.is_completed,
            goals=entity.goals,
            diet_preference=entity.diet_preference,
            completed_at=entity.completed_at,
            created_at=entity.created_at,
        )

    # ── Model → Entity ──
    def _to_entity(self, model: OnboardingProfileModel) -> OnboardingProfile:
        return OnboardingProfile(
            id=model.id,
            user_id=model.user_id,
            is_completed=model.is_completed,
            goals=model.goals or [],
            diet_preference=model.diet_preference,
            completed_at=model.completed_at,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    async def create(self, profile: OnboardingProfile) -> OnboardingProfile:
        profile.id = str(uuid.uuid4())
        profile.created_at = datetime.now(timezone.utc)
        model = self._to_model(profile)
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def get_by_user_id(self, user_id: str) -> Optional[OnboardingProfile]:
        result = await self.db.execute(
            select(OnboardingProfileModel).where(
                OnboardingProfileModel.user_id == user_id
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def update(self, profile: OnboardingProfile) -> OnboardingProfile:
        result = await self.db.execute(
            select(OnboardingProfileModel).where(
                OnboardingProfileModel.user_id == profile.user_id
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None
        # Güncellenebilir alanlar
        model.is_completed = profile.is_completed
        model.goals = profile.goals
        model.diet_preference = profile.diet_preference
        model.completed_at = profile.completed_at
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)


"""
DOSYA AKIŞI:
OnboardingRepository one-to-one pattern — preference_repository ile aynı yapı.
create → ilk kayıt (register sonrası otomatik oluşturulabilir)
get_by_user_id → Flutter her açılışta bunu kontrol eder
update → onboarding adımları tamamlandıkça güncellenir

Spring Boot karşılığı: @Repository anotasyonlu class.
"""