import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Remote Config & Feature Flag Controller for Halaa User App (Sections 14, 21, 22).
/// - Pulls versioned config from `/api/v1/app/bootstrap`
/// - Ignores stale versions (`incomingVersion <= currentVersion`)
/// - Persists last known good config in SharedPreferences for offline fallback
/// - Updates listeners selectively without recreating MaterialApp or losing navigation
class HalaaRemoteConfigController extends ChangeNotifier {
  static const String _cacheKey = 'halaa.central.remote_config.v1';

  final String serverBaseUrl;
  int _version = 0;
  Map<String, dynamic> _config = _defaultConfig();
  bool _loaded = false;

  HalaaRemoteConfigController({required this.serverBaseUrl});

  int get version => _version;
  bool get isLoaded => _loaded;
  bool get maintenanceMode => _config['maintenanceMode'] == true;
  String get minAppVersion => (_config['minAppVersion'] ?? '3.1.5').toString();
  Map<String, dynamic> get rawConfig => Map<String, dynamic>.unmodifiable(_config);

  static Map<String, dynamic> _defaultConfig() => {
        'maintenanceMode': false,
        'minAppVersion': '3.1.5',
        'features': {
          'voiceRooms': true,
          'privateChat': true,
          'guestLogin': true,
          'gifts': true,
          'vip': true,
          'agencies': true,
          'games': {
            'ludo': true,
            'billiards': true,
            'chess': true,
            'domino': true,
            'tarneeb': true,
          },
        },
      };

  /// Checks nested feature flags such as `'voiceRooms'` or `'games.ludo'`.
  bool isFeatureEnabled(String path) {
    dynamic node = _config['features'];
    for (final segment in path.split('.')) {
      if (node is! Map) return false;
      node = node[segment];
    }
    return node == true;
  }

  Future<void> loadCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final cachedVersion = (decoded['version'] as num?)?.toInt() ?? 0;
        final cachedValue = decoded['value'];
        if (cachedValue is Map<String, dynamic>) {
          _version = cachedVersion;
          _config = cachedValue;
          _loaded = true;
          notifyListeners();
        }
      }
    } catch (_) {
      // Keep safe defaults if cache is unreadable
    }
  }

  Future<bool> applyRemotePayload({
    required int incomingVersion,
    required Map<String, dynamic> value,
  }) async {
    if (incomingVersion <= _version) return false;
    _version = incomingVersion;
    _config = value;
    _loaded = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode({'version': _version, 'value': _config}),
      );
    } catch (_) {}
    return true;
  }

  Future<bool> refreshIfNewer([int? expectedVersion]) async {
    if (expectedVersion != null && expectedVersion <= _version) {
      return false;
    }
    final uri = Uri.parse('$serverBaseUrl/api/v1/app/bootstrap');
    if (uri.scheme != 'https' && uri.host != 'localhost' && uri.host != '127.0.0.1') {
      return false;
    }
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return false;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final cfg = body['config'] as Map<String, dynamic>?;
      if (cfg == null) return false;
      final incomingVersion = (cfg['version'] as num?)?.toInt() ?? 0;
      final value = cfg['value'];
      if (value is Map<String, dynamic>) {
        return await applyRemotePayload(incomingVersion: incomingVersion, value: value);
      }
    } catch (_) {
      // Keep last known good config on network failure
    }
    return false;
  }
}
