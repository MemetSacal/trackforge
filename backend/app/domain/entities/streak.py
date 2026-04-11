from dataclasses import dataclass
from datetime import datetime, date
from typing import Optional


@dataclass
class Streak:
    id: str
    user_id: str
    streak_type: str            # water / exercise / sleep
    current_streak: int = 0     # Mevcut seri
    longest_streak: int = 0     # En uzun seri (rekor)
    last_updated: Optional[date] = None
    created_at: Optional[datetime] = None