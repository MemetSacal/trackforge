# Pydantic şemaları — HTTP request/response veri doğrulaması
from datetime import date, datetime
from typing import Optional

from pydantic import BaseModel, Field


# ── İstek şemaları (request) ──

class WaterLogCreate(BaseModel):
    # Su kaydı oluştururken gönderilecek alanlar
    date: date
    amount_ml: int = Field(..., gt=0, le=10000, description="İçilen su miktarı (ml)")
    target_ml: int = Field(default=2800, gt=0, le=10000, description="Günlük hedef (ml)")


class WaterLogUpdate(BaseModel):
    # Kısmi güncelleme — hiçbir alan zorunlu değil
    amount_ml: Optional[int] = Field(None, gt=0, le=10000)
    target_ml: Optional[int] = Field(None, gt=0, le=10000)
    date: Optional[date] = None


# ── Yanıt şeması (response) ──

class WaterLogResponse(BaseModel):
    id: str
    user_id: str
    date: date
    amount_ml: int
    target_ml: int
    # Hesaplanan alan — yüzde doluluk
    percentage: float
    created_at: datetime
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


"""
DOSYA AKIŞI:
WaterLogCreate  → POST isteğinde body olarak gelir
WaterLogUpdate  → PUT isteğinde body olarak gelir (tüm alanlar opsiyonel)
WaterLogResponse → her endpoint'in döndürdüğü yanıt

percentage: amount_ml / target_ml * 100 — service katmanında hesaplanır.

Spring Boot karşılığı: DTO (Data Transfer Object) sınıfları.
"""