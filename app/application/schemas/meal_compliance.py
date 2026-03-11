from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional


class MealComplianceCreateRequest(BaseModel):
    # Yeni diyet uyum kaydı oluşturma isteği
    date: date                                                      # Zorunlu — hangi güne ait
    complied: bool                                                  # Zorunlu — diyete uyuldu mu?
    compliance_rate: Optional[float] = Field(None, ge=0, le=100)   # 0-100 arası, opsiyonel
    notes: Optional[str] = None                                     # Opsiyonel açıklama


class MealComplianceUpdateRequest(BaseModel):
    # Kayıt güncelleme isteği — date güncellenemez
    complied: Optional[bool] = None
    compliance_rate: Optional[float] = Field(None, ge=0, le=100)
    notes: Optional[str] = None


class MealComplianceResponse(BaseModel):
    # API'den dönecek diyet uyum verisi
    id: str
    user_id: str
    date: date
    complied: bool
    compliance_rate: Optional[float]
    notes: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True  # ORM modelinden direkt dönüşüm için

"""
NoteCreateRequest'ten farkı:
complied: bool → zorunlu, True/False
compliance_rate: float → ge=0, le=100 (0-100 arası)
notes opsiyonel — content gibi zorunlu değil

ge=0 → 0'dan küçük olamaz
le=100 → 100'den büyük olamaz
Pydantic bu kontrolü otomatik yapar, 422 döner.
"""