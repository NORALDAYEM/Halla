import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/halaa_models.dart';

class HalaaStorage {
  static const _cfgKey = 'halla.exact.flutter.config.v3';
  static const _memberAuthKey = 'halla.exact.flutter.member.v3';
  static const _logsKey = 'halla.exact.flutter.logs.v3';

  Future<HalaaConfig> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cfgKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return HalaaConfig.fromJson(decoded);
        }
      } catch (_) {}
    }
    return HalaaConfig.defaults();
  }

  Future<void> saveConfig(HalaaConfig cfg) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cfgKey, jsonEncode(cfg.toJson()));
  }

  Future<String?> getMemberUser() async =>
      (await SharedPreferences.getInstance()).getString(_memberAuthKey);

  Future<void> setMemberUser(String? u) async {
    final p = await SharedPreferences.getInstance();
    if (u == null) {
      await p.remove(_memberAuthKey);
    } else {
      await p.setString(_memberAuthKey, u);
    }
  }

  Future<List<String>> loadLogs() async {
    final p = await SharedPreferences.getInstance();
    return p.getStringList(_logsKey) ??
        const [
          'تفعيل نسخة هلاا الكاملة بلغة Flutter بنفس الشعار والخلفيات والشاشات المنبثقة',
          'النسخ الاحتياطي التلقائي مفعّل مع سحابة IDrive e2 (حاوية halla)',
        ];
  }

  Future<void> addLog(String message) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_logsKey) ?? <String>[];
    final now = DateTime.now().toLocal();
    final stamp =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    await p.setStringList(_logsKey, ['[$stamp] $message', ...list].take(50).toList());
  }
}
