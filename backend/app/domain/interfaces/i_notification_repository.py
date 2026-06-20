from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any

from backend.app.domain.entities.notification import Notification


class INotificationRepository(ABC):

    # ── Yeni bildirim kaydı oluştur (in-app geçmiş) ──
    @abstractmethod
    async def create(
        self,
        user_id: str,
        title: str,
        body: str,
        type: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> Notification:
        pass

    # ── Kullanıcının bildirim geçmişini getir (en yeni önce) ──
    @abstractmethod
    async def get_for_user(
        self, user_id: str, limit: int = 50, offset: int = 0
    ) -> List[Notification]:
        pass

    # ── Okunmamış bildirim sayısı ──
    @abstractmethod
    async def get_unread_count(self, user_id: str) -> int:
        pass

    # ── Tek bildirimi okundu işaretle ──
    @abstractmethod
    async def mark_as_read(self, notification_id: str, user_id: str) -> Optional[Notification]:
        pass

    # ── Kullanıcının tüm bildirimlerini okundu işaretle ──
    @abstractmethod
    async def mark_all_as_read(self, user_id: str) -> int:
        pass


"""
DOSYA AKIŞI:
INotificationRepository in-app bildirim geçmişi için repository sözleşmesini tanımlar.
Somut implementasyon: infrastructure/repositories/notification_repository.py

Bu, FCM gönderiminden BAĞIMSIZ çalışır — push başarısız olsa bile (kullanıcının
aktif cihazı yoksa) create() çağrılır ve bildirim geçmişte görünür.

Spring Boot karşılığı: Repository interface (JpaRepository extend etmeden saf interface).
"""
