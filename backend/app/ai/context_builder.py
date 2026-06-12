# ── context_builder.py — Ortak AI bağlamı (v2'nin kalbi) ──
#
# SORUN: 5+ AI modülü birbirinden habersizdi (silo sorunu).
#   workout_generator döngü fazını bilmiyordu, meal_advisor antrenman
#   günlerini bilmiyordu, weekly_analyzer kullanıcının plana kendi
#   eklediği egzersizleri görmüyordu.
#
# ÇÖZÜM: build_user_context() — kullanıcının güncel durumunu ve son
#   7 gününü TEK standart blok halinde toplar. Her AI prompt'unun
#   başına eklenir. Böylece tüm modüller "aynı koçun beyni" gibi
#   davranır ve AI tek yönlü olmaktan çıkar: ürettiği planın
#   gerçekleşmesini bir sonraki üretimde GÖRÜR.
#
# Tasarım kuralları:
#   - Sadece son durum + son 7 gün (~300-500 token hedefi)
#   - Veri yoksa satır tamamen atlanır ("veri yok" ile "kötü gitti"
#     asla karışmaz — 3 durumlu compliance mantığı)

from datetime import date, timedelta

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from backend.app.infrastructure.db.models.measurement_model import MeasurementModel
from backend.app.infrastructure.db.models.exercise_session_model import ExerciseSessionModel
from backend.app.infrastructure.db.models.session_exercise_model import SessionExerciseModel
from backend.app.infrastructure.db.models.meal_compliance_model import MealComplianceModel
from backend.app.infrastructure.db.models.menstrual_cycle_model import MenstrualCycleModel
from backend.app.infrastructure.repositories.user_preference_repository import UserPreferenceRepository

GOAL_TR = {
    "weight_loss": "kilo vermek",
    "muscle_gain": "kas kazanmak",
    "maintenance": "formu korumak",
}

PHASE_TR = {
    "menstrual": "regl",
    "follicular": "foliküler",
    "ovulation": "ovulasyon",
    "luteal": "luteal",
}


