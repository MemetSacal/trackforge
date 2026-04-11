from fastapi import APIRouter, Depends, Query
from sqlalchemy.ext.asyncio import AsyncSession
from datetime import date

from backend.app.application.schemas.meal_compliance import (
    MealComplianceCreateRequest,
    MealComplianceUpdateRequest,
    MealComplianceResponse,
)
from backend.app.application.services.meal_compliance_service import MealComplianceService
from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.repositories.meal_compliance_repository import MealComplianceRepository

router = APIRouter()


# ── DEPENDENCY ───────────────────────────────────────────────────
def get_meal_compliance_service(session: AsyncSession = Depends(get_db)) -> MealComplianceService:
    # session → MealComplianceRepository → MealComplianceService
    # db de inject edildi — kalori bankası hesapları için preferences ve measurements lazım
    repo = MealComplianceRepository(session)
    return MealComplianceService(repo, session)


# ── CREATE ───────────────────────────────────────────────────────
@router.post("", response_model=MealComplianceResponse)
async def create_compliance(
    request: MealComplianceCreateRequest,
    user_id: str = Depends(get_current_user),
    session: AsyncSession = Depends(get_db),
    service: MealComplianceService = Depends(get_meal_compliance_service),
):
    # POST /api/v1/meal-compliance
    result = await service.create(user_id, request, session)
    await session.commit()
    return result


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
    from_date: date = Query(..., alias="from"),
    to_date: date = Query(..., alias="to"),
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
    session: AsyncSession = Depends(get_db),
    service: MealComplianceService = Depends(get_meal_compliance_service),
):
    # PUT /api/v1/meal-compliance/{id}
    result = await service.update(user_id, compliance_id, request, session)
    await session.commit()
    return result


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
DOSYA AKIŞI:
HTTP Request → Endpoint → JWT doğrula → user_id al
→ MealComplianceService (kalori bankası logic dahil)
→ Response döner

create ve update'e session inject edildi — kalori bankası hesapları için:
  - user_preferences → TDEE hesabı
  - body_measurements → son kilo
  - meal_compliance → son 7 günün banka bakiyesi

notes endpoint'inden farkı:
  - complied ve compliance_rate alanları
  - calories_consumed girişi
  - bank_message ve today_max_calories response'da döner
"""