import uuid
from datetime import datetime, timezone
from typing import List, Optional, TYPE_CHECKING
from sqlalchemy import String, DateTime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.db.base import Base

# TYPE_CHECKING: döngüsel import'u önler — sadece tip kontrolü sırasında import edilir
if TYPE_CHECKING:
    from app.infrastructure.db.models.measurement_model import MeasurementModel
    from app.infrastructure.db.models.note_model import NoteModel
    from app.infrastructure.db.models.meal_compliance_model import MealComplianceModel
    from app.infrastructure.db.models.file_upload_model import FileUploadModel
    from app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel
    from app.infrastructure.db.models.water_log_model import WaterLogModel
    from app.infrastructure.db.models.sleep_log_model import SleepLogModel
    from app.infrastructure.db.models.user_preference_model import UserPreferenceModel
    from app.infrastructure.db.models.shopping_item_model import ShoppingItemModel

class UserModel(Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
    )
    email: Mapped[str] = mapped_column(String, unique=True, nullable=False)
    password_hash: Mapped[str] = mapped_column(String, nullable=False)
    full_name: Mapped[str] = mapped_column(String, nullable=False)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        onupdate=lambda: datetime.now(timezone.utc)
    )

    # ── İlişkiler — cascade: kullanıcı silinince bağlı kayıtlar da silinir ──
    measurements: Mapped[List["MeasurementModel"]] = relationship(
        "MeasurementModel", back_populates="user", cascade="all, delete-orphan"
    )
    notes: Mapped[List["NoteModel"]] = relationship(
        "NoteModel", back_populates="user", cascade="all, delete-orphan"
    )
    meal_compliances: Mapped[List["MealComplianceModel"]] = relationship(
        "MealComplianceModel", back_populates="user", cascade="all, delete-orphan"
    )
    file_uploads: Mapped[List["FileUploadModel"]] = relationship(
        "FileUploadModel", back_populates="user", cascade="all, delete-orphan"
    )
    exercise_sessions: Mapped[List["ExerciseSessionModel"]] = relationship(
        "ExerciseSessionModel", back_populates="user", cascade="all, delete-orphan"
    )
    water_logs: Mapped[List["WaterLogModel"]] = relationship(
        "WaterLogModel", back_populates="user", cascade="all, delete-orphan"
    )
    sleep_logs: Mapped[List["SleepLogModel"]] = relationship(
        "SleepLogModel", back_populates="user", cascade="all, delete-orphan"
    )
    preference: Mapped[Optional["UserPreferenceModel"]] = relationship(
        "UserPreferenceModel", back_populates="user", cascade="all, delete-orphan", uselist=False
    )
    shopping_items: Mapped[List["ShoppingItemModel"]] = relationship(
        "ShoppingItemModel", back_populates="user", cascade="all, delete-orphan"
    )

"""
DOSYA AKIŞI:
UserModel tüm diğer modellerin ana referansıdır.
TYPE_CHECKING bloğu döngüsel import hatasını önler —
Python çalışırken bu import'ları görmez, sadece IDE ve tip kontrolcüsü görür.
cascade="all, delete-orphan": kullanıcı silinince ona ait tüm veriler de silinir.

Spring Boot karşılığı: @OneToMany(mappedBy="user", cascade=CascadeType.ALL, orphanRemoval=true)
"""