from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional


class MeasurementCreateRequest(BaseModel):
    # Yeni ölçüm oluşturma isteği — tüm ölçüm alanları opsiyonel
    date: date                                    # Zorunlu — hangi güne ait
    weight_kg: Optional[float] = Field(None, gt=0, lt=500)   # 0'dan büyük, 500'den küçük olmalı
    body_fat_pct: Optional[float] = Field(None, ge=0, le=100) # 0-100 arası yüzde
    muscle_mass_kg: Optional[float] = Field(None, gt=0)
    waist_cm: Optional[float] = Field(None, gt=0)
    chest_cm: Optional[float] = Field(None, gt=0)
    hip_cm: Optional[float] = Field(None, gt=0)
    arm_cm: Optional[float] = Field(None, gt=0)
    leg_cm: Optional[float] = Field(None, gt=0)


class MeasurementUpdateRequest(BaseModel):
    # Mevcut ölçümü güncelleme isteği — create ile aynı alanlar
    # date güncellenemez — aynı güne ait kayıt kalır
    weight_kg: Optional[float] = Field(None, gt=0, lt=500)
    body_fat_pct: Optional[float] = Field(None, ge=0, le=100)
    muscle_mass_kg: Optional[float] = Field(None, gt=0)
    waist_cm: Optional[float] = Field(None, gt=0)
    chest_cm: Optional[float] = Field(None, gt=0)
    hip_cm: Optional[float] = Field(None, gt=0)
    arm_cm: Optional[float] = Field(None, gt=0)
    leg_cm: Optional[float] = Field(None, gt=0)


class MeasurementResponse(BaseModel):
    # API'den dönecek ölçüm verisi
    id: str
    user_id: str
    date: date
    weight_kg: Optional[float]
    body_fat_pct: Optional[float]
    muscle_mass_kg: Optional[float]
    waist_cm: Optional[float]
    chest_cm: Optional[float]
    hip_cm: Optional[float]
    arm_cm: Optional[float]
    leg_cm: Optional[float]
    created_at: datetime

    class Config:
        from_attributes = True  # ORM modelinden direkt dönüşüm için

"""
Field(None, gt=0) ne demek?
  None  → default değer, girilmezse None olur
  gt=0  → greater than 0, yani 0'dan büyük olmalı
  ge=0  → greater or equal 0, yani 0 veya büyük olmalı
  le=100 → less or equal 100

Pydantic bu validasyonları otomatik yapar.
Geçersiz değer gelirse 422 Unprocessable Entity döner, servis katmanına hiç ulaşmaz.

Genel akış:
Request → MeasurementCreateRequest validate → MeasurementService → MeasurementResponse döner
"""