from dataclasses import dataclass
from datetime import datetime
from typing import Optional


@dataclass
class UserLevel:
    id: str
    user_id: str
    level: int = 1
    xp: int = 0
    level_title: str = "Beginner"
    updated_at: Optional[datetime] = None