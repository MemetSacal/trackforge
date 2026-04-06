import uuid
from datetime import datetime, timezone, date
from typing import List, Optional

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.menstrual_cycle import MenstrualCycle
from app.domain.interfaces.i_menstrual_cycle_repository import IMenstrualCycleRepository
from app.infrastructure.db.models.menstrual_cycle_model import MenstrualCycleModel


class MenstrualCycleRepository(IMenstrualCycleRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    def _to_entity(self, model: MenstrualCycleModel) -> MenstrualCycle:
        return MenstrualCycle(
            id=model.id,
            user_id=model.user_id,
            cycle_start_date=model.cycle_start_date,
            cycle_length_days=model.cycle_length_days,
            period_length_days=model.period_length_days,
            notes=model.notes,
            created_at=model.created_at,
        )

    async def create(self, user_id: str, cycle_start_date: date,
                     cycle_length_days: int, period_length_days: int,
                     notes: Optional[str]) -> MenstrualCycle:
        model = MenstrualCycleModel(
            id=str(uuid.uuid4()),
            user_id=user_id,
            cycle_start_date=cycle_start_date,
            cycle_length_days=cycle_length_days,
            period_length_days=period_length_days,
            notes=notes,
        )
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def get_current(self, user_id: str) -> Optional[MenstrualCycle]:
        # En son başlayan döngüyü getir
        result = await self.db.execute(
            select(MenstrualCycleModel)
            .where(MenstrualCycleModel.user_id == user_id)
            .order_by(MenstrualCycleModel.cycle_start_date.desc())
            .limit(1)
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_history(self, user_id: str) -> List[MenstrualCycle]:
        # Tüm döngü geçmişi — en yeniden en eskiye
        result = await self.db.execute(
            select(MenstrualCycleModel)
            .where(MenstrualCycleModel.user_id == user_id)
            .order_by(MenstrualCycleModel.cycle_start_date.desc())
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    async def update(self, cycle_id: str, user_id: str, **kwargs) -> Optional[MenstrualCycle]:
        result = await self.db.execute(
            select(MenstrualCycleModel).where(
                MenstrualCycleModel.id == cycle_id,
                MenstrualCycleModel.user_id == user_id,
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None

        # Gelen alanları güncelle
        for key, value in kwargs.items():
            if value is not None:
                setattr(model, key, value)

        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)


"""
DOSYA AKIŞI:
MenstrualCycleRepository regl takvimi CRUD işlemlerini yönetir.

get_current → en son başlayan döngüyü getirir (AI faz hesabı için)
get_history → tüm geçmiş döngüler
update      → kwargs ile esnek güncelleme

Spring Boot karşılığı: @Repository.
"""