// ── api_exceptions.dart ─────────────────────────────────
import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// ── v2: Sunucu tarafı kota aşımı (HTTP 429) ────────────
/// Backend artık yapılandırılmış detail döndürüyor:
///   {"error_code": "QUOTA_EXCEEDED", "feature": "...", "used": 2,
///    "limit": 2, "period": "weekly", "resets_in_days": 4,
///    "is_premium": false, "message_tr": "..."}
/// Esas otorite backend'dir — lokal RateLimiter sadece UX iyileştirmesi.
class QuotaException implements Exception {
  final String feature;
  final int used;
  final int limit;
  final String period;       // "daily" | "weekly"
  final int resetsInDays;
  final bool isPremium;
  final String message;

  const QuotaException({
    required this.feature,
    required this.used,
    required this.limit,
    required this.period,
    required this.resetsInDays,
    required this.isPremium,
    required this.message,
  });

  /// DioException'dan QuotaException üretmeyi dener.
  /// 429 değilse veya detail beklenen yapıda değilse null döner.
  static QuotaException? fromDioError(DioException err) {
    if (err.response?.statusCode != 429) return null;
    final data = err.response?.data;
    final detail = (data is Map) ? data['detail'] : null;
    if (detail is! Map || detail['error_code'] != 'QUOTA_EXCEEDED') {
      // Eski backend formatı (düz string) — genel mesajla dön
      return QuotaException(
        feature: 'unknown', used: 0, limit: 0, period: 'weekly',
        resetsInDays: 7, isPremium: false,
        message: detail?.toString() ?? 'Kullanım limiti aşıldı.',
      );
    }
    return QuotaException(
      feature: detail['feature'] as String? ?? 'unknown',
      used: (detail['used'] as num?)?.toInt() ?? 0,
      limit: (detail['limit'] as num?)?.toInt() ?? 0,
      period: detail['period'] as String? ?? 'weekly',
      resetsInDays: (detail['resets_in_days'] as num?)?.toInt() ?? 7,
      isPremium: detail['is_premium'] as bool? ?? false,
      message: detail['message_tr'] as String? ?? 'Kullanım limiti aşıldı.',
    );
  }

  @override
  String toString() => message;
}
