# Rapor iş mantığı — tüm tablolardan veri toplayıp özet oluşturur
from datetime import date, timedelta
from typing import Optional

from sqlalchemy import select, and_, func
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.application.schemas.report import (
    WeeklyReportResponse, MonthlyReportResponse,
    MeasurementSummary, WaterSummary, SleepSummary,
    MealComplianceSummary, ExerciseSummary
)
# ORM modellerini direkt kullanıyoruz — rapor için ayrı repository yazmaya gerek yok
from backend.app.infrastructure.db.models.measurement_model import MeasurementModel
from backend.app.infrastructure.db.models.water_log_model import WaterLogModel
from backend.app.infrastructure.db.models.sleep_log_model import SleepLogModel
from backend.app.infrastructure.db.models.meal_compliance_model import MealComplianceModel
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel


class ReportService:

    def __init__(self, db: AsyncSession):
        self.db = db

    # ── Hafta başlangıcını hesapla (Pazartesi) ──
    def _get_week_range(self, reference_date: date) -> tuple[date, date]:
        # Pazartesi = 0, Pazar = 6
        # reference_date hangi gün olursa olsun o haftanın Pazartesi'sine döner
        days_since_monday = reference_date.weekday()
        week_start = reference_date - timedelta(days=days_since_monday)
        week_end = week_start + timedelta(days=6)
        return week_start, week_end

    # ── Ölçüm özeti ──
    async def _get_measurement_summary(
        self, user_id: str, start: date, end: date
    ) -> Optional[MeasurementSummary]:
        # Dönemdeki tüm ölçümleri tarihe göre sıralı getir
        result = await self.db.execute(
            select(MeasurementModel)
            .where(
                and_(
                    MeasurementModel.user_id == user_id,
                    MeasurementModel.date >= start,
                    MeasurementModel.date <= end,
                )
            )
            .order_by(MeasurementModel.date.asc())
        )
        measurements = result.scalars().all()

        # O dönemde hiç ölçüm yoksa None döndür
        if not measurements:
            return None

        # En son ölçümü al — dönemin son günündeki değeri göster
        latest = measurements[-1]

        # Ağırlık değişimi — ilk ve son ölçüm arasındaki fark
        weight_change = None
        if len(measurements) >= 2 and measurements[0].weight_kg and latest.weight_kg:
            weight_change = round(latest.weight_kg - measurements[0].weight_kg, 2)

        return MeasurementSummary(
            weight_kg=latest.weight_kg,
            body_fat_pct=latest.body_fat_pct,
            muscle_mass_kg=latest.muscle_mass_kg,
            waist_cm=latest.waist_cm,
            weight_change=weight_change,
        )

    # ── Su takibi özeti ──
    async def _get_water_summary(
        self, user_id: str, start: date, end: date
    ) -> Optional[WaterSummary]:
        result = await self.db.execute(
            select(WaterLogModel).where(
                and_(
                    WaterLogModel.user_id == user_id,
                    WaterLogModel.date >= start,
                    WaterLogModel.date <= end,
                )
            )
        )
        logs = result.scalars().all()

        if not logs:
            return None

        total_days = len(logs)
        # Günlük ortalama — toplam / gün sayısı
        avg_daily_ml = round(sum(l.amount_ml for l in logs) / total_days, 0)
        # Hedefi tutturan günler — amount_ml >= target_ml olan günler
        target_hit_days = sum(1 for l in logs if l.amount_ml >= l.target_ml)

        return WaterSummary(
            avg_daily_ml=avg_daily_ml,
            target_hit_days=target_hit_days,
            total_days=total_days,
        )

    # ── Uyku özeti ──
    async def _get_sleep_summary(
        self, user_id: str, start: date, end: date
    ) -> Optional[SleepSummary]:
        result = await self.db.execute(
            select(SleepLogModel).where(
                and_(
                    SleepLogModel.user_id == user_id,
                    SleepLogModel.date >= start,
                    SleepLogModel.date <= end,
                )
            )
        )
        logs = result.scalars().all()

        if not logs:
            return None

        total_days = len(logs)

        # Sadece duration_hours girilmiş kayıtlardan ortalama hesapla
        duration_logs = [l.duration_hours for l in logs if l.duration_hours is not None]
        avg_hours = round(sum(duration_logs) / len(duration_logs), 2) if duration_logs else None

        # Sadece quality_score girilmiş kayıtlardan ortalama hesapla
        quality_logs = [l.quality_score for l in logs if l.quality_score is not None]
        avg_quality = round(sum(quality_logs) / len(quality_logs), 1) if quality_logs else None

        return SleepSummary(
            avg_hours=avg_hours,
            avg_quality=avg_quality,
            total_days=total_days,
        )

    # ── Diyet uyum özeti ──
    async def _get_meal_compliance_summary(
        self, user_id: str, start: date, end: date
    ) -> Optional[MealComplianceSummary]:
        result = await self.db.execute(
            select(MealComplianceModel).where(
                and_(
                    MealComplianceModel.user_id == user_id,
                    MealComplianceModel.date >= start,
                    MealComplianceModel.date <= end,
                )
            )
        )
        logs = result.scalars().all()

        if not logs:
            return None

        total_days = len(logs)
        # complied=True olan günleri say
        complied_days = sum(1 for l in logs if l.complied)
        # Yüzde hesapla — 2 ondalık basamak
        compliance_rate = round((complied_days / total_days) * 100, 1)

        return MealComplianceSummary(
            complied_days=complied_days,
            total_days=total_days,
            compliance_rate=compliance_rate,
        )

    # ── Egzersiz özeti ──
    async def _get_exercise_summary(
        self, user_id: str, start: date, end: date
    ) -> Optional[ExerciseSummary]:
        result = await self.db.execute(
            select(ExerciseSessionModel).where(
                and_(
                    ExerciseSessionModel.user_id == user_id,
                    ExerciseSessionModel.date >= start,
                    ExerciseSessionModel.date <= end,
                )
            )
        )
        sessions = result.scalars().all()

        if not sessions:
            return None

        total_sessions = len(sessions)
        # None olan calories_burned değerlerini atla
        total_calories = round(
            sum(s.calories_burned for s in sessions if s.calories_burned is not None), 1
        )
        # None olan duration_minutes değerlerini atla
        total_duration = sum(
            s.duration_minutes for s in sessions if s.duration_minutes is not None
        )

        return ExerciseSummary(
            total_sessions=total_sessions,
            total_calories=total_calories,
            total_duration_minutes=total_duration,
        )

    # ── Haftalık rapor ──
    async def get_weekly_report(self, user_id: str, reference_date: date) -> WeeklyReportResponse:
        # reference_date'den haftanın başını ve sonunu hesapla
        week_start, week_end = self._get_week_range(reference_date)

        # Tüm özetleri paralel değil sıralı çek — async with aynı session
        measurements = await self._get_measurement_summary(user_id, week_start, week_end)
        water = await self._get_water_summary(user_id, week_start, week_end)
        sleep = await self._get_sleep_summary(user_id, week_start, week_end)
        meal_compliance = await self._get_meal_compliance_summary(user_id, week_start, week_end)
        exercise = await self._get_exercise_summary(user_id, week_start, week_end)

        return WeeklyReportResponse(
            week_start=week_start,
            week_end=week_end,
            measurements=measurements,
            water=water,
            sleep=sleep,
            meal_compliance=meal_compliance,
            exercise=exercise,
        )

    # ── Aylık rapor ──
    async def get_monthly_report(self, user_id: str, year: int, month: int) -> MonthlyReportResponse:
        # Ayın ilk ve son gününü hesapla
        start = date(year, month, 1)
        # Bir sonraki ayın ilk gününden bir gün çıkar → bu ayın son günü
        if month == 12:
            end = date(year + 1, 1, 1) - timedelta(days=1)
        else:
            end = date(year, month + 1, 1) - timedelta(days=1)

        # Aynı özetleri aylık tarih aralığıyla çek
        measurements = await self._get_measurement_summary(user_id, start, end)
        water = await self._get_water_summary(user_id, start, end)
        sleep = await self._get_sleep_summary(user_id, start, end)
        meal_compliance = await self._get_meal_compliance_summary(user_id, start, end)
        exercise = await self._get_exercise_summary(user_id, start, end)

        return MonthlyReportResponse(
            year=year,
            month=month,
            measurements=measurements,
            water=water,
            sleep=sleep,
            meal_compliance=meal_compliance,
            exercise=exercise,
        )


"""
DOSYA AKIŞI:
ReportService diğer servislerden farklı — repository pattern kullanmıyor.
Neden? Çünkü rapor için ayrı bir tablo yok, mevcut modellerden direkt okuyoruz.
ORM modellerini direkt import edip SQLAlchemy select() ile sorguluyoruz.

_get_week_range: herhangi bir tarihin Pazartesi-Pazar aralığını döndürür
Örn: 2026-03-17 (Salı) → week_start=2026-03-16, week_end=2026-03-22

Her _get_*_summary metodu:
  - O dönemde veri yoksa → None döner (hata vermez)
  - Veri varsa → özet hesaplayıp döner

Faz 8'de AI bu response'u input olarak alacak:
  report = await report_service.get_weekly_report(user_id, date.today())
  ai_summary = await ai_service.generate_summary(report)

Spring Boot karşılığı: @Service + custom @Query metodları.
"""