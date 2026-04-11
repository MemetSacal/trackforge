// ── login_screen.dart ───────────────────────────────────
// Kullanıcının email ve şifresiyle giriş yaptığı ekran.
// StatefulWidget kullanıyoruz çünkü form alanlarının state'ini
// (controller, loading, hata mesajı) tutmamız gerekiyor.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── FORM CONTROLLERS ────────────────────────────────────
  // TextEditingController — TextField'daki metni okumamızı sağlar.
  // Java'da getText() gibi düşün.
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Form key — validation için kullanılır
  // Form widget'ına bağlanır, _formKey.currentState!.validate() ile kontrol edilir
  final _formKey = GlobalKey<FormState>();

  // ── STATE DEĞİŞKENLERİ ──────────────────────────────────
  bool _isLoading = false;       // true iken buton spinner gösterir
  bool _obscurePassword = true;  // şifre gizli mi?
  String? _errorMessage;         // hata mesajı — null iken gösterilmez

  // ── LIFECYCLE ───────────────────────────────────────────
  // Widget destroy edilince controller'ları temizle — memory leak önler
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── LOGIN FONKSİYONU ────────────────────────────────────
  Future<void> _login() async {
    // Önce form validasyonunu kontrol et
    if (!_formKey.currentState!.validate()) return;

    // Loading başlat, hata mesajını temizle
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Backend'e POST /auth/login isteği gönder
      final response = await ApiClient.instance.post(
        Endpoints.login,
        data: {
          'email': _emailController.text.trim(),
          'password': _passwordController.text,
        },
      );

      // Gelen token'ları güvenli depoya kaydet
      await TokenManager.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
      );

      if (!mounted) return; // Widget hâlâ ekranda mı?

      // Ana sayfaya git — go() mevcut sayfayı stack'ten kaldırır
      // Yani geri tuşuna basınca login'e dönülmez
      context.go('/home');
    } on ApiException catch (e) {
      // Bilinen API hatası — kullanıcıya göster
      setState(() => _errorMessage = e.message);
    } catch (e) {
      // Beklenmeyen hata
      setState(() => _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      // Hata da olsa başarı da olsa loading'i kapat
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── UI ──────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        // SafeArea — notch ve status bar'ın altına içerik gitmesini önler
        child: SingleChildScrollView(
          // Klavye açılınca overflow olmaması için scroll
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey, // Validasyon için form key bağla
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),

                // ── BAŞLIK ────────────────────────────────
                Text(
                  '⚡ TrackForge',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Hesabına giriş yap',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 40),

                // ── EMAIL ALANI ───────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'E-posta',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  // validator — boş bırakılırsa veya @ yoksa hata verir
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'E-posta adresi gerekli';
                    }
                    if (!value.contains('@')) {
                      return 'Geçerli bir e-posta adresi girin';
                    }
                    return null; // null → geçerli
                  },
                ),
                const SizedBox(height: 16),

                // ── ŞİFRE ALANI ──────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // true → şifreyi gizle
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    // Göz ikonu — şifreyi göster/gizle
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        // setState → ekranı yeniden çiz
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Şifre gerekli';
                    }
                    if (value.length < 6) {
                      return 'Şifre en az 6 karakter olmalı';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ── HATA MESAJI ───────────────────────────
                // Sadece _errorMessage null değilse göster
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // ── GİRİŞ BUTONU ─────────────────────────
                ElevatedButton(
                  // Loading varsa null — null olunca buton disabled olur
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Text('Giriş Yap'),
                ),

                const SizedBox(height: 16),

                // ── KAYIT OL LİNKİ ───────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hesabın yok mu? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    GestureDetector(
                      onTap: () => context.go('/register'),
                      child: Text(
                        'Kayıt Ol',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}