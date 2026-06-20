from datetime import datetime
from typing import Optional, Any, Dict, Literal
from pydantic import BaseModel


# ── Bildirim türleri ──
# Native DB enum DEĞİL (bkz. domain/entities/notification.py açıklaması),
# ama API katmanında Literal ile sınırlandırılıyor — yanlış bir type
# string'i request gövdesinden sızamaz.
NotificationType = Literal[
    "friend_request",
    "friend_accepted",
    "ai_report",
    "streak_warning",
    "premium",
    "system",
    "workout",
    "meal",
]

DeviceType = Literal["android", "ios"]


# ── Request: Token register ──
class RegisterDeviceTokenSchema(BaseModel):
    token: str
    device_type: DeviceType
    device_name: Optional[str] = None
    app_version: Optional[str] = None


# ── Response: Device token kaydı ──
class DeviceTokenResponse(BaseModel):
    id: str
    user_id: str
    device_type: str
    device_name: Optional[str] = None
    app_version: Optional[str] = None
    is_active: bool
    last_seen: Optional[datetime] = None
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ── Response: Bildirim kaydı ──
class NotificationResponse(BaseModel):
    id: str
    user_id: str
    title: str
    body: str
    type: str
    data: Optional[Dict[str, Any]] = None
    is_read: bool
    created_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ── Response: Bildirim listesi + okunmamış sayaç ──
# Flutter'da bildirim ikonu üstündeki kırmızı badge için unread_count
# her seferinde ayrıca COUNT sorgusu atmaya gerek bırakmıyor.
class NotificationListResponse(BaseModel):
    notifications: list[NotificationResponse]
    unread_count: int


"""
DOSYA AKIŞI:
Notification & DeviceToken Pydantic şemaları — API request/response sözleşmeleri.

RegisterDeviceTokenSchema  → POST /notifications/register-token body'si
DeviceTokenResponse        → register-token endpoint'inin dönüşü
NotificationResponse       → tekil bildirim
NotificationListResponse   → GET /notifications/ dönüşü (liste + unread_count birlikte)

Spring Boot karşılığı: DTO sınıfları (RequestDTO / ResponseDTO).
"""