async def build_user_context(db: AsyncSession, user_id: str) -> str:
    """Tüm AI modüllerinin prompt'una eklenen ortak bağlam bloğu."""
    parts: list[str] = ["## KULLANICI BAĞLAMI (sistem tarafından otomatik eklendi)"]
    today = date.today()
    week_ago = today - timedelta(days=7)

    # ── Profil + hedef ──
    prefs = None
    try:
        prefs = await UserPreferenceRepository(db).get_by_user_id(user_id)
    except Exception:
        pass
    if prefs:
        line = f"Hedef: {GOAL_TR.get(prefs.fitness_goal or '', prefs.fitness_goal or 'belirtilmemiş')}"
        if getattr(prefs, "target_weight_kg", None):
            line += f" | Hedef kilo: {prefs.target_weight_kg} kg"
        if prefs.activity_level:
            line += f" | Aktivite: {prefs.activity_level}"
        parts.append(line)
        if prefs.allergies:
            parts.append(f"Alerjiler: {', '.join(prefs.allergies)}")

    # ── Güncel ölçüm ──
    m = (await db.execute(
        select(MeasurementModel)
        .where(MeasurementModel.user_id == user_id)
        .order_by(MeasurementModel.date.desc())
        .limit(2)
    )).scalars().all()
    if m:
        line = f"Güncel kilo: {m[0].weight_kg} kg ({m[0].date})"
        if len(m) >= 2 and m[0].weight_kg and m[1].weight_kg:
            diff = round(m[0].weight_kg - m[1].weight_kg, 1)
            yon = "↓" if diff < 0 else ("↑" if diff > 0 else "→")
            line += f" | Önceki ölçüme göre: {yon} {abs(diff)} kg"
        parts.append(line)

    # ── Son 7 gün antrenman gerçekleşmesi ──
    # AI'ın ürettiği planın akıbetini görmesini sağlayan kısım.
    sessions = (await db.execute(
        select(ExerciseSessionModel)
        .where(ExerciseSessionModel.user_id == user_id,
               ExerciseSessionModel.date >= week_ago)
        .order_by(ExerciseSessionModel.date.desc())
    )).scalars().all()
    if sessions:
        session_ids = [s.id for s in sessions]
        exercises = (await db.execute(
            select(SessionExerciseModel)
            .where(SessionExerciseModel.session_id.in_(session_ids))
        )).scalars().all()
        done = [e for e in exercises if getattr(e, "completed", False)]
        total_cal = sum(s.calories_burned or 0 for s in sessions)
        # v4: plan kilidi — AI planı seansları ile serbest seanslar ayrı sayılır.
        # AI, planına ne kadar uyulduğunu VE plan dışı ne kadar iş yapıldığını
        # ayrı ayrı görür ("planın %130'u" karmaşası biter).
        ai_sessions = [s for s in sessions if getattr(s, "source", "manual") == "ai_plan"]
        free_sessions = [s for s in sessions if getattr(s, "source", "manual") != "ai_plan"]
        parts.append(
            f"Son 7 gün antrenman: {len(sessions)} seans "
            f"({len(ai_sessions)} plan seansı + {len(free_sessions)} serbest), "
            f"{len(done)}/{len(exercises)} egzersiz tamamlandı, "
            f"~{int(total_cal)} kcal yakıldı"
        )
        # Kullanıcının kendisinin en çok yaptığı egzersizler → AI'a sinyal
        # ("kullanıcı sürekli biceps ekliyor" gibi tercihleri yakalar)
        names = {}
        for e in done:
            names[e.exercise_name] = names.get(e.exercise_name, 0) + 1
        top = sorted(names.items(), key=lambda x: -x[1])[:5]
        if top:
            parts.append("En çok yapılan egzersizler: " + ", ".join(n for n, _ in top))

    # ── Son 7 gün beslenme uyumu (3 durumlu) ──
    mc_rows = (await db.execute(
        select(MealComplianceModel)
        .where(MealComplianceModel.user_id == user_id,
               MealComplianceModel.date >= week_ago)
    )).scalars().all()
    if mc_rows:
        usable = [r for r in mc_rows if r.calories_consumed is not None]
        complied = sum(1 for r in usable if r.complied)
        deviated = len(usable) - complied
        no_data = 7 - len(usable)  # kayıtsız VEYA kalorisiz gün ≠ uyumsuz gün (v4 inceltme)
        cal_days = [r.calories_consumed for r in usable if r.calories_consumed]
        line = f"Son 7 gün beslenme: {complied} gün uyumlu, {deviated} gün sapma, {no_data} gün kayıtsız"
        if cal_days:
            line += f" | Ort. alınan: {int(sum(cal_days) / len(cal_days))} kcal/gün"
        parts.append(line)

    # ── v6: 🌙 Ramazan/oruç modu ──
    if prefs and getattr(prefs, "fasting_mode", False):
        parts.append(
            "🌙 ORUÇ/RAMAZAN MODU AKTİF: Kullanıcı gün boyunca yemek yemiyor ve su içmiyor. "
            "Beslenme önerilerini SADECE iftar (akşam) ve sahur (şafak öncesi) öğünlerine göre yapılandır. "
            "Sahurda tok tutan (protein + kompleks karbonhidrat + sağlıklı yağ), iftar açılışında hafif başlangıç öner. "
            "Antrenmanı iftardan 1-2 saat sonrasına veya iftara yakın saate öner; gündüz yoğun antrenman ÖNERME. "
            "Gündüz su/beslenme hatırlatması YAPMA; sıvı hedefini iftar-sahur aralığına sıkıştır. "
            "Kalori hedefini iki öğüne gerçekçi böl."
        )

    # ── v3: Plato tespiti — AI proaktif değinsin ──
    plateau = await detect_plateau(db, user_id)
    goal = getattr(prefs, "fitness_goal", None) if prefs else None
    if plateau and goal == "weight_loss":
        parts.append(
            f"DİKKAT — PLATO: Kilo {plateau['weeks']} haftadır {plateau['weight_kg']} kg civarında sabit "
            f"(değişim {plateau['change_kg']:+} kg). Tavsiyelerinde buna MUTLAKA değin ve "
            f"plato kırıcı somut öneriler ver (kalori döngüsü, NEAT artışı, antrenman değişikliği gibi)."
        )

    # ── Döngü fazı (varsa) ──
    # Regl verisi toplanıyordu ama workout/meal AI'ları KULLANMIYORDU.
    cycle = (await db.execute(
        select(MenstrualCycleModel)
        .where(MenstrualCycleModel.user_id == user_id)
        .order_by(MenstrualCycleModel.cycle_start_date.desc())
        .limit(1)
    )).scalar_one_or_none()
    if cycle:
        cycle_len = cycle.cycle_length_days or 28
        period_len = cycle.period_length_days or 5
        day_in_cycle = ((today - cycle.cycle_start_date).days % cycle_len) + 1
        if day_in_cycle <= period_len:
            phase = "menstrual"
        elif day_in_cycle <= 13:
            phase = "follicular"
        elif day_in_cycle <= 16:
            phase = "ovulation"
        else:
            phase = "luteal"
        parts.append(
            f"Döngü: {PHASE_TR[phase]} faz, {day_in_cycle}. gün — "
            f"antrenman yoğunluğu ve kalori önerilerinde bu fazı dikkate al"
        )

    # ── Bugünün kalori durumu ──
    mc_today = next((r for r in mc_rows if r.date == today), None) if mc_rows else None
    if mc_today and mc_today.calories_target:
        consumed = mc_today.calories_consumed or 0
        remaining = int(mc_today.calories_target - consumed)
        parts.append(f"Bugün: hedef {int(mc_today.calories_target)} kcal, alınan {int(consumed)} kcal, kalan {remaining} kcal")

    if len(parts) == 1:
        return ""  # hiç veri yoksa boş bağlam — prompt'u kirletme

    return "\n".join(parts)


