from datetime import date
from typing import List

from fastapi import APIRouter, Depends, status
from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.sleep import SleepLogCreate, SleepLogUpdate, SleepLogResponse
from app.application.services.sleep_service import SleepService
from app.application.services.gamification_service import GamificationService
from app.infrastructure.db.session import get_db
from app.core.dependencies import get_current_user

router = APIRouter()


def get_sleep_service(db: AsyncSession = Depends(get_db)) -> SleepService:
    return SleepService(db)


def get_gamification_service(db: AsyncSession = Depends(get_db)) -> GamificationService:
    return GamificationService(db)


@router.post("", response_model=SleepLogResponse, status_code=status.HTTP_201_CREATED)
async def create_sleep_log(
    data: SleepLogCreate,
    current_user: str = Depends(get_current_user),
    service: SleepService = Depends(get_sleep_service),
    gamification: GamificationService = Depends(get_gamification_service),
):
    """Yeni uyku kaydı oluştur."""
    result = await service.create(current_user, data)

    # Gamification tetikle — streak + XP
    # quality_score yoksa 0 gönder → streak artmaz ama XP kazanılır
    quality_score = data.quality_score if data.quality_score else 0
    await gamification.on_sleep_logged(current_user, data.date, quality_score)

    return result


@router.get("", response_model=List[SleepLogResponse])
async def get_sleep_logs(
    start_date: date,
    end_date: date,
    current_user: str = Depends(get_current_user),
    service: SleepService = Depends(get_sleep_service),
):
    """Tarih aralığındaki uyku kayıtlarını listele."""
    return await service.get_by_date_range(current_user, start_date, end_date)


@router.get("/date/{log_date}", response_model=SleepLogResponse)
async def get_sleep_log_by_date(
    log_date: date,
    current_user: str = Depends(get_current_user),
    service: SleepService = Depends(get_sleep_service),
):
    """Belirli bir geceye ait uyku kaydını getir."""
    return await service.get_by_date(current_user, log_date)


@router.put("/{log_id}", response_model=SleepLogResponse)
async def update_sleep_log(
    log_id: str,
    data: SleepLogUpdate,
    current_user: str = Depends(get_current_user),
    service: SleepService = Depends(get_sleep_service),
):
    """Uyku kaydını güncelle."""
    return await service.update(log_id, current_user, data)


@router.delete("/{log_id}", status_code=status.HTTP_204_NO_CONTENT)
async def delete_sleep_log(
    log_id: str,
    current_user: str = Depends(get_current_user),
    service: SleepService = Depends(get_sleep_service),
):
    """Uyku kaydını sil."""
    await service.delete(log_id, current_user)


"""
DOSYA AKIŞI:
POST   /sleep → uyku kaydı + gamification tetikler:
  - quality_score >= 6 → sleep streak +1
  - Her log → +15 XP

GET    /sleep?start_date=&end_date= → tarih aralığı
GET    /sleep/date/{date}           → belirli gece
PUT    /sleep/{id}                  → güncelle
DELETE /sleep/{id}                  → sil

Spring Boot karşılığı: @RestController + @RequestMapping.
"""