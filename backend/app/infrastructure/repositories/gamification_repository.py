# Streak, Badge ve UserLevel için tek repository
import uuid
from datetime import datetime, timezone, date, timedelta
from typing import Optional, List

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.domain.entities.streak import Streak
from backend.app.domain.entities.badge import Badge
from backend.app.domain.entities.user_level import UserLevel
from backend.app.infrastructure.db.models.streak_model import StreakModel
from backend.app.infrastructure.db.models.badge_model import BadgeModel
from backend.app.infrastructure.db.models.user_level_model import UserLevelModel


class GamificationRepository:

    def __init__(self, db: AsyncSession):
        self.db = db

    # ══════════════════════════════════════
    # STREAK
    # ══════════════════════════════════════

    def _streak_to_entity(self, model: StreakModel) -> Streak:
        return Streak(
            id=model.id,
            user_id=model.user_id,
            streak_type=model.streak_type,
            current_streak=model.current_streak,
            longest_streak=model.longest_streak,
            last_updated=model.last_updated,
            created_at=model.created_at,
        )

    async def get_streak(self, user_id: str, streak_type: str) -> Optional[Streak]:
        result = await self.db.execute(
            select(StreakModel).where(
                and_(StreakModel.user_id == user_id, StreakModel.streak_type == streak_type)
            )
        )
        model = result.scalar_one_or_none()
        return self._streak_to_entity(model) if model else None

    async def get_all_streaks(self, user_id: str) -> List[Streak]:
        result = await self.db.execute(
            select(StreakModel).where(StreakModel.user_id == user_id)
        )
        return [self._streak_to_entity(m) for m in result.scalars().all()]

    async def create_streak(self, user_id: str, streak_type: str) -> Streak:
        # Yeni streak kaydı oluştur
        model = StreakModel(
            id=str(uuid.uuid4()),
            user_id=user_id,
            streak_type=streak_type,
            current_streak=0,
            longest_streak=0,
        )
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._streak_to_entity(model)

    async def increment_streak(self, user_id: str, streak_type: str, today: date) -> Streak:
        # Streak'i getir veya oluştur
        result = await self.db.execute(
            select(StreakModel).where(
                and_(StreakModel.user_id == user_id, StreakModel.streak_type == streak_type)
            )
        )
        model = result.scalar_one_or_none()

        if not model:
            # İlk kez — yeni streak oluştur
            model = StreakModel(
                id=str(uuid.uuid4()),
                user_id=user_id,
                streak_type=streak_type,
                current_streak=1,
                longest_streak=1,
                last_updated=today,
            )
            self.db.add(model)
        else:
            # Bugün zaten güncellendiyse tekrar artırma
            if model.last_updated == today:
                return self._streak_to_entity(model)

            # Dün güncellenmediyse streak koptu — sıfırla
            if model.last_updated and model.last_updated < today - timedelta(days=1):
                model.current_streak = 1
            else:
                # Dün güncellendiyse devam et
                model.current_streak += 1

            # Rekor kırıldı mı?
            if model.current_streak > model.longest_streak:
                model.longest_streak = model.current_streak

            model.last_updated = today

        await self.db.flush()
        await self.db.refresh(model)
        return self._streak_to_entity(model)

    # ══════════════════════════════════════
    # BADGE
    # ══════════════════════════════════════

    def _badge_to_entity(self, model: BadgeModel) -> Badge:
        return Badge(
            id=model.id,
            user_id=model.user_id,
            badge_key=model.badge_key,
            badge_name=model.badge_name,
            description=model.description,
            earned_at=model.earned_at,
            created_at=model.created_at,
        )

    async def get_badges(self, user_id: str) -> List[Badge]:
        result = await self.db.execute(
            select(BadgeModel)
            .where(BadgeModel.user_id == user_id)
            .order_by(BadgeModel.earned_at.desc())
        )
        return [self._badge_to_entity(m) for m in result.scalars().all()]

    async def has_badge(self, user_id: str, badge_key: str) -> bool:
        # Rozet zaten kazanıldı mı kontrol et
        result = await self.db.execute(
            select(BadgeModel).where(
                and_(BadgeModel.user_id == user_id, BadgeModel.badge_key == badge_key)
            )
        )
        return result.scalar_one_or_none() is not None

    async def award_badge(
        self, user_id: str, badge_key: str, badge_name: str, description: str = None
    ) -> Optional[Badge]:
        # Zaten varsa ekleme
        if await self.has_badge(user_id, badge_key):
            return None

        model = BadgeModel(
            id=str(uuid.uuid4()),
            user_id=user_id,
            badge_key=badge_key,
            badge_name=badge_name,
            description=description,
            earned_at=datetime.now(timezone.utc),
        )
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._badge_to_entity(model)

    # ══════════════════════════════════════
    # USER LEVEL
    # ══════════════════════════════════════

    def _level_to_entity(self, model: UserLevelModel) -> UserLevel:
        return UserLevel(
            id=model.id,
            user_id=model.user_id,
            level=model.level,
            xp=model.xp,
            level_title=model.level_title,
            updated_at=model.updated_at,
        )

    async def get_level(self, user_id: str) -> Optional[UserLevel]:
        result = await self.db.execute(
            select(UserLevelModel).where(UserLevelModel.user_id == user_id)
        )
        model = result.scalar_one_or_none()
        return self._level_to_entity(model) if model else None

    async def add_xp(self, user_id: str, xp_amount: int) -> UserLevel:
        # Seviye eşikleri
        level_thresholds = {1: 0, 2: 500, 3: 1500, 4: 3000, 5: 6000}
        level_titles = {
            1: "Beginner", 2: "Active", 3: "Fit", 4: "Athlete", 5: "Champion"
        }

        result = await self.db.execute(
            select(UserLevelModel).where(UserLevelModel.user_id == user_id)
        )
        model = result.scalar_one_or_none()

        if not model:
            # İlk XP — yeni kayıt oluştur
            model = UserLevelModel(
                id=str(uuid.uuid4()),
                user_id=user_id,
                level=1,
                xp=xp_amount,
                level_title="Beginner",
            )
            self.db.add(model)
        else:
            model.xp += xp_amount

            # Seviye atladı mı kontrol et
            for level, threshold in sorted(level_thresholds.items(), reverse=True):
                if model.xp >= threshold:
                    model.level = level
                    model.level_title = level_titles[level]
                    break

        await self.db.flush()
        await self.db.refresh(model)
        return self._level_to_entity(model)


"""
DOSYA AKIŞI:
GamificationRepository streak, badge ve user_level işlemlerini yönetir.

increment_streak mantığı:
  - Bugün zaten güncellendiyse → değişme (idempotent)
  - Dünden bu yana 1 günden fazla geçtiyse → streak sıfırla
  - Dün güncellenmediyse → devam et (+1)
  - Rekor kırıldıysa longest_streak güncelle

award_badge mantığı:
  - Zaten varsa → None döner (tekrar verilmez)
  - Yoksa → yeni rozet ekle

add_xp mantığı:
  - XP ekle, seviye eşiklerini kontrol et
  - Seviye atlarsa level ve level_title güncelle

Spring Boot karşılığı: @Repository anotasyonlu class.
"""