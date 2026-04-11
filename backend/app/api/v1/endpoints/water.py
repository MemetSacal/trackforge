# HTTP katmanı — route tanımları ve dependency injection
from datetime import date
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.water import WaterLogCreate, WaterLogUpdate, WaterLogResponse
from backend.app.application.services.water_service import WaterService
from backend.app.application.services.gamification_service import GamificationService
from backend.app.infrastructure.db.session import get_db
from backend.app.core.dependencies import get_current_user

router = APIRouter()


def get_water_service(db: AsyncSession = Depends(get_db)) -> WaterService:
    return WaterService(db)


def get_gamification_service(db: AsyncSession = Depends(get_db)) -> GamificationService:
    return GamificationService(db)


@router.post("", response_model=WaterLogResponse, status_code=status.HTTP_201_CREATED)
async def create_water_log(
    data: WaterLogCreate,
    current_user: str = Depends(get_current_user),
    service: WaterService = Depends(get_water_service),
    gamification: GamificationService = Depends(get_gamification_service),
):
    """Yeni su kaydı oluştur."""
    result = await service.create(current_user, data)

    # Günlük hedef tutuldu mu kontrol et — gamification tetikle
    if data.target_ml and data.amount_ml and data.amount_ml >= data.target_ml:
        await gamification.on_water_goal_reached(current_user, data.date)

    return result


@router.get("", response_model=List[WaterLogResponse])
async def get_water_logs(
    start_date: date,
    end_date: date,
    current_user: str = Depends(get_current_user),
    service: WaterService = Depends(get_water_service),
):
    """Tarih aralığındaki su kayıtlarını listele."""
    return await service.get_by_date_range(current_user, start_date, end_date)


@router.get("/date/{log_date}", response_model=WaterLogResponse)
async def get_water_log_by_date(
    log_date: date,
    current_user: str = Depends(get_current_user),
    service: WaterService = Depends(get_water_service),
):
    """Belirli bir güne ait su kaydını getir."""
    return await service.get_by_date(current_user, log_date)


@router.put("/{log_id}", response_model=WaterLogResponse)
async def update_water_log(
    log_id: str,
    data: WaterLogUpdate,
    current_user: str = Depends(get_current_user),
    service: WaterService = Depends(get_water_service),
):
    """Su kaydını güncelle."""
    return await service.update(log_id, current_user, data)


@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_water_log(
    log_id: str,
    current_user: str = Depends(get_current_user),
    service: WaterService = Depends(get_water_service),
):
    """Su kaydını sil."""
    await service.delete(log_id, current_user)


"""
DOSYA AKIŞI:
POST /water → su kaydı oluştur + gamification kontrol:
  - amount_ml >= target_ml → hedef tutuldu → on_water_goal_reached()
  - Su streak +1, +20 XP
  - streak = 7  → "7_day_water" rozeti + 100 XP
  - streak = 30 → "30_day_water" rozeti + 100 XP

GET    /water?start_date=&end_date= → tarih aralığı
GET    /water/date/{date}           → belirli gün
PUT    /water/{id}                  → güncelle
DELETE /water/{id}                  → sil (204 No Content)

Spring Boot karşılığı: @RestController + @RequestMapping.
"""