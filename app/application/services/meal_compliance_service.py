import uuid
from datetime import date, datetime, timezone, timedelta
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession

from app.domain.entities.meal_compliance import MealCompliance
from app.domain.interfaces.i_meal_compliance_repository import IMealComplianceRepository
from app.application.schemas.meal_compliance import MealComplianceResponse
from app.core.exceptions import BadRequestException, NotFoundException
from app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository
from app.infrastructure.repositories.measurement_repository import MeasurementRepository


class MealComplianceService:

    def __init__(self, compliance_repository: IMealComplianceRepository, db: AsyncSession):
        self.compliance_repository = compliance_repository
        self.db = db

    # ── Yardımcı: TDEE hesapla ──
    def _calculate_tdee(self, prefs, weight_kg: Optional[float]) -> Optional[float]:
        # Fiziksel profil eksikse hesap yapılamaz
        if not all([prefs.height_cm, prefs.age, prefs.gender, weight_kg]):
            return None

        # Mifflin-St Jeor BMR formülü
        if prefs.gender == "male":
            bmr = 10 * weight_kg + 6.25 * prefs.height_cm - 5 * prefs.age + 5
        else:
            bmr = 10 * weight_kg + 6.25 * prefs.height_cm - 5 * prefs.age - 161

        # Aktivite katsayısı
        multipliers = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9
        }
        multiplier = multipliers.get(prefs.activity_level or "moderate", 1.55)
        return round(bmr * multiplier)

    # ── Yardımcı: Hedefe göre günlük kalori hedefi hesapla ──
    def _calculate_daily_target(self, tdee: float, fitness_goal: str) -> float:
        # Kilo verme: agresif açık (-700)
        # Kas yapma: fazla (+250)
        # Koruma: TDEE
        goal_adjustments = {
            "weight_loss": -700,
            "muscle_gain": +250,
            "maintenance": 0,
        }
        adjustment = goal_adjustments.get(fitness_goal or "maintenance", 0)
        daily_target = tdee + adjustment

        # Güvenli minimum — kas kaybını önle
        min_calories = 1500 if True else 1200  # erkek/kadın ayrımı ileride eklenebilir
        return max(daily_target, min_calories)

    # ── Yardımcı: Haftalık banka bakiyesini hesapla ──
    async def _calculate_weekly_bank(
        self, user_id: str, current_date: date, daily_target: float
    ) -> float:
        # Son 7 günün kayıtlarını getir
        week_start = current_date - timedelta(days=6)
        records = await self.compliance_repository.get_by_date_range(
            user_id, week_start, current_date
        )
        # Her gün için: target - consumed (eksik = kredi, fazla = borç)
        bank = 0.0
        for record in records:
            if record.calories_consumed is not None and record.calories_target is not None:
                bank += record.calories_target - record.calories_consumed
        return round(bank)

    # ── Yardımcı: Banka mesajı üret ──
    def _generate_bank_message(
        self, weekly_bank: float, daily_target: float, calories_consumed: Optional[float]
    ) -> str:
        today_max = daily_target + max(weekly_bank, 0)

        if weekly_bank > 500:
            return f"🎉 Bu hafta {int(weekly_bank)} kalori krediniz var! Bugün maksimum {int(today_max)} kcal yiyebilirsiniz."
        elif weekly_bank > 0:
            return f"✅ {int(weekly_bank)} kalori krediniz var. Bugün {int(today_max)} kcal'e kadar yiyebilirsiniz."
        elif weekly_bank < -300:
            deficit = abs(int(weekly_bank))
            return f"⚠️ Bu hafta {deficit} kalori borcunuz var. Bugün {int(max(daily_target - abs(weekly_bank), 1200))} kcal hedefleyin."
        else:
            return f"👍 Dengeli gidiyorsunuz. Bugünkü hedefiniz {int(daily_target)} kcal."

    # ── Yardımcı: entity → response ──
    async def _to_response(
        self, compliance: MealCompliance, daily_target: Optional[float] = None,
        weekly_bank: Optional[float] = None
    ) -> MealComplianceResponse:
        bank_message = None
        today_max = None
        if daily_target and weekly_bank is not None:
            bank_message = self._generate_bank_message(
                weekly_bank, daily_target, compliance.calories_consumed
            )
            today_max = daily_target + max(weekly_bank, 0)

        return MealComplianceResponse(
            id=compliance.id,
            user_id=compliance.user_id,
            date=compliance.date,
            complied=compliance.complied,
            compliance_rate=compliance.compliance_rate,
            notes=compliance.notes,
            calories_consumed=compliance.calories_consumed,
            calories_target=compliance.calories_target,
            calorie_balance=compliance.calorie_balance,
            weekly_bank_balance=compliance.weekly_bank_balance,
            bank_message=bank_message,
            today_max_calories=today_max,
            created_at=compliance.created_at,
        )

    async def create(self, user_id: str, data, db) -> MealComplianceResponse:
        # Aynı gün zaten kayıt var mı kontrol et
        existing = await self.compliance_repository.get_by_date(user_id, data.date)
        if existing:
            raise BadRequestException(f"{data.date} tarihine ait diyet kaydı zaten mevcut")

        # Kullanıcı tercihlerini ve son kiloyu çek
        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(user_id)

        # TDEE ve günlük hedef hesapla
        daily_target = None
        weekly_bank = None
        calorie_balance = None

        if prefs and data.calories_consumed is not None:
            from sqlalchemy import select
            from app.infrastructure.db.models.measurement_model import MeasurementModel
            result = await db.execute(
                select(MeasurementModel)
                .where(MeasurementModel.user_id == user_id)
                .order_by(MeasurementModel.date.desc())
                .limit(1)
            )
            last_measurement = result.scalar_one_or_none()
            weight_kg = last_measurement.weight_kg if last_measurement else None

            tdee = self._calculate_tdee(prefs, weight_kg)
            if tdee:
                daily_target = self._calculate_daily_target(tdee, prefs.fitness_goal)
                calorie_balance = round(data.calories_consumed - daily_target, 1)
                weekly_bank = await self._calculate_weekly_bank(user_id, data.date, daily_target)

        compliance = MealCompliance(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=data.date,
            complied=data.complied,
            compliance_rate=data.compliance_rate,
            notes=data.notes,
            calories_consumed=data.calories_consumed,
            calories_target=daily_target,
            calorie_balance=calorie_balance,
            weekly_bank_balance=weekly_bank,
            created_at=datetime.now(timezone.utc),
        )
        created = await self.compliance_repository.create(compliance)
        return await self._to_response(created, daily_target, weekly_bank)

    async def get_by_date(self, user_id: str, target_date: date) -> MealComplianceResponse:
        compliance = await self.compliance_repository.get_by_date(user_id, target_date)
        if not compliance:
            raise NotFoundException(f"{target_date} tarihine ait diyet kaydı bulunamadı")
        return await self._to_response(compliance)

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[MealComplianceResponse]:
        if from_date > to_date:
            raise BadRequestException("Başlangıç tarihi bitiş tarihinden büyük olamaz")
        records = await self.compliance_repository.get_by_date_range(user_id, from_date, to_date)
        return [await self._to_response(r) for r in records]

    async def update(self, user_id: str, compliance_id: str, data, db) -> MealComplianceResponse:
        existing = await self.compliance_repository.get_by_id(compliance_id)
        if not existing:
            raise NotFoundException("Diyet kaydı bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Diyet kaydı bulunamadı")

        existing.complied = data.complied if data.complied is not None else existing.complied
        existing.compliance_rate = data.compliance_rate if data.compliance_rate is not None else existing.compliance_rate
        existing.notes = data.notes if data.notes is not None else existing.notes

        # Kalori güncellenirse yeniden hesapla
        if data.calories_consumed is not None:
            existing.calories_consumed = data.calories_consumed
            pref_repo = UserPreferenceRepository(db)
            prefs = await pref_repo.get_by_user_id(user_id)
            if prefs:
                from sqlalchemy import select
                from app.infrastructure.db.models.measurement_model import MeasurementModel
                result = await db.execute(
                    select(MeasurementModel)
                    .where(MeasurementModel.user_id == user_id)
                    .order_by(MeasurementModel.date.desc())
                    .limit(1)
                )
                last_measurement = result.scalar_one_or_none()
                weight_kg = last_measurement.weight_kg if last_measurement else None
                tdee = self._calculate_tdee(prefs, weight_kg)
                if tdee:
                    existing.calories_target = self._calculate_daily_target(tdee, prefs.fitness_goal)
                    existing.calorie_balance = round(data.calories_consumed - existing.calories_target, 1)
                    existing.weekly_bank_balance = await self._calculate_weekly_bank(
                        user_id, existing.date, existing.calories_target
                    )

        updated = await self.compliance_repository.update(existing)
        return await self._to_response(updated, existing.calories_target, existing.weekly_bank_balance)

    async def delete(self, user_id: str, compliance_id: str) -> bool:
        existing = await self.compliance_repository.get_by_id(compliance_id)
        if not existing:
            raise NotFoundException("Diyet kaydı bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Diyet kaydı bulunamadı")
        return await self.compliance_repository.delete(compliance_id)


"""
DOSYA AKIŞI:
MealComplianceService kalori bankası sistemini yönetir:

_calculate_tdee → boy + kilo + yaş + cinsiyet + aktivite → günlük kalori ihtiyacı
_calculate_daily_target → TDEE ± hedef açığı (kilo verme: -700, kas: +250)
_calculate_weekly_bank → son 7 günün birikimli dengesi
_generate_bank_message → kullanıcıya anlaşılır mesaj üretir

create() çağrılınca:
  1. Kalori girilmişse TDEE hesapla
  2. Günlük hedefi belirle
  3. Günlük dengeyi hesapla (consumed - target)
  4. Haftalık bankayı güncelle
  5. Kullanıcıya banka mesajı üret

Spring Boot karşılığı: @Service anotasyonlu class.
"""