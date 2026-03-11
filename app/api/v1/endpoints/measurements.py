from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.application.schemas.measurement import (
    MeasurementCreateRequest,
    MeasurementUpdateRequest,
    MeasurementResponse,
)
from app.application.services.measurement_service import MeasurementService
from app.core.dependencies import get_current_user
from app.infrastructure.db.session import get_db
from app.infrastructure.repositories.measurement_repository import MeasurementRepository

router = APIRouter()


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_measurement_service(session: AsyncSession = Depends(get_db)) -> MeasurementService:
    # get_auth_service ile aynı DI zinciri mantığı
    # session → MeasurementRepository → MeasurementService
    repo = MeasurementRepository(session)
    return MeasurementService(repo)


# ── CREATE ───────────────────────────────────────────────────────
@router.post("", response_model=MeasurementResponse)
async def create_measurement(
    request: MeasurementCreateRequest,
    user_id: str = Depends(get_current_user),        # JWT'den user_id çek
    service: MeasurementService = Depends(get_measurement_service),
):
    # POST /api/v1/measurements
    return await service.create(user_id, request)


# ── GET BY DATE ──────────────────────────────────────────────────
@router.get("/date/{target_date}", response_model=MeasurementResponse)
async def get_by_date(
    target_date: date,                               # URL'den date parse edilir: /date/2026-03-10
    user_id: str = Depends(get_current_user),
    service: MeasurementService = Depends(get_measurement_service),
):
    # GET /api/v1/measurements/date/2026-03-10
    return await service.get_by_date(user_id, target_date)


# ── GET BY DATE RANGE ────────────────────────────────────────────
@router.get("", response_model=list[MeasurementResponse])
async def get_by_date_range(
    from_date: date = Query(..., alias="from"),      # ?from=2026-03-01
    to_date: date = Query(..., alias="to"),          # &to=2026-03-31
    user_id: str = Depends(get_current_user),
    service: MeasurementService = Depends(get_measurement_service),
):
    # GET /api/v1/measurements?from=2026-03-01&to=2026-03-31
    return await service.get_by_date_range(user_id, from_date, to_date)


# ── GET HISTORY ──────────────────────────────────────────────────
@router.get("/history", response_model=list[MeasurementResponse])
async def get_history(
    user_id: str = Depends(get_current_user),
    service: MeasurementService = Depends(get_measurement_service),
):
    # GET /api/v1/measurements/history — tüm geçmiş, grafik için
    return await service.get_history(user_id)


# ── UPDATE ───────────────────────────────────────────────────────
@router.put("/{measurement_id}", response_model=MeasurementResponse)
async def update_measurement(
    measurement_id: str,
    request: MeasurementUpdateRequest,
    user_id: str = Depends(get_current_user),
    service: MeasurementService = Depends(get_measurement_service),
):
    # PUT /api/v1/measurements/{id}
    return await service.update(user_id, measurement_id, request)


# ── DELETE ───────────────────────────────────────────────────────
@router.delete("/{measurement_id}")
async def delete_measurement(
    measurement_id: str,
    user_id: str = Depends(get_current_user),
    service: MeasurementService = Depends(get_measurement_service),
):
    # DELETE /api/v1/measurements/{id}
    await service.delete(user_id, measurement_id)
    return {"message": "Ölçüm silindi"}

"""
Genel akış:
HTTP Request → Endpoint → Depends(get_current_user) → JWT doğrula → user_id al
→ Depends(get_measurement_service) → session → repo → service
→ service iş mantığını çalıştır → Response döner

Query(..., alias="from") neden?
"from" Python'da reserved keyword — değişken adı olamaz.
alias="from" ile URL'de ?from= yazılabilirken Python'da from_date kullanıyoruz.

Neden DELETE 204 değil 200 dönüyor?
204 No Content daha doğru HTTP standardı ama Flutter tarafında
boş response parse etmek bazen sorun çıkarır. {"message": "..."} daha güvenli.
"""