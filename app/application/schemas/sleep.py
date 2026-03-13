from datetime import date, datetime, time
from typing import Optional

from pydantic import BaseModel, Field


# ── İstek şemaları ──

class SleepLogCreate(BaseModel):
    date: date
    sleep_time: Optional[time] = None                                    # "23:30:00"
    wake_time: Optional[time] = None                                     # "07:15:00"
    duration_hours: Optional[float] = Field(None, gt=0, le=24)          # Manuel giriş
    quality_score: Optional[int] = Field(None, ge=1, le=10)             # 1-10 arası
    notes: Optional[str] = None


class SleepLogUpdate(BaseModel):
    # Tüm alanlar opsiyonel — partial update
    date: Optional[date] = None
    sleep_time: Optional[time] = None
    wake_time: Optional[time] = None
    duration_hours: Optional[float] = Field(None, gt=0, le=24)
    quality_score: Optional[int] = Field(None, ge=1, le=10)
    notes: Optional[str] = None


# ── Yanıt şeması ──

class SleepLogResponse(BaseModel):
    id: str
    user_id: str
    date: date
    sleep_time: Optional[time] = None
    wake_time: Optional[time] = None
    duration_hours: Optional[float] = None
    quality_score: Optional[int] = None
    notes: Optional[str] = None
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


"""
DOSYA AKIŞI:
SleepLogCreate  → POST isteğinde body
SleepLogUpdate  → PUT isteğinde body (tüm alanlar opsiyonel)
SleepLogResponse → tüm endpoint'lerin döndürdüğü yanıt

sleep_time / wake_time: Pydantic time tipini "HH:MM:SS" formatında kabul eder.
duration_hours: le=24 ile max 24 saate sınırlandırıldı.
quality_score: ge=1, le=10 ile 1-10 arasına sınırlandırıldı.

Spring Boot karşılığı: DTO sınıfları.
"""