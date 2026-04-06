import uuid
from datetime import datetime, timezone, timedelta, date
from typing import List, Optional

from sqlalchemy import select, and_, or_
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.friendship import Friendship
from app.domain.interfaces.i_social_repository import ISocialRepository
from app.infrastructure.db.models.friendship_model import FriendshipModel
from app.infrastructure.db.models.user_level_model import UserLevelModel
from app.infrastructure.db.models.user_model import UserModel


class SocialRepository(ISocialRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Model → Entity dönüşümü ──
    def _to_entity(self, model: FriendshipModel) -> Friendship:
        return Friendship(
            id=model.id,
            requester_id=model.requester_id,
            addressee_id=model.addressee_id,
            status=model.status,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    # ── Arkadaşlık isteği gönder ──
    async def send_request(self, requester_id: str, addressee_id: str) -> Friendship:
        model = FriendshipModel(
            id=str(uuid.uuid4()),
            requester_id=requester_id,
            addressee_id=addressee_id,
            status="pending",
        )
        self.db.add(model)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    # ── İsteği kabul et ──
    async def accept_request(self, friendship_id: str, addressee_id: str) -> Optional[Friendship]:
        # Sadece addressee kabul edebilir, status pending olmalı
        result = await self.db.execute(
            select(FriendshipModel).where(
                and_(
                    FriendshipModel.id == friendship_id,
                    FriendshipModel.addressee_id == addressee_id,
                    FriendshipModel.status == "pending",
                )
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None

        model.status = "accepted"
        model.updated_at = datetime.now(timezone.utc)
        await self.db.flush()
        await self.db.refresh(model)
        return self._to_entity(model)

    # ── Arkadaşlığı veya isteği sil ──
    async def delete_friendship(self, friendship_id: str, user_id: str) -> bool:
        # Hem requester hem addressee silebilir
        result = await self.db.execute(
            select(FriendshipModel).where(
                and_(
                    FriendshipModel.id == friendship_id,
                    or_(
                        FriendshipModel.requester_id == user_id,
                        FriendshipModel.addressee_id == user_id,
                    ),
                )
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return False

        await self.db.delete(model)
        await self.db.flush()
        return True

    # ── Kullanıcının tüm kabul edilmiş arkadaşlarını getir ──
    async def get_friends(self, user_id: str) -> List[Friendship]:
        result = await self.db.execute(
            select(FriendshipModel).where(
                and_(
                    FriendshipModel.status == "accepted",
                    or_(
                        FriendshipModel.requester_id == user_id,
                        FriendshipModel.addressee_id == user_id,
                    ),
                )
            )
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    # ── İki kullanıcı arasındaki mevcut ilişkiyi getir ──
    async def get_friendship(self, requester_id: str, addressee_id: str) -> Optional[Friendship]:
        # Her iki yönde de kontrol et
        result = await self.db.execute(
            select(FriendshipModel).where(
                or_(
                    and_(
                        FriendshipModel.requester_id == requester_id,
                        FriendshipModel.addressee_id == addressee_id,
                    ),
                    and_(
                        FriendshipModel.requester_id == addressee_id,
                        FriendshipModel.addressee_id == requester_id,
                    ),
                )
            )
        )
        model = result.scalar_one_or_none()
        return self._to_entity(model) if model else None

    # ── Leaderboard: arkadaşların rolling 7 günlük XP sıralaması ──
    async def get_leaderboard(self, user_id: str) -> List[dict]:
        # 1. Kullanıcının tüm arkadaşlarını bul
        friends = await self.get_friends(user_id)

        # 2. Arkadaş ID listesini çıkar (karşı taraf kim?)
        friend_ids = []
        for f in friends:
            if f.requester_id == user_id:
                friend_ids.append(f.addressee_id)
            else:
                friend_ids.append(f.requester_id)

        # 3. Listeye kullanıcının kendisini de ekle
        all_ids = friend_ids + [user_id]

        # 4. Bu kullanıcıların XP ve isim bilgilerini çek
        result = await self.db.execute(
            select(UserModel, UserLevelModel)
            .join(UserLevelModel, UserModel.id == UserLevelModel.user_id, isouter=True)
            .where(UserModel.id.in_(all_ids))
            .order_by(UserLevelModel.xp.desc())
        )
        rows = result.all()

        # 5. Sıralı leaderboard listesi oluştur
        leaderboard = []
        for rank, (user, level) in enumerate(rows, start=1):
            leaderboard.append({
                "rank": rank,
                "user_id": user.id,
                "full_name": user.full_name,
                "xp": level.xp if level else 0,
                "level": level.level if level else 1,
                "level_title": level.level_title if level else "Beginner",
                "is_me": user.id == user_id,
            })

        return leaderboard


"""
DOSYA AKIŞI:
SocialRepository arkadaşlık ve leaderboard işlemlerini yönetir.

send_request    → pending status ile yeni kayıt oluşturur
accept_request  → sadece addressee kabul edebilir, status → accepted
delete_friendship → requester veya addressee silebilir
get_friends     → her iki yönde accepted kayıtları döner
get_friendship  → çift yönlü kontrol (A→B veya B→A)

get_leaderboard mantığı:
  1. Kullanıcının arkadaşlarını bul
  2. Arkadaş ID listesi çıkar
  3. Kendi ID'sini ekle
  4. Hepsinin UserLevel verisini JOIN ile çek
  5. XP'ye göre sıralı döndür

Spring Boot karşılığı: @Repository + JPQL query.
"""