# Domain katmanındaki saf Python entity — hiçbir dış bağımlılık yok
from dataclasses import dataclass
from datetime import date, datetime
from typing import Optional


@dataclass
class WaterLog:
    # Su kaydının temel alanları
    id: str
    user_id: str
    date: date
    amount_ml: int          # İçilen su miktarı (ml cinsinden)
    target_ml: int          # Günlük hedef (varsayılan 2800 ml = 2.8L)
    created_at: datetime
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
WaterLog entity'si saf bir Python dataclass'ıdır.
Veritabanı, FastAPI veya başka hiçbir şeye bağımlı değildir.
Repository interface'i bu entity'yi kullanır,
infrastructure katmanı ise bu entity'yi ORM modeline dönüştürür.

Spring Boot karşılığı: @Entity sınıfı ama Hibernate/JPA anotasyonu olmadan.
"""