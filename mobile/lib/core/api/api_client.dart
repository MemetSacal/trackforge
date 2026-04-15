// ── api_client.dart ─────────────────────────────────────
// Dio HTTP client'ının merkezi kurulum dosyası.
// Tüm API istekleri bu dosyadan geçer.
// Interceptor burada tanımlanır — her isteğe otomatik token eklenir,
// 401 gelirse token refresh yapılır.

import 'package:dio/dio.dart';
import '../auth/token_manager.dart';
import 'endpoints.dart';

/// Singleton Dio instance'ı döndüren sınıf.
/// Uygulama boyunca tek bir Dio nesnesi kullanılır.
class ApiClient {
  ApiClient._(); // Dışarıdan new ApiClient() yapılamaz

  // Tek Dio instance — static olduğu için uygulama boyunca aynı nesne
  static final Dio _dio = _createDio();

  /// Dışarıdan erişim noktası: ApiClient.instance
  static Dio get instance => _dio;

  /// Dio nesnesini oluşturup ayarları yapılandırır
  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: Endpoints.baseUrl, // Tüm isteklere otomatik eklenir
        connectTimeout: const Duration(seconds: 10), // Bağlantı timeout
        receiveTimeout: const Duration(seconds: 30), // Yanıt timeout (AI için uzun)
        headers: {
          'Content-Type': 'application/json', // Her istekte JSON gönderiyoruz
          'Accept': 'application/json',
        },
        extra: {'withCredentials': false},
      ),
    );

    // Interceptor ekle — her istek/yanıt buradan geçer
    dio.interceptors.add(_AuthInterceptor(dio));

    return dio;
  }
}

/// Her HTTP isteğine otomatik JWT token ekleyen interceptor.
/// Token süresi dolmuşsa refresh yapıp isteği tekrar gönderir.
class _AuthInterceptor extends Interceptor {
  // Refresh sırasında döngüye girmemek için aynı Dio instance'ı kullanıyoruz
  final Dio _dio;

  _AuthInterceptor(this._dio);

  // ── REQUEST ───────────────────────────────────────────
  // Her istek gönderilmeden önce burası çalışır.
  // Token varsa Authorization header'ına ekler.
  @override
  void onRequest(
      RequestOptions options,
      RequestInterceptorHandler handler,
      ) async {
    // flutter_secure_storage'dan access token'ı oku
    final token = await TokenManager.getAccessToken();

    if (token != null) {
      // "Authorization: Bearer <token>" header'ını ekle
      options.headers['Authorization'] = 'Bearer $token';
    }

    // İsteği devam ettir
    handler.next(options);
  }

  // ── RESPONSE ERROR ────────────────────────────────────
  // Sunucudan hata yanıtı geldiğinde burası çalışır.
  // 401 Unauthorized gelirse token refresh dener.
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Sadece 401 hatasında refresh dene
    if (err.response?.statusCode == 401) {
      try {
        // Refresh token ile yeni access token al
        final refreshed = await _refreshToken();

        if (refreshed) {
          // Yeni token ile başarısız isteği tekrar gönder
          final response = await _retry(err.requestOptions);
          handler.resolve(response); // Başarılı yanıtı döndür
          return;
        }
      } catch (_) {
        // Refresh da başarısız — token'ları sil, login'e yönlendir
        await TokenManager.clearTokens();
      }
    }

    // Diğer hatalar için normal hata akışına devam et
    handler.next(err);
  }

  /// Refresh token kullanarak yeni access token alır.
  /// Başarılıysa true, başarısızsa false döner.
  Future<bool> _refreshToken() async {
    final refreshToken = await TokenManager.getRefreshToken();
    if (refreshToken == null) return false;

    // /auth/refresh endpoint'ine istek at
    // Not: Bu isteğe interceptor tekrar çalışmasın diye ayrı Dio kullanmıyoruz,
    // zaten refresh token'ı header'da değil body'de gönderiyoruz.
    final response = await _dio.post(
      Endpoints.refresh,
      data: {'refresh_token': refreshToken},
      options: Options(
        // Bu isteğin interceptor'dan geçmemesi için extra flag
        extra: {'skipInterceptor': true},
      ),
    );

    if (response.statusCode == 200) {
      // Yeni token'ları kaydet
      await TokenManager.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );
      return true;
    }

    return false;
  }

  /// Başarısız isteği yeni token ile tekrar gönderir.
  Future<Response> _retry(RequestOptions requestOptions) async {
    final token = await TokenManager.getAccessToken();

    return _dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(
        method: requestOptions.method,
        headers: {
          ...requestOptions.headers,
          'Authorization': 'Bearer $token', // Yeni token
        },
      ),
    );
  }
}