# ═════════════════════════════════════════════════════════
# ── v3: Plato dedektörü ──
# Kilo verme hedefli kullanıcının kilosu 3+ haftadır yerinde
# sayıyorsa bunu TESPİT eder. İki yerden kullanılır:
#   1. build_user_context → AI özetlerde/tavsiyelerde PROAKTİF
#      olarak değinir ("reaktif koç" yerine "proaktif koç")
#   2. GET /ai/plateau-status → mobil tarafta banner göstermek için
# ═════════════════════════════════════════════════════════

PLATEAU_MIN_DAYS = 21          # en az 3 hafta
PLATEAU_THRESHOLD_PCT = 0.5    # toplam değişim < %0.5 ise plato


async def detect_plateau(db: AsyncSession, user_id: str) -> dict | None:
    """Plato varsa {"weeks": n, "weight_kg": x, "change_kg": y} döner, yoksa None.

    Mantık: Son 5 haftanın ölçümleri içinde, en az 21 gün aralıkla
    en az 3 ölçüm varsa ve ilk-son fark vücut ağırlığının %0.5'inden
    azsa → plato. (Günlük dalgalanmaları tekil ölçüm yerine uçlar
    arası farkla okumak yeterince dayanıklı.)"""
    since = date.today() - timedelta(weeks=5)
    rows = (await db.execute(
        select(MeasurementModel)
        .where(MeasurementModel.user_id == user_id,
               MeasurementModel.date >= since,
               MeasurementModel.weight_kg.isnot(None))
        .order_by(MeasurementModel.date.asc())
    )).scalars().all()

    if len(rows) < 3:
        return None
    first, last = rows[0], rows[-1]
    span_days = (last.date - first.date).days
    if span_days < PLATEAU_MIN_DAYS:
        return None

    change = abs(last.weight_kg - first.weight_kg)
    if change >= last.weight_kg * (PLATEAU_THRESHOLD_PCT / 100):
        return None

    return {
        "weeks": round(span_days / 7, 1),
        "weight_kg": last.weight_kg,
        "change_kg": round(last.weight_kg - first.weight_kg, 2),
    }
