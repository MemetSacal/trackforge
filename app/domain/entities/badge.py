from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class Badge:
    id: str
    user_id: str
    badge_key: str          # "first_workout", "7_day_water" vs.
    badge_name: str         # "İlk Antrenman"
    description: Optional[str] = None
    earned_at: Optional[datetime] = None
    created_at: Optional[datetime] = None