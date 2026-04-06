from datetime import date, datetime
from typing import Optional
from pydantic import BaseModel


class CycleCreateSchema(BaseModel):
    cycle_start_date: date
    cycle_length_days: int = 28
    period_length_days: int = 5
    notes: Optional[str] = None


class CycleUpdateSchema(BaseModel):
    cycle_length_days: Optional[int] = None
    period_length_days: Optional[int] = None
    notes: Optional[str] = None


class CycleResponse(BaseModel):
    id: str
    user_id: str
    cycle_start_date: date
    cycle_length_days: int
    period_length_days: int
    notes: Optional[str] = None
    created_at: Optional[datetime] = None
    current_phase: Optional[str] = None      # AI için — Menstrüasyon/Foliküler/Ovülasyon/Luteal
    current_day: Optional[int] = None        # Döngünün kaçıncı günü

    model_config = {"from_attributes": True}


"""
DOSYA AKIŞI:
CycleCreateSchema → POST /cycle body'si
CycleUpdateSchema → PUT /cycle/{id} body'si
CycleResponse     → response modeli

current_phase ve current_day → Flutter'da faz bilgisi göstermek için
AI antrenman/diyet önerisine de bu veri gönderilir.
Spring Boot karşılığı: DTO sınıfları.
"""