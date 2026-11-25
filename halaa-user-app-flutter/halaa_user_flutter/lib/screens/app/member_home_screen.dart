import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/halaa_models.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/welcome_gallery_bg.dart';
import 'package:url_launcher/url_launcher.dart';

/// Post-login member screen (`halla-web/member.html`) unified with the exact
/// same `.welcome-gallery` rotating background and 4 real-photo game cards.
class MemberHomeScreen extends StatefulWidget {
  final String displayName;
  final HalaaConfig config;
  final VoidCallback onLogout;

  const MemberHomeScreen({
    super.key,
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
    const games = [
      (
        'الشطرنج',
        'assets/images/welcome-gallery/chessboard.webp',
        'لعب مباشر ودردشة صوتية'
      ),
      (
        'الليدو',
        'assets/images/welcome-gallery/ludo-friends.webp',
        'تحديات جماعية وبطولات'
      ),
      (
        'البلياردو',
        'assets/images/welcome-gallery/pool-table.webp',
        '8-Ball وفيزياء واقعية'
      ),
      (
        'الضومينو',
        'assets/images/welcome-gallery/game-table.webp',
        'جولات سريعة مع الأصدقاء'
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: games.length,
      itemBuilder: (ctx, i) {
        final g = games[i];
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('جاري تشغيل لعبة ${g.$1}...')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(10, 30, 38, 0.62),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color.fromRGBO(255, 255, 255, 0.28),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Image.asset(g.$2, fit: BoxFit.cover),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            g.$1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            g.$3,
                            style: const TextStyle(
                              color: Color(0xFF99F6E4),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  Future<void> _openZegoRoom(String roomId, String roomTitle, bool asHost) async {
    final endpoint = widget.config.serverEndpoint.trim().isNotEmpty ? widget.config.serverEndpoint.trim() : 'https://halla.onrender.com';
    final uri = Uri.https('noraldayem.github.io', '/Halla/zego-room.html', {'appID': '400719759', 'roomID': roomId, 'userID': 'user_${DateTime.now().millisecondsSinceEpoch % 100000}', 'userName': widget.displayName, 'role': asHost ? 'Host' : 'Audience', 'title': roomTitle, 'serverEndpoint': endpoint});
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
  
  Widget _roomsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 30, 38, 0.72),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.26)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نشاطات الغرف الصوتية (${widget.config.micSeats} مقاعد مايك)',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(widget.config.micSeats, (i) {
                  return InkWell(borderRadius: BorderRadius.circular(14), onTap: () => _openZegoRoom('halaa_main_room', 'الغرفة الرئيسية — هلا', true), child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Color(0xFF0F7682),
                        child: Icon(Icons.mic_none_rounded, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مايك ${i + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  )),;
                }),
              ),
            ],
          ),
        ),
      const SizedBox(height: 14), ...[{'id': 'halaa_main_room', 'title': 'الغرفة الرئيسية — هلا'}, {'id': 'halaa_games_voice', 'title': 'غرفة الألعاب والتحديات'}, {'id': 'halaa_vip_1', 'title': 'ديوانية السهر VIP'}, {'id': 'halaa_music', 'title': 'غرفة الموسيقى والطرب'}].map((room) => Container(margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color.fromRGBO(10, 30, 38, 0.72), borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.22))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(room['title']!, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(height: 10), Row(children: [Expanded(child: ElevatedButton.icon(onPressed: () => _openZegoRoom(room['id']!, room['title']!, true), icon: const Icon(Icons.mic_rounded, size: 18), label: const Text('صعود للمايك'))), const SizedBox(width: 8), Expanded(child: OutlinedButton.icon(onPressed: () => _openZegoRoom(room['id']!, room['title']!, false), icon: const Icon(Icons.headphones_rounded, size: 18), label: const Text('استماع')))])]))), ],
      
    );
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
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color.fromRGBO(10, 30, 38, 0.74),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            children: [
              Image.asset('assets/images/halaa-clear.webp', height: 84),
              const SizedBox(height: 10),
              Text(
                widget.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'العملات الذهبية: 0 • الكريستال: 0',
                style: TextStyle(color: Color(0xFF99F6E4)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
