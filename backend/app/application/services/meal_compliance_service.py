import uuid
from datetime import date, datetime, timezone, timedelta
from typing import Optional
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.domain.entities.meal_compliance import MealCompliance
from backend.app.domain.interfaces.i_meal_compliance_repository import IMealComplianceRepository
from backend.app.application.schemas.meal_compliance import MealComplianceResponse
from backend.app.core.exceptions import BadRequestException, NotFoundException
from backend.app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository
from backend.app.infrastructure.repositories.measurement_repository import MeasurementRepository
from backend.app.infrastructure.db.models.measurement_model import MeasurementModel
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel


class MealComplianceService:

    def __init__(self, compliance_repository: IMealComplianceRepository, db: AsyncSession):
        self.compliance_repository = compliance_repository
        self.db = db

    # ── Yardımcı: O günün yakılan egzersiz kalorisini getir ──
    async def _get_burned_calories(self, user_id: str, target_date: date) -> float:
        """O gün yapılan egzersizlerde yakılan toplam kaloriyi döndürür."""
        result = await self.db.execute(
            select(ExerciseSessionModel)
            .where(
                ExerciseSessionModel.user_id == user_id,
                ExerciseSessionModel.date == target_date,
            )
        )
        sessions = result.scalars().all()
        total_burned = sum(
            s.calories_burned for s in sessions if s.calories_burned is not None
        )
        return round(total_burned, 1)

    # ── Yardımcı: TDEE hesapla ──
    def _calculate_tdee(self, prefs, weight_kg: Optional[float]) -> Optional[float]:
        if not all([prefs.height_cm, prefs.age, prefs.gender, weight_kg]):
            return None
        if prefs.gender == "male":
            bmr = 10 * weight_kg + 6.25 * prefs.height_cm - 5 * prefs.age + 5
        else:
            bmr = 10 * weight_kg + 6.25 * prefs.height_cm - 5 * prefs.age - 161
        multipliers = {
            "sedentary": 1.2, "light": 1.375, "lightly_active": 1.375,
            "moderate": 1.55, "moderately_active": 1.55,
            "active": 1.725, "very_active": 1.9
        }
        multiplier = multipliers.get(prefs.activity_level or "moderate", 1.55)
        return round(bmr * multiplier)

    # ── Yardımcı: Hedefe göre günlük kalori hedefi ──
    def _calculate_daily_target(self, tdee: float, fitness_goal: str) -> float:
        goal_adjustments = {
            "weight_loss": -500,   # Sürdürülebilir açık (eskiden -700, çok agresifti)
            "muscle_gain": +250,
            "maintenance": 0,
            "health": 0,
        }
        adjustment = goal_adjustments.get(fitness_goal or "maintenance", 0)
        daily_target = tdee + adjustment
        return max(daily_target, 1500)  # Güvenli minimum

    # ── YENİ: complied otomatik hesapla ──
    def _calculate_complied(
        self,
        calories_consumed: Optional[float],
        calories_target: Optional[float],
        calories_burned: float,
    ) -> bool:
        """
        Kullanıcı switch'e dokunmaz, sistem belirler.
        Net tüketim = yenen - yakılan
        Hedefin %80-120 arasındaysa uyuldu sayılır.
        Egzersiz yaparsa tolerans artar çünkü yakılan kalori hesaba girer.
        """
        if not calories_consumed or not calories_target:
            return True  # Veri yoksa varsayılan True

        net_consumed = calories_consumed - calories_burned
        ratio = net_consumed / calories_target

        # %80-120 arası → uyuldu
        return 0.80 <= ratio <= 1.20

    # ── Yardımcı: Haftalık banka bakiyesi ──
    async def _calculate_weekly_bank(
        self, user_id: str, current_date: date, daily_target: float
    ) -> float:
        week_start = current_date - timedelta(days=6)
        records = await self.compliance_repository.get_by_date_range(
            user_id, week_start, current_date
        )
        bank = 0.0
        for record in records:
            if record.calories_consumed is not None and record.calories_target is not None:
                # Egzersiz etkisi: o günün yakılan kalorisi bankayı genişletir
                burned = await self._get_burned_calories(user_id, record.date)
                net = record.calories_consumed - burned
                bank += record.calories_target - net
        return round(bank)

    # ── Yardımcı: Banka mesajı üret ──
    def _generate_bank_message(
        self,
        weekly_bank: float,
        daily_target: float,
        calories_consumed: Optional[float],
        calories_burned: float,
    ) -> str:
        today_max = daily_target + max(weekly_bank, 0)

        if calories_burned > 0:
            burned_msg = f" Egzersizde {int(calories_burned)} kcal yaktın — bu bankana kredi olarak eklendi."
        else:
            burned_msg = ""

        if weekly_bank > 500:
            return f"🎉 Bu hafta {int(weekly_bank)} kcal kredin var! Bugün {int(today_max)} kcal'e kadar yiyebilirsin.{burned_msg}"
        elif weekly_bank > 0:
            return f"✅ {int(weekly_bank)} kcal kredin var. Bugün {int(today_max)} kcal hedefleyebilirsin.{burned_msg}"
        elif weekly_bank < -300:
            deficit = abs(int(weekly_bank))
            safe_today = max(daily_target - abs(weekly_bank) * 0.3, 1300)
            return f"⚠️ Bu hafta {deficit} kcal borcun var. Dengelemek için bugün {int(safe_today)} kcal civarında kal.{burned_msg}"
        else:
            return f"👍 Dengeli gidiyorsun. Bugünkü hedefin {int(daily_target)} kcal.{burned_msg}"

    # ── Yardımcı: Son ölçümden kilo çek ──
    async def _get_last_weight(self, user_id: str, db: AsyncSession) -> Optional[float]:
        result = await db.execute(
            select(MeasurementModel)
            .where(MeasurementModel.user_id == user_id)
            .order_by(MeasurementModel.date.desc())
            .limit(1)
        )
        last = result.scalar_one_or_none()
        return last.weight_kg if last else None

    # ── Yardımcı: entity → response ──
    async def _to_response(
        self, compliance: MealCompliance,
        daily_target: Optional[float] = None,
        weekly_bank: Optional[float] = None,
        calories_burned: float = 0.0,
    ) -> MealComplianceResponse:
        bank_message = None
        today_max = None
        if daily_target and weekly_bank is not None:
            bank_message = self._generate_bank_message(
                weekly_bank, daily_target, compliance.calories_consumed, calories_burned
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
            calories_burned=calories_burned,   # ← YENİ: response'a eklendi
            calories_target=compliance.calories_target,
            calorie_balance=compliance.calorie_balance,
            weekly_bank_balance=compliance.weekly_bank_balance,
            bank_message=bank_message,
            today_max_calories=today_max,
            created_at=compliance.created_at,
        )

    async def create(self, user_id: str, data, db) -> MealComplianceResponse:
        existing = await self.compliance_repository.get_by_date(user_id, data.date)
        if existing:
            raise BadRequestException(f"{data.date} tarihine ait diyet kaydı zaten mevcut")

        pref_repo = UserPreferenceRepository(db)
        prefs = await pref_repo.get_by_user_id(user_id)

        daily_target = None
        weekly_bank = None
        calorie_balance = None
        calories_burned = 0.0

        if prefs and data.calories_consumed is not None:
            weight_kg = await self._get_last_weight(user_id, db)
            tdee = self._calculate_tdee(prefs, weight_kg)
            if tdee:
                daily_target = self._calculate_daily_target(tdee, prefs.fitness_goal)

                # ── Egzersiz kalorisi dahil ──
                calories_burned = await self._get_burned_calories(user_id, data.date)
                net_consumed = data.calories_consumed - calories_burned
                calorie_balance = round(net_consumed - daily_target, 1)
                weekly_bank = await self._calculate_weekly_bank(user_id, data.date, daily_target)

        # ── complied otomatik hesapla — kullanıcı switch'e dokunmaz ──
        auto_complied = self._calculate_complied(
            data.calories_consumed, daily_target, calories_burned
        )

        compliance = MealCompliance(
            id=str(uuid.uuid4()),
            user_id=user_id,
            date=data.date,
            complied=auto_complied,          # ← otomatik
            compliance_rate=None,            # ← kaldırıldı, otomatik hesaplanıyor
            notes=data.notes,
            calories_consumed=data.calories_consumed,
            calories_target=daily_target,
            calorie_balance=calorie_balance,
            weekly_bank_balance=weekly_bank,
            created_at=datetime.now(timezone.utc),
        )
        created = await self.compliance_repository.create(compliance)
        await db.commit()
        return await self._to_response(created, daily_target, weekly_bank, calories_burned)

    async def get_by_date(self, user_id: str, target_date: date) -> MealComplianceResponse:
        compliance = await self.compliance_repository.get_by_date(user_id, target_date)
        if not compliance:
            raise NotFoundException(f"{target_date} tarihine ait diyet kaydı bulunamadı")
        calories_burned = await self._get_burned_calories(user_id, target_date)
        return await self._to_response(
            compliance, compliance.calories_target, compliance.weekly_bank_balance, calories_burned
        )

    async def get_by_date_range(self, user_id: str, from_date: date, to_date: date) -> list[MealComplianceResponse]:
        if from_date > to_date:
            raise BadRequestException("Başlangıç tarihi bitiş tarihinden büyük olamaz")
        records = await self.compliance_repository.get_by_date_range(user_id, from_date, to_date)
        results = []
        for r in records:
            burned = await self._get_burned_calories(user_id, r.date)
            results.append(await self._to_response(r, r.calories_target, r.weekly_bank_balance, burned))
        return results

    async def update(self, user_id: str, compliance_id: str, data, db) -> MealComplianceResponse:
        existing = await self.compliance_repository.get_by_id(compliance_id)
        if not existing:
            raise NotFoundException("Diyet kaydı bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Diyet kaydı bulunamadı")

        existing.notes = data.notes if data.notes is not None else existing.notes

        calories_burned = await self._get_burned_calories(user_id, existing.date)

        if data.calories_consumed is not None:
            existing.calories_consumed = data.calories_consumed
            pref_repo = UserPreferenceRepository(db)
            prefs = await pref_repo.get_by_user_id(user_id)
            if prefs:
                weight_kg = await self._get_last_weight(user_id, db)
                tdee = self._calculate_tdee(prefs, weight_kg)
                if tdee:
                    existing.calories_target = self._calculate_daily_target(tdee, prefs.fitness_goal)
                    net_consumed = data.calories_consumed - calories_burned
                    existing.calorie_balance = round(net_consumed - existing.calories_target, 1)
                    existing.weekly_bank_balance = await self._calculate_weekly_bank(
                        user_id, existing.date, existing.calories_target
                    )

            # complied otomatik güncelle
            existing.complied = self._calculate_complied(
                existing.calories_consumed, existing.calories_target, calories_burned
            )

        updated = await self.compliance_repository.update(existing)
        await db.commit()
        return await self._to_response(
            updated, existing.calories_target, existing.weekly_bank_balance, calories_burned
        )

    async def delete(self, user_id: str, compliance_id: str) -> bool:
        existing = await self.compliance_repository.get_by_id(compliance_id)
        if not existing:
            raise NotFoundException("Diyet kaydı bulunamadı")
        if existing.user_id != user_id:
            raise NotFoundException("Diyet kaydı bulunamadı")
        return await self.compliance_repository.delete(compliance_id)