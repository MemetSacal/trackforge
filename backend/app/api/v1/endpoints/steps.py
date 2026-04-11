from datetime import date
from typing import List, Optional

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.steps import StepLogCreateSchema, StepLogResponse
from backend.app.application.services.step_service import StepService
from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db

router = APIRouter()


async def get_step_service(db: AsyncSession = Depends(get_db)) -> StepService:
    return StepService(db)


# ── POST /steps ──
@router.post("", response_model=StepLogResponse, status_code=201)
async def create_step_log(
    body: StepLogCreateSchema,
    user_id: str = Depends(get_current_user),
    service: StepService = Depends(get_step_service),
):
    # Adım kaydı oluştur — distance ve kalori otomatik hesaplanır
    return await service.create(user_id, body)


# ── GET /steps ──
@router.get("", response_model=List[StepLogResponse])
async def get_step_logs(
    start_date: date,
    end_date: date,
    user_id: str = Depends(get_current_user),
    service: StepService = Depends(get_step_service),
):
    # Tarih aralığına göre adım loglarını getir
    return await service.get_range(user_id, start_date, end_date)


# ── GET /steps/date/{date} ──
@router.get("/date/{log_date}", response_model=StepLogResponse)
async def get_step_log_by_date(
    log_date: date,
    user_id: str = Depends(get_current_user),
    service: StepService = Depends(get_step_service),
):
    # Belirli bir güne ait adım logu
    log = await service.get_by_date(user_id, log_date)
    if not log:
        raise HTTPException(status_code=404, detail="Bu tarihe ait adım logu bulunamadı.")
    return log


"""
DOSYA AKIŞI:
POST /steps          → adım kaydı oluştur
GET  /steps          → tarih aralığı sorgula
GET  /steps/date/{} → belirli güne ait kayıt

Spring Boot karşılığı: @RestController + @RequestMapping("/steps")
"""