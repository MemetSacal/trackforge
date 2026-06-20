from datetime import datetime, timezone
from typing import Optional, Any, Dict

from sqlalchemy import String, DateTime, ForeignKey, Boolean, JSON
from sqlalchemy.orm import Mapped, mapped_column, relationship
from backend.app.infrastructure.db.base import Base


class NotificationModel(Base):
    __tablename__ = "notifications"

    # ── Birincil anahtar ──
    id: Mapped[str] = mapped_column(String, primary_key=True)

    # ── Alıcı kullanıcı ──
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    # ── İçerik ──
    title: Mapped[str] = mapped_column(String, nullable=False)
    body: Mapped[str] = mapped_column(String, nullable=False)

    # ── Tür ──
    # STRING tutuluyor, native DB enum DEĞİL — bkz. domain/entities/notification.py
    # üstündeki açıklama. Pydantic Literal ile schema katmanında sınırlandırılır.
    type: Mapped[str] = mapped_column(String, nullable=False, default="system")

    # ── Deep-link payload ──
    # örn: {"type": "friend_request", "user_id": "42", "request_id": "91"}
    data: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSON, nullable=True)

    # ── Okunma durumu ──
    is_read: Mapped[bool] = mapped_column(Boolean, nullable=False, default=False)

    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
    )

    # ── İlişki (UserModel'e back_populates) ──
    user: Mapped["UserModel"] = relationship(
        "UserModel",
        back_populates="notifications",
    )


"""
DOSYA AKIŞI:
NotificationModel in-app bildirim GEÇMİŞİNİ tutar.

Bu tablo, Flutter tarafında şu ana kadar SharedPreferences'ta
('in_app_notifications' anahtarı altında) tutulan listenin backend
karşılığıdır. Telefon değişse / uygulama silinse bile geçmiş kaybolmaz,
GET /notifications/ ile her cihazdan erişilebilir.

NotificationService.send_to_user() çağrıldığında HEM FCM push gönderilir
HEM DE bu tabloya bir satır eklenir — push başarısız olsa bile (örn.
kullanıcının hiç aktif cihazı yoksa) bildirim geçmişte görünmeye devam eder.

Spring Boot karşılığı: @Entity + @ManyToOne (User'a).
"""
