import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../remote_config/halaa_remote_config_controller.dart';
import '../dynamic_theme/halaa_dynamic_theme_controller.dart';

const String kHalaaCentralServerUrl = String.fromEnvironment('HALAA_SERVER_URL', defaultValue: 'https://halla.onrender.com');

/// Real-Time Sync Client for Halaa User App (Sections 20, 21, 22).
/// - Connects via Server-Sent Events (`/api/v1/sync/stream`) using standard `package:http`
/// - Reconnects automatically with backoff and pulls missed events via `sinceVersion`
/// - Sends delivery acknowledgments to `/api/v1/sync/ack`
/// - Updates only affected controllers (zero full-app restart or flicker)
class HalaaRealtimeSyncClient {
  final String serverBaseUrl;
  final String deviceId;
  final HalaaRemoteConfigController configController;
  final HalaaDynamicThemeController themeController;

  int _lastGlobalVersion = 0;
  bool _running = false;
  http.Client? _streamClient;

  HalaaRealtimeSyncClient({
    this.serverBaseUrl = kHalaaCentralServerUrl,
    required this.deviceId,
    required this.configController,
    required this.themeController,
  });

  bool _isAllowedUri(Uri uri) =>
      uri.scheme == 'https' || uri.host == 'localhost' || uri.host == '127.0.0.1';

  Future<void> start() async {
    if (_running) return;
    _running = true;

    // 1. Load cached state immediately for zero-flicker startup
    await Future.wait([
      configController.loadCached(),
      themeController.loadCached(),
    ]);

    // 2. Sync latest snapshot from central server
    await syncMissedAndBootstrap();

    // 3. Start background SSE stream loop with automatic reconnect
    unawaited(_connectLoop());
  }

  Future<void> stop() async {
    _running = false;
    _streamClient?.close();
    _streamClient = null;
  }

  Future<void> syncMissedAndBootstrap() async {
    await Future.wait([
      configController.refreshIfNewer(),
      themeController.refreshIfNewer(),
    ]);

    final uri = Uri.parse('$serverBaseUrl/api/v1/sync/events?sinceVersion=$_lastGlobalVersion');
    if (!_isAllowedUri(uri)) return;
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return;
      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final events = (body['events'] as List?) ?? const [];
      for (final raw in events) {
        if (raw is Map<String, dynamic>) {
          await handleServerEvent(raw);
        }
      }
      final serverGlobal = (body['globalVersion'] as num?)?.toInt() ?? _lastGlobalVersion;
      if (serverGlobal > _lastGlobalVersion) {
        _lastGlobalVersion = serverGlobal;
      }
    } catch (_) {}
  }

  Future<void> handleServerEvent(Map<String, dynamic> event) async {
    final incomingVersion = (event['version'] as num?)?.toInt() ?? 0;
    if (incomingVersion <= _lastGlobalVersion) return;

    final type = (event['event'] ?? '').toString();
    switch (type) {
      case 'theme.updated':
        await themeController.refreshIfNewer();
        break;
      case 'config.updated':
      case 'feature.updated':
      case 'maintenance.updated':
        await configController.refreshIfNewer();
        break;
      default:
        break;
    }

    _lastGlobalVersion = incomingVersion;
    final eventId = (event['eventId'] ?? '').toString();
    if (eventId.isNotEmpty) {
      unawaited(_acknowledge(eventId, incomingVersion));
    }
  }

  Future<void> _acknowledge(String eventId, int appliedVersion) async {
    final uri = Uri.parse('$serverBaseUrl/api/v1/sync/ack');
    if (!_isAllowedUri(uri)) return;
    try {
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'eventId': eventId,
              'deviceId': deviceId,
              'appType': 'USER_APP',
              'appliedVersion': appliedVersion,
              'status': 'ACK',
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<void> _connectLoop() async {
    int backoffSeconds = 2;
    while (_running) {
      final uri = Uri.parse('$serverBaseUrl/api/v1/sync/stream');
      if (!_isAllowedUri(uri)) return;
      try {
        _streamClient?.close();
        _streamClient = http.Client();
        final req = http.Request('GET', uri);
        req.headers['Accept'] = 'text/event-stream';
        final response = await _streamClient!.send(req).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          backoffSeconds = 2;
          final lines = response.stream.transform(utf8.decoder).transform(const LineSplitter());
          await for (final line in lines) {
            if (!_running) break;
            if (line.startsWith('data:')) {
              final jsonStr = line.substring(5).trim();
              if (jsonStr.isNotEmpty) {
                try {
                  final parsed = jsonDecode(jsonStr);
                  if (parsed is Map<String, dynamic> && parsed['event'] != null) {
                    await handleServerEvent(parsed);
                  }
                } catch (_) {}
              }
            }
          }
        }
      } catch (_) {
        // Reconnect below with capped exponential backoff
      }

      if (!_running) break;
      await Future.delayed(Duration(seconds: backoffSeconds));
      backoffSeconds = (backoffSeconds * 2).clamp(2, 30);
      await syncMissedAndBootstrap();
    }
  }
}
