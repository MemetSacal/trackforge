import asyncio
import json
from backend.app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_MEAL


async def generate_meal_advice(
    liked_foods: list,
    disliked_foods: list,
    allergies: list,
    diseases: list,
    blood_values: dict,
    fitness_goal: str,
    calorie_target: int = None,
    height_cm: float = None,
    age: int = None,
    gender: str = None,
    activity_level: str = None,
    weight_kg: float = None,
    user_context: str = "",
) -> dict:
    # v2: user_context — build_user_context() çıktısı.
    # Diyet planı artık antrenman günlerini, döngü fazını ve geçen
    # haftanın gerçek beslenme uyumunu BİLEREK üretilir (silo çözümü).
    client = get_claude_client()

    goal_labels = {
        "weight_loss": "kilo vermek",
        "muscle_gain": "kas kütlesi kazanmak",
        "maintenance": "mevcut kiloyu korumak"
    }
    goal_text = goal_labels.get(fitness_goal, fitness_goal)

    blood_text = ""
    if blood_values:
        blood_text = f"\nKan değerleri: {json.dumps(blood_values, ensure_ascii=False)}"

    physical_text = ""
    if height_cm and age and gender and weight_kg:
        if gender == "male":
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
        else:
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161

        activity_multipliers = {
            "sedentary": 1.2,
            "light": 1.375,
            "moderate": 1.55,
            "active": 1.725,
            "very_active": 1.9
        }
        multiplier = activity_multipliers.get(activity_level or "moderate", 1.55)
        tdee = round(bmr * multiplier)

        physical_text = (
            f"\nFiziksel profil:"
            f"\n- Boy: {height_cm} cm"
            f"\n- Kilo: {weight_kg} kg"
            f"\n- Yaş: {age}"
            f"\n- Cinsiyet: {'Erkek' if gender == 'male' else 'Kadın'}"
            f"\n- Aktivite seviyesi: {activity_level or 'moderate'}"
            f"\n- Tahmini günlük kalori ihtiyacı (TDEE): {tdee} kcal"
        )

    context_block = f"\n{user_context}\n" if user_context else ""

    prompt = f"""
Sen bir diyetisyen asistanısın. Kullanıcının sağlık profiline göre kişiselleştirilmiş 7 günlük haftalık diyet planı oluştur.

ÖNEMLİ: Bu tıbbi tavsiye değil, genel beslenme önerisidir.
{context_block}
Yukarıdaki kullanıcı bağlamı varsa MUTLAKA dikkate al: antrenman yapılan
günlerde karbonhidratı artır, döngü fazına göre demir/magnezyum gibi
ihtiyaçları gözet, geçen haftaki gerçek uyuma göre planı gerçekçi tut
(sürekli sapma varsa daha esnek ve uygulanabilir bir plan yaz).

Kullanıcı profili:
- Hedef: {goal_text}
- Sevilen yiyecekler: {', '.join(liked_foods) if liked_foods else 'belirtilmemiş'}
- Sevilmeyen yiyecekler: {', '.join(disliked_foods) if disliked_foods else 'yok'}
- Alerjiler: {', '.join(allergies) if allergies else 'yok'}
- Hastalıklar/durumlar: {', '.join(diseases) if diseases else 'yok'}
- Kalori hedefi: {calorie_target if calorie_target else 'belirtilmemiş'}
{physical_text}
{blood_text}

SADECE JSON formatında yanıt ver, başka hiçbir şey yazma:

{{
  "summary": "kısa özet (2 cümle)",
  "daily_calorie_target": 2000,
  "macros": {{
    "protein_g": 150,
    "carbs_g": 200,
    "fat_g": 70
  }},
  "recommended_foods": ["yiyecek1", "yiyecek2"],
  "foods_to_avoid": ["yiyecek1", "yiyecek2"],
  "weekly_plan": {{
    "pazartesi": {{
      "breakfast": "kahvaltı önerisi",
      "lunch": "öğle yemeği önerisi",
      "dinner": "akşam yemeği önerisi",
      "snack": "ara öğün önerisi"
    }},
    "salı": {{
      "breakfast": "kahvaltı önerisi",
      "lunch": "öğle yemeği önerisi",
      "dinner": "akşam yemeği önerisi",
      "snack": "ara öğün önerisi"
    }},
    "çarşamba": {{
      "breakfast": "kahvaltı önerisi",
      "lunch": "öğle yemeği önerisi",
      "dinner": "akşam yemeği önerisi",
      "snack": "ara öğün önerisi"
    }},
    "perşembe": {{
      "breakfast": "kahvaltı önerisi",
      "lunch": "öğle yemeği önerisi",
      "dinner": "akşam yemeği önerisi",
      "snack": "ara öğün önerisi"
    }},
    "cuma": {{
      "breakfast": "kahvaltı önerisi",
      "lunch": "öğle yemeği önerisi",
      "dinner": "akşam yemeği önerisi",
      "snack": "ara öğün önerisi"
    }},
    "cumartesi": {{
      "breakfast": "kahvaltı önerisi",
      "lunch": "öğle yemeği önerisi",
      "dinner": "akşam yemeği önerisi",
      "snack": "ara öğün önerisi"
    }},
    "pazar": {{
      "breakfast": "kahvaltı önerisi",
      "lunch": "öğle yemeği önerisi",
      "dinner": "akşam yemeği önerisi",
      "snack": "ara öğün önerisi"
    }}
  }},
  "meal_suggestions": {{
    "breakfast": "bugünkü kahvaltı önerisi",
    "lunch": "bugünkü öğle önerisi",
    "dinner": "bugünkü akşam önerisi",
    "snack": "bugünkü ara öğün önerisi"
  }},
  "shopping_list": [
    {{"name": "malzeme adı", "quantity": "haftalık tahmini miktar (örn: 500g, 2 adet)"}}
  ],
  "warnings": ["varsa önemli uyarılar"]
}}

shopping_list KURALI: weekly_plan'daki tüm öğünler için gereken malzemeleri
konsolide et — aynı malzeme birden çok günde geçiyorsa TEK satırda topla.
Temel kiler malzemelerini (tuz, su) dahil etme. En fazla 25 kalem.
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

    result = json.loads(response_text)

    # weekly_plan'dan bugünün gününü meal_suggestions'a set et (fallback)
    if "weekly_plan" in result and result["weekly_plan"]:
        days_tr = ["pazartesi", "salı", "çarşamba", "perşembe", "cuma", "cumartesi", "pazar"]
        from datetime import datetime
        today_idx = datetime.now().weekday()  # 0=Pazartesi
        today_key = days_tr[today_idx]
        today_meals = result["weekly_plan"].get(today_key, {})
        if today_meals:
            result["meal_suggestions"] = today_meals

    return result