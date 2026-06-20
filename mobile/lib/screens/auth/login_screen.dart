// ── login_screen.dart ───────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';
import '../../app.dart';
import '../home/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey            = GlobalKey<FormState>();
  bool _isLoading       = false;
  bool _obscurePassword = true;
  bool _rememberMe      = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRememberMe();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    // Kayıtlı email varsa doldur
    final savedEmail = prefs.getString('saved_email') ?? '';
    if (savedEmail.isNotEmpty) {
      _emailController.text = savedEmail;
    }
    setState(() {
      _rememberMe = prefs.getBool('remember_me') ?? true;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await ApiClient.instance.post(Endpoints.login, data: {
        'email':    _emailController.text.trim(),
        'password': _passwordController.text,
      });

      final prefs = await SharedPreferences.getInstance();

      // email_verified durumunu prefs'e kaydet → home banner için
      final emailVerified = response.data['email_verified'] ?? true;
      await prefs.setBool('email_verified', emailVerified as bool);

      if (_rememberMe) {
        await TokenManager.saveTokens(
          accessToken:  response.data['access_token'],
          refreshToken: response.data['refresh_token'],
          userId:       response.data['user_id'] ?? '',
          isPremium:    response.data['is_premium'] ?? false,
        );
        await FcmService.registerTokenWithBackend();
        await prefs.setString('saved_email', _emailController.text.trim());
        await prefs.setBool('remember_me', true);
      } else {
        await TokenManager.saveTokens(
          accessToken:  response.data['access_token'],
          refreshToken: response.data['refresh_token'],
          userId:       response.data['user_id'] ?? '',
          isPremium:    response.data['is_premium'] ?? false,
        );
        await FcmService.registerTokenWithBackend();
        await prefs.remove('saved_email');
        await prefs.setBool('remember_me', false);
        await prefs.setBool('session_only', true);
      }

      if (!mounted) return;
      // FIX #6: login sonrası her zaman Dashboard (index 0) açılsın.
      // Önceki session'ın bottomNavIndexProvider state'i Riverpod'da kalıyordu,
      // bu yüzden farklı hesapla giriş yapınca son açık sekme (örn. More=4) geliyordu.
      ref.read(bottomNavIndexProvider.notifier).state = 0;
      context.go('/home');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark    = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg        = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard    = isDark ? const Color(0xFF141620) : Colors.white;
    final border    = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text      = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final textSoft  = isDark ? const Color(0xFF8A88A8) : const Color(0xFF5A6078);
    final muted     = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent    = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim = isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger    = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);
    final inputBg   = isDark ? const Color(0xFF1C1E2A) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // ── HEADER: Logo + Dark/Light toggle ──────────────────────
                Row(
                  children: [
                    // Logo
                    Container(
                      width: 44, height: 44,
                      decoration: BoxDecoration(
                        color: accentDim,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accent.withOpacity(0.4)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TRACKFORGE',
                          style: TextStyle(
                            fontSize: 9, letterSpacing: 3,
                            color: muted, fontWeight: FontWeight.w600,
                          )),
                        Text('TrackForge',
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w800,
                            color: text, letterSpacing: -0.5,
                          )),
                      ],
                    ),
                    const Spacer(),
                    // Dark / Light toggle
                    GestureDetector(
                      onTap: () => ref.read(themeModeProvider.notifier).toggle(),
                      child: Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF141620) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: border),
                        ),
                        child: Icon(
                          isDark ? Icons.wb_sunny_outlined : Icons.nightlight_round,
                          size: 16,
                          color: textSoft,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 44),

                // ── BAŞLIK ────────────────────────────────────────────────
                Text('Tekrar hoş geldin 👋',
                  style: TextStyle(
                    fontSize: 26, fontWeight: FontWeight.w800,
                    color: text, letterSpacing: -0.5,
                  )),
                const SizedBox(height: 6),
                Text('Hesabına giriş yap',
                  style: TextStyle(fontSize: 14, color: muted)),
                const SizedBox(height: 32),

                // ── E-POSTA ───────────────────────────────────────────────
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.email_outlined, color: muted),
                    filled: true, fillColor: inputBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: border.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: danger),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: danger, width: 1.5),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'E-posta adresi gerekli';
                    if (!v.contains('@')) return 'Geçerli bir e-posta girin';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // ── ŞİFRE ─────────────────────────────────────────────────
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.lock_outlined, color: muted),
                    filled: true, fillColor: inputBg,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: border.withOpacity(0.5)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: accent, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: danger),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: danger, width: 1.5),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: muted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gerekli';
                    if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 10),

                // ── BENİ HATIRLA ──────────────────────────────────────────
                Row(
                  children: [
                    SizedBox(
                      width: 20, height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) =>
                            setState(() => _rememberMe = v ?? true),
                        activeColor: accent,
                        checkColor: isDark ? Colors.black : Colors.white,
                        side: BorderSide(color: muted, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('Beni hatırla',
                      style: TextStyle(fontSize: 13, color: textSoft)),
                  ],
                ),
                const SizedBox(height: 16),

                // ── HATA MESAJI ───────────────────────────────────────────
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: danger.withOpacity(0.3)),
                    ),
                    child: Row(children: [
                      Icon(Icons.error_outline, color: danger, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!,
                        style: TextStyle(color: danger, fontSize: 13))),
                    ]),
                  ),

                // ── GİRİŞ BUTONU ──────────────────────────────────────────
                SizedBox(
                  width: double.infinity, height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20, width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? Colors.black : Colors.white,
                            ))
                        : const Text('Giriş Yap',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),

                // ── KAYIT OL LİNKİ ────────────────────────────────────────
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Hesabın yok mu? ',
                    style: TextStyle(color: muted)),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text('Kayıt Ol',
                      style: TextStyle(
                          color: accent, fontWeight: FontWeight.w700)),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}