import 'package:flutter/material.dart';

class HalaaThemePreset {
  final String name;
  final Color primary;
  final Color primaryDark;
  final Color accent;
  final Color bgDark;

  const HalaaThemePreset({
    required this.name,
    required this.primary,
    required this.primaryDark,
    required this.accent,
    required this.bgDark,
  });
}

const List<HalaaThemePreset> kHalaaThemes = [
  HalaaThemePreset(
    name: 'الفيروزي الملكي',
    primary: Color(0xFF14B8A6),
    primaryDark: Color(0xFF0F7682),
    accent: Color(0xFFF5BD20),
    bgDark: Color(0xFF071B21),
  ),
  HalaaThemePreset(
    name: 'الذهبي الداكن',
    primary: Color(0xFFD97706),
    primaryDark: Color(0xFF92400E),
    accent: Color(0xFFFBBF24),
    bgDark: Color(0xFF1C1306),
  ),
  HalaaThemePreset(
    name: 'ليالي السايبر',
    primary: Color(0xFF8B5CF6),
    primaryDark: Color(0xFF5B21B6),
    accent: Color(0xFF22D3EE),
    bgDark: Color(0xFF120A2A),
  ),
  HalaaThemePreset(
    name: 'اللؤلؤي الملكي',
    primary: Color(0xFF0284C7),
    primaryDark: Color(0xFF075985),
    accent: Color(0xFF7DD3FC),
    bgDark: Color(0xFF0B1F2E),
  ),
  HalaaThemePreset(
    name: 'قصر الزمرد',
    primary: Color(0xFF10B981),
    primaryDark: Color(0xFF047857),
    accent: Color(0xFF34D399),
    bgDark: Color(0xFF052019),
  ),
  HalaaThemePreset(
    name: 'الياقوت الإمبراطوري',
    primary: Color(0xFF2563EB),
    primaryDark: Color(0xFF1D4ED8),
    accent: Color(0xFF60A5FA),
    bgDark: Color(0xFF081633),
  ),
  HalaaThemePreset(
    name: 'العنبر الليلي',
    primary: Color(0xFFEA580C),
    primaryDark: Color(0xFF9A3412),
    accent: Color(0xFFFB923C),
    bgDark: Color(0xFF210F05),
  ),
  HalaaThemePreset(
    name: 'الأرجواني الفاخر',
    primary: Color(0xFFC026D3),
    primaryDark: Color(0xFF86198F),
    accent: Color(0xFFE879F9),
    bgDark: Color(0xFF200927),
  ),
];

HalaaThemePreset findThemePreset(String name) {
  for (final t in kHalaaThemes) {
    if (t.name == name) return t;
  }
  return kHalaaThemes.first;
}
