# İş mantığı burada — controller ile repository arasındaki köprü
from datetime import date
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.water import WaterLogCreate, WaterLogUpdate, WaterLogResponse
from backend.app.core.exceptions import NotFoundException, ConflictException
from backend.app.domain.entities.water_log import WaterLog
from backend.app.infrastructure.repositories.water_log_repository import WaterLogRepository


class WaterService:

    def __init__(self, db: AsyncSession):
        # Repository bağımlılığı — sadece interface üzerinden konuşabiliriz
        self.repo = WaterLogRepository(db)
        self.db = db

    # ── Yardımcı: entity → response dönüşümü ──
    def _to_response(self, entity: WaterLog) -> WaterLogResponse:
        # Yüzde doluluk hesapla
        percentage = round((entity.amount_ml / entity.target_ml) * 100, 1)
        return WaterLogResponse(
            id=entity.id,
            user_id=entity.user_id,
            date=entity.date,
            amount_ml=entity.amount_ml,
            target_ml=entity.target_ml,
            percentage=min(percentage, 100.0),  # 100'ü aşmasın
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )

    async def create(self, user_id: str, data: WaterLogCreate) -> WaterLogResponse:
        # Aynı gün için zaten kayıt var mı kontrol et
        existing = await self.repo.get_by_date(user_id, data.date)
        if existing:
            raise ConflictException("Bu tarihe ait su kaydı zaten mevcut.")

        entity = WaterLog(
            id="",  # repository UUID atayacak
            user_id=user_id,
            date=data.date,
            amount_ml=data.amount_ml,
            target_ml=data.target_ml,
            created_at=None,
        )
        created = await self.repo.create(entity)
        await self.db.commit()
        return self._to_response(created)

    async def get_by_date(self, user_id: str, log_date: date) -> WaterLogResponse:
        entity = await self.repo.get_by_date(user_id, log_date)
        if not entity:
            raise NotFoundException("Bu tarihe ait su kaydı bulunamadı.")
        return self._to_response(entity)

    async def get_by_date_range(
        self, user_id: str, start_date: date, end_date: date
    ) -> List[WaterLogResponse]:
        entities = await self.repo.get_by_date_range(user_id, start_date, end_date)
        return [self._to_response(e) for e in entities]

    async def update(self, log_id: str, user_id: str, data: WaterLogUpdate) -> WaterLogResponse:
        # Önce mevcut kaydı getir
        entity = await self.repo.get_by_id(log_id, user_id)
        if not entity:
            raise NotFoundException("Su kaydı bulunamadı.")

        # Sadece gönderilen alanları güncelle (partial update)
        entity.amount_ml = data.amount_ml if data.amount_ml is not None else entity.amount_ml
        entity.target_ml = data.target_ml if data.target_ml is not None else entity.target_ml
        entity.date = data.date if data.date is not None else entity.date

        updated = await self.repo.update(entity)
        await self.db.commit()
        return self._to_response(updated)

    async def delete(self, log_id: str, user_id: str) -> None:
        # 404 döndür — 403 değil (güvenlik için ownership gizle)
        deleted = await self.repo.delete(log_id, user_id)
        if not deleted:
            raise NotFoundException("Su kaydı bulunamadı.")
        await self.db.commit()


"""
DOSYA AKIŞI:
WaterService tüm iş mantığını yönetir:
  - Aynı güne çift kayıt engeli (ConflictException)
  - percentage hesabı (amount/target * 100, max 100)
  - Partial update pattern (None ise eskiyi koru)
  - Ownership kontrolü 404 ile (403 değil)

Spring Boot karşılığı: @Service anotasyonlu class.
"""