from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.preference import (
    UserPreferenceCreate, UserPreferenceUpdate, UserPreferenceResponse
)
from app.application.services.preference_service import PreferenceService
from app.infrastructure.db.session import get_db
from app.core.dependencies import get_current_user

router = APIRouter()


def get_preference_service(db: AsyncSession = Depends(get_db)) -> PreferenceService:
    return PreferenceService(db)


@router.post("", response_model=UserPreferenceResponse, status_code=status.HTTP_201_CREATED)
async def create_preferences(
    data: UserPreferenceCreate,
    current_user: str = Depends(get_current_user),
    service: PreferenceService = Depends(get_preference_service),
):
    """Kullanıcı tercihlerini oluştur."""
    return await service.create(current_user, data)


@router.get("", response_model=UserPreferenceResponse)
async def get_preferences(
    current_user: str = Depends(get_current_user),
    service: PreferenceService = Depends(get_preference_service),
):
    """Kullanıcı tercihlerini getir."""
    return await service.get(current_user)


@router.put("", response_model=UserPreferenceResponse)
async def update_preferences(
    data: UserPreferenceUpdate,
    current_user: str = Depends(get_current_user),
    service: PreferenceService = Depends(get_preference_service),
):
    """Kullanıcı tercihlerini güncelle."""
    return await service.update(current_user, data)


@router.delete("", status_code=status.HTTP_204_NO_CONTENT)
async def delete_preferences(
    current_user: str = Depends(get_current_user),
    service: PreferenceService = Depends(get_preference_service),
):
    """Kullanıcı tercihlerini sil."""
    await service.delete(current_user)


"""
DOSYA AKIŞI:
Diğer endpoint'lerden farkı:
- URL'de {id} veya {date} yok — one-to-one olduğu için token'dan user_id alınır
- POST /preferences   → oluştur
- GET  /preferences   → getir
- PUT  /preferences   → güncelle
- DELETE /preferences → sil

Spring Boot karşılığı: @RestController + @RequestMapping.
"""