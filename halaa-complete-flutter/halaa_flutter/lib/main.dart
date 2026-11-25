import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/halaa_config.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/app/app_login_screen.dart';
import 'screens/app/member_home_screen.dart';
import 'services/halaa_storage.dart';
import 'theme/halaa_themes.dart';

/// Build-time entry selector:
/// - Default / `--dart-define=ENTRY=app`   -> Halaa User App (`/Halla/halla-web/`)
/// - `--dart-define=ENTRY=admin`           -> Halaa Admin Panel (`/Halla/admin/`)
const String kEntryMode = String.fromEnvironment('ENTRY', defaultValue: 'app');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HalaaUnifiedApp());
}

class HalaaUnifiedApp extends StatefulWidget {
  const HalaaUnifiedApp({super.key});

  @override
  State<HalaaUnifiedApp> createState() => _HalaaUnifiedAppState();
}

class _HalaaUnifiedAppState extends State<HalaaUnifiedApp> {
  final _storage = HalaaStorage();
  late bool _inAdminPortal;
  HalaaConfig _config = HalaaConfig.defaults(isAdminSubpath: kEntryMode == 'admin');
  String? _memberUser;
  String? _adminUser;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _inAdminPortal = kEntryMode == 'admin';
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final isAdminSubpath = kEntryMode == 'admin';
    final cfg = await _storage.loadConfig(isAdminSubpath: isAdminSubpath);
    final member = await _storage.getMemberUser();
    final admin = await _storage.getAdminUser();
    if (!mounted) return;
    setState(() {
      _config = cfg;
      _memberUser = member;
      _adminUser = admin;
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final preset = findThemePreset(_config.activeTheme);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _inAdminPortal ? 'إدارة هلاا | Halaa Admin' : 'هلاا | ألعاب ودردشة',
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: preset.primary,
          brightness: Brightness.dark,
        ),
      ),
      home: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    if (_inAdminPortal) {
      if (_adminUser == null) {
        return AdminLoginScreen(
          config: _config,
          onAuthenticated: (u) async {
            await _storage.setAdminUser(u);
            await _storage.addLog('دخول المشرف $u');
            if (!mounted) return;
            setState(() => _adminUser = u);
          },
          onBackToApp: () => setState(() => _inAdminPortal = false),
        );
      }
      return AdminDashboardScreen(
        username: _adminUser!,
        initialConfig: _config,
        storage: _storage,
        onConfigUpdated: (updated) => setState(() => _config = updated),
        onLogout: () async {
          await _storage.setAdminUser(null);
          if (!mounted) return;
          setState(() => _adminUser = null);
        },
        onPreviewApp: () => setState(() => _inAdminPortal = false),
      );
    }

    if (_memberUser == null) {
      return AppLoginScreen(
        config: _config,
        onLoggedIn: (u) async {
          await _storage.setMemberUser(u);
          if (!mounted) return;
          setState(() => _memberUser = u);
        },
        onOpenAdminPortal: () => setState(() => _inAdminPortal = true),
      );
    }

    return MemberHomeScreen(
      displayName: _memberUser!,
      config: _config,
      onLogout: () async {
        await _storage.setMemberUser(null);
        if (!mounted) return;
        setState(() => _memberUser = null);
      },
      onOpenAdminPortal: () => setState(() => _inAdminPortal = true),
    );
  }
}
