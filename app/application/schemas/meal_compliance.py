from pydantic import BaseModel, Field
from datetime import date, datetime
from typing import Optional


class MealComplianceCreateRequest(BaseModel):
    # Yeni diyet uyum kaydı oluşturma isteği
    date: date
    complied: bool
    compliance_rate: Optional[float] = Field(None, ge=0, le=100)
    notes: Optional[str] = None

    # Kalori bankası için — opsiyonel, girilmezse hesaplanamaz
    calories_consumed: Optional[float] = Field(None, ge=0, description="O gün alınan toplam kalori")


class MealComplianceUpdateRequest(BaseModel):
    # Kayıt güncelleme isteği
    complied: Optional[bool] = None
    compliance_rate: Optional[float] = Field(None, ge=0, le=100)
    notes: Optional[str] = None
    calories_consumed: Optional[float] = Field(None, ge=0)


class MealComplianceResponse(BaseModel):
    # API'den dönecek diyet uyum verisi
    id: str
    user_id: str
    date: date
    complied: bool
    compliance_rate: Optional[float]
    notes: Optional[str]

    # Kalori bankası alanları
    calories_consumed: Optional[float] = None
    calories_target: Optional[float] = None
    calorie_balance: Optional[float] = None
    weekly_bank_balance: Optional[float] = None

    # Kalori bankası özeti — DB'ye yazılmaz, service'de hesaplanır
    bank_message: Optional[str] = None     # "Bu hafta 800 kalori krediniz var 🎉"
    today_max_calories: Optional[float] = None  # Bugün maksimum yiyebileceği kalori

    created_at: datetime

    class Config:
        from_attributes = True


"""
DOSYA AKIŞI:
calories_consumed → kullanıcı girer (ne yediğini bilir)
calories_target   → service hesaplar (TDEE - açık)
calorie_balance   → service hesaplar (consumed - target)
weekly_bank_balance → service hesaplar (son 7 gün toplamı)
bank_message      → AI'a gitmeden önce service'in ürettiği kısa mesaj
today_max_calories → bugün bankadan ne kadar harcayabileceği

Spring Boot karşılığı: DTO sınıfları.
"""