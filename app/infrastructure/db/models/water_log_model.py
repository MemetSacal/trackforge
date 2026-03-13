# SQLAlchemy ORM modeli — veritabanı tablosunu temsil eder
from datetime import date, datetime
from sqlalchemy import String, Integer, Date, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.infrastructure.db.base import Base


class WaterLogModel(Base):
    __tablename__ = "water_logs"

    # Primary key
    id: Mapped[str] = mapped_column(String, primary_key=True)

    # Foreign key — hangi kullanıcıya ait
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Su kaydı alanları
    date: Mapped[date] = mapped_column(Date, nullable=False)
    amount_ml: Mapped[int] = mapped_column(Integer, nullable=False)
    target_ml: Mapped[int] = mapped_column(Integer, nullable=False, default=2800)

    # Zaman damgaları
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # İlişki — User modeline many-to-one
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="water_logs")


"""
DOSYA AKIŞI:
WaterLogModel, PostgreSQL'deki water_logs tablosunu temsil eder.
user_id üzerinde index var — date range sorgularında performans için.
CASCADE DELETE: kullanıcı silinince su kayıtları da silinir.
UserModel'e back_populates eklemeyi unutma.

Spring Boot karşılığı: @Entity + @Table + @ManyToOne anotasyonları.
"""