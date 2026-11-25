import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/halaa_models.dart';
import '../../widgets/halaa_popups.dart';
import '../../widgets/welcome_gallery_bg.dart';

/// Exact pixel-faithful Flutter port of `admin/index.html` login screen:
/// - Rotating `welcome-gallery` background + dark radial scrim
/// - Exact 3D logo `assets/images/halaa-clear.webp` + `إدارة هلاا`
/// - Glassmorphic login card (`rgba(10,30,38,.52)`, radius 28)
/// - Empty username & password pill inputs + `إظهار`/`إخفاء` toggle
/// - Teal gradient pill button `دخول الإدارة`
/// - Red error text `#FCA5A5`
/// - 3 circular frosted options inside card: `نسيان الكلمة`, `شروط التطبيق`, `الدعم الفني`
class AdminLoginScreen extends StatefulWidget {
  final HalaaConfig config;
  final ValueChanged<String> onAuthenticated;
  final ValueChanged<SupportTicket> onTicketCreated;
  final VoidCallback onBackToApp;

  const AdminLoginScreen({
    super.key,
    required this.config,
    required this.onAuthenticated,
    required this.onTicketCreated,
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

  Widget _cardCircleOption({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.fromRGBO(255, 255, 255, 0.85),
                  Color.fromRGBO(213, 243, 247, 0.65),
                ],
              ),
              border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.7)),
            ),
            child: Icon(icon, color: const Color(0xFF143A42), size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              shadows: [Shadow(color: Color(0x73000000), blurRadius: 3)],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: WelcomeGalleryBackground(
        images: widget.config.bgImages,
        rotationSeconds: widget.config.rotationSeconds,
        darkAdminScrim: true,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Exact 3D logo + إدارة هلاا
                  Image.asset(
                    'assets/images/halaa-clear.webp',
                    height: 138,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'إدارة هلاا',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFF3FBFC),
                      shadows: [
                        Shadow(
                          color: Color.fromRGBO(0, 0, 0, 0.55),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Glassmorphic Login Card
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 346),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(10, 30, 38, 0.52),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color.fromRGBO(255, 255, 255, 0.30),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              const Text(
                                'اسم المستخدم',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD6F4F7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _userCtrl,
                                textInputAction: TextInputAction.next,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromRGBO(255, 255, 255, 0.14),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(
                                      color: Color.fromRGBO(255, 255, 255, 0.30),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide:
                                        const BorderSide(color: Color(0xFF5EEAD4)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 13),
                              const Text(
                                'كلمة المرور',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFD6F4F7),
                                ),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                onSubmitted: (_) => _submit(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      const Color.fromRGBO(255, 255, 255, 0.14),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 11,
                                  ),
                                  suffixIcon: TextButton(
                                    onPressed: () =>
                                        setState(() => _obscure = !_obscure),
                                    child: Text(
                                      _obscure ? 'إظهار' : 'إخفاء',
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: Color(0xFFBFEEF3),
                                      ),
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide: const BorderSide(
                                      color: Color.fromRGBO(255, 255, 255, 0.30),
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(999),
                                    borderSide:
                                        const BorderSide(color: Color(0xFF5EEAD4)),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              // Teal pill button `دخول الإدارة`
                              InkWell(
                                onTap: _submit,
                                borderRadius: BorderRadius.circular(999),
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF14B8A6),
                                        Color(0xFF0F7682),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    'دخول الإدارة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ),
                              if (_error != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFFDC2626),
                                    backgroundColor:
                                        Color.fromRGBO(255, 255, 255, 0.85),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 14),
                              const Divider(
                                color: Color.fromRGBO(255, 255, 255, 0.22),
                              ),
                              const SizedBox(height: 10),
                              // Exact 3 circular options inside login card
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _cardCircleOption(
                                    label: 'نسيان الكلمة',
                                    icon: Icons.vpn_key_outlined,
                                    onTap: () => showResetPasswordPopup(
                                      context,
                                      darkMode: true,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  _cardCircleOption(
                                    label: 'شروط التطبيق',
                                    icon: Icons.description_outlined,
                                    onTap: () => showServiceTermsPopup(
                                      context,
                                      darkMode: true,
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  _cardCircleOption(
                                    label: 'الدعم الفني',
                                    icon: Icons.support_agent_rounded,
                                    onTap: () => showSupportPopup(
                                      context: context,
                                      existingTickets: widget.config.tickets,
                                      onTicketCreated: widget.onTicketCreated,
                                      darkMode: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: widget.onBackToApp,
                    child: const Text(
                      'العودة إلى واجهة التطبيق',
                      style: TextStyle(color: Color(0xFF99F6E4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
