from abc import ABC, abstractmethod
from datetime import date
from typing import Optional, List

from app.domain.entities.sleep_log import SleepLog


class ISleepLogRepository(ABC):

    @abstractmethod
    async def create(self, sleep_log: SleepLog) -> SleepLog:
        pass

    @abstractmethod
    async def get_by_id(self, log_id: str, user_id: str) -> Optional[SleepLog]:
        pass

    @abstractmethod
    async def get_by_date(self, user_id: str, log_date: date) -> Optional[SleepLog]:
        # Bir kullanıcının belirli bir geceye ait uyku kaydını getirir
        pass

    @abstractmethod
    async def get_by_date_range(
        self, user_id: str, start_date: date, end_date: date
    ) -> List[SleepLog]:
        pass

    @abstractmethod
    async def update(self, sleep_log: SleepLog) -> SleepLog:
        pass

    @abstractmethod
    async def delete(self, log_id: str, user_id: str) -> bool:
        pass


"""
DOSYA AKIŞI:
Abstract base class — SleepLogRepository bu interface'i implement eder.
SleepService sadece bu interface'i bilir, implementasyonu bilmez.

Spring Boot karşılığı: JpaRepository'yi extend eden interface.
"""