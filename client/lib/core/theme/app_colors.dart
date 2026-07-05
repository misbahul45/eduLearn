import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand — primary sekarang lolos kontras AA untuk teks & ikon di atas putih (~5.3:1)
  static const Color primary = Color(0xFF00796B);
  static const Color primaryDark = Color(0xFF00695C);
  // Dekoratif saja (gradient, glow, chart) — JANGAN dipakai untuk teks/ikon kecil
  static const Color primaryLight = Color(0xFF00BFA5);

  static const Color accentBlue = Color(0xFF1565C0); // sudah bagus (~5.7:1), dipertahankan

  // Text
  static const Color textPrimary = Color(0xFF1A1A2E);   // ~14.7:1 — sangat aman
  static const Color textSecondary = Color(0xFF52586B); // dari ~4.6:1 → ~6.8:1
  static const Color textHint = Color(0xFF7A8194);       // dari ~2.4:1 → ~3.7:1
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E7EB);

  // Status — digelapkan supaya aman dipakai sebagai warna teks/label, bukan cuma dekorasi
  static const Color success = Color(0xFF047857); // dari ~2.5:1 → ~5.5:1
  static const Color error = Color(0xFFDC2626);   // dari ~3.8:1 → ~4.8:1
  static const Color warning = Color(0xFFB45309); // dari ~2.1:1 → ~5.0:1
}