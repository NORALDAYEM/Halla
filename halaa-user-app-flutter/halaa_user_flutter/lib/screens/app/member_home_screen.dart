import 'dart:ui';
import '../../services/supabase_auth_service.dart';
import 'package:flutter/material.dart';
import '../../models/halaa_models.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/welcome_gallery_bg.dart';
import '../../widgets/halaa_rooms_showcase_tab.dart';
import '../../widgets/halaa_games_showcase_tab.dart';
import '../../widgets/halaa_profile_page.dart';

/// Post-login member screen (`halla-web/member.html`) unified with the exact
/// same `.welcome-gallery` rotating background and 4 real-photo game cards.
class MemberHomeScreen extends StatefulWidget {
  final SupabaseAuthService authService;
  final bool voiceRoomsEnabled;
  final String displayName;
  final HalaaConfig config;
  final VoidCallback onLogout;

  const MemberHomeScreen({
    super.key,
    required this.authService,
    this.voiceRoomsEnabled = true,
    required this.displayName,
    required this.config,
    required this.onLogout,
  });

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _navIndex = 1; // الألعاب default

  @override
  Widget build(BuildContext context) {
    final theme = findThemePreset(widget.config.activeTheme);

    return Scaffold(
      body: WelcomeGalleryBackground(
        images: widget.config.bgImages,
        rotationSeconds: widget.config.rotationSeconds,
        child: SafeArea(
          child: Column(
            children: [
              // Top bar matching member.html header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(10, 30, 38, 0.62),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color.fromRGBO(255, 255, 255, 0.28),
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/halaa-clear.webp',
                            width: 34,
                            height: 34,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.displayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                  ),
                                ),
                                const Text(
                                  'هلاا | الألعاب والغرف',
                                  style: TextStyle(
                                    color: Color(0xFF99F6E4),
                                    fontSize: 11.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'الجوائز',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🏆 قائمة الجوائز والمهام اليومية'),
                                ),
                              );
                            },
                            icon: const Text('🏆', style: TextStyle(fontSize: 18)),
                          ),
                          IconButton(
                            tooltip: 'الهدايا',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🎁 متجر الهدايا والعملات'),
                                ),
                              );
                            },
                            icon: const Text('🎁', style: TextStyle(fontSize: 18)),
                          ),
                          IconButton(
                            tooltip: 'خروج',
                            onPressed: widget.onLogout,
                            icon: const Icon(
                              Icons.logout_rounded,
                              color: Color(0xFFFCA5A5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: IndexedStack(
                  index: _navIndex,
                  children: [
                    _roomsTab(),
                    _gamesTab(theme),
                    _momentsTab(),
                    _chatTab(),
                    _profileTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromRGBO(7, 27, 33, 0.94),
        indicatorColor: const Color.fromRGBO(20, 184, 166, 0.30),
        selectedIndex: _navIndex,
        onDestinationSelected: (i) => setState(() => _navIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.graphic_eq_rounded),
            label: 'الغرف',
          ),
          NavigationDestination(
            icon: Icon(Icons.sports_esports_rounded),
            label: 'الألعاب',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_rounded),
            label: 'اللحظات',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            label: 'الدردشة',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'حسابي',
          ),
        ],
      ),
    );
  }

  Widget _gamesTab(HalaaThemePreset theme) {
      return const HalaaGamesShowcaseTab();
  }
  
  Widget _roomsTab() {
      if (!widget.voiceRoomsEnabled) return const Center(child: Text('الغرف متوقفة مؤقتاً للصيانة'));
      return HalaaRoomsShowcaseTab(serverEndpoint: widget.config.serverEndpoint, accessToken: widget.authService.accessToken);
  }

  Widget _momentsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 30, 38, 0.72),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const ListTile(
            leading: CircleAvatar(child: Icon(Icons.auto_awesome)),
            title: Text('اللحظات والقصص', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'شارك صورك ولحظاتك مع أصدقائك في هلاا.',
              style: TextStyle(color: Color(0xFF99F6E4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _chatTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 30, 38, 0.72),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const ListTile(
            leading: CircleAvatar(child: Icon(Icons.chat_bubble_outline)),
            title: Text('فريق هلاا', style: TextStyle(color: Colors.white)),
            subtitle: Text(
              'مرحباً بك في تطبيق هلاا بلغة Flutter!',
              style: TextStyle(color: Color(0xFF99F6E4)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileTab(HalaaThemePreset theme) {
    return HalaaProfilePage(
      displayName: widget.displayName,
      onLogout: widget.onLogout,
    );
  }
}
