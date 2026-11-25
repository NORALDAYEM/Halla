import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/halaa_models.dart';
import 'screens/app/app_login_screen.dart';
import 'screens/app/member_home_screen.dart';
import 'services/halaa_storage.dart';
import 'services/supabase_auth_service.dart';
import 'theme/halaa_themes.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HalaaUserApp());
}

class HalaaUserApp extends StatefulWidget {
  const HalaaUserApp({super.key});

  @override
  State<HalaaUserApp> createState() => _HalaaUserAppState();
}

class _HalaaUserAppState extends State<HalaaUserApp> {
  final _storage = HalaaStorage();
  final _auth = SupabaseAuthService();
  HalaaConfig _cfg = HalaaConfig.defaults();
  String? _memberUser;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
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
    if (!mounted) return;
    setState(() {
      _cfg = c;
      _memberUser = m;
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
      scrollBehavior: const _SilentScrollBehavior(),
      title: 'هلاا | ألعاب ودردشة',
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
          : (_memberUser == null
              ? AppLoginScreen(
                  config: _cfg,
                  authService: _auth,
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
                )
              : MemberHomeScreen(
                  displayName: _memberUser!,
                  config: _cfg,
                  onLogout: () async {
                    await _storage.setMemberUser(null);
                    if (!mounted) return;
                    setState(() => _memberUser = null);
                  },
                )),
    );
  }
}


class _SilentScrollBehavior extends MaterialScrollBehavior {
  const _SilentScrollBehavior();

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
