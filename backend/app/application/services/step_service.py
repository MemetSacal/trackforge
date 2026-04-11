from datetime import date
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.steps import StepLogCreateSchema, StepLogResponse
from backend.app.infrastructure.repositories.step_log_repository import StepLogRepository


class StepService:

    def __init__(self, db: AsyncSession):
        self.repo = StepLogRepository(db)
        self.db = db

    def _to_response(self, log) -> StepLogResponse:
        return StepLogResponse(
            id=log.id,
            user_id=log.user_id,
            date=log.date,
            step_count=log.step_count,
            target_steps=log.target_steps,
            distance_km=log.distance_km,
            calories_burned=log.calories_burned,
            created_at=log.created_at,
        )

    async def create(self, user_id: str, body: StepLogCreateSchema) -> StepLogResponse:
        log = await self.repo.create(
            user_id=user_id,
            log_date=body.date,
            step_count=body.step_count,
            target_steps=body.target_steps,
            distance_km=body.distance_km,
            calories_burned=body.calories_burned,
        )
        await self.db.commit()
        return self._to_response(log)

    async def get_by_date(self, user_id: str, log_date: date) -> Optional[StepLogResponse]:
        log = await self.repo.get_by_date(user_id, log_date)
        return self._to_response(log) if log else None

    async def get_range(self, user_id: str, start_date: date, end_date: date) -> List[StepLogResponse]:
        logs = await self.repo.get_range(user_id, start_date, end_date)
        return [self._to_response(l) for l in logs]


"""
DOSYA AKIŞI:
StepService adım sayar iş mantığını yönetir.
Her write işlemi sonunda db.commit() çağrılır.
Spring Boot karşılığı: @Service.
"""