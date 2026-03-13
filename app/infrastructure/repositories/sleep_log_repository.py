import uuid
from datetime import date, datetime, time
from typing import Optional, List

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.sleep_log import SleepLog
from app.domain.interfaces.i_sleep_log_repository import ISleepLogRepository
from app.infrastructure.db.models.sleep_log_model import SleepLogModel


class SleepLogRepository(ISleepLogRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Entity → Model dönüşümü ──
    def _to_model(self, entity: SleepLog) -> SleepLogModel:
        return SleepLogModel(
            id=entity.id,
            user_id=entity.user_id,
            date=entity.date,
            sleep_time=entity.sleep_time,
            wake_time=entity.wake_time,
            duration_hours=entity.duration_hours,
            quality_score=entity.quality_score,
            notes=entity.notes,
            created_at=entity.created_at,
        )

    # ── Model → Entity dönüşümü ──
    def _to_entity(self, model: SleepLogModel) -> SleepLog:
        return SleepLog(
            id=model.id,
            user_id=model.user_id,
            date=model.date,
            sleep_time=model.sleep_time,
            wake_time=model.wake_time,
            duration_hours=model.duration_hours,
            quality_score=model.quality_score,
            notes=model.notes,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    async def create(self, sleep_log: SleepLog) -> SleepLog:
        sleep_log.id = str(uuid.uuid4())
        sleep_log.created_at = datetime.utcnow()
        model = self._to_model(sleep_log)
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def get_by_id(self, log_id: str, user_id: str) -> Optional[SleepLog]:
        # Ownership kontrolü — başkasının kaydına erişilemesin
        result = await self.db.execute(
            select(SleepLogModel).where(
                and_(SleepLogModel.id == log_id, SleepLogModel.user_id == user_id)
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_by_date(self, user_id: str, log_date: date) -> Optional[SleepLog]:
        result = await self.db.execute(
            select(SleepLogModel).where(
                and_(
                    SleepLogModel.user_id == user_id,
                    SleepLogModel.date == log_date,
                )
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_by_date_range(
        self, user_id: str, start_date: date, end_date: date
    ) -> List[SleepLog]:
        # Tarihe göre sıralı getir
        result = await self.db.execute(
            select(SleepLogModel)
            .where(
                and_(
                    SleepLogModel.user_id == user_id,
                    SleepLogModel.date >= start_date,
                    SleepLogModel.date <= end_date,
                )
            )
            .order_by(SleepLogModel.date.asc())
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    async def update(self, sleep_log: SleepLog) -> SleepLog:
        result = await self.db.execute(
            select(SleepLogModel).where(
                and_(
                    SleepLogModel.id == sleep_log.id,
                    SleepLogModel.user_id == sleep_log.user_id,
                )
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None
        # Sadece güncellenebilir alanları değiştir
        model.date = sleep_log.date
        model.sleep_time = sleep_log.sleep_time
        model.wake_time = sleep_log.wake_time
        model.duration_hours = sleep_log.duration_hours
        model.quality_score = sleep_log.quality_score
        model.notes = sleep_log.notes
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def delete(self, log_id: str, user_id: str) -> bool:
        result = await self.db.execute(
            select(SleepLogModel).where(
                and_(SleepLogModel.id == log_id, SleepLogModel.user_id == user_id)
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return False
        await self.db.delete(model)
        await self.db.flush()
        return True


"""
DOSYA AKIŞI:
SleepLogRepository, ISleepLogRepository interface'ini implement eder.
Water pattern'iyle birebir aynı yapı — tutarlılık için.

Spring Boot karşılığı: @Repository anotasyonlu class.
"""