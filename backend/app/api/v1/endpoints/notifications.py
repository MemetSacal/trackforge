from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.notification import (
    RegisterDeviceTokenSchema,
    DeviceTokenResponse,
    NotificationResponse,
    NotificationListResponse,
)
from backend.app.application.services.notification_service import NotificationService
from backend.app.core.dependencies import get_current_user
from backend.app.infrastructure.db.session import get_db
from backend.app.infrastructure.repositories.device_token_repository import DeviceTokenRepository
from backend.app.infrastructure.repositories.notification_repository import NotificationRepository

router = APIRouter(tags=["Notifications"])


# ── Dependency: NotificationService ──
async def get_notification_service(db: AsyncSession = Depends(get_db)) -> NotificationService:
    return NotificationService(db)


# ── POST /notifications/register-token ──
# Login sonrası (ve her onTokenRefresh tetiklendiğinde) Flutter tarafından çağrılır.
@router.post("/register-token", response_model=DeviceTokenResponse, status_code=201)
async def register_device_token(
    body: RegisterDeviceTokenSchema,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = DeviceTokenRepository(db)
    token = await repo.upsert_token(
        user_id=user_id,
        fcm_token=body.token,
        device_type=body.device_type,
        device_name=body.device_name,
        app_version=body.app_version,
    )
    await db.commit()
    return DeviceTokenResponse(
        id=token.id,
        user_id=token.user_id,
        device_type=token.device_type,
        device_name=token.device_name,
        app_version=token.app_version,
        is_active=token.is_active,
        last_seen=token.last_seen,
        created_at=token.created_at,
    )


# ── PATCH /notifications/token/deactivate ──
# Logout'ta çağrılır — eski cihaza bildirim gitmeye devam etmesin diye.
@router.patch("/token/deactivate", status_code=200)
async def deactivate_device_token(
    body: RegisterDeviceTokenSchema,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = DeviceTokenRepository(db)
    success = await repo.deactivate_token(user_id=user_id, fcm_token=body.token)
    if not success:
        raise HTTPException(status_code=404, detail="Token bulunamadı.")
    await db.commit()
    return {"detail": "Token deaktive edildi."}


# ── GET /notifications/ ──
# In-app bildirim geçmişi (eski SharedPreferences ekranının yerini alır).
@router.get("/", response_model=NotificationListResponse)
async def get_notifications(
    limit: int = 50,
    offset: int = 0,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = NotificationRepository(db)
    notifications = await repo.get_for_user(user_id=user_id, limit=limit, offset=offset)
    unread_count = await repo.get_unread_count(user_id=user_id)
    return NotificationListResponse(
        notifications=[
            NotificationResponse(
                id=n.id,
                user_id=n.user_id,
                title=n.title,
                body=n.body,
                type=n.type,
                data=n.data,
                is_read=n.is_read,
                created_at=n.created_at,
            )
            for n in notifications
        ],
        unread_count=unread_count,
    )


# ── PATCH /notifications/{notification_id}/read ──
@router.patch("/{notification_id}/read", response_model=NotificationResponse)
async def mark_notification_as_read(
    notification_id: str,
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = NotificationRepository(db)
    notification = await repo.mark_as_read(notification_id=notification_id, user_id=user_id)
    if not notification:
        raise HTTPException(status_code=404, detail="Bildirim bulunamadı.")
    await db.commit()
    return NotificationResponse(
        id=notification.id,
        user_id=notification.user_id,
        title=notification.title,
        body=notification.body,
        type=notification.type,
        data=notification.data,
        is_read=notification.is_read,
        created_at=notification.created_at,
    )


# ── PATCH /notifications/read-all ──
@router.patch("/read-all", status_code=200)
async def mark_all_notifications_as_read(
    user_id: str = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    repo = NotificationRepository(db)
    count = await repo.mark_all_as_read(user_id=user_id)
    await db.commit()
    return {"detail": f"{count} bildirim okundu işaretlendi."}


"""
DOSYA AKIŞI:
Notification & DeviceToken endpoint'leri.

POST   /notifications/register-token   → login sonrası / token refresh'te
PATCH  /notifications/token/deactivate → logout'ta
GET    /notifications/                 → in-app bildirim geçmişi + unread_count
PATCH  /notifications/{id}/read        → tek bildirimi okundu işaretle
PATCH  /notifications/read-all         → hepsini okundu işaretle

NOT: Bu dosyada NotificationService'in send_to_user/send_to_users metodları
DOĞRUDAN kullanılmıyor — onlar başka servisler tarafından (örn. social_service.py
arkadaşlık isteği gönderirken) çağrılacak. Bu endpoint'ler sadece token
yönetimi ve geçmiş okuma içindir.

Spring Boot karşılığı: @RestController sınıfı.
"""
