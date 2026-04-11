from abc import ABC, abstractmethod
from typing import List, Optional

from backend.app.domain.entities.menstrual_cycle import MenstrualCycle


class IMenstrualCycleRepository(ABC):

    @abstractmethod
    async def create(self, user_id: str, cycle_start_date, cycle_length_days: int,
                     period_length_days: int, notes: Optional[str]) -> MenstrualCycle:
        pass

    @abstractmethod
    async def get_current(self, user_id: str) -> Optional[MenstrualCycle]:
        pass

    @abstractmethod
    async def get_history(self, user_id: str) -> List[MenstrualCycle]:
        pass

    @abstractmethod
    async def update(self, cycle_id: str, user_id: str, **kwargs) -> Optional[MenstrualCycle]:
        pass


"""
DOSYA AKIŞI:
IMenstrualCycleRepository regl takvimi için repository sözleşmesini tanımlar.
Spring Boot karşılığı: Repository interface.
"""