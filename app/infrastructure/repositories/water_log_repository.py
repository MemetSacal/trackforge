# Interface'in somut implementasyonu — gerçek DB işlemleri burada
import uuid
from datetime import date, datetime
from typing import Optional, List

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.water_log import WaterLog
from app.domain.interfaces.i_water_log_repository import IWaterLogRepository
from app.infrastructure.db.models.water_log_model import WaterLogModel


class WaterLogRepository(IWaterLogRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Entity → Model dönüşümü (DB'ye yazarken) ──
    def _to_model(self, entity: WaterLog) -> WaterLogModel:
        return WaterLogModel(
            id=entity.id,
            user_id=entity.user_id,
            date=entity.date,
            amount_ml=entity.amount_ml,
            target_ml=entity.target_ml,
            created_at=entity.created_at,
        )

    # ── Model → Entity dönüşümü (DB'den okurken) ──
    def _to_entity(self, model: WaterLogModel) -> WaterLog:
        return WaterLog(
            id=model.id,
            user_id=model.user_id,
            date=model.date,
            amount_ml=model.amount_ml,
            target_ml=model.target_ml,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    async def create(self, water_log: WaterLog) -> WaterLog:
        # Yeni UUID ata ve modeli kaydet
        water_log.id = str(uuid.uuid4())
        water_log.created_at = datetime.utcnow()
        model = self._to_model(water_log)
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def get_by_id(self, log_id: str, user_id: str) -> Optional[WaterLog]:
        # Ownership kontrolü — başkasının kaydına erişilemesin
        result = await self.db.execute(
            select(WaterLogModel).where(
                and_(WaterLogModel.id == log_id, WaterLogModel.user_id == user_id)
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_by_date(self, user_id: str, log_date: date) -> Optional[WaterLog]:
        # Belirli bir güne ait kaydı getir
        result = await self.db.execute(
            select(WaterLogModel).where(
                and_(
                    WaterLogModel.user_id == user_id,
                    WaterLogModel.date == log_date,
                )
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    async def get_by_date_range(
        self, user_id: str, start_date: date, end_date: date
    ) -> List[WaterLog]:
        # Tarih aralığındaki tüm kayıtları tarihe göre sıralı getir
        result = await self.db.execute(
            select(WaterLogModel)
            .where(
                and_(
                    WaterLogModel.user_id == user_id,
                    WaterLogModel.date >= start_date,
                    WaterLogModel.date <= end_date,
                )
            )
            .order_by(WaterLogModel.date.asc())
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    async def update(self, water_log: WaterLog) -> WaterLog:
        # Mevcut kaydı güncelle
        result = await self.db.execute(
            select(WaterLogModel).where(
                and_(
                    WaterLogModel.id == water_log.id,
                    WaterLogModel.user_id == water_log.user_id,
                )
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None
        # Sadece güncellenebilir alanları değiştir
        model.amount_ml = water_log.amount_ml
        model.target_ml = water_log.target_ml
        model.date = water_log.date
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    async def delete(self, log_id: str, user_id: str) -> bool:
        result = await self.db.execute(
            select(WaterLogModel).where(
                and_(WaterLogModel.id == log_id, WaterLogModel.user_id == user_id)
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
WaterLogRepository, IWaterLogRepository interface'ini implement eder.
_to_model / _to_entity metodları domain ile infrastructure arasındaki köprüdür.
Tüm işlemler async — commit() yok, flush() var (Service katmanı commit eder).
get_by_date: bir kullanıcının aynı güne birden fazla kayıt girmesini önlemek için kullanılır.

Spring Boot karşılığı: @Repository anotasyonlu class.
"""