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
generate_meal_advice → kullanıcı tercihleri + kan değerleri + hastalıklar alır → Claude'a gönderir → JSON diyet tavsiyesi döner.
"ÖNEMLİ: Bu tıbbi tavsiye değil" notu prompt'a eklendi — sorumluluk reddi.
blood_values dict olarak gelir → json.dumps ile okunabilir hale getirilir.

Spring Boot karşılığı: @Service + dış API entegrasyonu.
"""