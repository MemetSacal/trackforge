import uuid
from datetime import datetime, timezone
from sqlalchemy import String, Text, Integer, Float, DateTime, ForeignKey, JSON
from sqlalchemy import String, Text, Integer, Float, DateTime, ForeignKey
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.db.base import Base


class SessionExerciseModel(Base):
    # Spring'deki @Entity @Table(name="session_exercises") ile aynı mantık
    __tablename__ = "session_exercises"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    session_id: Mapped[str] = mapped_column(
        String, ForeignKey("exercise_sessions.id"), nullable=False
        # FK — exercise_sessions tablosuna bağlı
        # Seans silinince CASCADE ile bu kayıt da silinir
    )
    exercise_name: Mapped[str] = mapped_column(
        String, nullable=False              # Zorunlu — "Squat", "Bench Press" gibi
    )
    sets: Mapped[int] = mapped_column(
        Integer, nullable=True              # Kaç set — opsiyonel
    )
    reps: Mapped[int] = mapped_column(
        Integer, nullable=True              # Set başına kaç tekrar — opsiyonel
    )
    weight_kg: Mapped[float] = mapped_column(
        Float, nullable=True                # Kullanılan ağırlık — opsiyonel
    )
    muscle_groups: Mapped[dict] = mapped_column(
        JSON, nullable=True                 # Çalışan kas grupları — ["göğüs", "omuz", "triceps"]
    )
    notes: Mapped[str] = mapped_column(
        Text, nullable=True                 # Egzersiz notu — opsiyonel
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )

    # Ters ilişki — Spring'deki @ManyToOne ile aynı mantık
    session: Mapped["ExerciseSessionModel"] = relationship(
        "ExerciseSessionModel",
        back_populates="exercises"          # ExerciseSessionModel.exercises ile eşleşir
    )

"""
Genel akış:
ExerciseSessionModel.exercises → o seansa ait tüm SessionExerciseModel listesi
SessionExerciseModel.session   → bu egzersizin ait olduğu ExerciseSessionModel

ForeignKey + relationship farkı:
ForeignKey → DB seviyesinde bağlantı, veri bütünlüğü
relationship → Python seviyesinde bağlantı, obje üzerinden erişim
İkisi birlikte kullanılır.
"""