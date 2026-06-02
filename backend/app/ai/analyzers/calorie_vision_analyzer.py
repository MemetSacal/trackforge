import asyncio
import base64
import json
from backend.app.ai.client import get_claude_client, CLAUDE_MODEL


async def analyze_food_calories(image_data: bytes, image_media_type: str = "image/jpeg") -> dict:
    client = get_claude_client()

    image_base64 = base64.standard_b64encode(image_data).decode("utf-8")

    prompt = """Bu yemek fotoğrafını analiz et ve kalori ile besin değerlerini hesapla.

Gördüğün yiyecekleri tek tek listele ve toplam değerleri hesapla.
Porsiyon boyutlarını fotoğraftaki görsel ipuçlarından tahmin et.

SADECE JSON formatında yanıt ver, başka hiçbir şey yazma:

{
  "food_items": [
    {
      "name": "yiyecek adı",
      "estimated_portion": "tahmini porsiyon (örn: 150g, 1 porsiyon)",
      "calories": 250,
      "protein_g": 20,
      "carbs_g": 30,
      "fat_g": 8
    }
  ],
  "total_calories": 450,
  "macros": {
    "protein_g": 35,
    "carbs_g": 55,
    "fat_g": 12,
    "fiber_g": 5
  },
  "confidence": "high/medium/low",
  "notes": "varsa önemli notlar"
}"""

    # ✅ Senkron Claude çağrısını ayrı thread'de çalıştır
    def _call():
        return client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=1000,
            messages=[
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "image",
                            "source": {
                                "type": "base64",
                                "media_type": image_media_type,
                                "data": image_base64,
                            },
                        },
                        {
                            "type": "text",
                            "text": prompt
                        }
                    ],
                }
            ],
        )

    message = await asyncio.to_thread(_call)

    response_text = message.content[0].text.strip()
    if "```json" in response_text:
        response_text = response_text.split("```json")[1].split("```")[0].strip()
    elif "```" in response_text:
        response_text = response_text.split("```")[1].split("```")[0].strip()

    return json.loads(response_text)