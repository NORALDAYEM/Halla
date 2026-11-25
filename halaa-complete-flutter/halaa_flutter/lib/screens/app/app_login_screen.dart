import 'package:flutter/material.dart';
import '../../models/halaa_config.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/glass_box.dart';
import '../../widgets/halaa_background.dart';

/// Matches the approved Halaa glassmorphic login screen:
/// - Rotating welcome-gallery real-photo background
/// - Translucent teal-blue "Halaa" & "ألعاب ودردشة" header
/// - Solid yellow "وضع الضيف" button
/// - Translucent sky-blue "جوجل" button with opaque turquoise "آخر تسجيل دخول" badge
/// - Frosted glass "Facebook" button
/// - Three frosted dark-sky-blue circular bottom icons (Support, Mail, Terms/Phone)
class AppLoginScreen extends StatefulWidget {
  final HalaaConfig config;
  final ValueChanged<String> onLoggedIn;
  final VoidCallback onOpenAdminPortal;

  const AppLoginScreen({
    super.key,
    required this.config,
    required this.onLoggedIn,
    required this.onOpenAdminPortal,
  });

  @override
  State<AppLoginScreen> createState() => _AppLoginScreenState();
}

class _AppLoginScreenState extends State<AppLoginScreen> {
  void _showEmailDialog() {
    final userCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String? errorMsg;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF071B2B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color.fromRGBO(56, 189, 248, 0.35)),
          ),
          title: const Text(
            'الدخول بالبريد الإلكتروني',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: userCtrl,
                decoration: const InputDecoration(
                  labelText: 'البريد الإلكتروني أو اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'كلمة المرور',
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(
                  errorMsg!,
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () {
                final u = userCtrl.text.trim();
                final p = passCtrl.text.trim();
                if (u.isEmpty) {
                  setDialogState(() => errorMsg = 'اسم المستخدم غير صحيح');
                  return;
                }
                if (p.length < 4) {
                  setDialogState(() => errorMsg = 'كلمة المرور غير صحيحة');
                  return;
                }
                Navigator.pop(ctx);
                widget.onLoggedIn(u);
              },
              child: const Text('دخول'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomCircleIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(12, 74, 110, 0.58),
                Color.fromRGBO(7, 89, 133, 0.46),
              ],
            ),
            border: Border.all(
              color: const Color.fromRGBO(125, 211, 252, 0.35),
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        tooltip: 'بوابة الإدارة',
                        onPressed: widget.onOpenAdminPortal,
                        icon: const Icon(
                          Icons.admin_panel_settings_outlined,
                          color: Color.fromRGBO(186, 230, 253, 0.78),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Logo + Translucent teal-blue title
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [theme.primary, const Color(0xFFF59E0B)],
                        ),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.55),
                          width: 2.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.mic_rounded,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Halaa',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        color: const Color.fromRGBO(56, 189, 248, 0.88),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'ألعاب ودردشة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color.fromRGBO(125, 211, 252, 0.85),
                      ),
                    ),
                    const Spacer(),
                    // Solid Yellow Guest Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: () => widget.onLoggedIn('ضيف هلاا'),
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text(
                          'وضع الضيف',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFACC15),
                          foregroundColor: const Color(0xFF0F172A),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Translucent Sky-Blue Google Button + Opaque Turquoise Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () => widget.onLoggedIn('حساب Google'),
                            icon: const Icon(Icons.g_mobiledata_rounded, size: 30),
                            label: const Text(
                              'جوجل',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromRGBO(14, 165, 233, 0.45),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              side: const BorderSide(
                                color: Color.fromRGBO(125, 211, 252, 0.55),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: -10,
                          left: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: const Text(
                              'آخر تسجيل دخول',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Frosted Glass Facebook Button
                    GlassBox(
                      padding: EdgeInsets.zero,
                      borderRadius: 18,
                      fillColor: const Color.fromRGBO(255, 255, 255, 0.14),
                      borderColor: const Color.fromRGBO(255, 255, 255, 0.30),
                      child: SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: TextButton.icon(
                          onPressed: () => widget.onLoggedIn('حساب Facebook'),
                          icon: const Icon(
                            Icons.facebook_rounded,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Facebook',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Three Frosted Dark-Sky-Blue Circular Bottom Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _bottomCircleIcon(
                          icon: Icons.support_agent_rounded,
                          tooltip: 'الدعم الفني',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('فريق الدعم الفني متاح على مدار الساعة.'),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 20),
                        _bottomCircleIcon(
                          icon: Icons.mail_outline_rounded,
                          tooltip: 'الدخول بالبريد',
                          onTap: _showEmailDialog,
                        ),
                        const SizedBox(width: 20),
                        _bottomCircleIcon(
                          icon: Icons.phone_in_talk_outlined,
                          tooltip: 'الهاتف وشروط الخدمة',
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('بتسجيل دخولك فإنك توافق على شروط خدمة هلاا.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
