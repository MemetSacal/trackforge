from dataclasses import dataclass
from datetime import date, datetime
from typing import Optional


@dataclass
class MealCompliance:
    # Domain entity — günlük diyet uyum ve kalori takip kaydı
    id: str
    user_id: str                            # FK — hangi kullanıcıya ait
    date: date                              # DATE_BASED zaman referansı
    complied: bool                          # Zorunlu — diyete uyuldu mu?
    compliance_rate: Optional[float]        # 0-100 arası uyum yüzdesi, opsiyonel
    notes: Optional[str]                    # Opsiyonel açıklama

    # Kalori bankası sistemi
    calories_consumed: Optional[float]      # O gün alınan toplam kalori
    calories_target: Optional[float]        # O günün hedef kalorisi (TDEE bazlı)
    calorie_balance: Optional[float]        # consumed - target (+ fazla, - eksik)
    weekly_bank_balance: Optional[float]    # Son 7 günün birikimli dengesi

    created_at: datetime


"""
DOSYA AKIŞI:
calories_consumed → kullanıcının o gün girdiği kalori
calories_target   → TDEE - açık (kilo verme: -700, kas: +200)
calorie_balance   → consumed - target
weekly_bank_balance → son 7 günün birikimli dengesi (+ kredi, - borç)

Örnek:
  Hedef: 1600 kcal/gün
  Pazartesi: 1200 aldı → balance: -400, bank: +400 kredi
  Salı:      2000 aldı → balance: +400, bank: 0
  Çarşamba:  1400 aldı → balance: -200, bank: +200 kredi
"""