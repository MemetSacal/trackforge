# Gamification iş mantığı — XP, streak, rozet yönetimi
from datetime import date
from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.gamification import (
    StreakResponse, BadgeResponse, UserLevelResponse, GamificationSummaryResponse
)
from backend.app.domain.entities.streak import Streak
from backend.app.domain.entities.badge import Badge
from backend.app.domain.entities.user_level import UserLevel
from backend.app.infrastructure.repositories.gamification_repository import GamificationRepository


# XP miktarları — her aksiyon için
XP_REWARDS = {
    "workout_session": 50,      # Antrenman seansı
    "water_goal": 20,           # Su hedefi tutuldu
    "sleep_log": 15,            # Uyku logu girildi
    "badge_earned": 100,        # Rozet kazanıldı
    "weekly_report": 10,        # Haftalık rapor görüntülendi
}

# Seviye eşikleri
LEVEL_THRESHOLDS = {1: 0, 2: 500, 3: 1500, 4: 3000, 5: 6000}

# Rozet tanımları
BADGE_DEFINITIONS = {
    "first_workout": ("İlk Antrenman 💪", "İlk antrenman seansını tamamladın!"),
    "7_day_water": ("7 Gün Su Hedefi 💧", "7 gün boyunca su hedefine ulaştın!"),
    "30_day_water": ("30 Gün Su Hedefi 🏆", "30 gün boyunca su hedefine ulaştın!"),
    "weight_loss_5kg": ("5 kg Kayıp ⚡", "5 kg verdin, harika ilerliyorsun!"),
    "weight_loss_10kg": ("10 kg Kayıp 🔥", "10 kg verdin, muhteşem!"),
    "first_photo": ("İlk Fotoğraf 📸", "İlerleme fotoğrafını yükledin!"),
    "streak_warrior": ("Streak Savaşçısı ⚔️", "7 gün boyunca egzersiz yaptın!"),
}


