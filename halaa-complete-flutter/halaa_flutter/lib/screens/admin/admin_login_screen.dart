import 'package:flutter/material.dart';
import '../../models/halaa_config.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/glass_box.dart';
import '../../widgets/halaa_background.dart';

/// Single-screen no-scroll Admin login matching approved Halaa Admin specs:
/// - Empty fields (no placeholder text)
/// - Working show/hide password toggle
/// - Red (#DC2626) distinct error messages
/// - Login: ADMIN / 12345678
class AdminLoginScreen extends StatefulWidget {
  final HalaaConfig config;
  final ValueChanged<String> onAuthenticated;
  final VoidCallback onBackToApp;

  const AdminLoginScreen({
    super.key,
    required this.config,
    required this.onAuthenticated,
    required this.onBackToApp,
  });

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  String? _error;

  static const _validUser = 'ADMIN';
  static const _validPass = '12345678';

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final user = _userCtrl.text.trim();
    final pass = _passCtrl.text.trim();

    if (user.isEmpty || user.toUpperCase() != _validUser) {
      setState(() => _error = 'اسم المستخدم غير صحيح');
      return;
    }
    if (pass != _validPass) {
      setState(() => _error = 'كلمة المرور غير صحيحة');
      return;
    }
    setState(() => _error = null);
    widget.onAuthenticated(_validUser);
  }

  @override
  Widget build(BuildContext context) {
    final theme = findThemePreset(widget.config.activeTheme);

    return Scaffold(
      body: HalaaBackground(
        images: widget.config.bgImages,
        rotationSeconds: widget.config.rotationSeconds,
        theme: theme,
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: GlassBox(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  borderRadius: 26,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [theme.primary, theme.accent],
                          ),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.5),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'إدارة هلاا | Halaa Admin',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: theme.accent,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _userCtrl,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'اسم المستخدم',
                          prefixIcon: const Icon(
                            Icons.person_outline_rounded,
                            color: Color(0xFF7DD3FC),
                          ),
                          filled: true,
                          fillColor: const Color.fromRGBO(7, 26, 43, 0.58),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _passCtrl,
                        obscureText: _obscure,
                        onSubmitted: (_) => _submit(),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'كلمة المرور',
                          prefixIcon: const Icon(
                            Icons.lock_outline_rounded,
                            color: Color(0xFF7DD3FC),
                          ),
                          suffixIcon: IconButton(
                            tooltip: _obscure ? 'إظهار' : 'إخفاء',
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFF7DD3FC),
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          filled: true,
                          fillColor: const Color.fromRGBO(7, 26, 43, 0.58),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(220, 38, 38, 0.24),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFDC2626)),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFFCA5A5),
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'دخول الإدارة',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: widget.onBackToApp,
                        child: const Text(
                          'العودة إلى تطبيق هلاا',
                          style: TextStyle(color: Color(0xFFBAE6FD)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
