from datetime import date
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.cycle import CycleCreateSchema, CycleUpdateSchema, CycleResponse
from app.infrastructure.repositories.menstrual_cycle_repository import MenstrualCycleRepository


# ── Faz hesaplama yardımcısı ──
def _calculate_phase(cycle_start: date, cycle_length: int, period_length: int) -> tuple:
    today = date.today()
    delta = (today - cycle_start).days % cycle_length
    current_day = delta + 1  # 1-bazlı

    if current_day <= period_length:
        phase = "Menstrüasyon"
    elif current_day <= 13:
        phase = "Foliküler"
    elif current_day <= 16:
        phase = "Ovülasyon"
    else:
        phase = "Luteal"

    return phase, current_day


class CycleService:

    def __init__(self, db: AsyncSession):
        self.repo = MenstrualCycleRepository(db)
        self.db = db

    def _to_response(self, cycle, include_phase: bool = False) -> CycleResponse:
        phase, day = None, None
        if include_phase:
            phase, day = _calculate_phase(
                cycle.cycle_start_date,
                cycle.cycle_length_days,
                cycle.period_length_days,
            )
        return CycleResponse(
            id=cycle.id,
            user_id=cycle.user_id,
            cycle_start_date=cycle.cycle_start_date,
            cycle_length_days=cycle.cycle_length_days,
            period_length_days=cycle.period_length_days,
            notes=cycle.notes,
            created_at=cycle.created_at,
            current_phase=phase,
            current_day=day,
        )

    async def create(self, user_id: str, body: CycleCreateSchema) -> CycleResponse:
        cycle = await self.repo.create(
            user_id=user_id,
            cycle_start_date=body.cycle_start_date,
            cycle_length_days=body.cycle_length_days,
            period_length_days=body.period_length_days,
            notes=body.notes,
        )
        await self.db.commit()
        return self._to_response(cycle, include_phase=True)

    async def get_current(self, user_id: str) -> Optional[CycleResponse]:
        cycle = await self.repo.get_current(user_id)
        return self._to_response(cycle, include_phase=True) if cycle else None

    async def get_history(self, user_id: str) -> List[CycleResponse]:
        cycles = await self.repo.get_history(user_id)
        return [self._to_response(c) for c in cycles]

    async def update(self, cycle_id: str, user_id: str, body: CycleUpdateSchema) -> CycleResponse:
        cycle = await self.repo.update(
            cycle_id=cycle_id,
            user_id=user_id,
            cycle_length_days=body.cycle_length_days,
            period_length_days=body.period_length_days,
            notes=body.notes,
        )
        if not cycle:
            raise ValueError("Döngü kaydı bulunamadı.")
        await self.db.commit()
        return self._to_response(cycle, include_phase=True)


"""
DOSYA AKIŞI:
CycleService regl takvimi iş mantığını yönetir.

_calculate_phase → bugünün döngü fazını hesaplar:
  Menstrüasyon : gün 1 → period_length_days
  Foliküler    : gün period_length_days+1 → 13
  Ovülasyon    : gün 14 → 16
  Luteal       : gün 17 → cycle_length_days

include_phase=True → current_phase ve current_day response'a eklenir
Spring Boot karşılığı: @Service.
"""