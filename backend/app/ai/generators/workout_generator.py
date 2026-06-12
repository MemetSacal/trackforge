# ── workout_generator.py (v2) ──
#
# v2 DEĞİŞİKLİKLERİ:
#   1. day_of_week (1=Pazartesi ... 7=Pazar) tamsayı alanı eklendi.
#      AI'dan SAYI istenir, Türkçe gün adı backend'de deterministik
#      üretilir → "Pzt" / "1. Gün" gibi serbest metin kırılmaları biter.
#      Mobil taraf eski "day" alanını da almaya devam eder (geriye uyumlu).
#   2. user_context parametresi — build_user_context() çıktısı.
#      AI artık geçen haftanın gerçekleşmesini, kullanıcının kendi
#      eklediği egzersizleri ve döngü fazını görerek plan üretir.
#   3. Revizyon modu: previous_plan + revision_request verilirse
#      sıfırdan üretmek yerine mevcut planı kullanıcının isteğine göre
#      düzeltir ("beğenmedim, baştan" yerine "şunu değiştir" — daha
#      ucuz ve kullanıcı kendini duyulmuş hisseder).

import asyncio
import json
from backend.app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_WORKOUT

DAYS_TR = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"]


def _parse_json_response(response_text: str) -> dict:
    """Claude yanıtındaki markdown çitlerini temizleyip JSON parse eder."""
    text = response_text.strip()
    if "```json" in text:
        text = text.split("```json")[1].split("```")[0].strip()
    elif "```" in text:
        text = text.split("```")[1].split("```")[0].strip()
    return json.loads(text)


def _ground_exercises(plan: dict, catalog: list) -> dict:
    """v5: AI çıktısındaki egzersiz adlarını katalogla eşler.

    Eşleşme stratejisi: önce normalize edilmiş tam eşleşme, sonra
    difflib benzerlik (>= 0.75). Eşleşen egzersizin adı ve kas
    grupları KATALOGDAN basılır — yazım/şema tutarlılığı garanti.
    Eşleşmeyen (nadiren) olduğu gibi bırakılır; plan kırılmaz."""
    if not catalog:
        return plan
    import difflib
    by_norm = {c["name"].lower().strip(): c for c in catalog}
    norms = list(by_norm.keys())

    for day in plan.get("weekly_schedule", []):
        for ex in day.get("exercises", []):
            raw = str(ex.get("name", "")).lower().strip()
            if not raw:
                continue
            hit = by_norm.get(raw)
            if not hit:
                close = difflib.get_close_matches(raw, norms, n=1, cutoff=0.75)
                hit = by_norm[close[0]] if close else None
            if hit:
                ex["name"] = hit["name"]
                ex["muscle_groups"] = hit["muscle_groups"]
    return plan


def _postprocess_plan(plan: dict) -> dict:
    """day_of_week → Türkçe 'day' etiketini deterministik üretir.

    AI gün adı yazmaz, sayı yazar; etiketi BİZ basarız.
    AI yine de eski formatta 'day' döndürmüşse onu da tolere eder.
    """
    for day in plan.get("weekly_schedule", []):
        dow = day.get("day_of_week")
        if isinstance(dow, int) and 1 <= dow <= 7:
            day["day"] = DAYS_TR[dow - 1]
        elif "day" in day and "day_of_week" not in day:
            # Geriye uyum: AI sayı vermediyse addan sayıyı türetmeyi dene
            name = str(day["day"]).strip().lower()
            for i, d in enumerate(DAYS_TR):
                if d.lower() == name:
                    day["day_of_week"] = i + 1
                    break
    return plan


