import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/halaa_config.dart';

class HalaaStorage {
  static const _configKey = 'halla.flutter.live_config.v2';
  static const _adminUserKey = 'halla.flutter.admin_user.v2';
  static const _memberUserKey = 'halla.flutter.member_user.v2';
  static const _logsKey = 'halla.flutter.logs.v2';

  Future<HalaaConfig> loadConfig({bool isAdminSubpath = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_configKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return HalaaConfig.fromJson(decoded, isAdminSubpath: isAdminSubpath);
        }
      } catch (_) {}
    }
    return HalaaConfig.defaults(isAdminSubpath: isAdminSubpath);
  }

  Future<void> saveConfig(HalaaConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_configKey, jsonEncode(cfg.toJson()));
  }

  Future<HalaaConfig?> fetchRemoteConfig({
    required String url,
    bool isAdminSubpath = false,
  }) async {
    try {
      final resp = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 6));
      if (resp.statusCode == 200) {
        final decoded = jsonDecode(utf8.decode(resp.bodyBytes));
        if (decoded is Map<String, dynamic>) {
          return HalaaConfig.fromJson(decoded, isAdminSubpath: isAdminSubpath);
        }
      }
    } catch (_) {}
    return null;
  }

  Future<String> pushToServer(HalaaConfig cfg, String token) async {
    final endpoint = cfg.serverEndpoint.trim();
    if (endpoint.isEmpty) {
      return 'تم الحفظ محلياً بنجاح (أدخل رابط السيرفر للبث المباشر).';
    }
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (token.trim().isNotEmpty) {
        headers['Authorization'] = 'Bearer ${token.trim()}';
      }
      final resp = await http
          .post(
            Uri.parse(endpoint),
            headers: headers,
            body: jsonEncode(cfg.toJson()),
          )
          .timeout(const Duration(seconds: 12));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return 'تم الحفظ والبث الفوري إلى السيرفر بنجاح (${resp.statusCode}).';
      }
      return 'تم الحفظ محلياً، واستجاب السيرفر بالرمز ${resp.statusCode}.';
    } catch (e) {
      return 'تم الحفظ محلياً، وتعذّر الاتصال بالسيرفر: $e';
    }
  }

  Future<String?> getAdminUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminUserKey);
  }

  Future<void> setAdminUser(String? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_adminUserKey);
    } else {
      await prefs.setString(_adminUserKey, user);
    }
  }

  Future<String?> getMemberUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_memberUserKey);
  }

  Future<void> setMemberUser(String? user) async {
    final prefs = await SharedPreferences.getInstance();
    if (user == null) {
      await prefs.remove(_memberUserKey);
    } else {
      await prefs.setString(_memberUserKey, user);
    }
  }

  Future<List<String>> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_logsKey) ??
        const [
          'تشغيل تطبيق هلاا ولوحة الإدارة بالكامل بلغة Flutter',
          'النسخ الاحتياطي التلقائي مفعّل مع سحابة IDrive e2 (حاوية halla)',
        ];
  }

  Future<void> addLog(String message) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getStringList(_logsKey) ?? <String>[];
    final now = DateTime.now().toLocal();
    final ts =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await prefs.setStringList(
      _logsKey,
      ['[$ts] $message', ...existing].take(50).toList(),
    );
  }
}
