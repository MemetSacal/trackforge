from dataclasses import dataclass
from datetime import date, datetime
from typing import Optional


@dataclass
class WeeklyNote:
    # Domain entity — SQLAlchemy'den bağımsız, saf Python sınıfı
    # BodyMeasurement entity ile aynı mantık

    id: str
    user_id: str                          # FK — hangi kullanıcıya ait
    date: date                            # DATE_BASED zaman referansı
    title: Optional[str]                  # Opsiyonel başlık
    content: str                          # Zorunlu — notun içeriği
    energy_level: Optional[int]           # 1-10 arası enerji skoru
    mood_score: Optional[int]             # 1-10 arası ruh hali skoru
    created_at: datetime