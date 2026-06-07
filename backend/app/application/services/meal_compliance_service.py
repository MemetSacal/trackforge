from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional


class MealComplianceCreateRequest(BaseModel):
    date: date
    # ── complied KALDIRILDI — sistem otomatik belirliyor ──
    notes: Optional[str] = None
    calories_consumed: Optional[float] = Field(None, ge=0, description="O gün alınan toplam kalori")


class MealComplianceUpdateRequest(BaseModel):
    notes: Optional[str] = None
    calories_consumed: Optional[float] = Field(None, ge=0)


class MealComplianceResponse(BaseModel):
    id: str
    user_id: str
    date: date
    complied: bool                          # sistem otomatik belirler
    compliance_rate: Optional[float] = None

    notes: Optional[str] = None
    calories_consumed: Optional[float] = None
    calories_burned: Optional[float] = None  # ← YENİ: o günkü egzersiz kalorisi
    calories_target: Optional[float] = None
    calorie_balance: Optional[float] = None
    weekly_bank_balance: Optional[float] = None

    bank_message: Optional[str] = None
    today_max_calories: Optional[float] = None

    created_at: datetime

    class Config:
        from_attributes = True