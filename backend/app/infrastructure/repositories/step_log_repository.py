import uuid
from datetime import datetime, timezone, date
from typing import List, Optional

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.domain.entities.step_log import StepLog
from backend.app.domain.interfaces.i_step_log_repository import IStepLogRepository
from backend.app.infrastructure.db.models.step_log_model import StepLogModel


class StepLogRepository(IStepLogRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    def _to_entity(self, model: StepLogModel) -> StepLog:
        return StepLog(
            id=model.id,
            user_id=model.user_id,
            date=model.date,
            step_count=model.step_count,
            target_steps=model.target_steps,
            distance_km=model.distance_km,
            calories_burned=model.calories_burned,
            created_at=model.created_at,
        )

    async def create(self, user_id: str, log_date: date, step_count: int,
                     target_steps: int, distance_km: Optional[float],
                     calories_burned: Optional[float]) -> StepLog:
        # Otomatik hesapla — Flutter göndermezse backend hesaplar
        if distance_km is None:
            distance_km = round(step_count * 0.000762, 2)
        if calories_burned is None:
            calories_burned = round(step_count * 0.04, 1)

        model = StepLogModel(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=log_date,
            step_count=step_count,
            target_steps=target_steps,
            distance_km=distance_km,
            calories_burned=calories_burned,
        )
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def get_by_date(self, user_id: str, log_date: date) -> Optional[StepLog]:
        result = await self.db.execute(
            select(StepLogModel).where(
                and_(
                    StepLogModel.user_id == user_id,
                    StepLogModel.date == log_date,
                )
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_range(self, user_id: str, start_date: date, end_date: date) -> List[StepLog]:
        result = await self.db.execute(
            select(StepLogModel).where(
                and_(
                    StepLogModel.user_id == user_id,
                    StepLogModel.date >= start_date,
                    StepLogModel.date <= end_date,
                )
            ).order_by(StepLogModel.date.desc())
        )
        return [self._to_entity(m) for m in result.scalars().all()]


"""
DOSYA AKIŞI:
StepLogRepository adım sayar CRUD işlemlerini yönetir.

create → distance_km ve calories_burned otomatik hesaplanır
  distance_km     = step_count × 0.000762
  calories_burned = step_count × 0.04

Spring Boot karşılığı: @Repository.
"""