from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.social import (
    SendFriendRequestSchema,
    FriendshipResponse,
    LeaderboardEntryResponse,
    PendingRequestResponse,
)
from backend.app.application.services.social_service import SocialService
from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db
from sqlalchemy import select
from datetime import date as _date, timedelta as _timedelta
from pydantic import BaseModel as _BaseModel

from sqlalchemy import select as _select, func as _func, or_ as _or, and_ as _and
from backend.app.infrastructure.db.models.duel_model import DuelModel
from backend.app.infrastructure.db.models.step_log_model import StepLogModel
from backend.app.infrastructure.db.models.friendship_model import FriendshipModel
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


# ── GET /social/friends/pending ──
@router.get("/friends/pending", response_model=list[PendingRequestResponse])
async def get_pending_requests(
    user_id: str = Depends(get_current_user),
    service: SocialService = Depends(get_social_service),
):
    return await service.get_pending_requests(user_id)


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

# ═════════════════════════════════════════════════════════
# ── v5: ADIM DÜELLOSU ──
# 7 günlük arkadaş yarışması. Adımlar step_logs'tan canlı toplanır.
# Bitiş tarihi geçmiş aktif düellolar listeleme anında finalize edilir
# (lazy finalization — cron/job gerekmez, v1.0 için yeterli).
# ═════════════════════════════════════════════════════════




class DuelCreateRequest(_BaseModel):
    opponent_id: str


async def _steps_between(db, user_id: str, start: _date, end: _date) -> int:
    total = (await db.execute(
        _select(_func.coalesce(_func.sum(StepLogModel.step_count), 0)).where(
            StepLogModel.user_id == user_id,
            StepLogModel.date >= start,
            StepLogModel.date <= end,
        )
    )).scalar_one()
    return int(total)


async def _duel_to_dict(db, duel: DuelModel, current_user: str) -> dict:
    names = {}
    for uid in (duel.challenger_id, duel.opponent_id):
        u = (await db.execute(
            _select(UserModel).where(UserModel.id == uid)
        )).scalar_one_or_none()
        names[uid] = u.full_name if u else "Kullanıcı"

    counted_end = min(duel.end_date, _date.today())
    challenger_steps = await _steps_between(db, duel.challenger_id, duel.start_date, counted_end)
    opponent_steps = await _steps_between(db, duel.opponent_id, duel.start_date, counted_end)
    days_left = max((duel.end_date - _date.today()).days, 0)

    return {
        "id": duel.id,
        "status": duel.status,
        "start_date": str(duel.start_date),
        "end_date": str(duel.end_date),
        "days_left": days_left,
        "winner_id": duel.winner_id,
        "is_challenger": duel.challenger_id == current_user,
        "challenger": {"id": duel.challenger_id, "name": names[duel.challenger_id], "steps": challenger_steps},
        "opponent": {"id": duel.opponent_id, "name": names[duel.opponent_id], "steps": opponent_steps},
    }


@router.post("/duels")
async def create_duel(
    data: DuelCreateRequest,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Arkadaşa 7 günlük adım düellosu daveti gönder."""
    if data.opponent_id == current_user:
        raise HTTPException(status_code=400, detail="Kendinle düello yapamazsın aslanım 😄")

    # Sadece kabul edilmiş arkadaşlarla düello
    friendship = (await db.execute(
        _select(FriendshipModel).where(
            FriendshipModel.status == "accepted",
            _or(
                _and(FriendshipModel.requester_id == current_user,
                     FriendshipModel.addressee_id == data.opponent_id),
                _and(FriendshipModel.requester_id == data.opponent_id,
                     FriendshipModel.addressee_id == current_user),
            ),
        )
    )).scalar_one_or_none()
    if not friendship:
        raise HTTPException(status_code=400, detail="Sadece arkadaşlarınla düello yapabilirsin.")

    # Aynı ikili arasında bekleyen/aktif düello varsa yenisi açılmaz
    existing = (await db.execute(
        _select(DuelModel).where(
            DuelModel.status.in_(["pending", "active"]),
            _or(
                _and(DuelModel.challenger_id == current_user, DuelModel.opponent_id == data.opponent_id),
                _and(DuelModel.challenger_id == data.opponent_id, DuelModel.opponent_id == current_user),
            ),
        )
    )).scalar_one_or_none()
    if existing:
        raise HTTPException(status_code=400, detail="Bu arkadaşınla zaten süren bir düellonuz var.")

    duel = DuelModel(
        challenger_id=current_user,
        opponent_id=data.opponent_id,
        start_date=_date.today(),          # kabulle aktive olur; tarihler kabulde tazelenir
        end_date=_date.today() + _timedelta(days=6),
        status="pending",
    )
    db.add(duel)
    await db.commit()
    await db.refresh(duel)
    return await _duel_to_dict(db, duel, current_user)


@router.post("/duels/{duel_id}/respond")
async def respond_duel(
    duel_id: str,
    accept: bool = True,
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Düello davetini kabul et veya reddet (sadece davet edilen)."""
    duel = (await db.execute(
        _select(DuelModel).where(
            DuelModel.id == duel_id,
            DuelModel.opponent_id == current_user,  # IDOR: sadece muhatap yanıtlar
            DuelModel.status == "pending",
        )
    )).scalar_one_or_none()
    if not duel:
        raise HTTPException(status_code=404, detail="Bekleyen düello bulunamadı.")

    if accept:
        duel.status = "active"
        duel.start_date = _date.today()    # adil başlangıç: sayım kabul anından
        duel.end_date = _date.today() + _timedelta(days=6)
    else:
        duel.status = "declined"
    await db.commit()
    return await _duel_to_dict(db, duel, current_user)


@router.get("/duels")
async def list_duels(
    current_user: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Kullanıcının düelloları (canlı skorlarla) + lazy finalization."""
    duels = (await db.execute(
        _select(DuelModel).where(
            _or(DuelModel.challenger_id == current_user,
                DuelModel.opponent_id == current_user),
            DuelModel.status.in_(["pending", "active", "finished"]),
        ).order_by(DuelModel.created_at.desc()).limit(20)
    )).scalars().all()

    out = []
    dirty = False
    for d in duels:
        # Süresi dolmuş aktif düelloyu finalize et
        if d.status == "active" and _date.today() > d.end_date:
            cs = await _steps_between(db, d.challenger_id, d.start_date, d.end_date)
            os_ = await _steps_between(db, d.opponent_id, d.start_date, d.end_date)
            d.status = "finished"
            d.winner_id = (
                d.challenger_id if cs > os_
                else d.opponent_id if os_ > cs
                else None  # berabere
            )
            dirty = True
        out.append(await _duel_to_dict(db, d, current_user))
    if dirty:
        await db.commit()
    return out
