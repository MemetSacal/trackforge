from datetime import date, time
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.sleep import SleepLogCreate, SleepLogUpdate, SleepLogResponse
from backend.app.core.exceptions import NotFoundException, ConflictException
from backend.app.domain.entities.sleep_log import SleepLog
from backend.app.infrastructure.repositories.sleep_log_repository import SleepLogRepository


class SleepService:

    def __init__(self, db: AsyncSession):
        self.repo = SleepLogRepository(db)
        self.db = db

    # ── Yardımcı: sleep_time ve wake_time'dan duration hesapla ──
    def _calculate_duration(
        self, sleep_time: Optional[time], wake_time: Optional[time]
    ) -> Optional[float]:
        if not sleep_time or not wake_time:
            return None
        # Gece yarısını geçen uyku — örn: 23:00 yat, 07:00 kalk
        sleep_minutes = sleep_time.hour * 60 + sleep_time.minute
        wake_minutes = wake_time.hour * 60 + wake_time.minute
        if wake_minutes < sleep_minutes:
            # Gece yarısını geçti — 24 saat ekle
            wake_minutes += 24 * 60
        duration = (wake_minutes - sleep_minutes) / 60
        return round(duration, 2)

    # ── Yardımcı: entity → response ──
    def _to_response(self, entity: SleepLog) -> SleepLogResponse:
        return SleepLogResponse(
            id=entity.id,
            user_id=entity.user_id,
            date=entity.date,
            sleep_time=entity.sleep_time,
            wake_time=entity.wake_time,
            duration_hours=entity.duration_hours,
            quality_score=entity.quality_score,
            notes=entity.notes,
            created_at=entity.created_at,
            updated_at=entity.updated_at,
        )

    async def create(self, user_id: str, data: SleepLogCreate) -> SleepLogResponse:
        # Aynı gün için zaten kayıt var mı kontrol et
        existing = await self.repo.get_by_date(user_id, data.date)
        if existing:
            raise ConflictException("Bu tarihe ait uyku kaydı zaten mevcut.")

        # sleep_time ve wake_time varsa duration otomatik hesapla
        duration = data.duration_hours
        if not duration and data.sleep_time and data.wake_time:
            duration = self._calculate_duration(data.sleep_time, data.wake_time)

        entity = SleepLog(
            id="",
            user_id=user_id,
            date=data.date,
            sleep_time=data.sleep_time,
            wake_time=data.wake_time,
            duration_hours=duration,
            quality_score=data.quality_score,
            notes=data.notes,
            created_at=None,
        )
        created = await self.repo.create(entity)
        await self.db.commit()
        return self._to_response(created)

    async def get_by_date(self, user_id: str, log_date: date) -> SleepLogResponse:
        entity = await self.repo.get_by_date(user_id, log_date)
        if not entity:
            raise NotFoundException("Bu tarihe ait uyku kaydı bulunamadı.")
        return self._to_response(entity)

    async def get_by_date_range(
        self, user_id: str, start_date: date, end_date: date
    ) -> List[SleepLogResponse]:
        entities = await self.repo.get_by_date_range(user_id, start_date, end_date)
        return [self._to_response(e) for e in entities]

    async def update(self, log_id: str, user_id: str, data: SleepLogUpdate) -> SleepLogResponse:
        entity = await self.repo.get_by_id(log_id, user_id)
        if not entity:
            raise NotFoundException("Uyku kaydı bulunamadı.")

        # Partial update — None ise eskiyi koru
        entity.date = data.date if data.date is not None else entity.date
        entity.sleep_time = data.sleep_time if data.sleep_time is not None else entity.sleep_time
        entity.wake_time = data.wake_time if data.wake_time is not None else entity.wake_time
        entity.quality_score = data.quality_score if data.quality_score is not None else entity.quality_score
        entity.notes = data.notes if data.notes is not None else entity.notes

        # duration'ı yeniden hesapla — sleep/wake değiştiyse
        if data.duration_hours is not None:
            entity.duration_hours = data.duration_hours
        elif data.sleep_time or data.wake_time:
            entity.duration_hours = self._calculate_duration(
                entity.sleep_time, entity.wake_time
            )

        updated = await self.repo.update(entity)
        await self.db.commit()
        return self._to_response(updated)

    async def delete(self, log_id: str, user_id: str) -> None:
        deleted = await self.repo.delete(log_id, user_id)
        if not deleted:
            raise NotFoundException("Uyku kaydı bulunamadı.")
        await self.db.commit()


"""
DOSYA AKIŞI:
SleepService'in water'dan farkı: _calculate_duration metodu.
sleep_time=23:00, wake_time=07:00 → gece yarısını geçiyor → 8 saat hesaplar.
Kullanıcı duration_hours manuel girdiyse onu kullanır, girmemişse otomatik hesaplar.

Spring Boot karşılığı: @Service anotasyonlu class.
"""