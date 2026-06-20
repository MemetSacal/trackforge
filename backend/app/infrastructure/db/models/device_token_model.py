from datetime import datetime, timezone
from typing import Optional

from sqlalchemy import String, DateTime, ForeignKey, Boolean
from sqlalchemy.orm import Mapped, mapped_column, relationship
from backend.app.infrastructure.db.base import Base


class DeviceTokenModel(Base):
    __tablename__ = "device_tokens"

    # ── Birincil anahtar ──
    id: Mapped[str] = mapped_column(String, primary_key=True)

    # ── Sahip kullanıcı ──
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    # ── FCM token bilgisi ──
    fcm_token: Mapped[str] = mapped_column(String, nullable=False)

    # ── Cihaz bilgileri ──
    device_type: Mapped[str] = mapped_column(String, nullable=False)  # android / ios
    device_name: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    app_version: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    # ── Aktiflik durumu ──
    # Logout olunca True -> False çekilir, satır SİLİNMEZ
    # (geçmiş cihaz bilgisi korunur, eski token'a bildirim gitmesi engellenir)
    is_active: Mapped[bool] = mapped_column(Boolean, nullable=False, default=True)

    last_seen: Mapped[Optional[datetime]] = mapped_column(
        DateTime(timezone=True), nullable=True
    )

    # ── Zaman damgaları ──
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc),
    )

    # ── İlişki (UserModel'e back_populates) ──
    user: Mapped["UserModel"] = relationship(
        "UserModel",
        back_populates="device_tokens",
    )


"""
DOSYA AKIŞI:
DeviceTokenModel her kullanıcının (çoklu cihaz olabilir) FCM push
token'larını tutar.

Aynı kullanıcı + aynı fcm_token kombinasyonu register edildiğinde
repository katmanı UPSERT yapar (var olanı günceller, last_seen'i
yeniler) — tekrar tekrar aynı satırı oluşturmaz.

is_active = False olan token'lara NotificationService bildirim göndermez,
bu yüzden logout akışında bu alan mutlaka güncellenmeli.

Spring Boot karşılığı: @Entity + @ManyToOne (User'a).
"""
