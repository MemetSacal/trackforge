import asyncio
import json
from backend.app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_SUMMARY
from backend.app.application.schemas.report import WeeklyReportResponse


async def generate_weekly_summary(report: WeeklyReportResponse, user_name: str) -> str:
    client = get_claude_client()

    report_data = {}

    if report.water:
        report_data["su_takibi"] = {
            "gunluk_ortalama_ml": report.water.avg_daily_ml,
            "hedefe_ulasan_gun": report.water.target_hit_days,
            "toplam_gun": report.water.total_days,
        }

    if report.sleep:
        report_data["uyku"] = {
            "ortalama_sure_saat": report.sleep.avg_hours,
            "ortalama_kalite_10": report.sleep.avg_quality,
            "toplam_gun": report.sleep.total_days,
        }

    if report.meal_compliance:
        report_data["diyet_uyumu"] = {
            "uyulan_gun": report.meal_compliance.complied_days,
            "toplam_gun": report.meal_compliance.total_days,
            "uyum_yuzdesi": report.meal_compliance.compliance_rate,
        }

    if report.exercise:
        report_data["egzersiz"] = {
            "toplam_seans": report.exercise.total_sessions,
            "toplam_sure_dakika": report.exercise.total_duration_minutes,
            "toplam_kalori": report.exercise.total_calories,
        }

    if report.measurements:
        report_data["olcumler"] = {
            "kilo_kg": report.measurements.weight_kg,
            "yag_orani": report.measurements.body_fat_pct,
            "kilo_degisimi_kg": report.measurements.weight_change,
        }

    prompt = f"""
Sen TrackForge uygulamasının kişisel sağlık asistanısın.
Kullanıcı adı: {user_name}
Hafta: {report.week_start} - {report.week_end}

Kullanıcının bu haftaki sağlık verileri:
{json.dumps(report_data, ensure_ascii=False, indent=2)}

Lütfen bu verilere dayanarak:
1. Haftanın kısa ve samimi bir özetini yaz (2-3 cümle)
2. En iyi 1-2 başarıyı vurgula
3. Geliştirilmesi gereken 1-2 alanı nazikçe belirt
4. Önümüzdeki hafta için 1-2 somut öneri ver

Yanıt Türkçe olsun, samimi ve motive edici bir ton kullan.
Maksimum 200 kelime.
"""

    # ✅ Senkron Claude çağrısını ayrı thread'de çalıştır — event loop bloke olmaz
    def _call():
        return client.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=MAX_TOKENS_SUMMARY,
            messages=[{"role": "user", "content": prompt}]
        )

    message = await asyncio.to_thread(_call)
    return message.content[0].text