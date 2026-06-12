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

# ═════════════════════════════════════════════════════════
# ── v3: Buzdolabı/kiler fotoğrafından malzeme çıkarma ──
# Aynı vision altyapısı, farklı görev: fotoğraftaki yenilebilir
# malzemeleri listele → recipe_generator'a beslenir.
# "Dolapta ne varsa fotoğrafla, akşam yemeğini söyleyeyim."
# ═════════════════════════════════════════════════════════

async def analyze_fridge_ingredients(image_data: bytes, image_media_type: str = "image/jpeg") -> list:
    client = get_claude_client()
    image_base64 = base64.standard_b64encode(image_data).decode("utf-8")

    prompt = """Bu bir buzdolabı, kiler veya mutfak tezgahı fotoğrafı.
Görünen YENİLEBİLİR malzemeleri tespit et.

Kurallar:
- Sadece net şekilde tanıyabildiğin malzemeleri yaz
- Marka adı değil, malzeme adı yaz ("Pınar Süt" değil "süt")
- Yemek pişirmede kullanılamayacak şeyleri (içecek şişesi hariç su, ilaç vb.) dahil etme
- En fazla 20 malzeme

SADECE JSON formatında yanıt ver, başka hiçbir şey yazma:

{
  "ingredients": ["domates", "yumurta", "kaşar peyniri", "biber"],
  "confidence": "high/medium/low"
}"""

    def _call():
        return client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=512,
            messages=[{
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
                    {"type": "text", "text": prompt},
                ],
            }],
        )

    message = await asyncio.to_thread(_call)
    text = message.content[0].text.strip()
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()
    data = json.loads(text)
    return data.get("ingredients", [])


# ═════════════════════════════════════════════════════════
# ── v6: Serbest metinden kalori analizi ──
# "2 yumurta, bir dilim tam buğday ekmeği, şekersiz çay" →
# kalori + makrolar. Vision ile AYNI yanıt şekli döner; mobil
# tek render koduyla ikisini de gösterir.
# Sesli giriş bedavaya gelir: klavyenin 🎤 tuşu dikte eder,
# biz sadece metni anlarız — ekstra paket/izin gerekmez.
# ═════════════════════════════════════════════════════════

async def analyze_food_text(description: str) -> dict:
    client = get_claude_client()

    prompt = f"""Kullanıcı yediği öğünü serbest metinle tarif etti:

"{description}"

Türk mutfağı porsiyon ölçülerini bil (1 dilim ekmek ~25g, 1 kepçe çorba ~250ml,
1 porsiyon pilav ~150g, 1 su bardağı ~200ml gibi). Miktar belirtilmemişse
makul ev porsiyonu varsay ve notes'ta varsayımını belirt.

SADECE JSON formatında yanıt ver, başka hiçbir şey yazma:

{{
  "food_items": [
    {{"name": "yemek adı", "portion": "tahmini porsiyon", "calories": 150}}
  ],
  "total_calories": 450,
  "macros": {{"protein_g": 20, "carbs_g": 50, "fat_g": 15}},
  "confidence": "high/medium/low",
  "notes": "varsayımlar veya öneriler (opsiyonel)"
}}"""

    def _call():
        return client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=1024,
            messages=[{"role": "user", "content": prompt}],
        )

    message = await asyncio.to_thread(_call)
    text = message.content[0].text.strip()
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()
    return json.loads(text)
