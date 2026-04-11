// ── date_utils.dart ─────────────────────────────────────
// Tarih formatlama yardımcı fonksiyonları.
// Backend her yerde 'yyyy-MM-dd' formatı bekliyor.
// Flutter'da DateTime nesnesi var ama string'e çevirmek için
// bu yardımcı sınıfı kullanıyoruz — her yerde tekrar yazmayalım.

class TFDateUtils {
  TFDateUtils._();

  /// DateTime → 'yyyy-MM-dd' string'e çevirir.
  /// Backend'e tarih gönderirken kullanılır.
  /// Örnek: DateTime(2026, 4, 8) → '2026-04-08'
  static String toApiDate(DateTime date) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0'); // 4 → '04'
    final d = date.day.toString().padLeft(2, '0');   // 8 → '08'
    return '$y-$m-$d';
  }

  /// 'yyyy-MM-dd' string → DateTime'a çevirir.
  /// Backend'den gelen tarihleri parse ederken kullanılır.
  static DateTime fromApiDate(String date) {
    return DateTime.parse(date);
  }

  /// Bugünün tarihini 'yyyy-MM-dd' formatında döndürür.
  /// Rapor ve log endpoint'lerinde sık kullanılır.
  static String today() {
    return toApiDate(DateTime.now());
  }

  /// Bu haftanın Pazartesi gününü döndürür.
  /// Haftalık rapor endpoint'i için referans tarih.
  static String thisWeekMonday() {
    final now = DateTime.now();
    // weekday: Pazartesi=1, Salı=2 ... Pazar=7
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return toApiDate(monday);
  }

  /// İki tarih arasındaki gün sayısını döndürür.
  static int daysBetween(DateTime from, DateTime to) {
    final f = DateTime(from.year, from.month, from.day);
    final t = DateTime(to.year, to.month, to.day);
    return t.difference(f).inDays;
  }
}