async def generate_workout_plan(
        workout_location: str,
        fitness_goal: str,
        fitness_level: str = "intermediate",
        available_days: int = 4,
        recent_exercises: list = None,
        user_context: str = "",
        previous_plan: dict = None,
        revision_request: str = None,
        catalog: list = None,
) -> dict:
    # v5: catalog — [{"name": ..., "muscle_groups": [...]}] listesi.
    # AI'a SADECE bu isimlerden seçmesi söylenir; çıktı yine de
    # katalogla eşlenir (fuzzy) ve kanonik ad + kas grupları basılır.
    # "Şınav"/"Push-up"/"Push Up" üçlemesi biter, takip tutarlı olur.
    client = get_claude_client()

    location_labels = {
        "home": "evde (ekipman yok)",
        "gym": "spor salonunda (tüm ekipmanlar mevcut)",
        "outdoor": "dışarıda (park, koşu parkuru)"
    }
    goal_labels = {
        "weight_loss": "kilo vermek ve yağ yakmak",
        "muscle_gain": "kas kütlesi kazanmak",
        "maintenance": "mevcut formu korumak"
    }

    location_text = location_labels.get(workout_location, workout_location)
    goal_text = goal_labels.get(fitness_goal, fitness_goal)

    recent_text = ""
    if recent_exercises:
        recent_text = f"\nSon yapılan egzersizler (tekrardan kaçın): {', '.join(recent_exercises)}"

    context_block = f"\n{user_context}\n" if user_context else ""

    catalog_block = ""
    if catalog:
        names = ", ".join(c["name"] for c in catalog)
        catalog_block = f"""
EGZERSİZ KATALOĞU (SADECE bu listeden seç, listede olmayan egzersiz YAZMA):
{names}
"""

    # ── Revizyon modu: tam üretim yerine hedefli düzeltme ──
    revision_block = ""
    if previous_plan and revision_request:
        revision_block = f"""
MEVCUT PLAN (kullanıcı bunu değiştirmek istiyor):
{json.dumps(previous_plan, ensure_ascii=False)}

KULLANICININ DEĞİŞİKLİK İSTEĞİ: {revision_request}

Planı SIFIRDAN yazma — mevcut planı koru, yalnızca kullanıcının
isteğine göre gerekli kısımları revize et.
"""

    prompt = f"""
Sen kişisel bir fitness koçusun.
{context_block}
Kullanıcı bilgileri:
- Antrenman yeri: {location_text}
- Hedef: {goal_text}
- Seviye: {fitness_level}
- Haftada {available_days} gün antrenman yapabilir
{recent_text}
{catalog_block}{revision_block}
Lütfen haftalık antrenman planı oluştur. Her gün için maksimum 4 egzersiz yaz.
Yukarıdaki kullanıcı bağlamı varsa MUTLAKA dikkate al: geçen hafta tamamlanamayan
hacmi azalt, kullanıcının kendi eklediği egzersiz türlerine planda yer ver,
döngü fazına göre yoğunluğu ayarla.

KURAL: Gün belirtirken "day_of_week" alanına SAYI yaz (1=Pazartesi, 2=Salı,
3=Çarşamba, 4=Perşembe, 5=Cuma, 6=Cumartesi, 7=Pazar). Gün adı YAZMA.

SADECE JSON formatında yanıt ver, başka hiçbir şey yazma:

{{
  "plan_title": "plan başlığı",
  "weekly_schedule": [
    {{
      "day_of_week": 1,
      "focus": "antrenman odağı (örn: Üst Vücut)",
      "exercises": [
        {{
          "name": "egzersiz adı",
          "sets": 3,
          "reps": "10-12",
          "rest_seconds": 60,
          "notes": "teknik notu (opsiyonel)",
          "muscle_groups": ["Göğüs", "Triceps"]
        }}
      ],
      "estimated_duration_minutes": 45,
      "estimated_calories": 300
    }}
  ],
  "weekly_notes": "genel haftalık tavsiye"
}}
"""

    # ✅ Senkron Claude çağrısını ayrı thread'de çalıştır
    def _call():
        return client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=MAX_TOKENS_WORKOUT,
            messages=[{"role": "user", "content": prompt}]
        )

    message = await asyncio.to_thread(_call)
    plan = _parse_json_response(message.content[0].text)
    plan = _ground_exercises(plan, catalog)  # v5: katalog eşleme
    return _postprocess_plan(plan)
