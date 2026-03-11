from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional


class NoteCreateRequest(BaseModel):
    # Yeni not oluşturma isteği
    date: date                                              # Zorunlu — hangi güne ait
    content: str = Field(..., min_length=1)                 # Zorunlu — boş not olamaz
    title: Optional[str] = None                            # Opsiyonel başlık
    energy_level: Optional[int] = Field(None, ge=1, le=10) # 1-10 arası, opsiyonel
    mood_score: Optional[int] = Field(None, ge=1, le=10)   # 1-10 arası, opsiyonel


class NoteUpdateRequest(BaseModel):
    # Not güncelleme isteği — date güncellenemez
    content: Optional[str] = Field(None, min_length=1)
    title: Optional[str] = None
    energy_level: Optional[int] = Field(None, ge=1, le=10)
    mood_score: Optional[int] = Field(None, ge=1, le=10)


class NoteResponse(BaseModel):
    # API'den dönecek not verisi
    id: str
    user_id: str
    date: date
    title: Optional[str]
    content: str
    energy_level: Optional[int]
    mood_score: Optional[int]
    created_at: datetime

    class Config:
        from_attributes = True  # ORM modelinden direkt dönüşüm için

"""
Field(..., min_length=1) ne demek?
  ... → required, boş geçilemez
  min_length=1 → en az 1 karakter olmalı, boş string "" geçersiz

ge=1, le=10 → 1'den küçük veya 10'dan büyük değer gelirse
Pydantic otomatik 422 döner, servis katmanına hiç ulaşmaz.

Genel akış:
Request → NoteCreateRequest validate → NoteService → NoteResponse döner
"""