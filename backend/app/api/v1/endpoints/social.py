from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.social import (
    SendFriendRequestSchema,
    FriendshipResponse,
    LeaderboardEntryResponse,
)
from backend.app.application.services.social_service import SocialService
from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db
from sqlalchemy import select
from backend.app.infrastructure.db.models.user_model import UserModel

router = APIRouter(tags=["Social"])


# ── Dependency: SocialService ──
async def get_social_service(db: AsyncSession = Depends(get_db)) -> SocialService:
    return SocialService(db)


@router.post("/friends/request", response_model=FriendshipResponse, status_code=201)
async def send_friend_request(
    body: SendFriendRequestSchema,
    user_id: str = Depends(get_current_user),
    service: SocialService = Depends(get_social_service),
    db: AsyncSession = Depends(get_db),
):
    result = await db.execute(
        select(UserModel).where(UserModel.email == body.addressee_email)
    )
    addressee = result.scalar_one_or_none()
    if not addressee:
        raise HTTPException(status_code=404, detail="Bu e-posta ile kayıtlı kullanıcı bulunamadı.")

    try:
        return await service.send_friend_request(user_id, str(addressee.id))
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
# ── POST /social/friends/accept/{friendship_id} ──
@router.post("/friends/accept/{friendship_id}", response_model=FriendshipResponse)
async def accept_friend_request(
    friendship_id: str,
    user_id: str = Depends(get_current_user),
    service: SocialService = Depends(get_social_service),
):
    # Sadece addressee kabul edebilir
    try:
        return await service.accept_friend_request(friendship_id, user_id)
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))


# ── DELETE /social/friends/{friendship_id} ──
@router.delete("/friends/{friendship_id}")
async def delete_friendship(
    friendship_id: str,
    user_id: str = Depends(get_current_user),
    service: SocialService = Depends(get_social_service),
):
    # Hem requester hem addressee silebilir
    try:
        return await service.delete_friendship(friendship_id, user_id)
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))


# ── GET /social/friends ──
@router.get("/friends", response_model=list[FriendshipResponse])
async def get_friends(
    user_id: str = Depends(get_current_user),
    service: SocialService = Depends(get_social_service),
):
    # Kabul edilmiş arkadaşları listele
    return await service.get_friends(user_id)


# ── GET /social/leaderboard ──
@router.get("/leaderboard", response_model=list[LeaderboardEntryResponse])
async def get_leaderboard(
    user_id: str = Depends(get_current_user),
    service: SocialService = Depends(get_social_service),
):
    # Arkadaşlar arası haftalık XP sıralaması
    return await service.get_leaderboard(user_id)


"""
DOSYA AKIŞI:
Social endpoint'leri arkadaşlık ve leaderboard işlemlerini yönetir.

POST /friends/request          → arkadaşlık isteği gönder
POST /friends/accept/{id}      → isteği kabul et
DELETE /friends/{id}           → arkadaşlığı/isteği sil
GET  /friends                  → arkadaş listesi
GET  /leaderboard              → arkadaşlar arası XP sıralaması

ValueError → 400 Bad Request
Bulunamayan kayıt → 404 Not Found

Spring Boot karşılığı: @RestController + @RequestMapping("/social")
"""