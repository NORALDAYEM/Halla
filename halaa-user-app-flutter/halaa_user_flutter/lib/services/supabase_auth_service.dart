import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/halaa_models.dart';
import 'halaa_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  static const String endpoint =String.fromEnvironment('SUPABASE_URL', defaultValue:  'https://uwjrboviicypyhregpoo.supabase.co');
  static const String publicKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: 'sb_publishable_QbUKNVMYDRK63NjB26tCtw_jzOaEXdR');


  GoTrueClient get auth => Supabase.instance.client.auth;
  String get redirect => kIsWeb
      ? Uri.base.replace(query: '', fragment: '').toString().split('?').first.split('#').first
      : 'com.halla.voiceclubs://auth/callback';

  String? get displayName {
    final user = auth.currentSession?.user;
    if (user == null) return null;
    final meta = user.userMetadata ?? {};
    return (meta['nickname'] ?? meta['full_name'] ?? meta['name'] ?? user.email?.split('@').first ?? 'عضو هلا').toString();
  }

  Future<String> accessToken() async {
    final current = auth.currentSession;
    if (current == null) throw StateError('سجّل الدخول للانضمام إلى الغرفة');
    if (!current.isExpired) return current.accessToken;
    final next = await auth.refreshSession();
    if (next.session == null) throw StateError('انتهت الجلسة. سجّل الدخول مجدداً');
    return next.session!.accessToken;
  }

  Future<String?> startOAuth(String provider) async {
    try {
      final opened = await auth.signInWithOAuth(
        provider == 'google' ? OAuthProvider.google : OAuthProvider.facebook,
        redirectTo: redirect,
        queryParams: provider == 'google' ? {'prompt':'select_account'} : null,
      );
      return opened ? null : 'تعذّر فتح صفحة تسجيل الدخول.';
    } catch (_) { return 'تعذّر الاتصال بخدمة تسجيل الدخول. حاول مجدداً.'; }
  }

  static StreamSubscription<AuthState>? _authStateSub;

  SupabaseAuthService() {
    ensureAuthSyncListener();
  }

  void ensureAuthSyncListener() {
    if (_authStateSub != null) return;
    _authStateSub = auth.onAuthStateChange.listen((data) {
      if (data.session != null &&
          (data.event == AuthChangeEvent.signedIn ||
              data.event == AuthChangeEvent.tokenRefreshed ||
              data.event == AuthChangeEvent.userUpdated)) {
        unawaited(syncCurrentUserToServer(action: 'auth_state_sync'));
      }
    });
  }

  bool hasLinkedProvider(String provider) {
    final user = auth.currentUser;
    if (user == null) return false;
    final identities = user.identities ?? const <UserIdentity>[];
    if (identities.any((i) => i.provider == provider)) return true;
    final providers = user.appMetadata['providers'];
    if (providers is List) {
      return providers.any((p) => p.toString() == provider);
    }
    return user.appMetadata['provider'] == provider;
  }

  String? linkedProviderEmail(String provider) {
    final user = auth.currentUser;
    if (user == null) return null;
    final identities = user.identities ?? const <UserIdentity>[];
    for (final identity in identities) {
      if (identity.provider == provider) {
        final email = identity.identityData?['email']?.toString();
        if (email != null && email.isNotEmpty) return email;
      }
    }
    return hasLinkedProvider(provider) ? user.email : null;
  }

  Future<String?> linkWithGoogle() async {
    try {
      ensureAuthSyncListener();
      final opened = await auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirect,
        queryParams: const {'prompt': 'select_account'},
      );
      return opened ? null : 'تعذر فتح نافذة اختيار حسابات Gmail.';
    } catch (e) {
      return 'فشل الربط المباشر بحساب Gmail: $e';
    }
  }

  Future<String?> linkWithFacebook() async {
    try {
      ensureAuthSyncListener();
      final opened = await auth.signInWithOAuth(
        OAuthProvider.facebook,
        redirectTo: redirect,
      );
      return opened ? null : 'تعذر فتح صفحة الربط بحساب Facebook.';
    } catch (e) {
      return 'فشل الربط المباشر بصفحة Facebook: $e';
    }
  }

  Future<Map<String, dynamic>?> syncCurrentUserToServer({
    String action = 'oauth_sync',
  }) async {
    final session = auth.currentSession;
    final user = session?.user ?? auth.currentUser;
    if (user == null) return null;

    final meta = user.userMetadata ?? const <String, dynamic>{};
    final identities = user.identities ?? const <UserIdentity>[];

    UserIdentity? findIdentity(String provider) {
      for (final identity in identities) {
        if (identity.provider == provider) return identity;
      }
      return null;
    }

    final googleIdentity = findIdentity('google');
    final facebookIdentity = findIdentity('facebook');

    final googleId = googleIdentity?.id ??
        googleIdentity?.identityData?['sub']?.toString() ??
        googleIdentity?.identityData?['provider_id']?.toString();
    final gmailEmail = googleIdentity?.identityData?['email']?.toString() ??
        (googleIdentity != null ? user.email : null);
    final facebookId = facebookIdentity?.id ??
        facebookIdentity?.identityData?['sub']?.toString() ??
        facebookIdentity?.identityData?['provider_id']?.toString();

    final config = await HalaaStorage.loadConfig();
    final rawBase = config.serverEndpoint.trim().isNotEmpty
        ? config.serverEndpoint.trim()
        : HalaaConfig.defaults().serverEndpoint;
    final baseUrl = rawBase.endsWith('/')
        ? rawBase.substring(0, rawBase.length - 1)
        : rawBase;

    final payload = <String, dynamic>{
      'id': user.id,
      'email': user.email,
      'phone': user.phone,
      'username': meta['username'] ??
          meta['preferred_username'] ??
          user.email?.split('@').first ??
          user.id.substring(0, user.id.length > 8 ? 8 : user.id.length),
      'display_name': meta['full_name'] ??
          meta['name'] ??
          meta['nickname'] ??
          displayName,
      'user_metadata': meta,
      'identities': identities
          .map((i) => {
                'id': i.id,
                'provider': i.provider,
                'identity_data': i.identityData,
              })
          .toList(),
      if (googleId != null && googleId.isNotEmpty) 'google_id': googleId,
      if (gmailEmail != null && gmailEmail.isNotEmpty)
        'gmail_email': gmailEmail,
      if (facebookId != null && facebookId.isNotEmpty)
        'facebook_id': facebookId,
      'action': action,
      'last_login_at': DateTime.now().toUtc().toIso8601String(),
    };

    final response = await http.post(
      Uri.parse('$baseUrl/api/users'),
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('فشلت مزامنة البيانات مع الخادم (${response.statusCode})');
    }
    if (response.body.trim().isEmpty) return <String, dynamic>{};
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }
}
