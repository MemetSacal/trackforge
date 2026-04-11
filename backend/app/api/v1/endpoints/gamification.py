# Gamification endpoint'leri — streak, rozet, seviye
from typing import List

from fastapi import APIRouter, Depends
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.gamification import (
    StreakResponse, BadgeResponse, UserLevelResponse, GamificationSummaryResponse
)
from backend.app.application.services.gamification_service import GamificationService
from backend.app.infrastructure.db.session import get_db
from backend.app.core.dependencies import get_current_user

router = APIRouter()


def get_gamification_service(db: AsyncSession = Depends(get_db)) -> GamificationService:
    return GamificationService(db)


@router.get("/summary", response_model=GamificationSummaryResponse)
async def get_gamification_summary(
    current_user: str = Depends(get_current_user),
    service: GamificationService = Depends(get_gamification_service),
):
    """Tüm gamification verisini getir — streak, rozet, seviye."""
    return await service.get_summary(current_user)


@router.get("/streaks", response_model=List[StreakResponse])
async def get_streaks(
    current_user: str = Depends(get_current_user),
    service: GamificationService = Depends(get_gamification_service),
):
    """Su, egzersiz, uyku streak'lerini getir."""
    return await service.get_streaks(current_user)


@router.get("/badges", response_model=List[BadgeResponse])
async def get_badges(
    current_user: str = Depends(get_current_user),
    service: GamificationService = Depends(get_gamification_service),
):
    """Kazanılan rozetleri getir."""
    return await service.get_badges(current_user)


@router.get("/level", response_model=UserLevelResponse)
async def get_level(
    current_user: str = Depends(get_current_user),
    service: GamificationService = Depends(get_gamification_service),
):
    """Mevcut seviye ve XP bilgisini getir."""
    level = await service.get_level(current_user)
    if not level:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Henüz XP kazanılmadı.")
    return level


"""
DOSYA AKIŞI:
GET /gamification/summary → streak + rozet + seviye hepsi bir arada
GET /gamification/streaks → sadece streak'ler
GET /gamification/badges  → sadece rozetler
GET /gamification/level   → sadece seviye + XP

Flutter'da ana ekranda summary endpoint'i kullanılır.
Gamification sayfasında detaylı görünüm için ayrı endpoint'ler.

Spring Boot karşılığı: @RestController + @GetMapping.
"""