import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

const String kHalaaCentralServerUrl = String.fromEnvironment('HALAA_SERVER_URL', defaultValue: 'https://halla.onrender.com');

/// Central Admin API Client for Halaa Admin App (Sections 4, 5, 11, 23, 34).
/// - Enforces HTTPS for all non-localhost server URLs
/// - Uses short-lived Bearer admin access tokens obtained via `/api/v1/auth/admin/login`
/// - Connects every admin toggle/action to real server endpoints (no fake local-only controls)
class HalaaCentralAdminApi {
  final String serverBaseUrl;
  String? _accessToken;
  String? _refreshToken;
  String? _sessionId;

    HalaaCentralAdminApi({this.serverBaseUrl = kHalaaCentralServerUrl});

  bool get isAuthenticated => _accessToken != null && _accessToken!.isNotEmpty;

  Uri _secureUri(String path) {
    final uri = Uri.parse('$serverBaseUrl$path');
    final isLocal = uri.host == 'localhost' || uri.host == '127.0.0.1';
    if (uri.scheme != 'https' && !isLocal) {
      throw StateError('Insecure HTTP endpoint rejected; HTTPS is mandatory for Admin API');
    }
    return uri;
  }

  Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
    required String totpCode,
    String deviceName = 'Halaa Admin App',
  }) async {
    final res = await http.post(
      _secureUri('/api/v1/auth/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'password': password,
        'totpCode': totpCode,
        'deviceName': deviceName,
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200 || body['ok'] != true) {
      throw Exception(body['error'] ?? 'فشل تسجيل الدخول الإداري');
    }
    _accessToken = body['accessToken']?.toString();
    _refreshToken = body['refreshToken']?.toString();
    _sessionId = body['sessionId']?.toString();
    return body;
  }

  Future<Map<String, dynamic>> fetchSyncStatus() => _get('/api/v1/admin/sync/status');
  Future<Map<String, dynamic>> fetchPermissions() => _get('/api/v1/admin/permissions');
  Future<Map<String, dynamic>> fetchConfig() => _get('/api/v1/admin/config');
  Future<Map<String, dynamic>> fetchAuditLogs() => _get('/api/v1/admin/audit/logs');
  Future<Map<String, dynamic>> manageVoiceRoom({required String room, required String target, required String action}) =>
    _send('POST', '/api/v1/admin/voice/rooms', {'room':room,'target':target,'action':action});

  Future<Map<String, dynamic>> updateConfig({
    required Map<String, dynamic> patch,
    required String reason,
  }) =>
      _send('PATCH', '/api/v1/admin/config', {'patch': patch, 'reason': reason});

  Future<Map<String, dynamic>> rollbackConfig({
    required int targetVersion,
    required String reason,
  }) =>
      _send('POST', '/api/v1/admin/config/rollback', {
        'targetVersion': targetVersion,
        'reason': reason,
      });

  Future<Map<String, dynamic>> saveThemeDraft({
    required Map<String, dynamic> payload,
    required String reason,
    String themeId = 'halaa_default',
  }) =>
      _send('POST', '/api/v1/admin/themes', {
        'themeId': themeId,
        'payload': payload,
        'reason': reason,
      });

  Future<Map<String, dynamic>> publishTheme({
    required int version,
    required String reason,
    String themeId = 'halaa_default',
  }) =>
      _send('POST', '/api/v1/admin/themes/$themeId/publish', {
        'version': version,
        'reason': reason,
      });

  Future<Map<String, dynamic>> toggleEmergency({
    required String actionKey,
    required bool active,
    required String reason,
    String scope = 'GLOBAL',
  }) =>
      _send('POST', '/api/v1/security/emergency', {
        'actionKey': actionKey,
        'active': active,
        'reason': reason,
        'scope': scope,
      });

  Future<Map<String, dynamic>> submitFinancialAdjustment({
    required String targetUserId,
    required String currency,
    required String operation,
    required num amount,
    required String reason,
    required String approvalId,
    String? idempotencyKey,
  }) {
    final key = idempotencyKey ??
        'fin_${DateTime.now().millisecondsSinceEpoch}_${Random.secure().nextInt(999999)}';
    return _send('POST', '/api/v1/admin/finance/adjustments', {
      'targetUserId': targetUserId,
      'currency': currency,
      'operation': operation,
      'amount': amount,
      'reason': reason,
      'approvalId': approvalId,
      'idempotencyKey': key,
    });
  }

  Future<Map<String, dynamic>> _get(String path) async {
    final res = await http.get(_secureUri(path), headers: _headers());
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || body['ok'] != true) {
      throw Exception(body['error'] ?? 'HTTP ${res.statusCode}');
    }
    return body;
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path,
    Map<String, dynamic> payload,
  ) async {
    final req = http.Request(method, _secureUri(path));
    req.headers.addAll(_headers());
    req.body = jsonEncode(payload);
    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 400 || body['ok'] != true) {
      throw Exception(body['error'] ?? 'HTTP ${res.statusCode}');
    }
    return body;
  }
}
