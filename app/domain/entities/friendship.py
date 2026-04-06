from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Friendship:
    id: str
    requester_id: str
    addressee_id: str
    status: str  # pending / accepted / blocked
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
Friendship domain entity — saf Python, hiçbir dış bağımlılık yok.
status değerleri: pending / accepted / blocked

Spring Boot karşılığı: @Entity sınıfı ama sadece alan tanımları,
JPA/Hibernate anotasyonu olmadan.
"""