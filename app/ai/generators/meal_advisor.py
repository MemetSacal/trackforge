# Kan değerleri ve hastalık geçmişine göre diyet tavsiyesi
import json
from app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_MEAL


async def generate_meal_advice(
    liked_foods: list,
    disliked_foods: list,
    allergies: list,
    diseases: list,
    blood_values: dict,
    fitness_goal: str,
    calorie_target: int = None,
    # Fiziksel profil — BMR/TDEE hesabı için
    height_cm: float = None,
    age: int = None,
    gender: str = None,
    activity_level: str = None,
    weight_kg: float = None,
) -> dict:
    """
    Kullanıcının sağlık profili ve tercihlerine göre diyet tavsiyesi üretir.

    Returns:
        dict: {
            "summary": str,
            "daily_calorie_target": int,
            "macros": {...},
            "recommended_foods": [...],
            "foods_to_avoid": [...],
            "meal_suggestions": {...},
            "warnings": [...]
        }
    """
    client = get_claude_client()

    # Hedef etiketleri
    goal_labels = {
        "weight_loss": "kilo vermek",
        "muscle_gain": "kas kütlesi kazanmak",
        "maintenance": "mevcut kiloyu korumak"
    }
    goal_text = goal_labels.get(fitness_goal, fitness_goal)

    # Kan değerlerini okunabilir formata çevir
    blood_text = ""
    if blood_values:
        blood_text = f"\nKan değerleri: {json.dumps(blood_values, ensure_ascii=False)}"

    # Fiziksel profil varsa BMR ve TDEE hesapla (Mifflin-St Jeor formülü)
    physical_text = ""
    if height_cm and age and gender and weight_kg:
        if gender == "male":
            # Erkek BMR formülü
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age + 5
        else:
            # Kadın BMR formülü
            bmr = 10 * weight_kg + 6.25 * height_cm - 5 * age - 161

        # Aktivite seviyesine göre TDEE katsayıları
        activity_multipliers = {
            "sedentary": 1.2,       # Hareketsiz — masa başı iş
            "light": 1.375,         # Hafif aktif — haftada 1-3 gün egzersiz
            "moderate": 1.55,       # Orta aktif — haftada 3-5 gün egzersiz
            "active": 1.725,        # Aktif — haftada 6-7 gün egzersiz
            "very_active": 1.9      # Çok aktif — günde 2 antrenman
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

    prompt = f"""
Sen bir diyetisyen asistanısın. Kullanıcının sağlık profiline göre kişiselleştirilmiş diyet tavsiyesi ver.

ÖNEMLİ: Bu tıbbi tavsiye değil, genel beslenme önerisidir.

Kullanıcı profili:
- Hedef: {goal_text}
- Sevilen yiyecekler: {', '.join(liked_foods) if liked_foods else 'belirtilmemiş'}
- Sevilmeyen yiyecekler: {', '.join(disliked_foods) if disliked_foods else 'yok'}
- Alerjiler: {', '.join(allergies) if allergies else 'yok'}
- Hastalıklar/durumlar: {', '.join(diseases) if diseases else 'yok'}
- Kalori hedefi: {calorie_target if calorie_target else 'belirtilmemiş'}
{physical_text}
{blood_text}

SADECE JSON formatında yanıt ver:

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
  "meal_suggestions": {{
    "breakfast": "kahvaltı önerisi",
    "lunch": "öğle önerisi",
    "dinner": "akşam önerisi",
    "snack": "ara öğün önerisi"
  }},
  "warnings": ["varsa önemli uyarılar"]
}}
"""

    message = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=MAX_TOKENS_MEAL,
        messages=[{"role": "user", "content": prompt}]
    )

    response_text = message.content[0].text.strip()
    if "```json" in response_text:
        response_text = response_text.split("```json")[1].split("```")[0].strip()
    elif "```" in response_text:
        response_text = response_text.split("```")[1].split("```")[0].strip()

    return json.loads(response_text)


"""
DOSYA AKIŞI:
generate_meal_advice → kullanıcı tercihleri + kan değerleri + fiziksel profil alır → Claude'a gönderir → JSON diyet tavsiyesi döner.

BMR hesabı (Mifflin-St Jeor formülü):
  Erkek: 10 × kilo + 6.25 × boy - 5 × yaş + 5
  Kadın: 10 × kilo + 6.25 × boy - 5 × yaş - 161

TDEE = BMR × aktivite katsayısı
  sedentary: 1.2 / light: 1.375 / moderate: 1.55 / active: 1.725 / very_active: 1.9

Fiziksel profil girilmemişse physical_text boş kalır, Claude genel tavsiye verir.
"ÖNEMLİ: Bu tıbbi tavsiye değil" notu prompt'a eklendi — sorumluluk reddi.

Spring Boot karşılığı: @Service + dış API entegrasyonu.
"""