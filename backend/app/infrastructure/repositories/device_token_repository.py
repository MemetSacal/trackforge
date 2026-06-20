import uuid
from datetime import datetime, timezone
from typing import List, Optional

from sqlalchemy import select, and_
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.domain.entities.device_token import DeviceToken
from backend.app.domain.interfaces.i_device_token_repository import IDeviceTokenRepository
from backend.app.infrastructure.db.models.device_token_model import DeviceTokenModel


class DeviceTokenRepository(IDeviceTokenRepository):

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Model → Entity dönüşümü ──
    def _to_entity(self, model: DeviceTokenModel) -> DeviceToken:
        return DeviceToken(
            id=model.id,
            user_id=model.user_id,
            fcm_token=model.fcm_token,
            device_type=model.device_type,
            device_name=model.device_name,
            app_version=model.app_version,
            is_active=model.is_active,
            last_seen=model.last_seen,
            created_at=model.created_at,
            updated_at=model.updated_at,
        )

    # ── Token kaydet/güncelle (upsert) ──
    async def upsert_token(
        self,
        user_id: str,
        fcm_token: str,
        device_type: str,
        device_name: Optional[str] = None,
        app_version: Optional[str] = None,
    ) -> DeviceToken:
        result = await self.db.execute(
            select(DeviceTokenModel).where(
                and_(
                    DeviceTokenModel.user_id == user_id,
                    DeviceTokenModel.fcm_token == fcm_token,
                )
            )
        )
        existing = result.scalar_one_or_none()

        now = datetime.now(timezone.utc)

        if existing:
            # Var olan kaydı güncelle — yeni satır AÇMA
            existing.device_type = device_type
            existing.device_name = device_name
            existing.app_version = app_version
            existing.is_active = True
            existing.last_seen = now
            await self.db.flush()
            return self._to_entity(existing)

        # Yoksa yeni kayıt oluştur
        model = DeviceTokenModel(
            id=str(uuid.uuid4()),
            user_id=user_id,
            fcm_token=fcm_token,
            device_type=device_type,
            device_name=device_name,
            app_version=app_version,
            is_active=True,
            last_seen=now,
        )
        self.db.add(model)
        await self.db.flush()
        return self._to_entity(model)

    # ── Kullanıcının tüm aktif token'larını getir ──
    async def get_active_tokens(self, user_id: str) -> List[DeviceToken]:
        result = await self.db.execute(
            select(DeviceTokenModel).where(
                and_(
                    DeviceTokenModel.user_id == user_id,
                    DeviceTokenModel.is_active == True,  # noqa: E712
                )
            )
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    # ── Birden çok kullanıcının aktif token'larını getir (toplu gönderim) ──
    async def get_active_tokens_for_users(self, user_ids: List[str]) -> List[DeviceToken]:
        if not user_ids:
            return []
        result = await self.db.execute(
            select(DeviceTokenModel).where(
                and_(
                    DeviceTokenModel.user_id.in_(user_ids),
                    DeviceTokenModel.is_active == True,  # noqa: E712
                )
            )
        )
        return [self._to_entity(m) for m in result.scalars().all()]

    # ── Token'ı deaktive et (logout) ──
    async def deactivate_token(self, user_id: str, fcm_token: str) -> bool:
        result = await self.db.execute(
            select(DeviceTokenModel).where(
                and_(
                    DeviceTokenModel.user_id == user_id,
                    DeviceTokenModel.fcm_token == fcm_token,
                )
            )
        )
        model = result.scalar_one_or_none()
        if not model:
            return False
        model.is_active = False
        await self.db.flush()
        return True

    # ── Geçersiz/expired token'ı işaretle ──
    async def deactivate_by_token_value(self, fcm_token: str) -> bool:
        result = await self.db.execute(
            select(DeviceTokenModel).where(DeviceTokenModel.fcm_token == fcm_token)
        )
        model = result.scalar_one_or_none()
        if not model:
            return False
        model.is_active = False
        await self.db.flush()
        return True


"""
DOSYA AKIŞI:
DeviceTokenRepository, IDeviceTokenRepository sözleşmesinin SQLAlchemy
implementasyonu.

upsert_token: SELECT ile (user_id, fcm_token) ikilisini arar.
  - Bulursa: UPDATE (yeni satır açmaz, last_seen'i yeniler)
  - Bulamazsa: INSERT

Commit burada YAPILMAZ — service katmanı sorumluluğu (transaction sınırı
service'te çiziliyor, repository pattern'i projenin geri kalanıyla tutarlı).

Spring Boot karşılığı: @Repository implementasyonu (JpaRepository yerine
elle yazılmış SQL/Criteria sorguları).
"""
