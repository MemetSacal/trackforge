# HTTP katmanı — route tanımları ve dependency injection
from datetime import date
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.water import WaterLogCreate, WaterLogUpdate, WaterLogResponse
from app.application.services.water_service import WaterService
from app.infrastructure.db.session import get_db
from app.core.dependencies import get_current_user

router = APIRouter()


# ── Dependency: her request'te WaterService oluştur ──
def get_water_service(db: AsyncSession = Depends(get_db)) -> WaterService:
    return WaterService(db)


@router.post("", response_model=WaterLogResponse, status_code=status.HTTP_201_CREATED)
async def create_water_log(
    data: WaterLogCreate,
    current_user: str = Depends(get_current_user),
    service: WaterService = Depends(get_water_service),
):
    """Yeni su kaydı oluştur."""
    return await service.create(current_user, data)


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
POST   /water              → yeni kayıt oluştur
GET    /water?start_date=&end_date=  → tarih aralığı listesi
GET    /water/date/{date}  → belirli gün
PUT    /water/{id}         → güncelle
DELETE /water/{id}         → sil (204 No Content döner)

get_current_user → User objesi değil, direkt user_id string döndürür.
Bu yüzden current_user: str — diğer endpoint'lerle aynı pattern.

Spring Boot karşılığı: @RestController + @RequestMapping.
"""