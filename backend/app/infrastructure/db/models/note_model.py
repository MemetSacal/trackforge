import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING
from sqlalchemy import String, Text, Integer, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from backend.app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from backend.app.infrastructure.db.models.user_model import UserModel


class NoteModel(Base):
    # Spring'deki @Entity @Table(name="weekly_notes") ile aynı mantık
    __tablename__ = "weekly_notes"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
        # UUID primary key — her not için benzersiz
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
        # FK — users tablosunda olmayan user_id ile kayıt oluşturulamaz
    )
    date: Mapped[datetime] = mapped_column(
        Date, nullable=False
        # DATE_BASED zaman referansı — hafta bu tarihten hesaplanır
    )
    title: Mapped[str] = mapped_column(
        String, nullable=True              # Opsiyonel — kullanıcı başlık girmek zorunda değil
    )
    content: Mapped[str] = mapped_column(
        Text, nullable=False               # Zorunlu — Text tipi uzun yazılar için VARCHAR değil
    )
    energy_level: Mapped[int] = mapped_column(
        Integer, nullable=True             # 1-10 arası enerji skoru, opsiyonel
    )
    mood_score: Mapped[int] = mapped_column(
        Integer, nullable=True             # 1-10 arası ruh hali skoru, opsiyonel
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
        # Kayıt oluşturulunca otomatik set edilir
    )

    # user_model.py'deki notes ile eşleşir
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="notes")


"""
String vs Text farkı:
String → kısa metinler için, DB'de VARCHAR olarak saklanır, max uzunluk var
Text   → uzun metinler için, DB'de TEXT olarak saklanır, sınırsız uzunluk
content için Text kullandık çünkü haftalık not uzun olabilir.
title için String kullandık çünkü kısa bir başlık.

MeasurementModel'den farkı:
Float yerine Integer kullandık — energy_level ve mood_score tam sayı (1-10)
Text tipi eklendi — content alanı için
"""