import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/halaa_models.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/app/app_login_screen.dart';
import 'screens/app/member_home_screen.dart';
import 'services/halaa_storage.dart';
import 'services/supabase_auth_service.dart';
import 'theme/halaa_themes.dart';

const String kEntryMode = String.fromEnvironment('ENTRY', defaultValue: 'app');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HalaaExactApp());
}

class HalaaExactApp extends StatefulWidget {
  const HalaaExactApp({super.key});

  @override
  State<HalaaExactApp> createState() => _HalaaExactAppState();
}

class _HalaaExactAppState extends State<HalaaExactApp> {
  final _storage = HalaaStorage();
  final _auth = SupabaseAuthService();
  late bool _inAdmin;
  HalaaConfig _cfg = HalaaConfig.defaults();
  String? _memberUser;
  String? _adminUser;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _inAdmin = kEntryMode == 'admin';
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final c = await _storage.loadConfig();
    var m = await _storage.getMemberUser();
    final oauthReturn = await _auth.checkOAuthReturn();
    if (oauthReturn != null && oauthReturn.ok && oauthReturn.displayName != null) {
      m = oauthReturn.displayName;
      await _storage.setMemberUser(m);
    }
    final a = await _storage.getAdminUser();
    if (!mounted) return;
    setState(() {
      _cfg = c;
      _memberUser = m;
      _adminUser = a;
      _ready = true;
    });
  }

  Future<void> _updateConfig(HalaaConfig next) async {
    await _storage.saveConfig(next);
    if (!mounted) return;
    setState(() => _cfg = next);
  }

  @override
  Widget build(BuildContext context) {
    final preset = findThemePreset(_cfg.activeTheme);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: _inAdmin ? 'إدارة هلاا | Halaa Admin' : 'هلاا | ألعاب ودردشة',
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
          : _buildScreen(),
    );
  }

  Widget _buildScreen() {
    if (_inAdmin) {
      if (_adminUser == null) {
        return AdminLoginScreen(
          config: _cfg,
          onAuthenticated: (u) async {
            await _storage.setAdminUser(u);
            await _storage.addLog('تسجيل دخول المشرف $u');
            if (!mounted) return;
            setState(() => _adminUser = u);
          },
          onTicketCreated: (t) => _updateConfig(
            _cfg.copyWith(tickets: [t, ..._cfg.tickets]),
          ),
          onBackToApp: () => setState(() => _inAdmin = false),
        );
      }
      return AdminDashboardScreen(
        username: _adminUser!,
        initialConfig: _cfg,
        storage: _storage,
        onConfigUpdated: (u) => setState(() => _cfg = u),
        onLogout: () async {
          await _storage.setAdminUser(null);
          if (!mounted) return;
          setState(() => _adminUser = null);
        },
        onPreviewApp: () => setState(() => _inAdmin = false),
      );
    }

    if (_memberUser == null) {
      return AppLoginScreen(
        config: _cfg,
        onLoggedIn: (u) async {
          await _storage.setMemberUser(u);
          if (!mounted) return;
          setState(() => _memberUser = u);
        },
        onRegisteredUser: (rec) => _updateConfig(
          _cfg.copyWith(appUsers: [rec, ..._cfg.appUsers]),
        ),
        onTicketCreated: (t) => _updateConfig(
          _cfg.copyWith(tickets: [t, ..._cfg.tickets]),
        ),
        onOpenAdminPortal: () => setState(() => _inAdmin = true),
        authService: _auth,
      );
    }

    return MemberHomeScreen(
      displayName: _memberUser!,
      config: _cfg,
      onLogout: () async {
        await _storage.setMemberUser(null);
        if (!mounted) return;
        setState(() => _memberUser = null);
      },
      onOpenAdminPortal: () => setState(() => _inAdmin = true),
    );
  }
}
