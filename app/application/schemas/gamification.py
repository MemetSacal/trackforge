from datetime import datetime, date
from typing import Optional, List
from pydantic import BaseModel


class StreakResponse(BaseModel):
    streak_type: str
    current_streak: int
    longest_streak: int
    last_updated: Optional[date] = None

    class Config:
        from_attributes = True


class BadgeResponse(BaseModel):
    badge_key: str
    badge_name: str
    description: Optional[str] = None
    earned_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class UserLevelResponse(BaseModel):
    level: int
    xp: int
    level_title: str
    # Bir sonraki seviyeye kaç XP kaldı
    xp_to_next_level: Optional[int] = None
    updated_at: Optional[datetime] = None

    class Config:
        from_attributes = True


class GamificationSummaryResponse(BaseModel):
    # Tüm gamification verisini tek seferde döndürür
    streaks: List[StreakResponse]
    badges: List[BadgeResponse]
    level: Optional[UserLevelResponse] = None


"""
DOSYA AKIŞI:
StreakResponse     → su/egzersiz/uyku streak bilgisi
BadgeResponse      → kazanılan rozetler
UserLevelResponse  → seviye + XP + bir sonraki seviyeye kalan XP
GamificationSummaryResponse → hepsini tek seferde döndürür

xp_to_next_level service'de hesaplanır:
  Seviye 2 için: 500 - mevcut_xp
  Seviye 3 için: 1500 - mevcut_xp

Spring Boot karşılığı: DTO sınıfları.
"""