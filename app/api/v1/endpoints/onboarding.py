# HTTP katmanı — onboarding endpoint'leri
from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.onboarding import (
    OnboardingCreateRequest, OnboardingUpdateRequest,
    OnboardingCompleteRequest, OnboardingResponse
)
from app.application.services.onboarding_service import OnboardingService
from app.infrastructure.db.session import get_db
from app.core.dependencies import get_current_user

router = APIRouter()


def get_onboarding_service(db: AsyncSession = Depends(get_db)) -> OnboardingService:
    return OnboardingService(db)


@router.post("", response_model=OnboardingResponse, status_code=status.HTTP_201_CREATED)
async def create_onboarding(
    data: OnboardingCreateRequest,
    current_user: str = Depends(get_current_user),
    service: OnboardingService = Depends(get_onboarding_service),
):
    """Register sonrası onboarding kaydı oluştur."""
    return await service.create(current_user, data)


@router.get("", response_model=OnboardingResponse)
async def get_onboarding(
    current_user: str = Depends(get_current_user),
    service: OnboardingService = Depends(get_onboarding_service),
):
    """Onboarding durumunu getir — Flutter açılışta bunu kontrol eder."""
    return await service.get(current_user)


@router.put("", response_model=OnboardingResponse)
async def update_onboarding(
    data: OnboardingUpdateRequest,
    current_user: str = Depends(get_current_user),
    service: OnboardingService = Depends(get_onboarding_service),
):
    """Onboarding adımlarını güncelle."""
    return await service.update(current_user, data)


@router.post("/complete", response_model=OnboardingResponse)
async def complete_onboarding(
    data: OnboardingCompleteRequest,
    current_user: str = Depends(get_current_user),
    service: OnboardingService = Depends(get_onboarding_service),
):
    """Onboarding'i tamamla — is_completed = True olur, bir daha gösterilmez."""
    return await service.complete(current_user, data)


"""
DOSYA AKIŞI:
POST   /onboarding          → boş onboarding kaydı oluştur (register sonrası)
GET    /onboarding          → durum kontrol (is_completed?)
PUT    /onboarding          → adım adım güncelle
POST   /onboarding/complete → tamamla (is_completed = True)

Flutter akışı:
  1. Register → POST /onboarding (boş kayıt)
  2. GET /onboarding → is_completed kontrolü
  3. Her adımda → PUT /onboarding
  4. Son adımda → POST /onboarding/complete
  5. is_completed = True → dashboard'a yönlendir

Spring Boot karşılığı: @RestController + @RequestMapping.
"""