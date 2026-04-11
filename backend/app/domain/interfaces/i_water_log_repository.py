# Repository sözleşmesi — infrastructure ne yaparsa yapsın bu interface sabit kalır
from abc import ABC, abstractmethod
from datetime import date
from typing import Optional, List

from backend.app.domain.entities.water_log import WaterLog


class IWaterLogRepository(ABC):

    @abstractmethod
    async def create(self, water_log: WaterLog) -> WaterLog:
        pass

    @abstractmethod
    async def get_by_id(self, log_id: str, user_id: str) -> Optional[WaterLog]:
        pass

    @abstractmethod
    async def get_by_date(self, user_id: str, log_date: date) -> Optional[WaterLog]:
        # Bir kullanıcının belirli bir güne ait su kaydını getirir
        pass

    @abstractmethod
    async def get_by_date_range(
        self, user_id: str, start_date: date, end_date: date
    ) -> List[WaterLog]:
        pass

    @abstractmethod
    async def update(self, water_log: WaterLog) -> WaterLog:
        pass

    @abstractmethod
    async def delete(self, log_id: str, user_id: str) -> bool:
        pass


"""
DOSYA AKIŞI:
Abstract base class olarak tanımlanan repository interface'i.
WaterLogRepository (infrastructure) bu class'ı implement eder.
WaterService (application) ise sadece bu interface'i bilir — implementasyonu bilmez.

Spring Boot karşılığı: JpaRepository'yi extend eden interface.
"""