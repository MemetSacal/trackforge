import uuid
from datetime import datetime, timezone
from typing import List, Optional, Dict, Any

from sqlalchemy import select, and_, func, update
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.domain.entities.notification import Notification
from backend.app.domain.interfaces.i_notification_repository import INotificationRepository
from backend.app.infrastructure.db.models.notification_model import NotificationModel


class NotificationRepository(INotificationRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Model → Entity dönüşümü ──
    def _to_entity(self, model: NotificationModel) -> Notification:
        return Notification(
            id=model.id,
            user_id=model.user_id,
            title=model.title,
            body=model.body,
            type=model.type,
            data=model.data,
            is_read=model.is_read,
            created_at=model.created_at,
        )

    # ── Yeni bildirim kaydı oluştur ──
    async def create(
        self,
        user_id: str,
        title: str,
        body: str,
        type: str,
        data: Optional[Dict[str, Any]] = None,
    ) -> Notification:
        model = NotificationModel(
            id=str(uuid.uuid4()),
            user_id=user_id,
            title=title,
            body=body,
            type=type,
            data=data,
            is_read=False,
            created_at=datetime.now(timezone.utc),
        )
        self.db.add(model)
        await self.db.flush()
        return self._to_entity(model)

    # ── Kullanıcının bildirim geçmişini getir (en yeni önce) ──
    async def get_for_user(
        self, user_id: str, limit: int = 50, offset: int = 0
    ) -> List[Notification]:
        result = await self.db.execute(
            select(NotificationModel)
            .where(NotificationModel.user_id == user_id)
            .order_by(NotificationModel.created_at.desc())
            .limit(limit)
            .offset(offset)
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    # ── Okunmamış bildirim sayısı ──
    async def get_unread_count(self, user_id: str) -> int:
        result = await self.db.execute(
            select(func.count(NotificationModel.id)).where(
                and_(
                    NotificationModel.user_id == user_id,
                    NotificationModel.is_read == False,  # noqa: E712
                )
            )
        )
        return result.scalar_one()

    # ── Tek bildirimi okundu işaretle ──
    async def mark_as_read(self, notification_id: str, user_id: str) -> Optional[Notification]:
        result = await self.db.execute(
            select(NotificationModel).where(
                and_(
                    NotificationModel.id == notification_id,
                    NotificationModel.user_id == user_id,
                )
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return None
        model.is_read = True
        await self.db.flush()
        return self._to_entity(model)

    # ── Kullanıcının tüm bildirimlerini okundu işaretle ──
    async def mark_all_as_read(self, user_id: str) -> int:
        result = await self.db.execute(
            update(NotificationModel)
            .where(
                and_(
                    NotificationModel.user_id == user_id,
                    NotificationModel.is_read == False,  # noqa: E712
                )
            )
            .values(is_read=True)
        )
        await self.db.flush()
        return result.rowcount


"""
DOSYA AKIŞI:
NotificationRepository, INotificationRepository sözleşmesinin SQLAlchemy
implementasyonu.

Commit burada YAPILMAZ — service katmanı sorumluluğu.

Spring Boot karşılığı: @Repository implementasyonu (JpaRepository yerine
elle yazılmış SQL/Criteria sorguları).
"""
