import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/halaa_models.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'services/halaa_storage.dart';
import 'theme/halaa_themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HalaaAdminStandaloneApp());
}

class HalaaAdminStandaloneApp extends StatefulWidget {
  const HalaaAdminStandaloneApp({super.key});

  @override
  State<HalaaAdminStandaloneApp> createState() => _HalaaAdminStandaloneAppState();
}

class _HalaaAdminStandaloneAppState extends State<HalaaAdminStandaloneApp> {
  final _storage = HalaaStorage();
  HalaaConfig _cfg = HalaaConfig.defaults();
  String? _adminUser;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final c = await _storage.loadConfig();
    final a = await _storage.getAdminUser();
    if (!mounted) return;
    setState(() {
      _cfg = c;
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
      title: 'إدارة هلاا | Halaa Admin',
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
          : (_adminUser == null
              ? AdminLoginScreen(
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
                )
              : AdminDashboardScreen(
                  username: _adminUser!,
                  initialConfig: _cfg,
                  storage: _storage,
                  onConfigUpdated: (u) => setState(() => _cfg = u),
                  onLogout: () async {
                    await _storage.setAdminUser(null);
                    if (!mounted) return;
                    setState(() => _adminUser = null);
                  },
                )),
    );
  }
}
