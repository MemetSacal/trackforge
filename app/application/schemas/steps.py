from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel


class StepLogCreateSchema(BaseModel):
    date: date
    step_count: int
    target_steps: int = 10000
    distance_km: Optional[float] = None
    calories_burned: Optional[float] = None


class StepLogResponse(BaseModel):
    id: str
    user_id: str
    date: date
    step_count: int
    target_steps: int
    distance_km: Optional[float] = None
    calories_burned: Optional[float] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


"""
DOSYA AKIŞI:
StepLogCreateSchema → POST /steps body'si
StepLogResponse     → response modeli

distance_km ve calories_burned opsiyonel —
Flutter göndermezse backend otomatik hesaplar.
Spring Boot karşılığı: DTO sınıfları.
"""