import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

class AuthResult {
  final bool ok;
  final String? displayName;
  final String? email;
  final String? error;

  const AuthResult({
    required this.ok,
    this.displayName,
    this.email,
    this.error,
  });
}

/// Real Supabase Auth integration matching `halla-web/accounts.js`:
/// - Google OAuth (`provider=google&prompt=select_account`)
/// - Facebook OAuth (`provider=facebook`)
/// - Email Login / Signup / Password Recovery
class SupabaseAuthService {
  static const String endpoint = 'https://uwjrboviicypyhregpoo.supabase.co';
  static const String publicKey = 'sb_publishable_QbUKNVMYDRK63NjB26tCtw_jzOaEXdR';

  Map<String, String> get _headers => {
        'apikey': publicKey,
        'Content-Type': 'application/json',
      };

  /// Checks whether an external OAuth provider (`google` or `facebook`) is enabled
  /// in Supabase Auth settings (`/auth/v1/settings`).
  Future<bool> isProviderEnabled(String provider) async {
    try {
      final resp = await http
          .get(
            Uri.parse('$endpoint/auth/v1/settings'),
            headers: {'apikey': publicKey},
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode != 200) return false;
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      if (data is Map<String, dynamic>) {
        final ext = data['external'];
        if (ext is Map<String, dynamic>) {
          return ext[provider] == true;
        }
      }
    } catch (_) {}
    return false;
  }

  /// Launches real OAuth sign-in for `google` or `facebook` via Supabase Auth.
  Future<String?> startOAuth(String provider) async {
    final enabled = await isProviderEnabled(provider);
    if (!enabled) {
      final label = provider == 'google' ? 'Google (جيميل)' : 'فيسبوك';
      return 'تسجيل الدخول عبر $label غير مفعّل حالياً في إعدادات الحساب.';
    }

    final redirectTo = kIsWeb
        ? '${Uri.base.origin}${Uri.base.path}?account_return=$provider'
        : 'com.halla.voiceclubs://auth/$provider';

    final params = <String, String>{
      'provider': provider,
      'redirect_to': redirectTo,
    };
    if (provider == 'google') {
      params['prompt'] = 'select_account';
    }

    final authUri = Uri.parse('$endpoint/auth/v1/authorize')
        .replace(queryParameters: params);

    final launched = await launchUrl(
      authUri,
      mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
      webOnlyWindowName: '_self',
    );
    if (!launched) {
      final label = provider == 'google' ? 'Google' : 'فيسبوك';
      return 'تعذر فتح صفحة تسجيل الدخول عبر $label. تحقق من اتصالك ثم أعد المحاولة.';
    }
    return null;
  }

  /// Parses OAuth return URL on Web (`#access_token=...`) and loads user profile.
  Future<AuthResult?> checkOAuthReturn() async {
    if (!kIsWeb) return null;
    final uri = Uri.base;
    final fragment = uri.fragment;
    if (fragment.isEmpty) return null;

    final fragParams = Uri.splitQueryString(fragment);
    final accessToken = fragParams['access_token'];
    if (accessToken == null || accessToken.isEmpty) return null;

    try {
      final resp = await http
          .get(
            Uri.parse('$endpoint/auth/v1/user'),
            headers: {
              'apikey': publicKey,
              'Authorization': 'Bearer $accessToken',
            },
          )
          .timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final data = jsonDecode(utf8.decode(resp.bodyBytes));
        if (data is Map<String, dynamic>) {
          final email = (data['email'] ?? '').toString();
          final meta = data['user_metadata'];
          String name = '';
          if (meta is Map<String, dynamic>) {
            name = (meta['full_name'] ??
                    meta['name'] ??
                    meta['nickname'] ??
                    '')
                .toString();
          }
          if (name.isEmpty) {
            name = email.isNotEmpty ? email.split('@').first : 'مستخدم هلاا';
          }
          return AuthResult(ok: true, displayName: name, email: email);
        }
      }
    } catch (_) {}
    return null;
  }

  /// Real Email + Password sign-in via Supabase Auth.
  Future<AuthResult> signInWithEmail(String email, String password) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$endpoint/auth/v1/token?grant_type=password'),
            headers: _headers,
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      if (resp.statusCode == 200 && data is Map<String, dynamic>) {
        final user = data['user'];
        String name = email.split('@').first;
        if (user is Map<String, dynamic>) {
          final meta = user['user_metadata'];
          if (meta is Map<String, dynamic> &&
              (meta['nickname'] ?? '').toString().isNotEmpty) {
            name = meta['nickname'].toString();
          }
        }
        return AuthResult(ok: true, displayName: name, email: email);
      }
      return const AuthResult(
        ok: false,
        error: 'اسم المستخدم أو كلمة المرور غير صحيحة',
      );
    } catch (_) {
      return const AuthResult(
        ok: false,
        error: 'تعذّر الاتصال بخادم الحسابات. تحقق من الإنترنت وأعد المحاولة.',
      );
    }
  }

  /// Real Email Signup via Supabase Auth.
  Future<AuthResult> signUpWithEmail({
    required String nickname,
    required String email,
    required String password,
    required String gender,
    required String country,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$endpoint/auth/v1/signup'),
            headers: _headers,
            body: jsonEncode({
              'email': email,
              'password': password,
              'data': {
                'nickname': nickname,
                'gender': gender,
                'country': country,
              },
            }),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return AuthResult(ok: true, displayName: nickname, email: email);
      }
      final data = jsonDecode(utf8.decode(resp.bodyBytes));
      final msg = (data is Map<String, dynamic>)
          ? (data['msg'] ?? data['error_description'] ?? '').toString()
          : '';
      return AuthResult(
        ok: false,
        error: msg.isNotEmpty ? msg : 'تعذر إنشاء الحساب، تأكد من البيانات.',
      );
    } catch (_) {
      return const AuthResult(
        ok: false,
        error: 'تعذّر الاتصال بخادم الحسابات. تحقق من الإنترنت وأعد المحاولة.',
      );
    }
  }

  /// Real Password Recovery email via Supabase Auth.
  Future<String?> resetPassword(String email) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$endpoint/auth/v1/recover'),
            headers: _headers,
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return null;
      }
      return 'تعذر إرسال رابط الاستعادة، تأكد من صحة البريد الإلكتروني.';
    } catch (_) {
      return 'تعذّر الاتصال بالخادم حالياً.';
    }
  }
}
