# Rapor endpoint'lerinin request/response şemaları
from datetime import date
from typing import Optional

from pydantic import BaseModel


# ── Ölçüm özeti ──
class MeasurementSummary(BaseModel):
    # Haftanın/ayın son ölçüm değerleri
    weight_kg: Optional[float] = None
    body_fat_pct: Optional[float] = None
    muscle_mass_kg: Optional[float] = None
    waist_cm: Optional[float] = None
    # Hafta başına göre değişim — pozitif artış, negatif azalış
    weight_change: Optional[float] = None


# ── Su takibi özeti ──
class WaterSummary(BaseModel):
    # Dönemdeki günlük ortalama su tüketimi
    avg_daily_ml: float
    # Hedefi tutturan gün sayısı
    target_hit_days: int
    # Toplam kayıt gün sayısı
    total_days: int


# ── Uyku özeti ──
class SleepSummary(BaseModel):
    # Ortalama uyku süresi (saat)
    avg_hours: Optional[float] = None
    # Ortalama uyku kalitesi (1-10)
    avg_quality: Optional[float] = None
    # Toplam kayıt gün sayısı
    total_days: int


# ── Diyet uyum özeti ──
class MealComplianceSummary(BaseModel):
    # Diyete uyan gün sayısı
    complied_days: int
    # Toplam kayıt gün sayısı
    total_days: int
    # Uyum oranı — complied_days / total_days * 100
    compliance_rate: float


# ── Egzersiz özeti ──
class ExerciseSummary(BaseModel):
    # Toplam seans sayısı
    total_sessions: int
    # Toplam yakılan kalori
    total_calories: float
    # Toplam egzersiz süresi (dakika)
    total_duration_minutes: int


# ── Haftalık rapor response ──
class WeeklyReportResponse(BaseModel):
    # Hafta aralığı — "10-16 Mart 2026"
    week_start: date
    week_end: date
    # Her bölüm opsiyonel — o hafta veri yoksa None döner
    measurements: Optional[MeasurementSummary] = None
    water: Optional[WaterSummary] = None
    sleep: Optional[SleepSummary] = None
    meal_compliance: Optional[MealComplianceSummary] = None
    exercise: Optional[ExerciseSummary] = None


# ── Aylık rapor response ──
class MonthlyReportResponse(BaseModel):
    # Ay bilgisi — "2026-03"
    year: int
    month: int
    # Her bölüm opsiyonel — o ay veri yoksa None döner
    measurements: Optional[MeasurementSummary] = None
    water: Optional[WaterSummary] = None
    sleep: Optional[SleepSummary] = None
    meal_compliance: Optional[MealComplianceSummary] = None
    exercise: Optional[ExerciseSummary] = None


"""
DOSYA AKIŞI:
Her özet class ayrı bir tablonun verisini temsil eder.
WeeklyReportResponse ve MonthlyReportResponse bunları birleştirir.
Tüm alt özetler Optional — o dönemde hiç veri yoksa None döner, hata vermez.
Bu response yapısı Faz 8'de AI'a direkt input olarak gönderilecek.

Spring Boot karşılığı: Nested DTO sınıfları.
"""