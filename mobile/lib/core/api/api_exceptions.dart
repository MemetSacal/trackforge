// ── api_exceptions.dart ─────────────────────────────────
// Dio'dan gelen HTTP hatalarını yakalayıp anlamlı exception'lara
// dönüştüren sınıf.
// Repository katmanında try/catch ile kullanılır.
// Kullanıcıya gösterilecek mesajlar burada tanımlanır.

import 'package:dio/dio.dart';

/// Tüm API hatalarının base sınıfı.
/// Exception implement ediyor — Dart'ta hata fırlatmak için kullanılır.
class ApiException implements Exception {
  final String message;    // Kullanıcıya gösterilecek mesaj
  final int? statusCode;   // HTTP status kodu (400, 401, 404...)

  const ApiException({
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// 401 — Token geçersiz veya süresi dolmuş
class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super(message: 'Oturum süresi doldu. Lütfen tekrar giriş yapın.', statusCode: 401);
}

/// 404 — İstenen kaynak bulunamadı
class NotFoundException extends ApiException {
  const NotFoundException([String? message])
      : super(message: message ?? 'İçerik bulunamadı.', statusCode: 404);
}

/// 400 — Geçersiz istek (validation hatası)
class BadRequestException extends ApiException {
  const BadRequestException([String? message])
      : super(message: message ?? 'Geçersiz istek.', statusCode: 400);
}

/// 422 — Validation hatası (FastAPI'nin döndürdüğü)
class ValidationException extends ApiException {
  const ValidationException([String? message])
      : super(message: message ?? 'Lütfen tüm alanları doğru doldurun.', statusCode: 422);
}

/// 500 — Sunucu hatası
class ServerException extends ApiException {
  const ServerException()
      : super(message: 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.', statusCode: 500);
}

/// İnternet bağlantısı yok
class NetworkException extends ApiException {
  const NetworkException()
      : super(message: 'İnternet bağlantısı yok. Lütfen bağlantınızı kontrol edin.');
}

/// Dio hatalarını yukarıdaki exception'lara dönüştüren yardımcı fonksiyon.
/// Repository'lerde try/catch içinde kullanılır:
/// catch (e) { throw ApiExceptionHandler.handle(e); }
class ApiExceptionHandler {
  ApiExceptionHandler._();

  static ApiException handle(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
      // Sunucuya ulaşılamadı — internet yok veya backend kapalı
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return const NetworkException();

      // Sunucudan yanıt geldi ama hata kodu var
        case DioExceptionType.badResponse:
          return _handleStatusCode(error.response?.statusCode);

        default:
          return const ApiException(message: 'Beklenmeyen bir hata oluştu.');
      }
    }

    // DioException değilse genel hata
    return const ApiException(message: 'Beklenmeyen bir hata oluştu.');
  }

  /// HTTP status koduna göre doğru exception'ı döndürür
  static ApiException _handleStatusCode(int? statusCode) {
    switch (statusCode) {
      case 400:
        return const BadRequestException();
      case 401:
        return const UnauthorizedException();
      case 404:
        return const NotFoundException();
      case 422:
        return const ValidationException();
      case 500:
        return const ServerException();
      default:
        return ApiException(
          message: 'Bir hata oluştu.',
          statusCode: statusCode,
        );
    }
  }
}