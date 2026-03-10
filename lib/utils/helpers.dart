import 'package:flutter/material.dart';

class Helpers {
  Helpers._();

  /// Tarih formatlama: "10 Mar 2026"
  static String formatDate(DateTime date) {
    const months = [
      'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
      'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Para formatlama: "₺12.500,00"
  static String formatCurrency(double amount) {
    final parts = amount.toStringAsFixed(2).split('.');
    final intPart = parts[0].replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
    return '₺$intPart,${parts[1]}';
  }

  /// SnackBar göster
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// HEX renk string'inden Color oluştur
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  /// Color'dan HEX string
  static String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  /// E-posta validasyonu
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'E-posta gerekli';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Geçerli bir e-posta girin';
    return null;
  }

  /// Şifre validasyonu
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Şifre gerekli';
    if (value.length < 6) return 'Şifre en az 6 karakter olmalı';
    return null;
  }

  /// İsim validasyonu
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) return 'İsim gerekli';
    if (value.length < 2) return 'İsim en az 2 karakter olmalı';
    return null;
  }
}
