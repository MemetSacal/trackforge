// ── date_utils.dart ──────────────────────────────────────
class TFDateUtils {
  TFDateUtils._();

  /// Bugünün tarihini API formatında döner: "2025-01-15"
  static String today() {
    final now = DateTime.now();
    return _fmt(now);
  }

  /// Verilen DateTime'ı API formatına çevirir
  static String toApiDate(DateTime date) => _fmt(date);

  /// Bu haftanın pazartesi tarihini döner
  static String weekStart() {
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    return _fmt(monday);
  }

  /// Bu haftanın pazar tarihini döner
  static String weekEnd() {
    final now = DateTime.now();
    final sunday = now.add(Duration(days: 7 - now.weekday));
    return _fmt(sunday);
  }

  /// Yıl ve hafta numarasını döner: "2025-W03"
  static String yearWeek() {
    final now = DateTime.now();
    final dayOfYear = int.parse(
        '${now.difference(DateTime(now.year, 1, 1)).inDays + 1}');
    final weekNum = ((dayOfYear - now.weekday + 10) / 7).floor();
    return '${now.year}-W${weekNum.toString().padLeft(2, '0')}';
  }

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}