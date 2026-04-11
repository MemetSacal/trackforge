// TrackForge Renk Paleti — Dark & Light Mode
// Tüm uygulama boyunca bu sınıf üzerinden renklere erişilir

import 'package:flutter/material.dart';

/// Uygulamanın tüm renk sabitlerini barındıran sınıf.
/// Dark ve Light mod için ayrı ayrı tanımlanmıştır.
class AppColors {
  AppColors._(); // instantiate edilemesin

  // ── DARK MODE ──────────────────────────────────────────
  static const darkBg = Color(0xFF0C0D10);        // Ana arka plan
  static const darkBgCard = Color(0xFF141620);    // Kart arka planı
  static const darkAccent = Color(0xFFFFB020);    // Altın sarısı — vurgu rengi
  static const darkPositive = Color(0xFF34D399);  // Başarı / pozitif
  static const darkDanger = Color(0xFFFF5555);    // Hata / tehlike
  static const darkText = Color(0xFFFFFFFF);      // Ana metin
  static const darkTextSub = Color(0xFF8A8FA8);   // İkincil metin
  static const darkBorder = Color(0xFF1E2130);    // Kart border

  // ── LIGHT MODE ─────────────────────────────────────────
  static const lightBg = Color(0xFFF0F2F6);       // Ana arka plan
  static const lightBgCard = Color(0xFFFFFFFF);   // Kart arka planı
  static const lightAccent = Color(0xFFFF6B2B);   // Turuncu — vurgu rengi
  static const lightPositive = Color(0xFF059669); // Başarı / pozitif
  static const lightDanger = Color(0xFFDC2626);   // Hata / tehlike
  static const lightText = Color(0xFF0C0D10);     // Ana metin
  static const lightTextSub = Color(0xFF6B7280);  // İkincil metin
  static const lightBorder = Color(0xFFE5E7EB);   // Kart border
}