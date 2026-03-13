import 'package:flutter/material.dart';

/// DesignAll renk sistemi — khroma.co ilhamıyla
/// Profesyonel, sofistike, minimalist bir iç mimarlık paleti
class AppColors {
  AppColors._();

  // ─── Ana Renkler ─────────────────────────────────────
  static const primary = Color(0xFF1A1A2E);       // Koyu lacivert
  static const primaryLight = Color(0xFF16213E);   // Orta lacivert
  static const primaryMedium = Color(0xFF0F3460);  // Orta-açık lacivert
  static const accent = Color(0xFFE94560);         // Canlı kırmızı-pembe
  static const accentSoft = Color(0xFFF5C6D0);     // Soft pembe
  static const accentLight = Color(0xFFFFF0F3);    // Çok hafif pembe

  // ─── Zengin Renkler ─────────────────────────────────
  static const gold = Color(0xFFD4A574);           // Altın/bronz
  static const goldLight = Color(0xFFF5E6D3);      // Hafif altın
  static const teal = Color(0xFF2DD4BF);           // Modern turkuaz
  static const purple = Color(0xFF8B5CF6);         // Mor
  static const purpleLight = Color(0xFFEDE9FE);    // Hafif mor
  static const blue = Color(0xFF3B82F6);           // Mavi
  static const blueLight = Color(0xFFEFF6FF);      // Hafif mavi
  static const emerald = Color(0xFF059669);        // Zümrüt

  // ─── Nötr Tonlar ─────────────────────────────────────
  static const background = Color(0xFFF8F9FC);     // Hafif soğuk beyaz
  static const surface = Color(0xFFFFFFFF);         // Saf beyaz
  static const surfaceVariant = Color(0xFFF3F4F8);  // Kart arka planı
  static const surfaceElevated = Color(0xFFFCFCFE); // Yükseltilmiş yüzey
  static const border = Color(0xFFE5E7EB);          // İnce border
  static const borderLight = Color(0xFFF0F0F5);     // Çok hafif border

  // ─── Metin Renkleri ──────────────────────────────────
  static const textPrimary = Color(0xFF111827);
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
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const accentGradient = LinearGradient(
    colors: [Color(0xFFE94560), Color(0xFFFF6B6B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const warmGradient = LinearGradient(
    colors: [Color(0xFFD4A574), Color(0xFFE8C4A0), Color(0xFFF5E6D3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460), Color(0xFF1A4B8C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const cardGradient = LinearGradient(
    colors: [Color(0xFFFFFFFF), Color(0xFFF8F9FE)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x11FFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ─── Gölgeler ────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF1A1A2E).withOpacity(0.08),
      blurRadius: 32,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: const Color(0xFF1A1A2E).withOpacity(0.05),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: const Color(0xFF1A1A2E).withOpacity(0.12),
      blurRadius: 40,
      offset: const Offset(0, 16),
      spreadRadius: -8,
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: accent.withOpacity(0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
      spreadRadius: -4,
    ),
  ];

  static List<BoxShadow> get accentGlow => [
    BoxShadow(
      color: accent.withOpacity(0.25),
      blurRadius: 30,
      offset: const Offset(0, 4),
    ),
  ];
}
