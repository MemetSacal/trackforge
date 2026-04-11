from typing import List

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.cycle import CycleCreateSchema, CycleUpdateSchema, CycleResponse
from backend.app.application.services.cycle_service import CycleService
from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db

router = APIRouter()


async def get_cycle_service(db: AsyncSession = Depends(get_db)) -> CycleService:
    return CycleService(db)


# ── POST /cycle ──
@router.post("", response_model=CycleResponse, status_code=201)
async def create_cycle(
    body: CycleCreateSchema,
    user_id: str = Depends(get_current_user),
    service: CycleService = Depends(get_cycle_service),
):
    # Yeni döngü kaydı oluştur
    return await service.create(user_id, body)


# ── GET /cycle ──
@router.get("", response_model=CycleResponse)
async def get_current_cycle(
    user_id: str = Depends(get_current_user),
    service: CycleService = Depends(get_cycle_service),
):
    # Mevcut döngüyü ve fazını getir
    cycle = await service.get_current(user_id)
    if not cycle:
        raise HTTPException(status_code=404, detail="Döngü kaydı bulunamadı.")
    return cycle


# ── GET /cycle/history ──
@router.get("/history", response_model=List[CycleResponse])
async def get_cycle_history(
    user_id: str = Depends(get_current_user),
    service: CycleService = Depends(get_cycle_service),
):
    # Tüm döngü geçmişini getir
    return await service.get_history(user_id)


# ── PUT /cycle/{cycle_id} ──
@router.put("/{cycle_id}", response_model=CycleResponse)
async def update_cycle(
    cycle_id: str,
    body: CycleUpdateSchema,
    user_id: str = Depends(get_current_user),
    service: CycleService = Depends(get_cycle_service),
):
    # Döngü kaydını güncelle
    try:
        return await service.update(cycle_id, user_id, body)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


"""
DOSYA AKIŞI:
POST /cycle          → yeni döngü kaydı oluştur
GET  /cycle          → mevcut döngü + faz bilgisi
GET  /cycle/history  → tüm döngü geçmişi
PUT  /cycle/{id}     → döngü güncelle

Spring Boot karşılığı: @RestController + @RequestMapping("/cycle")
"""