import 'package:flutter/material.dart';
import '../../models/halaa_config.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/glass_box.dart';
import '../../widgets/halaa_background.dart';

/// Post-login member app unified with the exact same rotating glassmorphic
/// background, real-photo game cards (Chess, Ludo, Pool, Domino), and 5 tabs.
class MemberHomeScreen extends StatefulWidget {
  final String displayName;
  final HalaaConfig config;
  final VoidCallback onLogout;
  final VoidCallback onOpenAdminPortal;

  const MemberHomeScreen({
    super.key,
    required this.displayName,
    required this.config,
    required this.onLogout,
    required this.onOpenAdminPortal,
  });

  @override
  State<MemberHomeScreen> createState() => _MemberHomeScreenState();
}

class _MemberHomeScreenState extends State<MemberHomeScreen> {
  int _tabIndex = 1; // Games tab default to showcase real-photo game cards
  String _roomCategory = 'شائع';

  @override
  Widget build(BuildContext context) {
    final theme = findThemePreset(widget.config.activeTheme);
    final imgPrefix = widget.config.bgImages.isNotEmpty &&
            widget.config.bgImages.first.url.startsWith('../halla-web/')
        ? '../halla-web/assets/welcome-gallery/'
        : 'assets/welcome-gallery/';

    return Scaffold(
      body: HalaaBackground(
        images: widget.config.bgImages,
        rotationSeconds: widget.config.rotationSeconds,
        theme: theme,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primary,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.displayName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'هلاا | ألعاب ودردشة صوتية',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFBAE6FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'لوحة الإدارة',
                      onPressed: widget.onOpenAdminPortal,
                      icon: const Icon(
                        Icons.admin_panel_settings_outlined,
                        color: Color(0xFF7DD3FC),
                      ),
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
              Expanded(
                child: IndexedStack(
                  index: _tabIndex,
                  children: [
                    _buildRoomsTab(theme),
                    _buildGamesTab(imgPrefix, theme),
                    _buildMomentsTab(),
                    _buildChatTab(),
                    _buildProfileTab(theme),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color.fromRGBO(6, 26, 41, 0.94),
        indicatorColor: const Color.fromRGBO(6, 182, 212, 0.28),
        selectedIndex: _tabIndex,
        onDestinationSelected: (i) => setState(() => _tabIndex = i),
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
            label: 'أنا',
          ),
        ],
      ),
    );
  }

  Widget _buildGamesTab(String prefix, HalaaThemePreset theme) {
    final games = [
      (
        title: 'الشطرنج الملكي',
        subtitle: 'لعب مباشر ومشاهدة ومحادثة صوتية',
        image: '${prefix}chessboard.webp',
      ),
      (
        title: 'الليدو الجماعي',
        subtitle: 'تحديات أصدقاء وبطولات فورية',
        image: '${prefix}ludo-friends.webp',
      ),
      (
        title: 'البلياردو 8-Ball',
        subtitle: 'فيزياء دقيقة وعصي متدرجة',
        image: '${prefix}pool-table.webp',
      ),
      (
        title: 'الضومينو الكلاسيكي',
        subtitle: 'جولات سريعة مع غرف صوتية',
        image: '${prefix}game-table.webp',
      ),
    ];

    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 0.86,
      ),
      itemCount: games.length,
      itemBuilder: (context, index) {
        final g = games[index];
        return InkWell(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('جاري فتح طاولة ${g.title}...')),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: GlassBox(
            padding: EdgeInsets.zero,
            borderRadius: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Image.network(
                    g.image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: theme.bgTop,
                      child: Icon(
                        Icons.sports_esports_rounded,
                        size: 42,
                        color: theme.accent,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        g.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFBAE6FD),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRoomsTab(HalaaThemePreset theme) {
    const categories = [
      'شائع',
      'جديد',
      'المفضلة',
      'غرف الدول',
      'شعر',
      'غناء',
      'قرآن',
      'ألعاب',
    ];
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final c = categories[i];
              return ChoiceChip(
                label: Text(c),
                selected: _roomCategory == c,
                onSelected: (_) => setState(() => _roomCategory = c),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'غرفة صوتية تفاعلية (${widget.config.micSeats} مقاعد)',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(widget.config.micSeats, (i) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color.fromRGBO(14, 165, 233, 0.35),
                        child: const Icon(Icons.mic_none_rounded, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'مايك ${i + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMomentsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: const [
        GlassBox(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.auto_awesome)),
            title: Text('اللحظات والقصص (24 ساعة)'),
            subtitle: Text('شارك صورك وفيديوهاتك القصيرة وتفاعل مع الأصدقاء.'),
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: const [
        GlassBox(
          child: ListTile(
            leading: CircleAvatar(child: Icon(Icons.smart_toy_outlined)),
            title: Text('فريق هلاا'),
            subtitle: Text('أهلاً بك في تطبيق هلاا بنسخة Flutter الموحدة!'),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileTab(HalaaThemePreset theme) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Column(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: theme.primary,
                child: const Icon(Icons.person, size: 38, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                widget.displayName,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'المستوى 1 • العملات الذهبية: 0 • الكريستال: 0',
                style: TextStyle(fontSize: 12.5, color: Color(0xFFBAE6FD)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
