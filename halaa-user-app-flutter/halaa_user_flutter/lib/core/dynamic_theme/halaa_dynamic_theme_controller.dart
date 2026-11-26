import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Immutable dynamic theme snapshot with strict safety bounds (Sections 12 & 13).
class HalaaDynamicThemeData {
  final String themeId;
  final int version;
  final Color primary;
  final Color secondary;
  final Color background;
  final Color textPrimary;
  final double buttonOpacity;
  final double buttonRadius;
  final double buttonHeight;
  final bool animationsEnabled;
  final Duration animationDuration;

  const HalaaDynamicThemeData({
    required this.themeId,
    required this.version,
    required this.primary,
    required this.secondary,
    required this.background,
    required this.textPrimary,
    required this.buttonOpacity,
    required this.buttonRadius,
    required this.buttonHeight,
    required this.animationsEnabled,
    required this.animationDuration,
  });

  /// Preserves Halaa's current Royal Turquoise default palette untouched.
  factory HalaaDynamicThemeData.fallback() => const HalaaDynamicThemeData(
        themeId: 'halaa_default',
        version: 1,
        primary: Color(0xFF118B97),
        secondary: Color(0xFF54649F),
        background: Color(0xFF101426),
        textPrimary: Color(0xFFFFFFFF),
        buttonOpacity: 0.90,
        buttonRadius: 16,
        buttonHeight: 46,
        animationsEnabled: true,
        animationDuration: Duration(milliseconds: 200),
      );

  static Color? _parseHex(dynamic value) {
    if (value is! String) return null;
    final clean = value.trim().replaceFirst('#', '');
    if (clean.length != 6 && clean.length != 8) return null;
    final hex = clean.length == 6 ? 'FF$clean' : clean;
    final parsed = int.tryParse(hex, radix: 16);
    return parsed == null ? null : Color(parsed);
  }

  static HalaaDynamicThemeData? tryParse(Map<String, dynamic> json) {
    final colors = json['colors'];
    if (colors is! Map<String, dynamic>) return null;
    final primary = _parseHex(colors['primary']);
    final secondary = _parseHex(colors['secondary']);
    final background = _parseHex(colors['background']);
    final textPrimary = _parseHex(colors['textPrimary']);
    if (primary == null || secondary == null || background == null || textPrimary == null) {
      return null;
    }

    final buttons = (json['buttons'] as Map<String, dynamic>?) ?? const {};
    final animations = (json['animations'] as Map<String, dynamic>?) ?? const {};

    final opacity = ((buttons['opacity'] as num?)?.toDouble() ?? 0.90).clamp(0.2, 1.0);
    final radius = ((buttons['borderRadius'] as num?)?.toDouble() ?? 16.0).clamp(0.0, 40.0);
    final height = ((buttons['height'] as num?)?.toDouble() ?? 46.0).clamp(32.0, 72.0);
    final durationMs = ((animations['durationMs'] as num?)?.toInt() ?? 200).clamp(0, 1500);

    return HalaaDynamicThemeData(
      themeId: (json['themeId'] ?? 'halaa_default').toString(),
      version: (json['version'] as num?)?.toInt() ?? 1,
      primary: primary,
      secondary: secondary,
      background: background,
      textPrimary: textPrimary,
      buttonOpacity: opacity,
      buttonRadius: radius,
      buttonHeight: height,
      animationsEnabled: animations['enabled'] != false,
      animationDuration: Duration(milliseconds: durationMs),
    );
  }
}

/// Dynamic Theme Controller: applies published themes selectively with fallback protection.
class HalaaDynamicThemeController extends ChangeNotifier {
  static const String _cacheKey = 'halaa.central.dynamic_theme.v1';

  final String serverBaseUrl;
  HalaaDynamicThemeData _current = HalaaDynamicThemeData.fallback();

  HalaaDynamicThemeController({required this.serverBaseUrl});

  HalaaDynamicThemeData get current => _current;
  int get version => _current.version;

  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final parsed = HalaaDynamicThemeData.tryParse(jsonDecode(raw) as Map<String, dynamic>);
        if (parsed != null) {
          _current = parsed;
          notifyListeners();
        }
      }
    } catch (_) {
      // Fall back safely to current theme
    }
  }

  Future<bool> applyRemoteTheme(Map<String, dynamic> json) async {
    final parsed = HalaaDynamicThemeData.tryParse(json);
    if (parsed == null || parsed.version <= _current.version) return false;
    _current = parsed;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cacheKey, jsonEncode(json));
    } catch (_) {}
    return true;
  }

  Future<bool> refreshIfNewer([int? expectedVersion]) async {
    if (expectedVersion != null && expectedVersion <= _current.version) return false;
    final uri = Uri.parse('$serverBaseUrl/api/v1/app/bootstrap');
    if (uri.scheme != 'https' && uri.host != 'localhost' && uri.host != '127.0.0.1') {
      return false;
    }
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final theme = body['theme'];
      if (theme is Map<String, dynamic>) {
        return await applyRemoteTheme(theme);
      }
    } catch (_) {}
    return false;
  }
}
