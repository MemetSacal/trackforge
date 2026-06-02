import asyncio
import json
from backend.app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_RECIPE


async def generate_recipe(
    available_ingredients: list,
    liked_foods: list = None,
    disliked_foods: list = None,
    allergies: list = None,
    meal_type: str = "dinner",
    calorie_limit: int = None,
) -> dict:
    client = get_claude_client()

    meal_labels = {
        "breakfast": "kahvaltı",
        "lunch": "öğle yemeği",
        "dinner": "akşam yemeği",
        "snack": "ara öğün"
    }
    meal_text = meal_labels.get(meal_type, meal_type)

    prompt = f"""
Sen bir sağlıklı beslenme şefisin. Verilen malzemelerle sağlıklı bir {meal_text} tarifi öner.

Mevcut malzemeler: {', '.join(available_ingredients)}
Sevilen yiyecekler: {', '.join(liked_foods) if liked_foods else 'belirtilmemiş'}
Sevilmeyen yiyecekler: {', '.join(disliked_foods) if disliked_foods else 'yok'}
Alerjiler: {', '.join(allergies) if allergies else 'yok'}
Kalori limiti: {calorie_limit if calorie_limit else 'yok'}

SADECE JSON formatında yanıt ver:

{{
  "recipe_name": "tarif adı",
  "description": "kısa açıklama",
  "ingredients": [
    {{"name": "malzeme", "amount": "miktar", "unit": "birim"}}
  ],
  "steps": [
    {{"step": 1, "instruction": "adım açıklaması", "duration_minutes": 5}}
  ],
  "nutrition": {{
    "calories": 350,
    "protein_g": 25,
    "carbs_g": 40,
    "fat_g": 10,
    "fiber_g": 5
  }},
  "prep_time_minutes": 10,
  "cook_time_minutes": 20,
  "servings": 2,
  "tips": "pişirme ipuçları"
}}
"""

    # ✅ Senkron Claude çağrısını ayrı thread'de çalıştır
    def _call():
        return client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=MAX_TOKENS_RECIPE,
            messages=[{"role": "user", "content": prompt}]
        )

    message = await asyncio.to_thread(_call)

    response_text = message.content[0].text.strip()
    if "```json" in response_text:
        response_text = response_text.split("```json")[1].split("```")[0].strip()
    elif "```" in response_text:
        response_text = response_text.split("```")[1].split("```")[0].strip()

    return json.loads(response_text)