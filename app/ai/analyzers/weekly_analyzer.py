# Haftalık veri analizi — tüm kategorilerin özetini Claude'a gönderir
import json
from app.ai.client import get_claude_client, CLAUDE_MODEL, MAX_TOKENS_SUMMARY
from app.application.schemas.report import WeeklyReportResponse


async def generate_weekly_summary(report: WeeklyReportResponse, user_name: str) -> str:
    """
    Haftalık raporu Claude API'ye gönderir ve kişiselleştirilmiş özet alır.

    Args:
        report: Faz 6'da oluşturduğumuz haftalık rapor
        user_name: Kullanıcının adı — kişiselleştirme için

    Returns:
        Claude'un ürettiği Türkçe özet metin
    """
    client = get_claude_client()

    # Raporu Claude'un okuyabileceği formata dönüştür
    report_data = {}

    # Su verisi varsa ekle
    if report.water:
        report_data["su_takibi"] = {
            "gunluk_ortalama_ml": report.water.avg_daily_ml,
            "hedefe_ulasan_gun": report.water.target_hit_days,
            "toplam_gun": report.water.total_days,
        }

    # Uyku verisi varsa ekle
    if report.sleep:
        report_data["uyku"] = {
            "ortalama_sure_saat": report.sleep.avg_hours,
            "ortalama_kalite_10": report.sleep.avg_quality,
            "toplam_gun": report.sleep.total_days,
        }

    # Diyet uyumu varsa ekle
    if report.meal_compliance:
        report_data["diyet_uyumu"] = {
            "uyulan_gun": report.meal_compliance.complied_days,
            "toplam_gun": report.meal_compliance.total_days,
            "uyum_yuzdesi": report.meal_compliance.compliance_rate,
        }

    # Egzersiz verisi varsa ekle
    if report.exercise:
        report_data["egzersiz"] = {
            "toplam_seans": report.exercise.total_sessions,
            "toplam_sure_dakika": report.exercise.total_duration_minutes,
            "toplam_kalori": report.exercise.total_calories,
        }

    # Ölçüm verisi varsa ekle
    if report.measurements:
        report_data["olcumler"] = {
            "kilo_kg": report.measurements.weight_kg,
            "yag_orani": report.measurements.body_fat_pct,
            "kilo_degisimi_kg": report.measurements.weight_change,
        }

    # Claude'a gönderilecek prompt
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

    # Claude API çağrısı — senkron (async wrapper içinde çalışır)
    message = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=MAX_TOKENS_SUMMARY,
        messages=[
            {"role": "user", "content": prompt}
        ]
    )

    # Yanıtın metin kısmını döndür
    return message.content[0].text


"""
DOSYA AKIŞI:
generate_weekly_summary → Faz 6 rapor verisini alır → Claude'a prompt olarak gönderir → Türkçe özet döner.
Veri yoksa (None) o kategori prompt'a dahil edilmez — hata vermez.
json.dumps ile rapor verisi okunabilir formata çevrilir.
Claude yanıtı message.content[0].text ile alınır.

Spring Boot karşılığı: @Service + RestTemplate ile dış API çağrısı.
"""