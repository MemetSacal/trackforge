// ── login_screen.dart ───────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/api/api_client.dart';
import '../../core/api/api_exceptions.dart';
import '../../core/api/endpoints.dart';
import '../../core/auth/token_manager.dart';
import '../../app.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading       = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() { _emailController.dispose(); _passwordController.dispose(); super.dispose(); }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final response = await ApiClient.instance.post(Endpoints.login, data: {
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      });
      await TokenManager.saveTokens(
        accessToken: response.data['access_token'],
        refreshToken: response.data['refresh_token'],
        userId:       response.data['user_id'] ?? '',
        isPremium:    response.data['is_premium'] ?? false,
      );
      if (!mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = 'Bir hata oluştu. Lütfen tekrar deneyin.');
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    // ── TEMA FARKI: provider'dan al, sabit renk yazma ──
    final isDark   = ref.watch(themeModeProvider) == ThemeMode.dark;
    final bg       = isDark ? const Color(0xFF0C0D10) : const Color(0xFFF0F2F6);
    final bgCard   = isDark ? const Color(0xFF141620) : Colors.white;
    final border   = isDark ? const Color(0x12FFFFFF) : const Color(0x12000000);
    final text     = isDark ? const Color(0xFFF0EEF8) : const Color(0xFF111318);
    final muted    = isDark ? const Color(0xFF4A4860) : const Color(0xFF9AA0B8);
    final accent   = isDark ? const Color(0xFFFFB020) : const Color(0xFFFF6B2B);
    final accentDim= isDark ? const Color(0x1FFFB020) : const Color(0x1AFF6B2B);
    final danger   = isDark ? const Color(0xFFFF5555) : const Color(0xFFDC2626);
    final inputBg  = isDark ? const Color(0xFF1C1E2A) : Colors.white;

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
                const SizedBox(height: 40),

                // Logo
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: accentDim,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: accent.withOpacity(0.4)),
                    ),
                    child: const Center(child: Text('⚡', style: TextStyle(fontSize: 22))),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('TRACKFORGE', style: TextStyle(fontSize: 9, letterSpacing: 3, color: muted, fontWeight: FontWeight.w600)),
                    Text('TrackForge', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                  ]),
                ]),
                const SizedBox(height: 40),

                Text('Tekrar hoş geldin 👋', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: text, letterSpacing: -0.5)),
                const SizedBox(height: 6),
                Text('Hesabına giriş yap', style: TextStyle(fontSize: 14, color: muted)),
                const SizedBox(height: 32),

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: 'E-posta',
                    labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.email_outlined, color: muted),
                    filled: true,
                    fillColor: inputBg,
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

                // Şifre
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: text),
                  decoration: InputDecoration(
                    labelText: 'Şifre',
                    labelStyle: TextStyle(color: muted),
                    prefixIcon: Icon(Icons.lock_outlined, color: muted),
                    filled: true,
                    fillColor: inputBg,
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
                      icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: muted),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Şifre gerekli';
                    if (v.length < 6) return 'Şifre en az 6 karakter olmalı';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Hata
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
                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: danger, fontSize: 13))),
                    ]),
                  ),

                // Giriş butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: isDark ? Colors.black : Colors.white))
                        : const Text('Giriş Yap', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(height: 20),

                // Kayıt ol linki
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Hesabın yok mu? ', style: TextStyle(color: muted)),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: Text('Kayıt Ol', style: TextStyle(color: accent, fontWeight: FontWeight.w700)),
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