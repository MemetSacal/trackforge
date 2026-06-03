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
    craving: str = None,           # tatlı / tuzlu / baharatlı / hafif / ağır / diyete uygun
    weekly_bank_balance: float = None,  # haftanın kalori açığı/fazlası
    daily_calorie_target: int = None,
) -> dict:
    client = get_claude_client()

    meal_labels = {
        "breakfast": "kahvaltı",
        "lunch":     "öğle yemeği",
        "dinner":    "akşam yemeği",
        "snack":     "ara öğün",
    }
    meal_text = meal_labels.get(meal_type, meal_type)

    craving_text = ""
    if craving:
        craving_text = f"\nKullanıcının canı: {craving}"

    calorie_text = ""
    if weekly_bank_balance is not None and daily_calorie_target:
        if weekly_bank_balance > 200:
            # Haftanın fazlası var — biraz kısıtlı tarif
            calorie_text = (
                f"\nKalori bankası durumu: Bu hafta {int(weekly_bank_balance)} kcal fazla alınmış. "
                f"Tarifin kalori hedefi günlük {daily_calorie_target} kcal'in altında olsun — "
                f"yaklaşık {max(300, daily_calorie_target - 200)} kcal civarında tut."
            )
        elif weekly_bank_balance < -200:
            # Haftanın açığı var — biraz daha dolu tarif
            calorie_text = (
                f"\nKalori bankası durumu: Bu hafta {abs(int(weekly_bank_balance))} kcal açık var. "
                f"Tarifin kalori hedefi günlük {daily_calorie_target} kcal'e yakın veya biraz üzerinde olabilir — "
                f"yaklaşık {daily_calorie_target + 100} kcal civarında tut."
            )
        else:
            calorie_text = (
                f"\nKalori bankası: Dengeli durumda. "
                f"Tarifin kalori hedefi yaklaşık {daily_calorie_target} kcal olsun."
            )
    elif calorie_limit:
        calorie_text = f"\nKalori limiti: {calorie_limit} kcal"

    ingredient_text = ""
    if available_ingredients:
        ingredient_text = f"\nKullanıcının eklemek istediği malzemeler: {', '.join(available_ingredients)}"
    else:
        ingredient_text = "\nKullanıcı özel malzeme belirtmedi — genel market malzemeleri kullanabilirsin."

    prompt = f"""
Sen bir sağlıklı beslenme şefisin. Kullanıcının tercihlerine göre kişiselleştirilmiş bir {meal_text} tarifi öner.

Kullanıcı profili:
- Sevilen yiyecekler: {', '.join(liked_foods) if liked_foods else 'belirtilmemiş'}
- Sevilmeyen yiyecekler: {', '.join(disliked_foods) if disliked_foods else 'yok'}
- Alerjiler: {', '.join(allergies) if allergies else 'yok'}
{ingredient_text}
{craving_text}
{calorie_text}

ÖNEMLİ TALİMATLAR:
- Tarif sağlıklı ve dengeli olsun
- Malzeme listesi market'te bulunabilir, pratik şeyler olsun
- Adımlar açık ve anlaşılır olsun
- Eğer kullanıcının canı tatlı istiyorsa sağlıklı tatlı alternatifi ver
- Eğer diyete uygun istiyorsa düşük kalorili, protein ağırlıklı tarif ver

SADECE JSON formatında yanıt ver:

{{
  "recipe_name": "tarif adı",
  "description": "kısa açıklama (1-2 cümle)",
  "ingredients": [
    {{"name": "malzeme adı", "amount": "miktar ve birim (örn: 200g, 1 su bardağı, 2 adet)"}}
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
  "tips": "pişirme ipuçları veya alternatif öneri"
}}
"""

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