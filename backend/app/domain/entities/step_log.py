from dataclasses import dataclass
from datetime import datetime, date
from typing import Optional


@dataclass
class StepLog:
    id: str
    user_id: str
    date: date
    step_count: int
    target_steps: int = 10000
    distance_km: Optional[float] = None
    calories_burned: Optional[float] = None
    created_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
StepLog domain entity — saf Python, hiçbir dış bağımlılık yok.

distance_km     = step_count × 0.000762
calories_burned = step_count × 0.04

Spring Boot karşılığı: @Entity sınıfı ama sadece alan tanımları.
"""