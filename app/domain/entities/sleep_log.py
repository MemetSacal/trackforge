from dataclasses import dataclass
from datetime import date, datetime, time
from typing import Optional


@dataclass
class SleepLog:
    id: str
    user_id: str
    date: date                          # Uyunan gece tarihi (yatış tarihi)
    sleep_time: Optional[time]          # Yatış saati — opsiyonel
    wake_time: Optional[time]           # Kalkış saati — opsiyonel
    duration_hours: Optional[float]     # Toplam uyku süresi (saat)
    quality_score: Optional[int]        # Uyku kalitesi 1-10 arası
    notes: Optional[str]                # Opsiyonel not
    created_at: datetime
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
SleepLog entity'si saf Python dataclass'ıdır, hiçbir dış bağımlılık yok.
duration_hours otomatik hesaplanabilir (wake_time - sleep_time) ama
kullanıcı manuel de girebilir — ikisi de desteklenir.

Spring Boot karşılığı: @Entity sınıfı ama JPA anotasyonu olmadan.
"""