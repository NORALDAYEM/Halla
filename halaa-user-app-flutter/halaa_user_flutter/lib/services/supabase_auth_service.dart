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
}
