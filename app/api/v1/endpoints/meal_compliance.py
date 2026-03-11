from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from app.application.schemas.meal_compliance import (
    MealComplianceCreateRequest,
    MealComplianceUpdateRequest,
    MealComplianceResponse,
)
from app.application.services.meal_compliance_service import MealComplianceService
from app.core.dependencies import get_current_user
from app.infrastructure.db.session import get_db
from app.infrastructure.repositories.meal_compliance_repository import MealComplianceRepository

router = APIRouter()


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_meal_compliance_service(session: AsyncSession = Depends(get_db)) -> MealComplianceService:
    # session → MealComplianceRepository → MealComplianceService
    repo = MealComplianceRepository(session)
    return MealComplianceService(repo)


# ── CREATE ───────────────────────────────────────────────────────
@router.post("", response_model=MealComplianceResponse)
async def create_compliance(
    request: MealComplianceCreateRequest,
    user_id: str = Depends(get_current_user),
    service: MealComplianceService = Depends(get_meal_compliance_service),
):
    # POST /api/v1/meal-compliance
    return await service.create(user_id, request)


# ── GET BY DATE ──────────────────────────────────────────────────
@router.get("/date/{target_date}", response_model=MealComplianceResponse)
async def get_by_date(
    target_date: date,
    user_id: str = Depends(get_current_user),
    service: MealComplianceService = Depends(get_meal_compliance_service),
):
    # GET /api/v1/meal-compliance/date/2026-03-11
    return await service.get_by_date(user_id, target_date)


# ── GET BY DATE RANGE ────────────────────────────────────────────
@router.get("", response_model=list[MealComplianceResponse])
async def get_by_date_range(
    from_date: date = Query(..., alias="from"),  # ?from=2026-03-01
    to_date: date = Query(..., alias="to"),      # &to=2026-03-31
    user_id: str = Depends(get_current_user),
    service: MealComplianceService = Depends(get_meal_compliance_service),
):
    # GET /api/v1/meal-compliance?from=2026-03-01&to=2026-03-31
    return await service.get_by_date_range(user_id, from_date, to_date)


# ── UPDATE ───────────────────────────────────────────────────────
@router.put("/{compliance_id}", response_model=MealComplianceResponse)
async def update_compliance(
    compliance_id: str,
    request: MealComplianceUpdateRequest,
    user_id: str = Depends(get_current_user),
    service: MealComplianceService = Depends(get_meal_compliance_service),
):
    # PUT /api/v1/meal-compliance/{id}
    return await service.update(user_id, compliance_id, request)


# ── DELETE ───────────────────────────────────────────────────────
@router.delete("/{compliance_id}")
async def delete_compliance(
    compliance_id: str,
    user_id: str = Depends(get_current_user),
    service: MealComplianceService = Depends(get_meal_compliance_service),
):
    # DELETE /api/v1/meal-compliance/{id}
    await service.delete(user_id, compliance_id)
    return {"message": "Diyet kaydı silindi"}

"""
Genel akış:
HTTP Request → Endpoint → Depends(get_current_user) → JWT doğrula → user_id al
→ Depends(get_meal_compliance_service) → session → repo → service
→ service iş mantığını çalıştır → Response döner

notes endpoint'inden farkı:
complied ve compliance_rate alanları var
"""