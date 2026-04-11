from abc import ABC, abstractmethod
from datetime import date
from typing import List, Optional

from backend.app.domain.entities.step_log import StepLog


class IStepLogRepository(ABC):

    @abstractmethod
    async def create(self, user_id: str, log_date: date, step_count: int,
                     target_steps: int, distance_km: Optional[float],
                     calories_burned: Optional[float]) -> StepLog:
        pass

    @abstractmethod
    async def get_by_date(self, user_id: str, log_date: date) -> Optional[StepLog]:
        pass

    @abstractmethod
    async def get_range(self, user_id: str, start_date: date, end_date: date) -> List[StepLog]:
        pass


"""
DOSYA AKIŞI:
IStepLogRepository adım sayar için repository sözleşmesini tanımlar.
Spring Boot karşılığı: Repository interface.
"""