from abc import ABC, abstractmethod
from datetime import date
from typing import Optional
from app.domain.entities.weekly_note import WeeklyNote


class INoteRepository(ABC):
    # Abstract repository interface — IMeasurementRepository ile aynı mantık

    @abstractmethod
    async def create(self, note: WeeklyNote) -> WeeklyNote:
        pass

    @abstractmethod
    async def get_by_id(self, note_id: str) -> Optional[WeeklyNote]:
        pass

    @abstractmethod
    async def get_by_date(self, user_id: str, target_date: date) -> Optional[WeeklyNote]:
        # Belirli bir günün notu — günde 1 not mantığı
        pass

    @abstractmethod
    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[WeeklyNote]:
        pass

    @abstractmethod
    async def update(self, note: WeeklyNote) -> WeeklyNote:
        pass

    @abstractmethod
    async def delete(self, note_id: str) -> bool:
        pass

"""
Genel akış:
Service katmanı bu interface'i çağırır →
infrastructure/repositories/note_repository.py implement eder

IMeasurementRepository'den farkı:
get_all yok — notlar için tüm geçmiş yerine tarih aralığı yeterli.
"""