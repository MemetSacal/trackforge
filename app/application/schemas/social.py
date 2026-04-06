from datetime import datetime
from typing import Optional
from pydantic import BaseModel


# ── İstek Gönderme ──
class SendFriendRequestSchema(BaseModel):
    addressee_id: str


# ── Response: Arkadaşlık kaydı ──
class FriendshipResponse(BaseModel):
    id: str
    requester_id: str
    addressee_id: str
    status: str  # pending / accepted / blocked
    created_at: Optional[datetime] = None
    updated_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ── Response: Leaderboard satırı ──
class LeaderboardEntryResponse(BaseModel):
    rank: int
    user_id: str
    full_name: str
    xp: int
    level: int
    level_title: str
    is_me: bool  # Kullanıcının kendisi mi?

    model_config = {"from_attributes": True}


"""
DOSYA AKIŞI:
SendFriendRequestSchema → POST /social/friends/request body'si
FriendshipResponse      → arkadaşlık kaydının response modeli
LeaderboardEntryResponse → leaderboard her satırı için response modeli

is_me alanı Flutter tarafında "Sen" etiketini göstermek için kullanılır.

Spring Boot karşılığı: DTO sınıfları (record veya @Data).
"""