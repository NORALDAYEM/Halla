import 'dart:convert';
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
  bool _dismissedOptional = false;

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

      final latestBuild = (section['latest_build'] as num?)?.toInt() ?? 0;
      final minRequiredBuild =
          (section['min_required_build'] as num?)?.toInt() ?? 0;
      final forceUpdate = section['force_update'] == true;
      final updateType = (section['update_type'] as String?)?.trim().toLowerCase() ?? 'minor';
      final isMajor = updateType == 'major';
      final latestVersion =
          (section['latest_version'] as String?)?.trim() ?? '';
      final title = (section['title'] as String?)?.trim() ?? 'تحديث جديد متوفر';
      final message = (section['message'] as String?)?.trim() ??
          'يرجى تحديث التطبيق للحصول على آخر التعديلات والتحسينات.';
      final downloadUrl = (section['download_url'] as String?)?.trim() ??
          'https://github.com/NORALDAYEM/Halla/releases/latest';

      final needsUpdate = latestBuild > widget.currentBuild ||
          minRequiredBuild > widget.currentBuild;
      if (!needsUpdate) return;

      final isMandatory =
          isMajor || forceUpdate || (minRequiredBuild > widget.currentBuild);
      if (!isMandatory && _dismissedOptional) return;

      _showUpdateDialog(
        title: isMandatory ? 'تحديث كبير مطلوب للتطبيق' : title,
        message: message,
        latestVersion: latestVersion,
        downloadUrl: downloadUrl,
        isMandatory: isMandatory,
      );
    } finally {
      _checking = false;
    }
  }

  Future<void> _openDownload(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https' || !['github.com', 'noraldayem.github.io', 'apps.apple.com', 'play.google.com'].contains(uri.host)) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _showUpdateDialog({
    required String title,
    required String message,
    required String latestVersion,
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
                    'الإصدار الحالي: ${widget.currentVersion}  •  الإصدار الجديد: $latestVersion',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ],
            ),
            actions: [
              if (!isMandatory)
                TextButton(
                  onPressed: () {
                    _dismissedOptional = true;
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
