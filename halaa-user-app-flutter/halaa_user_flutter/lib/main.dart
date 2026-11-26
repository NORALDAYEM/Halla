import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'models/halaa_models.dart';
import 'screens/app/app_login_screen.dart';
import 'screens/app/member_home_screen.dart';
import 'services/halaa_storage.dart';
import 'services/supabase_auth_service.dart';
import 'theme/halaa_themes.dart';
import 'widgets/app_update_gate.dart';
import 'core/dynamic_theme/halaa_dynamic_theme_controller.dart';
import 'core/realtime_sync/halaa_realtime_sync_client.dart';
import 'core/remote_config/halaa_remote_config_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: SupabaseAuthService.endpoint, anonKey: SupabaseAuthService.publicKey);
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
  bool _recovering = false;
  StreamSubscription<AuthState>? _accountEvents;
  final _remoteConfigController = HalaaRemoteConfigController(
    serverBaseUrl: kHalaaCentralServerUrl,
  );
  final _dynamicThemeController = HalaaDynamicThemeController(
    serverBaseUrl: kHalaaCentralServerUrl,
  );
  late final HalaaRealtimeSyncClient _realtimeSyncClient;

  @override
  void initState() {
    super.initState();
    _dynamicThemeController.addListener(_remoteChanged);
    _remoteConfigController.addListener(_remoteChanged);
    _accountEvents = _auth.auth.onAuthStateChange.listen((state) {
      if (!mounted) return;
      if (state.event == AuthChangeEvent.passwordRecovery) {
        setState(() => _recovering = true);
      }
      final name = _auth.displayName;
      if (name != null || state.event == AuthChangeEvent.signedOut) {
        setState(() => _memberUser = name);
      }
    }, onError: (Object error) { if (mounted && _auth.auth.currentSession == null) setState(() => _memberUser = null); });
    _bootstrap();
    _realtimeSyncClient = HalaaRealtimeSyncClient(
      serverBaseUrl: kHalaaCentralServerUrl,
      deviceId: 'halaa-user-${DateTime.now().millisecondsSinceEpoch}',
      configController: _remoteConfigController,
      themeController: _dynamicThemeController,
    );
    _realtimeSyncClient.start();
  }

  void _remoteChanged() { if (mounted) setState(() {}); }
  @override
  void dispose() {
    _dynamicThemeController.removeListener(_remoteChanged);
    _remoteConfigController.removeListener(_remoteChanged);
    _accountEvents?.cancel();
    _realtimeSyncClient.stop();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final c = await _storage.loadConfig();
    final saved = await _storage.getMemberUser();
    final m = _auth.displayName ?? (saved == 'وضع الضيف' ? saved : null);
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
    final remoteTheme = _dynamicThemeController.current;
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
          seedColor: remoteTheme.version > 1 ? remoteTheme.primary : preset.primary,
          brightness: Brightness.dark,
        ),
      ),
      home: AppUpdateGate(
        appKey: 'user_app',
        currentVersion: '3.1.5',
        currentBuild: 6,
        child: !_ready
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : _recovering ? _PasswordRecovery(auth: _auth, onDone: () => setState(() => _recovering = false))
          : (_memberUser == null
              ? AppLoginScreen(
                  config: _cfg,
                  authService: _auth,
                  onLoggedIn: (u) async {
                    await _storage.setMemberUser(u);
                    if (!mounted) return;
                    setState(() => _memberUser = u);
                  },
                  onTicketCreated: (t) => _updateConfig(
                    _cfg.copyWith(tickets: [t, ..._cfg.tickets]),
                  ),
                )
              : MemberHomeScreen(
                  voiceRoomsEnabled: _remoteConfigController.isFeatureEnabled('voiceRooms'),
                  authService: _auth,
                  displayName: _memberUser!,
                  config: _cfg,
                  onLogout: () async {
                    if (_auth.auth.currentSession != null) await _auth.auth.signOut(scope: SignOutScope.local);
                    await _storage.setMemberUser(null);
                    if (!mounted) return;
                    setState(() => _memberUser = null);
                  },
                )),
      ),
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

class _PasswordRecovery extends StatefulWidget {
  const _PasswordRecovery({required this.auth, required this.onDone});
  final SupabaseAuthService auth;
  final VoidCallback onDone;
  @override
  State<_PasswordRecovery> createState() => _PasswordRecoveryState();
}

class _PasswordRecoveryState extends State<_PasswordRecovery> {
  String password = '', message = '';
  bool busy = false;
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: const Text('تعيين كلمة مرور جديدة')),
    body: SafeArea(child: ListView(padding: const EdgeInsets.all(24), children: [
      TextField(obscureText: true, autofocus: true, autofillHints: const [AutofillHints.newPassword],
        decoration: const InputDecoration(labelText: 'كلمة المرور الجديدة'), onChanged: (v) => password = v),
      Text(message),
      FilledButton(onPressed: busy ? null : () async {
        setState(() => busy = true);
        try {
          await widget.auth.auth.updateUser(UserAttributes(password: password));
          if (mounted) widget.onDone();
        } catch (_) {
          if (mounted) setState(() { busy = false; message = 'تعذّر حفظ كلمة المرور. تحقّق من صلاحية الرابط وقوة كلمة المرور.'; });
        }
      }, child: const Text('حفظ كلمة المرور')),
    ])));
}
