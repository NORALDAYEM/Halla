import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/halaa_models.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/halaa_popups.dart';
import '../../widgets/welcome_gallery_bg.dart';

/// Exact pixel-faithful Flutter port of `halla-web/index.html` + `welcome-gallery.css`:
/// - Rotating `welcome-gallery` real-photo background
/// - Top-left golden-yellow `وضع الضيف` pill
/// - Exact 3D logo `assets/images/halaa-clear.webp`
/// - Exact 4 pill buttons: `تسجيل الدخول` (green), `تسجيل` (amber), `جيميل` (white-sky), `Facebook` (aqua-sky)
/// - `نسيت كلمة المرور؟` link opening `#reset-options` popup
/// - `─── أو ───` divider
/// - 3 frosted dark-sky-blue circular icons: `الهاتف`, `شروط الخدمة`, `المساعدة`
class AppLoginScreen extends StatelessWidget {
  final HalaaConfig config;
  final ValueChanged<String> onLoggedIn;
  final ValueChanged<AppUserRecord> onRegisteredUser;
  final ValueChanged<SupportTicket> onTicketCreated;
  final SupabaseAuthService authService;

  const AppLoginScreen({
    super.key,
    required this.config,
    required this.onLoggedIn,
    required this.onRegisteredUser,
    required this.onTicketCreated,
    required this.authService,
  });


  Future<void> _handleOAuth(BuildContext context, String provider) async {
    final label = provider == 'google' ? 'جيميل (Google)' : 'فيسبوك';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('جارٍ فتح تسجيل الدخول عبر $label...'),
        duration: const Duration(seconds: 2),
      ),
    );
    final err = await authService.startOAuth(provider);
    if (err != null && context.mounted) {
      showHalaaGlassDialog<void>(
        context: context,
        title: 'الدخول عبر $label',
        child: Text(
          err,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFFDC2626),
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      );
    }
  }

  Widget _pillButton({
    required String label,
    required List<Color> gradientColors,
    required Color textColor,
    required Widget icon,
    required VoidCallback onTap,
    Color borderColor = const Color(0x90FFFFFF),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(999),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 51,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerRight,
                  end: Alignment.centerLeft,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: borderColor),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x24257988),
                    blurRadius: 13,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(right: 16, child: icon),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: textColor,
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

  Widget _bottomOption({
    required String label,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
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
                    color: const Color.fromRGBO(125, 211, 252, 0.48),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromRGBO(7, 45, 72, 0.35),
                      blurRadius: 14,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF172F36),
              shadows: [
                Shadow(color: Colors.white, blurRadius: 4),
                Shadow(color: Colors.white, blurRadius: 8),
              ],
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
        images: config.bgImages,
        rotationSeconds: config.rotationSeconds,
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 28),
                        // Exact 3D Halaa Logo from assets/images/halaa-clear.webp
                        ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxHeight: 250,
                            maxWidth: 250,
                          ),
                          child: Image.asset(
                            'assets/images/halaa-clear.webp',
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 360),
                          child: Column(
                            children: [
                              // 1. تسجيل الدخول (Green translucent pill)
                              _pillButton(
                                label: 'تسجيل الدخول',
                                gradientColors: const [
                                  Color.fromRGBO(18, 104, 60, 0.65),
                                  Color.fromRGBO(22, 132, 78, 0.56),
                                ],
                                textColor: Colors.white,
                                icon: const Icon(
                                  Icons.login_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onTap: () => showEmailAccessPopup(
                                  context: context,
                                  isSignup: false,
                                  onSuccess: (u) => onLoggedIn(u.nickname),
                                ),
                              ),
                              // 2. تسجيل (Amber/orange translucent pill)
                              _pillButton(
                                label: 'تسجيل',
                                gradientColors: const [
                                  Color.fromRGBO(161, 64, 9, 0.65),
                                  Color.fromRGBO(187, 83, 11, 0.56),
                                ],
                                textColor: Colors.white,
                                icon: const Icon(
                                  Icons.person_add_alt_1_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                                onTap: () => showEmailAccessPopup(
                                  context: context,
                                  isSignup: true,
                                  onSuccess: (u) {
                                    onRegisteredUser(u);
                                    onLoggedIn(u.nickname);
                                  },
                                ),
                              ),
                              // 3. جيميل (Frosted white-sky pill)
                              _pillButton(
                                label: 'جيميل',
                                gradientColors: const [
                                  Color(0xA8FFFFFF),
                                  Color(0x80E4F7FF),
                                ],
                                textColor: const Color(0xFF111111),
                                icon: const Icon(
                                  Icons.mail_rounded,
                                  color: Color(0xFFEA4335),
                                  size: 26,
                                ),
                                onTap: () => _handleOAuth(context, 'google'),
                              ),
                              // 4. Facebook (Frosted aqua-sky pill)
                              _pillButton(
                                label: 'Facebook',
                                gradientColors: const [
                                  Color(0xADEDFFFA),
                                  Color(0x99B9E9F3),
                                ],
                                textColor: const Color(0xFF111111),
                                icon: const CircleAvatar(
                                  radius: 15,
                                  backgroundColor: Color(0xFF0866FF),
                                  child: Icon(
                                    Icons.facebook_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                                onTap: () => _handleOAuth(context, 'facebook'),
                              ),
                              // Forgot password link
                              TextButton(
                                onPressed: () =>
                                    showResetPasswordPopup(context),
                                child: const Text(
                                  'نسيت كلمة المرور؟',
                                  style: TextStyle(
                                    color: Color(0xFF174955),
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    shadows: [
                                      Shadow(color: Colors.white, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                              // Divider: أو
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 54,
                                      child: Divider(
                                        color: Color(0xFFDEEAEB),
                                        thickness: 1.2,
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      child: Text(
                                        'أو',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF172F36),
                                          shadows: [
                                            Shadow(
                                              color: Colors.white,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    SizedBox(
                                      width: 54,
                                      child: Divider(
                                        color: Color(0xFFDEEAEB),
                                        thickness: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              // 3 Frosted Dark-Sky-Blue Circular Bottom Icons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _bottomOption(
                                    label: 'الهاتف',
                                    icon: Icons.phone_android_rounded,
                                    iconColor: const Color(0xFF35B394),
                                    onTap: () => onLoggedIn('الدخول بالهاتف'),
                                  ),
                                  const SizedBox(width: 28),
                                  _bottomOption(
                                    label: 'شروط الخدمة',
                                    icon: Icons.error_outline_rounded,
                                    iconColor: const Color(0xFFEFBD45),
                                    onTap: () =>
                                        showServiceTermsPopup(context),
                                  ),
                                  const SizedBox(width: 28),
                                  _bottomOption(
                                    label: 'المساعدة',
                                    icon: Icons.support_agent_rounded,
                                    iconColor: const Color(0xFF38BDF8),
                                    onTap: () => showSupportPopup(
                                      context: context,
                                      existingTickets: config.tickets,
                                      onTicketCreated: onTicketCreated,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Top-left exact golden-yellow `وضع الضيف` pill
                  Positioned(
                    top: 12,
                    left: 14,
                    child: InkWell(
                      onTap: () => onLoggedIn('وضع الضيف'),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xC9FFF28A),
                              Color(0xC9FFCD37),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: const Color(0xFFAD831C)),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x40605016),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          'وضع الضيف',
                          style: TextStyle(
                            color: Color(0xFF30250A),
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
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
