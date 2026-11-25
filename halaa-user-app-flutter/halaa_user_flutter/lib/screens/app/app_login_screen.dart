import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/halaa_models.dart';
import '../../services/supabase_auth_service.dart';
import '../../widgets/halaa_brand_icons.dart';
import '../../widgets/halaa_popups.dart';
import '../../widgets/welcome_gallery_bg.dart';
import '../../widgets/halaa_animated_logo.dart';

/// Standalone Halaa User App Login Screen — Exact previous design, colors,
/// raised 3D glass transparency, Gmail & Facebook brand icons, and Phone/OAuth
/// "coming soon" dialogs. Responsive across Phone, Tablet, and Desktop.
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

  void _showProviderComingSoon(BuildContext context, String providerLabel) {
    showHalaaGlassDialog<void>(
      context: context,
      title: 'الدخول عبر $providerLabel',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(255, 255, 255, 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF9ACFD0)),
            ),
            child: Text(
              'تسجيل الدخول عبر $providerLabel غير مفعّل حالياً — قريباً.\nيمكنك الدخول الآن عبر البريد الإلكتروني أو وضع الضيف.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.65,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F7682),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('حسناً'),
          ),
        ],
      ),
    );
  }

  Future<void> _startSocialOAuth(
    BuildContext context,
    String provider,
    String providerLabel,
  ) async {
    final err = await authService.startOAuth(provider);
    if (!context.mounted) return;
    if (err != null && err.isNotEmpty) {
      showHalaaGlassDialog(
        context: context,
        title: providerLabel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              err,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D4FF),
                  foregroundColor: const Color(0xFF091B2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('حسناً'),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _showPhoneComingSoonDialog(BuildContext context) {
    final phoneCtrl = TextEditingController();
    showHalaaGlassDialog<void>(
      context: context,
      title: 'التسجيل برقم الهاتف',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(245, 189, 32, 0.22),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFAD831C)),
            ),
            child: const Text(
              'التسجيل برقم الهاتف غير مفعّل حالياً — قريباً',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFFDE68A),
                fontWeight: FontWeight.w800,
                fontSize: 13.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phoneCtrl,
            enabled: false,
            textDirection: TextDirection.ltr,
            decoration: InputDecoration(
              labelText: 'رقم الهاتف (+966 5X XXX XXXX)',
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F7682),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _pillButton({
    required String label,
    required List<Color> gradientColors,
    required Color textColor,
    required Widget icon,
    required VoidCallback onTap,
    required double height,
    Color borderColor = const Color(0x98FFFFFF),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color(0x36143D47),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
            BoxShadow(
              color: Color(0x28000000),
              blurRadius: 3,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                height: height,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerRight,
                    end: Alignment.centerLeft,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Subtle top 3D glass shine
                    Positioned(
                      top: 0,
                      left: 18,
                      right: 18,
                      child: Container(
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: const Color.fromRGBO(255, 255, 255, 0.48),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
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
      ),
    );
  }

  Widget _bottomOption({
    required String label,
    required Widget icon,
    required double circleSize,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: circleSize,
            height: circleSize,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color.fromRGBO(7, 45, 72, 0.42),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
                BoxShadow(
                  color: Color.fromRGBO(6, 36, 58, 0.55),
                  blurRadius: 2,
                  offset: Offset(0, 2.5),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.fromRGBO(12, 74, 110, 0.62),
                        Color.fromRGBO(7, 89, 133, 0.48),
                      ],
                    ),
                    border: Border.all(
                      color: const Color.fromRGBO(186, 230, 253, 0.58),
                      width: 1.3,
                    ),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Inner top rim gloss for 3D raised look
                      Positioned(
                        top: 2,
                        left: 10,
                        right: 10,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            gradient: const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color.fromRGBO(224, 242, 254, 0.46),
                                Color.fromRGBO(224, 242, 254, 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),
                      icon,
                    ],
                  ),
                ),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final isTablet = w >= 600 && w < 1024;
              final isDesktop = w >= 1024;
              final shellMaxW = isDesktop ? 480.0 : (isTablet ? 440.0 : 540.0);
              final btnMaxW = isDesktop ? 380.0 : (isTablet ? 370.0 : 350.0);
              final logoHeight = (h * 0.27).clamp(155.0, 245.0);
              final btnHeight = h < 700 ? 46.0 : 51.0;
              final circleSize = h < 700 ? 50.0 : 54.0;

              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: shellMaxW),
                  child: Stack(
                    children: [
                      Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 12,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 22),
                             HalaaAnimatedLogo(height: logoHeight),
                              const SizedBox(height: 14),
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: btnMaxW),
                                child: Column(
                                  children: [
                                    // 1. تسجيل الدخول (Green translucent pill)
                                    _pillButton(
                                      label: 'تسجيل الدخول',
                                      height: btnHeight,
                                      gradientColors: const [
                                        Color.fromRGBO(18, 104, 60, 0.62),
                                        Color.fromRGBO(22, 132, 78, 0.54),
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
                                      height: btnHeight,
                                      gradientColors: const [
                                        Color.fromRGBO(161, 64, 9, 0.62),
                                        Color.fromRGBO(187, 83, 11, 0.54),
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
                                    // 3. جيميل (Frosted white-sky pill + exact 5-color Gmail M logo)
                                    _pillButton(
                                      label: 'جيميل',
                                      height: btnHeight,
                                      gradientColors: const [
                                        Color(0xB8FFFFFF),
                                        Color(0x90E4F7FF),
                                      ],
                                      textColor: const Color(0xFF111111),
                                      icon: const GmailLogoIcon(size: 28),
                                      onTap: () => _startSocialOAuth(
                                      context,
                                      'google',
                                      'Google (Gmail)',
                                    ),
                                    ),
                                    // 4. Facebook (Frosted aqua-sky pill + exact #0866FF Facebook logo)
                                    _pillButton(
                                      label: 'Facebook',
                                      height: btnHeight,
                                      gradientColors: const [
                                        Color(0xBAEDFFFA),
                                        Color(0xA6B9E9F3),
                                      ],
                                      textColor: const Color(0xFF111111),
                                      icon: const FacebookLogoIcon(size: 32),
                                      onTap: () => _startSocialOAuth(
                                        context,
                                        'facebook',
                                        'Facebook',
                                      ),
                                    ),
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
                                            Shadow(
                                              color: Colors.white,
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 6),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
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
                                    // Exact 3 raised dark-sky-blue glass circular buttons
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        _bottomOption(
                                          label: 'الهاتف',
                                          icon: const PhoneOptionIcon(size: 30),
                                          circleSize: circleSize,
                                          onTap: () =>
                                              _showPhoneComingSoonDialog(context),
                                        ),
                                        const SizedBox(width: 28),
                                        _bottomOption(
                                          label: 'شروط الخدمة',
                                          icon: const TermsOptionIcon(size: 30),
                                          circleSize: circleSize,
                                          onTap: () =>
                                              showServiceTermsPopup(context),
                                        ),
                                        const SizedBox(width: 28),
                                        _bottomOption(
                                          label: 'المساعدة',
                                          icon: const HelpOptionIcon(size: 30),
                                          circleSize: circleSize,
                                          onTap: () => showSupportPopup(
                                            context: context,
                                            existingTickets: config.tickets,
                                            onTicketCreated: onTicketCreated,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Exact raised golden-yellow `وضع الضيف` pill top-left
                      Positioned(
                        top: 10,
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
                                  Color(0xD8FFF48B),
                                  Color(0xD8FFD63B),
                                  Color(0xD8F5BD20),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFBD890E),
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0xFFB5800B),
                                  blurRadius: 0,
                                  offset: Offset(0, 3),
                                ),
                                BoxShadow(
                                  color: Color(0x40605016),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Text(
                              'وضع الضيف',
                              style: TextStyle(
                                color: Color(0xFF352907),
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
              );
            },
          ),
        ),
      ),
    );
  }
}
