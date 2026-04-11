from dataclasses import dataclass
from datetime import datetime, date
from typing import Optional


@dataclass
class MenstrualCycle:
    id: str
    user_id: str
    cycle_start_date: date
    cycle_length_days: int = 28
    period_length_days: int = 5
    notes: Optional[str] = None
    created_at: Optional[datetime] = None


"""
DOSYA AKIŞI:
MenstrualCycle domain entity — saf Python, hiçbir dış bağımlılık yok.

Döngü fazları (AI entegrasyonu için):
  Faz 1 — Menstrüasyon : gün 1 → period_length_days
  Faz 2 — Foliküler    : gün period_length_days+1 → 13
  Faz 3 — Ovülasyon    : gün 14 → 16
  Faz 4 — Luteal       : gün 17 → cycle_length_days

Spring Boot karşılığı: @Entity sınıfı ama sadece alan tanımları.
"""