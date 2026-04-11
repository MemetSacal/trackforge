# SQLAlchemy ORM modeli — PostgreSQL'deki shopping_items tablosunu temsil eder
import uuid
from datetime import datetime
from typing import TYPE_CHECKING
from sqlalchemy import String, Boolean, Float, Text, DateTime, ForeignKey, func
from sqlalchemy.orm import Mapped, mapped_column, relationship

from backend.app.infrastructure.db.base import Base

# TYPE_CHECKING: döngüsel import'u önler — sadece tip kontrolü sırasında import edilir
if TYPE_CHECKING:
    from backend.app.infrastructure.db.models.user_model import UserModel


class ShoppingItemModel(Base):
    # Spring'deki @Entity @Table(name="shopping_items") ile aynı mantık
    __tablename__ = "shopping_items"

    # Primary key — UUID string olarak saklanır
    id: Mapped[str] = mapped_column(String, primary_key=True)

    # Foreign key — CASCADE: kullanıcı silinince ürünler de silinir
    # index=True — user_id ile sık sorgu yapılacağı için performans için
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True
    )

    # Ürün temel bilgileri
    name: Mapped[str] = mapped_column(String, nullable=False)               # Zorunlu — ürün adı
    quantity: Mapped[str] = mapped_column(String, nullable=True)            # "500g", "2 adet"
    category: Mapped[str] = mapped_column(String, nullable=True)            # "protein", "sebze"

    # Tamamlandı mı? — default False, toggle endpoint ile değiştirilir
    is_completed: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Fiyat bilgileri — opsiyonel, girilirse summary hesaplanır
    price: Mapped[float] = mapped_column(Float, nullable=True)
    currency: Mapped[str] = mapped_column(String, default="TRY", nullable=False)

    # Nereden alınacak — "getir", "migros", "market"
    source: Mapped[str] = mapped_column(String, nullable=True)

    # Her hafta tekrar eden ürün mü? — haftalık şablon için
    is_recurring: Mapped[bool] = mapped_column(Boolean, default=False, nullable=False)

    # Ek not — "organik olsun", "light versiyonu"
    notes: Mapped[str] = mapped_column(Text, nullable=True)

    # server_default=func.now() → DB tarafında otomatik set edilir
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    # onupdate=func.now() → kayıt güncellenince otomatik güncellenir
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now(), onupdate=func.now()
    )

    # user_model.py'deki shopping_items ile eşleşir — Many-to-One ilişki
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="shopping_items")


"""
DOSYA AKIŞI:
ShoppingItemModel, PostgreSQL'deki shopping_items tablosunu temsil eder.
is_completed Boolean → DB'de 0/1 olarak saklanır, Python'da True/False
is_recurring Boolean → True olan kayıtlar haftalık şablon olarak kullanılır
price Float nullable → fiyat girilmemişse summary hesaplamasında atlanır
currency default "TRY" → çoğu kullanıcı TL kullanacağı için varsayılan

Spring Boot karşılığı: @Entity + @Table + @ManyToOne + @Column anotasyonları.
"""