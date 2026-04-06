from datetime import datetime, timezone
from sqlalchemy import String, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.db.base import Base


class FriendshipModel(Base):
    __tablename__ = "friendships"

    # ── Birincil anahtar ──
    id: Mapped[str] = mapped_column(String, primary_key=True)

    # ── İlişki tarafları ──
    # İstek gönderen kullanıcı
    requester_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )
    # İstek alan kullanıcı
    addressee_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False
    )

    # ── Durum ──
    # pending  → istek gönderildi, henüz kabul edilmedi
    # accepted → arkadaşlık aktif
    # blocked  → engellendi
    status: Mapped[str] = mapped_column(String, nullable=False, default="pending")

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

    # ── İlişkiler (UserModel'e back_populates) ──
    requester: Mapped["UserModel"] = relationship(
        "UserModel",
        foreign_keys=[requester_id],
        back_populates="sent_friend_requests",
    )
    addressee: Mapped["UserModel"] = relationship(
        "UserModel",
        foreign_keys=[addressee_id],
        back_populates="received_friend_requests",
    )


"""
DOSYA AKIŞI:
FriendshipModel arkadaşlık isteklerini ve durumlarını tutar.

status değerleri:
  pending  → istek gönderildi
  accepted → kabul edildi, arkadaşlar
  blocked  → engellendi

İki ayrı foreign key (requester_id, addressee_id) her ikisi de
users tablosuna bağlı — bu yüzden foreign_keys parametresi
relationship'lerde açıkça belirtilmeli.

Spring Boot karşılığı: @Entity + @ManyToOne (iki kez).
"""