class GamificationService:

    def __init__(self, db: AsyncSession):
        self.repo = GamificationRepository(db)
        self.db = db

    # ── Yardımcı: StreakResponse oluştur ──
    def _streak_to_response(self, streak: Streak) -> StreakResponse:
        return StreakResponse(
            streak_type=streak.streak_type,
            current_streak=streak.current_streak,
            longest_streak=streak.longest_streak,
            last_updated=streak.last_updated,
        )

    # ── Yardımcı: BadgeResponse oluştur ──
    def _badge_to_response(self, badge: Badge) -> BadgeResponse:
        return BadgeResponse(
            badge_key=badge.badge_key,
            badge_name=badge.badge_name,
            description=badge.description,
            earned_at=badge.earned_at,
        )

    # ── Yardımcı: UserLevelResponse oluştur ──
    def _level_to_response(self, level: UserLevel) -> UserLevelResponse:
        # Bir sonraki seviyeye kaç XP kaldı
        xp_to_next = None
        for lvl, threshold in sorted(LEVEL_THRESHOLDS.items()):
            if threshold > level.xp:
                xp_to_next = threshold - level.xp
                break

        return UserLevelResponse(
            level=level.level,
            xp=level.xp,
            level_title=level.level_title,
            xp_to_next_level=xp_to_next,
            updated_at=level.updated_at,
        )

    # ── Tüm gamification verisini getir ──
    async def get_summary(self, user_id: str) -> GamificationSummaryResponse:
        streaks = await self.repo.get_all_streaks(user_id)
        badges = await self.repo.get_badges(user_id)
        level = await self.repo.get_level(user_id)

        return GamificationSummaryResponse(
            streaks=[self._streak_to_response(s) for s in streaks],
            badges=[self._badge_to_response(b) for b in badges],
            level=self._level_to_response(level) if level else None,
        )

    async def get_streaks(self, user_id: str) -> List[StreakResponse]:
        streaks = await self.repo.get_all_streaks(user_id)
        return [self._streak_to_response(s) for s in streaks]

    async def get_badges(self, user_id: str) -> List[BadgeResponse]:
        badges = await self.repo.get_badges(user_id)
        return [self._badge_to_response(b) for b in badges]

    async def get_level(self, user_id: str) -> Optional[UserLevelResponse]:
        level = await self.repo.get_level(user_id)
        return self._level_to_response(level) if level else None

    # ── Su hedefi tutuldu — streak + XP + rozet kontrol ──
    async def on_water_goal_reached(self, user_id: str, today: date) -> None:
        # Su streak'ini artır
        streak = await self.repo.increment_streak(user_id, "water", today)

        # XP ekle
        await self.repo.add_xp(user_id, XP_REWARDS["water_goal"])

        # Rozet kontrol
        if streak.current_streak >= 7:
            name, desc = BADGE_DEFINITIONS["7_day_water"]
            badge = await self.repo.award_badge(user_id, "7_day_water", name, desc)
            if badge:
                await self.repo.add_xp(user_id, XP_REWARDS["badge_earned"])

        if streak.current_streak >= 30:
            name, desc = BADGE_DEFINITIONS["30_day_water"]
            badge = await self.repo.award_badge(user_id, "30_day_water", name, desc)
            if badge:
                await self.repo.add_xp(user_id, XP_REWARDS["badge_earned"])

        await self.db.commit()

    # ── Antrenman seansı oluşturuldu — streak + XP + rozet kontrol ──
    async def on_workout_created(self, user_id: str, today: date, is_first: bool = False) -> None:
        # Egzersiz streak'ini artır
        streak = await self.repo.increment_streak(user_id, "exercise", today)

        # XP ekle
        await self.repo.add_xp(user_id, XP_REWARDS["workout_session"])

        # İlk antrenman rozeti
        if is_first:
            name, desc = BADGE_DEFINITIONS["first_workout"]
            badge = await self.repo.award_badge(user_id, "first_workout", name, desc)
            if badge:
                await self.repo.add_xp(user_id, XP_REWARDS["badge_earned"])

        # 7 gün egzersiz serisi
        if streak.current_streak >= 7:
            name, desc = BADGE_DEFINITIONS["streak_warrior"]
            badge = await self.repo.award_badge(user_id, "streak_warrior", name, desc)
            if badge:
                await self.repo.add_xp(user_id, XP_REWARDS["badge_earned"])

        await self.db.commit()

    # ── Uyku logu girildi — streak + XP ──
    async def on_sleep_logged(self, user_id: str, today: date, quality_score: int) -> None:
        # Kalite skoru >= 6 ise streak artır
        if quality_score >= 6:
            await self.repo.increment_streak(user_id, "sleep", today)

        # Her uyku logu XP kazandırır
        await self.repo.add_xp(user_id, XP_REWARDS["sleep_log"])
        await self.db.commit()

    # ── Kilo kaybı rozeti kontrol ──
    async def check_weight_loss_badges(
        self, user_id: str, initial_weight: float, current_weight: float
    ) -> None:
        loss = initial_weight - current_weight
        if loss >= 5:
            name, desc = BADGE_DEFINITIONS["weight_loss_5kg"]
            badge = await self.repo.award_badge(user_id, "weight_loss_5kg", name, desc)
            if badge:
                await self.repo.add_xp(user_id, XP_REWARDS["badge_earned"])

        if loss >= 10:
            name, desc = BADGE_DEFINITIONS["weight_loss_10kg"]
            badge = await self.repo.award_badge(user_id, "weight_loss_10kg", name, desc)
            if badge:
                await self.repo.add_xp(user_id, XP_REWARDS["badge_earned"])

        await self.db.commit()

    # ── İlk fotoğraf yüklendi ──
    async def on_first_photo(self, user_id: str) -> None:
        name, desc = BADGE_DEFINITIONS["first_photo"]
        badge = await self.repo.award_badge(user_id, "first_photo", name, desc)
        if badge:
            await self.repo.add_xp(user_id, XP_REWARDS["badge_earned"])
        await self.db.commit()


"""
DOSYA AKIŞI:
GamificationService event-driven çalışır:
  on_water_goal_reached() → su endpoint'inden çağrılır
  on_workout_created()    → egzersiz endpoint'inden çağrılır
  on_sleep_logged()       → uyku endpoint'inden çağrılır
  check_weight_loss_badges() → ölçüm endpoint'inden çağrılır
  on_first_photo()        → dosya endpoint'inden çağrılır

Her event:
  1. Streak güncelle
  2. XP ekle
  3. Rozet kontrol et (kazanıldıysa +100 XP daha)

Spring Boot karşılığı: @Service + Event-driven pattern.
"""