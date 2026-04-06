from abc import ABC, abstractmethod
from typing import List, Optional

from app.domain.entities.friendship import Friendship


class ISocialRepository(ABC):

    # ── Arkadaşlık isteği gönder ──
    @abstractmethod
    async def send_request(self, requester_id: str, addressee_id: str) -> Friendship:
        pass

    # ── İsteği kabul et ──
    @abstractmethod
    async def accept_request(self, friendship_id: str, addressee_id: str) -> Optional[Friendship]:
        pass

    # ── Arkadaşlığı/isteği sil ──
    @abstractmethod
    async def delete_friendship(self, friendship_id: str, user_id: str) -> bool:
        pass

    # ── Kullanıcının tüm arkadaşlarını getir (accepted) ──
    @abstractmethod
    async def get_friends(self, user_id: str) -> List[Friendship]:
        pass

    # ── İki kullanıcı arasındaki mevcut ilişkiyi getir ──
    @abstractmethod
    async def get_friendship(self, requester_id: str, addressee_id: str) -> Optional[Friendship]:
        pass

    # ── Leaderboard: arkadaşların haftalık XP sıralaması ──
    @abstractmethod
    async def get_leaderboard(self, user_id: str) -> List[dict]:
        pass


"""
DOSYA AKIŞI:
ISocialRepository sosyal sistem için repository sözleşmesini tanımlar.
Somut implementasyon: infrastructure/repositories/social_repository.py

get_leaderboard → dict listesi döner çünkü birden fazla tablodan
(friendships + user_levels + users) veri birleştirilir.

Spring Boot karşılığı: Repository interface (JpaRepository extend etmeden saf interface).
"""