from typing import List, Optional

from sqlalchemy.ext.asyncio import AsyncSession

from app.application.schemas.social import (
    FriendshipResponse,
    LeaderboardEntryResponse,
)
from app.domain.entities.friendship import Friendship
from app.infrastructure.repositories.social_repository import SocialRepository


class SocialService:

    def __init__(self, db: AsyncSession):
        self.repo = SocialRepository(db)
        self.db = db

    # ── Yardımcı: Friendship → FriendshipResponse ──
    def _to_response(self, friendship: Friendship) -> FriendshipResponse:
        return FriendshipResponse(
            id=friendship.id,
            requester_id=friendship.requester_id,
            addressee_id=friendship.addressee_id,
            status=friendship.status,
            created_at=friendship.created_at,
            updated_at=friendship.updated_at,
        )

    # ── Arkadaşlık isteği gönder ──
    async def send_friend_request(
        self, requester_id: str, addressee_id: str
    ) -> FriendshipResponse:
        # Kendine istek göndermeyi engelle
        if requester_id == addressee_id:
            raise ValueError("Kendinize arkadaşlık isteği gönderemezsiniz.")

        # Zaten mevcut bir ilişki var mı kontrol et
        existing = await self.repo.get_friendship(requester_id, addressee_id)
        if existing:
            if existing.status == "accepted":
                raise ValueError("Bu kullanıcı zaten arkadaşınız.")
            if existing.status == "pending":
                raise ValueError("Bu kullanıcıya zaten bekleyen bir isteğiniz var.")
            if existing.status == "blocked":
                raise ValueError("Bu kullanıcıyla arkadaşlık isteği gönderilemez.")

        friendship = await self.repo.send_request(requester_id, addressee_id)
        await self.db.commit()
        return self._to_response(friendship)

    # ── Arkadaşlık isteğini kabul et ──
    async def accept_friend_request(
        self, friendship_id: str, addressee_id: str
    ) -> FriendshipResponse:
        friendship = await self.repo.accept_request(friendship_id, addressee_id)
        if not friendship:
            raise ValueError("İstek bulunamadı veya kabul etme yetkiniz yok.")

        await self.db.commit()
        return self._to_response(friendship)

    # ── Arkadaşlığı veya isteği sil ──
    async def delete_friendship(self, friendship_id: str, user_id: str) -> dict:
        deleted = await self.repo.delete_friendship(friendship_id, user_id)
        if not deleted:
            raise ValueError("Arkadaşlık bulunamadı veya silme yetkiniz yok.")

        await self.db.commit()
        return {"message": "Arkadaşlık silindi."}

    # ── Arkadaş listesini getir ──
    async def get_friends(self, user_id: str) -> List[FriendshipResponse]:
        friends = await self.repo.get_friends(user_id)
        return [self._to_response(f) for f in friends]

    # ── Leaderboard: arkadaşlar arası haftalık XP sıralaması ──
    async def get_leaderboard(self, user_id: str) -> List[LeaderboardEntryResponse]:
        rows = await self.repo.get_leaderboard(user_id)
        return [
            LeaderboardEntryResponse(
                rank=row["rank"],
                user_id=row["user_id"],
                full_name=row["full_name"],
                xp=row["xp"],
                level=row["level"],
                level_title=row["level_title"],
                is_me=row["is_me"],
            )
            for row in rows
        ]


"""
DOSYA AKIŞI:
SocialService iş mantığını yönetir:

send_friend_request  → kendine istek engeli + duplicate kontrol
accept_friend_request → sadece addressee kabul edebilir
delete_friendship    → requester veya addressee silebilir
get_friends          → accepted arkadaşlar
get_leaderboard      → arkadaşlar + kendisi, XP'ye göre sıralı

Her write işlemi sonunda db.commit() çağrılır.

Spring Boot karşılığı: @Service sınıfı.
"""