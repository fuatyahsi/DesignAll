import 'package:flutter/material.dart';

/// DesignAll renk sistemi — khroma.co ilhamıyla
/// Profesyonel, sofistike, minimalist bir iç mimarlık paleti
class AppColors {
  AppColors._();

  // ─── Ana Renkler ─────────────────────────────────────
  static const primary = Color(0xFF1A1A2E);       // Koyu lacivert
  static const primaryLight = Color(0xFF16213E);   // Orta lacivert
  static const accent = Color(0xFFE94560);         // Canlı kırmızı-pembe
  static const accentSoft = Color(0xFFF5C6D0);     // Soft pembe

  // ─── Nötr Tonlar ─────────────────────────────────────
  static const background = Color(0xFFFAFAFC);     // Hafif soğuk beyaz
  static const surface = Color(0xFFFFFFFF);         // Saf beyaz
  static const surfaceVariant = Color(0xFFF5F5F8);  // Kart arka planı
  static const border = Color(0xFFE8E8ED);          // İnce border
  static const borderLight = Color(0xFFF0F0F5);     // Çok hafif border

  // ─── Metin Renkleri ──────────────────────────────────
  static const textPrimary = Color(0xFF1A1A2E);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textOnDark = Color(0xFFFFFFFF);
  static const textOnAccent = Color(0xFFFFFFFF);

  // ─── Durum Renkleri ──────────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);

  // ─── Proje Durumu Renkleri ───────────────────────────
  static const statusActive = Color(0xFF10B981);
  static const statusPaused = Color(0xFFF59E0B);
  static const statusCompleted = Color(0xFF6366F1);

  // ─── Gradient'ler ────────────────────────────────────
  static const primaryGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ─── Gölgeler ────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1A1A2E).withOpacity(0.06),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF1A1A2E).withOpacity(0.04),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: accent.withOpacity(0.3),
      blurRadius: 16,
      offset: const Offset(0, 6),
    ),
  ];
}
