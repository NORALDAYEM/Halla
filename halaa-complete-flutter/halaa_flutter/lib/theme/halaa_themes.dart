import 'package:flutter/material.dart';

class HalaaThemePreset {
  final String name;
  final Color primary;
  final Color accent;
  final Color bgTop;
  final Color bgBottom;

  const HalaaThemePreset({
    required this.name,
    required this.primary,
    required this.accent,
    required this.bgTop,
    required this.bgBottom,
  });
}

const List<HalaaThemePreset> kHalaaThemes = [
  HalaaThemePreset(
    name: 'الفيروزي الملكي',
    primary: Color(0xFF06B6D4),
    accent: Color(0xFF38BDF8),
    bgTop: Color(0xFF062030),
    bgBottom: Color(0xFF040D16),
  ),
  HalaaThemePreset(
    name: 'الذهبي الداكن',
    primary: Color(0xFFD97706),
    accent: Color(0xFFFBBF24),
    bgTop: Color(0xFF1F1609),
    bgBottom: Color(0xFF0B0804),
  ),
  HalaaThemePreset(
    name: 'ليالي السايبر',
    primary: Color(0xFF8B5CF6),
    accent: Color(0xFF22D3EE),
    bgTop: Color(0xFF130B2E),
    bgBottom: Color(0xFF070412),
  ),
  HalaaThemePreset(
    name: 'اللؤلؤي الملكي',
    primary: Color(0xFF0284C7),
    accent: Color(0xFF7DD3FC),
    bgTop: Color(0xFF0F2537),
    bgBottom: Color(0xFF091521),
  ),
  HalaaThemePreset(
    name: 'قصر الزمرد',
    primary: Color(0xFF10B981),
    accent: Color(0xFF34D399),
    bgTop: Color(0xFF06261E),
    bgBottom: Color(0xFF03120E),
  ),
  HalaaThemePreset(
    name: 'الياقوت الإمبراطوري',
    primary: Color(0xFF2563EB),
    accent: Color(0xFF60A5FA),
    bgTop: Color(0xFF0A1B3D),
    bgBottom: Color(0xFF050D1F),
  ),
  HalaaThemePreset(
    name: 'العنبر الليلي',
    primary: Color(0xFFEA580C),
    accent: Color(0xFFFB923C),
    bgTop: Color(0xFF261207),
    bgBottom: Color(0xFF100703),
  ),
  HalaaThemePreset(
    name: 'الأرجواني الفاخر',
    primary: Color(0xFFC026D3),
    accent: Color(0xFFE879F9),
    bgTop: Color(0xFF250B2E),
    bgBottom: Color(0xFF0F0414),
  ),
];

HalaaThemePreset findThemePreset(String name) {
  for (final p in kHalaaThemes) {
    if (p.name == name) return p;
  }
  return kHalaaThemes.first;
}
