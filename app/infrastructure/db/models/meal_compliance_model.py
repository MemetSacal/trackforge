import uuid
from datetime import datetime, timezone
from typing import TYPE_CHECKING
from sqlalchemy import String, Text, Float, Boolean, Date, DateTime, ForeignKey, Integer
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.infrastructure.db.base import Base

if TYPE_CHECKING:
    from app.infrastructure.db.models.user_model import UserModel


class MealComplianceModel(Base):
    # Spring'deki @Entity @Table(name="meal_compliance") ile aynı mantık
    __tablename__ = "meal_compliance"

    id: Mapped[str] = mapped_column(
        String, primary_key=True, default=lambda: str(uuid.uuid4())
        # UUID primary key — her kayıt için benzersiz
    )
    user_id: Mapped[str] = mapped_column(
        String, ForeignKey("users.id"), nullable=False
        # ForeignKey = FK — users tablosunda olmayan user_id ile kayıt oluşturulamaz
    )
    date: Mapped[datetime] = mapped_column(
        Date, nullable=False
        # DATE_BASED zaman referansı — o günün kaydı
    )
    complied: Mapped[bool] = mapped_column(
        Boolean, nullable=False
        # Zorunlu — True: diyete uyuldu, False: uyulmadı
    )
    compliance_rate: Mapped[float] = mapped_column(
        Float, nullable=True
        # Opsiyonel — 0.0 ile 100.0 arası uyum yüzdesi
    )

    # ── Kalori takibi — kalori bankası sistemi için ──
    calories_consumed: Mapped[float] = mapped_column(
        Float, nullable=True
        # O gün alınan toplam kalori
    )
    calories_target: Mapped[float] = mapped_column(
        Float, nullable=True
        # O günün hedef kalorisi — TDEE bazlı hesaplanır
    )
    calorie_balance: Mapped[float] = mapped_column(
        Float, nullable=True
        # Günlük fark — pozitif: fazla aldı, negatif: eksik aldı
        # calorie_balance = calories_consumed - calories_target
    )
    weekly_bank_balance: Mapped[float] = mapped_column(
        Float, nullable=True
        # Haftalık birikimli kalori bankası — + kredi, - borç
        # Her kayıt girildiğinde son 7 günün toplamından hesaplanır
    )

    notes: Mapped[str] = mapped_column(
        Text, nullable=True
        # Opsiyonel — neden uymadı, ne yedi vs. uzun metin olabilir
    )
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc)
        # Kayıt oluşturulunca otomatik set edilir
    )

    # user_model.py'deki meal_compliances ile eşleşir
    user: Mapped["UserModel"] = relationship("UserModel", back_populates="meal_compliances")


"""
DOSYA AKIŞI:
Kalori bankası sistemi için 4 yeni alan eklendi:
  calories_consumed   → kullanıcının o gün girdiği kalori
  calories_target     → TDEE - açık (kilo verme: -700, kas: +200)
  calorie_balance     → consumed - target (+ fazla, - eksik)
  weekly_bank_balance → son 7 günün birikimli dengesi

Örnek:
  Hedef: 1600 kcal/gün
  Pazartesi: 1200 aldı → balance: -400 (eksik), bank: +400 kredi
  Salı: 2000 aldı → balance: +400 (fazla), bank: 0
  Çarşamba: 1400 aldı → balance: -200, bank: +200 kredi

NoteModel'den farkı:
Boolean tip eklendi — complied alanı için
Float tip eklendi — compliance_rate ve kalori alanları için
"""