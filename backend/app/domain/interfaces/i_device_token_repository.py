from abc import ABC, abstractmethod
from typing import List, Optional

from backend.app.domain.entities.device_token import DeviceToken


class IDeviceTokenRepository(ABC):

    # ── Token kaydet/güncelle (upsert) ──
    @abstractmethod
    async def upsert_token(
        self,
        user_id: str,
        fcm_token: str,
        device_type: str,
        device_name: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> DeviceToken:
        pass

    # ── Kullanıcının tüm aktif token'larını getir ──
    @abstractmethod
    async def get_active_tokens(self, user_id: str) -> List[DeviceToken]:
        pass

    # ── Birden çok kullanıcının aktif token'larını getir (toplu gönderim için) ──
    @abstractmethod
    async def get_active_tokens_for_users(self, user_ids: List[str]) -> List[DeviceToken]:
        pass

    # ── Token'ı deaktive et (logout) ──
    @abstractmethod
    async def deactivate_token(self, user_id: str, fcm_token: str) -> bool:
        pass

    # ── Geçersiz/expired token'ı işaretle (FCM "unregistered" hatası dönünce) ──
    @abstractmethod
    async def deactivate_by_token_value(self, fcm_token: str) -> bool:
        pass


"""
DOSYA AKIŞI:
IDeviceTokenRepository FCM cihaz token sistemi için repository sözleşmesini tanımlar.
Somut implementasyon: infrastructure/repositories/device_token_repository.py

upsert_token → aynı (user_id, fcm_token) ikilisi tekrar register edilirse
yeni satır AÇMAZ, mevcut satırı günceller (last_seen, is_active=True).

deactivate_by_token_value → NotificationService bir token'a gönderim
yaptığında Firebase "bu token artık geçersiz" derse (kullanıcı app'i
silmiş vs.) bu metodla işaretlenir, bir daha o token'a gönderim denenmez.

Spring Boot karşılığı: Repository interface (JpaRepository extend etmeden saf interface).
"""
