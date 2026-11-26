import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AppUpdateGate extends StatefulWidget {
  final String appKey;
  final String currentVersion;
  final int currentBuild;
  final Widget child;

  const AppUpdateGate({
    super.key,
    required this.appKey,
    required this.currentVersion,
    required this.currentBuild,
    required this.child,
  });

  @override
  State<AppUpdateGate> createState() => _AppUpdateGateState();
}

class _AppUpdateGateState extends State<AppUpdateGate>
    with WidgetsBindingObserver {
  Timer? _pollTimer;
  bool _checking = false;
  bool _dialogOpen = false;
  int? _dismissedBuild;
  late final Future<PackageInfo> _installed = PackageInfo.fromPlatform();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pollTimer = Timer.periodic(const Duration(minutes: 5), (_) => _checkForUpdate());
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkForUpdate());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForUpdate();
    }
  }

  Future<Map<String, dynamic>?> _fetchManifest() async {
    final ts = DateTime.now().millisecondsSinceEpoch;
    final urls = [
      'https://raw.githubusercontent.com/NORALDAYEM/Halla/main/app_version.json?t=$ts',
      'https://noraldayem.github.io/Halla/app_version.json?t=$ts',
    ];
    for (final rawUrl in urls) {
      try {
        final res = await http
            .get(Uri.parse(rawUrl))
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final decoded = jsonDecode(utf8.decode(res.bodyBytes));
          if (decoded is Map<String, dynamic>) {
            return decoded;
          }
        }
      } catch (_) {
        // Ignore network errors so offline users are never blocked
      }
    }
    return null;
  }

  Future<void> _checkForUpdate() async {
    if (_checking || _dialogOpen || !mounted) return;
    _checking = true;
    try {
      final manifest = await _fetchManifest();
      if (manifest == null || !mounted) return;
      final section = manifest[widget.appKey];
      if (section is! Map<String, dynamic>) return;
      final remoteCfgVer = (section['remote_config_version'] as num?)?.toInt() ?? 0;
      final liveConfig = section['live_config'];
if (remoteCfgVer > 0) {
final prefs = await SharedPreferences.getInstance();
final verKey = 'halaa_remote_cfg_ver_' + widget.appKey;
final lastVer = prefs.getInt(verKey) ?? 0;
if (remoteCfgVer > lastVer) {
if (liveConfig != null) {
await prefs.setString('halaa_live_config_' + widget.appKey, jsonEncode(liveConfig));
}
await prefs.setInt(verKey, remoteCfgVer);
  if (mounted) {
ScaffoldMessenger.maybeOf(context)?.showSnackBar(
const SnackBar(
content: Text('تم تحديث إعدادات ومحتوى التطبيق تلقائياً'),
duration: Duration(seconds: 3),
),
);
}
}
}
      
      if (kIsWeb || ![TargetPlatform.android, TargetPlatform.iOS].contains(defaultTargetPlatform)) return;
      final platform = defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
      final platformSections = section['platforms'];
      final entry = platformSections is Map ? platformSections[platform] : null;
      final release = entry is Map ? entry : section;
      final installed = await _installed;
      if (!mounted) return;
      final installedBuild = int.tryParse(installed.buildNumber) ?? widget.currentBuild;
      final latestBuild = (release['latest_build'] as num?)?.toInt() ?? 0;
      final minRequiredBuild =
          (release['min_required_build'] as num?)?.toInt() ?? 0;
      final forceUpdate = release['force_update'] == true;
      final updateType = (release['update_type'] as String?)?.trim().toLowerCase() ?? 'minor';
      final isMajor = updateType == 'major';
      final latestVersion =
          (release['latest_version'] as String?)?.trim() ?? '';
      final title = (release['title'] as String?)?.trim() ?? 'تحديث جديد متوفر';
      final message = (release['message'] as String?)?.trim() ??
          'يرجى تحديث التطبيق للحصول على آخر التعديلات والتحسينات.';
      final downloadUrl = (release['download_url'] as String?)?.trim() ??
          'https://github.com/NORALDAYEM/Halla/releases/latest';

      if (!_validDownload(downloadUrl, platform)) return;
      final needsUpdate = latestBuild > installedBuild ||
          minRequiredBuild > installedBuild;
      if (!needsUpdate) return;

      final isMandatory =
          isMajor || forceUpdate || (minRequiredBuild > installedBuild);
      if (!isMandatory && _dismissedBuild == latestBuild) return;

      _showUpdateDialog(
        title: isMandatory ? 'تحديث كبير مطلوب للتطبيق' : title,
        message: message,
        latestVersion: latestVersion,
        installedVersion: installed.version,
        build: latestBuild,
        downloadUrl: downloadUrl,
        isMandatory: isMandatory,
      );
    } finally {
      _checking = false;
    }
  }

  bool _validDownload(String url, String platform) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || uri.userInfo.isNotEmpty) return false;
    if (platform == 'ios') return ['apps.apple.com', 'testflight.apple.com'].contains(uri.host);
    return uri.host == 'play.google.com' ||
        (uri.host == 'github.com' && uri.path.startsWith('/NORALDAYEM/Halla/releases/download/') && uri.path.endsWith('.apk'));
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || !['github.com', 'noraldayem.github.io', 'apps.apple.com', 'testflight.apple.com', 'play.google.com'].contains(uri.host)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showUpdateDialog({
    required String title,
    required String message,
    required String latestVersion,
    required String installedVersion,
    required int build,
    required String downloadUrl,
    required bool isMandatory,
  }) {
    if (!mounted || _dialogOpen) return;
    _dialogOpen = true;
    showDialog<void>(
      context: context,
      barrierDismissible: !isMandatory,
      builder: (ctx) {
        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            title: Row(
              children: [
                const Icon(
                  Icons.system_update_alt_rounded,
                  color: Color(0xFF118B97),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message, style: const TextStyle(fontSize: 14, height: 1.5)),
                if (latestVersion.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'الإصدار الحالي: ${installedVersion}  •  الإصدار الجديد: $latestVersion',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () {
                    _dismissedBuild = build;
                    Navigator.of(ctx).pop();
                  },
                  child: const Text('لاحقاً'),
                ),
              FilledButton.icon(
                onPressed: () => _openDownload(downloadUrl),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text('تحديث الآن'),
              ),
            ],
          ),
        );
      },
    ).whenComplete(() {
      _dialogOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
