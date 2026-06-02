import asyncio
import json
from backend.app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_WORKOUT


async def generate_workout_plan(
        workout_location: str,
        fitness_goal: str,
        fitness_level: str = "intermediate",
        available_days: int = 4,
        recent_exercises: list = None,
) -> dict:
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

    prompt = f"""
Sen kişisel bir fitness koçusun.

Kullanıcı bilgileri:
- Antrenman yeri: {location_text}
- Hedef: {goal_text}
- Seviye: {fitness_level}
- Haftada {available_days} gün antrenman yapabilir
{recent_text}

Lütfen haftalık antrenman planı oluştur. Her gün için maksimum 4 egzersiz yaz.
SADECE JSON formatında yanıt ver, başka hiçbir şey yazma:

{{
  "plan_title": "plan başlığı",
  "weekly_schedule": [
    {{
      "day": "Pazartesi",
      "focus": "antrenman odağı (örn: Üst Vücut)",
      "exercises": [
        {{
          "name": "egzersiz adı",
          "sets": 3,
          "reps": "10-12",
          "rest_seconds": 60,
          "notes": "teknik notu (opsiyonel)"
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

    response_text = message.content[0].text.strip()
    if "```json" in response_text:
        response_text = response_text.split("```json")[1].split("```")[0].strip()
    elif "```" in response_text:
        response_text = response_text.split("```")[1].split("```")[0].strip()

    return json.loads(response_text)