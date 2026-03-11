from dataclasses import dataclass
from datetime import date, datetime
from typing import Optional


@dataclass
class MealCompliance:
    # Domain entity — günlük diyet uyum kaydı
    # Kullanıcının o gün diyetine uyup uymadığını takip eder

    id: str
    user_id: str                        # FK — hangi kullanıcıya ait
    date: date                          # DATE_BASED zaman referansı
    complied: bool                      # Zorunlu — diyete uyuldu mu?
    compliance_rate: Optional[float]    # 0-100 arası uyum yüzdesi, opsiyonel
    notes: Optional[str]                # Opsiyonel açıklama — neden uymadı vs.
    created_at: datetime