import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING
from sqlalchemy import String, Text, Integer, Float, Date, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from app.infrastructure.db.models.user_model import UserModel
    from app.infrastructure.db.models.session_exercise_model import SessionExerciseModel


class ExerciseSessionModel(Base):
    # Spring'deki @Entity @Table(name="exercise_sessions") ile aynı mantık
    __tablename__ = "exercise_sessions"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
        # UUID primary key — her seans için benzersiz
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
        # FK — users tablosuna bağlı
    )
    date: Mapped[datetime] = mapped_column(
        Date, nullable=False
        # DATE_BASED zaman referansı
    )
    duration_minutes: Mapped[int] = mapped_column(
        Integer, nullable=True              # Seansın süresi — opsiyonel
    )
    calories_burned: Mapped[float] = mapped_column(
        Float, nullable=True                # Yakılan kalori — opsiyonel
    )
    notes: Mapped[str] = mapped_column(
        Text, nullable=True                 # Seans notu — opsiyonel
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )

    # İlişki tanımı — Spring'deki @OneToMany ile aynı mantık
    # cascade="all, delete-orphan" → seans silinince içindeki egzersizler de silinir
    exercises: Mapped[list["SessionExerciseModel"]] = relationship(
        "SessionExerciseModel",
        back_populates="session",
        cascade="all, delete-orphan",       # EN KRİTİK KISIM — cascade deletion
        lazy="selectin"                     # Seans getirilince egzersizler de otomatik getirilir
    )

    # user_model.py'deki exercise_sessions ile eşleşir
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="exercise_sessions")


"""
cascade="all, delete-orphan" ne demek?
Bir ExerciseSession silinince ona bağlı tüm SessionExercise kayıtları da otomatik silinir.
Manuel olarak önce egzersizleri, sonra seansı silmek gerekmez.
Spring'deki @OneToMany(cascade = CascadeType.ALL, orphanRemoval = true) ile aynı mantık.

lazy="selectin" ne demek?
Seans sorgulanınca SQLAlchemy otomatik olarak egzersizleri de getirir.
Ayrı bir sorgu yazmak gerekmez.
"""