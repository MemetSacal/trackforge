from datetime import datetime, timezone
from typing import Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.onboarding import (
    OnboardingCreateRequest, OnboardingUpdateRequest,
    OnboardingCompleteRequest, OnboardingResponse
)
from app.core.exceptions import NotFoundException, ConflictException
from app.domain.entities.onboarding_profile import OnboardingProfile
from app.infrastructure.repositories.onboarding_repository import OnboardingRepository
from app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository


class OnboardingService:

    def __init__(self, db: AsyncSession):
        self.repo = OnboardingRepository(db)
        self.db = db

    # ── Yardımcı: entity → response ──
    def _to_response(self, entity: OnboardingProfile) -> OnboardingResponse:
        return OnboardingResponse(
            id=entity.id,
            user_id=entity.user_id,
            is_completed=entity.is_completed,
            goals=entity.goals,
            diet_preference=entity.diet_preference,
            completed_at=entity.completed_at,
            created_at=entity.created_at,
        )

    async def create(self, user_id: str, data: OnboardingCreateRequest) -> OnboardingResponse:
        # Zaten kayıt var mı kontrol et
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

        # Partial update
        entity.goals = data.goals if data.goals is not None else entity.goals
        entity.diet_preference = data.diet_preference if data.diet_preference is not None else entity.diet_preference

        updated = await self.repo.update(entity)
        await self.db.commit()
        return self._to_response(updated)

    async def complete(self, user_id: str, data: OnboardingCompleteRequest) -> OnboardingResponse:
        entity = await self.repo.get_by_user_id(user_id)
        if not entity:
            raise NotFoundException("Onboarding kaydı bulunamadı.")

        # Tüm verileri kaydet ve tamamla
        entity.goals = data.goals
        entity.diet_preference = data.diet_preference
        entity.is_completed = True
        entity.completed_at = datetime.now(timezone.utc)

        updated = await self.repo.update(entity)

        # diet_preference'ı user_preferences'a da yaz — AI için
        if data.diet_preference:
            pref_repo = UserPreferenceRepository(self.db)
            prefs = await pref_repo.get_by_user_id(user_id)
            if prefs:
                # liked_foods'a diyet tercihini ekle (AI bunu okuyacak)
                if data.diet_preference == "vegetarian":
                    prefs.disliked_foods = list(set((prefs.disliked_foods or []) + ["et", "tavuk", "balık"]))
                elif data.diet_preference == "vegan":
                    prefs.disliked_foods = list(set((prefs.disliked_foods or []) + ["et", "tavuk", "balık", "süt", "yumurta"]))
                elif data.diet_preference == "gluten_free":
                    prefs.allergies = list(set((prefs.allergies or []) + ["gluten", "buğday"]))
                await pref_repo.update(prefs)

        await self.db.commit()
        return self._to_response(updated)


"""
DOSYA AKIŞI:
OnboardingService Flutter'ın ilk kurulum akışını yönetir:

create()   → Register sonrası boş onboarding kaydı oluştur
get()      → Flutter açılışta kontrol eder (is_completed?)
update()   → Adım adım güncelleme (her adımda PUT)
complete() → Son adımda tamamla (is_completed = True)

complete() özelliği:
  - diet_preference'ı user_preferences'a da yazar
  - Vejetaryen → et/tavuk/balık disliked_foods'a eklenir
  - Vegan → + süt/yumurta disliked_foods'a eklenir
  - Glutensiz → gluten/buğday allergies'e eklenir
  - AI bu bilgileri otomatik okur — diyet tavsiyeleri doğrulanır

Spring Boot karşılığı: @Service anotasyonlu class.
"""