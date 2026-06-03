import asyncio
import json
from backend.app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_MEAL


async def generate_cycle_advice(
    current_phase: str,
    current_day: int,
    cycle_length_days: int,
    period_length_days: int,
    fitness_goal: str = None,
    liked_foods: list = None,
    disliked_foods: list = None,
    allergies: list = None,
    weight_kg: float = None,
    height_cm: float = None,
    age: int = None,
    activity_level: str = None,
) -> dict:
    client = get_claude_client()

    phase_labels = {
        "menstrual":   "Menstrüasyon (Adet)",
        "follicular":  "Foliküler",
        "ovulation":   "Ovülasyon",
        "luteal":      "Luteal",
    }
    phase_text = phase_labels.get(current_phase, current_phase)

    goal_labels = {
        "weight_loss":  "kilo vermek",
        "muscle_gain":  "kas kütlesi kazanmak",
        "maintenance":  "mevcut kiloyu korumak",
        "health":       "sağlıklı kalmak",
    }
    goal_text = goal_labels.get(fitness_goal or "health", fitness_goal or "sağlıklı kalmak")

    physical_text = ""
    if height_cm and age and weight_kg:
        physical_text = (
            f"\nFiziksel profil:"
            f"\n- Boy: {height_cm} cm"
            f"\n- Kilo: {weight_kg} kg"
            f"\n- Yaş: {age}"
            f"\n- Aktivite seviyesi: {activity_level or 'orta'}"
        )

    food_text = ""
    if liked_foods:
        food_text += f"\n- Sevilen yiyecekler: {', '.join(liked_foods)}"
    if disliked_foods:
        food_text += f"\n- Sevilmeyen yiyecekler: {', '.join(disliked_foods)}"
    if allergies:
        food_text += f"\n- Alerjiler: {', '.join(allergies)}"

    prompt = f"""
Sen bir kadın sağlığı uzmanı ve diyetisyensin. Kullanıcının menstüral döngü fazına göre kişiselleştirilmiş diyet ve antrenman önerisi ver.

ÖNEMLİ: Bu tıbbi tavsiye değil, genel sağlık önerisidir.

Kullanıcı bilgileri:
- Mevcut faz: {phase_text}
- Döngünün {current_day}. günü ({cycle_length_days} günlük döngü)
- Adet süresi: {period_length_days} gün
- Fitness hedefi: {goal_text}
{physical_text}
{food_text}

Her faz için öneriler:
- Menstrüasyon: Demir, magnezyum, anti-enflamatuar besinler. Hafif egzersiz (yoga, yürüyüş).
- Foliküler: Protein, kompleks karbonhidrat. Orta-yoğun antrenman.
- Ovülasyon: Antioksidanlar, hafif kalori artışı. Yoğun HIIT, güç antrenmanı.
- Luteal: Magnezyum, B6, karmaşık karbonhidrat. Orta egzersiz, stres yönetimi.

SADECE JSON formatında yanıt ver:

{{
  "phase_summary": "Bu fazda vücudun nasıl hisseder, 2 cümle",
  "energy_level": "düşük/orta/yüksek",
  "diet_advice": {{
    "focus_nutrients": ["besin1", "besin2", "besin3"],
    "recommended_foods": ["yiyecek1", "yiyecek2", "yiyecek3", "yiyecek4", "yiyecek5"],
    "foods_to_limit": ["yiyecek1", "yiyecek2"],
    "calorie_adjustment": "normal/+100-200 kcal artır/-100 kcal azalt",
    "meal_tip": "Bu faz için özel beslenme ipucu, 1-2 cümle"
  }},
  "workout_advice": {{
    "recommended_types": ["egzersiz tipi 1", "egzersiz tipi 2"],
    "intensity": "hafif/orta/yoğun",
    "duration_minutes": 30,
    "workout_tip": "Bu faz için özel antrenman ipucu, 1-2 cümle",
    "avoid": ["kaçınılacak egzersiz"]
  }},
  "wellness_tips": ["genel tavsiye 1", "genel tavsiye 2", "genel tavsiye 3"]
}}
"""

    def _call():
        return client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=MAX_TOKENS_MEAL,
            messages=[{"role": "user", "content": prompt}]
        )

    message = await asyncio.to_thread(_call)

    response_text = message.content[0].text.strip()
    if "```json" in response_text:
        response_text = response_text.split("```json")[1].split("```")[0].strip()
    elif "```" in response_text:
        response_text = response_text.split("```")[1].split("```")[0].strip()

    return json.loads(response_text)