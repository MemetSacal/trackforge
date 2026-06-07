# ── ai/generators/calorie_bank_advisor.py ───────────────
# "Dengeleyelim" felsefesiyle çalışan kalori bankası AI danışmanı.
# Kullanıcıyı zorlamaz — ne yaşıyorsa dengeler, sonucu şeffaf gösterir.

import asyncio
from typing import Optional
from backend.app.ai.client import get_claude_client


async def generate_calorie_bank_advice(
    # Kullanıcı profili
    fitness_goal: str,              # weight_loss / muscle_gain / maintenance
    daily_target: float,            # Bugünkü kalori hedefi
    calories_consumed: float,       # Bugün yenen kalori
    calories_burned: float,         # Bugün yakılan kalori (egzersiz)
    weekly_bank: float,             # Haftalık birikimli banka bakiyesi

    # Kişisel bağlam
    age: Optional[int] = None,
    gender: Optional[str] = None,
    weight_kg: Optional[float] = None,
    target_weight_kg: Optional[float] = None,
    daily_calorie_habit: Optional[str] = None,  # "1500-2000" gibi alışkanlık aralığı

    # Geçmiş performans
    avg_weekly_loss_kg: Optional[float] = None,  # Kullanıcının geçmiş kilo verme hızı
    days_on_plan: Optional[int] = None,           # Kaç gündür programda
) -> dict:
    """
    Kullanıcının kalori bankası durumunu analiz edip kişiselleştirilmiş
    tavsiye üretir. Yasaklamaz, dengeler.
    """

    # ── Net kalori hesapla ────────────────────────────────
    # Egzersiz kalorisi bankayı genişletir
    net_consumed = calories_consumed - calories_burned
    net_balance = net_consumed - daily_target
    effective_bank = weekly_bank + calories_burned  # egzersiz kredi olarak eklenir

    # ── Hedef kilo tahmini ────────────────────────────────
    estimated_days = None
    if target_weight_kg and weight_kg and avg_weekly_loss_kg and avg_weekly_loss_kg > 0:
        kg_to_lose = abs(weight_kg - target_weight_kg)
        weekly_rate = avg_weekly_loss_kg
        estimated_weeks = kg_to_lose / weekly_rate
        estimated_days = int(estimated_weeks * 7)

    # ── Kademeli kalori azaltma önerisi ──────────────────
    # Kullanıcı alışkanlığından hedef kaloriye kademeli geçiş
    gradual_suggestion = None
    if daily_calorie_habit:
        try:
            parts = daily_calorie_habit.replace("+", "").split("-")
            habit_avg = sum(float(p) for p in parts) / len(parts)
            if habit_avg > daily_target + 300:
                # Çok büyük fark — kademeli indir
                step1 = round(habit_avg - 300)
                step2 = round(habit_avg - 600)
                gradual_suggestion = {
                    "current_habit": round(habit_avg),
                    "week_1_2_target": step1,
                    "week_3_4_target": step2,
                    "final_target": round(daily_target),
                    "message": f"Sizi zorlamadan {round(habit_avg)} kcal'den {round(daily_target)} kcal'e 4 haftada indiriyoruz."
                }
        except Exception:
            pass

    # ── Prompt ───────────────────────────────────────────
    goal_labels = {
        "weight_loss": "kilo vermek",
        "muscle_gain": "kas yapmak",
        "maintenance": "kiloyu korumak",
    }
    goal_label = goal_labels.get(fitness_goal, fitness_goal)

    prompt = f"""Sen TrackForge'un kalori bankası AI danışmanısın. Felsefeniz: Yasaklamak değil, dengelemek.

KULLANICI DURUMU:
- Hedef: {goal_label}
- Bugünkü kalori hedefi: {daily_target:.0f} kcal
- Bugün yenen: {calories_consumed:.0f} kcal
- Bugün yakılan (egzersiz): {calories_burned:.0f} kcal
- Net tüketim: {net_consumed:.0f} kcal
- Günlük denge: {"+" if net_balance > 0 else ""}{net_balance:.0f} kcal
- Haftalık banka bakiyesi: {"+" if effective_bank > 0 else ""}{effective_bank:.0f} kcal
{f"- Mevcut kilo: {weight_kg} kg" if weight_kg else ""}
{f"- Hedef kilo: {target_weight_kg} kg" if target_weight_kg else ""}
{f"- Yaş: {age}, Cinsiyet: {'Erkek' if gender == 'male' else 'Kadın'}" if age and gender else ""}
{f"- Geçmiş kilo verme hızı: haftada {avg_weekly_loss_kg:.1f} kg" if avg_weekly_loss_kg else ""}
{f"- Programda {days_on_plan} gündür" if days_on_plan else ""}

FELSEFEMİZ:
- Kullanıcıyı yargılama, yönlendir
- "Bunu yeme" değil, "bunu yediysen şöyle dengeleriz" de
- Alkol, tatlı, kaçamak — hepsi hesaba katılır, telafi edilir
- Hedef tarihi kesin değil, kişinin kendi hızına göre belirlenir
- Zorla değil, sürdürülebilir şekilde

Şu formatta JSON döndür, başka hiçbir şey yazma:
{{
    "status": "on_track" | "slightly_over" | "significantly_over" | "under_eating" | "great",
    "short_message": "Kısa, motive edici mesaj (max 100 karakter)",
    "detailed_advice": "Detaylı tavsiye (2-3 cümle, dengeleyelim felsefesiyle)",
    "tomorrow_suggestion": "Yarın için somut öneri",
    "weekly_outlook": "Haftalık genel değerlendirme",
    "estimated_goal_date": "Hedef tarih tahmini (varsa, string olarak ay/yıl formatında)",
    "telafi_options": ["Telafi seçeneği 1", "Telafi seçeneği 2", "Telafi seçeneği 3"]
}}"""

    client = get_claude_client()

    def _call():
        return client.messages.create(
            model="claude-sonnet-4-5",
            max_tokens=800,
            messages=[{"role": "user", "content": prompt}]
        )

    response = await asyncio.to_thread(_call)
    raw = response.content[0].text.strip()

    # JSON parse
    import json
    import re
    match = re.search(r'\{.*\}', raw, re.DOTALL)
    if match:
        advice = json.loads(match.group())
    else:
        advice = {
            "status": "on_track",
            "short_message": "Bugün iyi gidiyorsun!",
            "detailed_advice": "Verilerini takip etmeye devam et.",
            "tomorrow_suggestion": "Yarın da hedefe yakın kal.",
            "weekly_outlook": "Hafta genelinde dengeli görünüyorsun.",
            "estimated_goal_date": None,
            "telafi_options": []
        }

    # Ek hesaplanan alanları ekle
    advice["net_consumed"] = round(net_consumed)
    advice["net_balance"] = round(net_balance)
    advice["effective_bank"] = round(effective_bank)
    advice["estimated_days_to_goal"] = estimated_days
    advice["gradual_reduction_plan"] = gradual_suggestion

    return advice