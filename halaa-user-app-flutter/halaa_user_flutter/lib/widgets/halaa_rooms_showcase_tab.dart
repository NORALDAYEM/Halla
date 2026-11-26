import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
class HalaaRoomsShowcaseTab extends StatefulWidget {
  const HalaaRoomsShowcaseTab({super.key, this.serverEndpoint = ''});
  final String serverEndpoint;
  @override
  State<HalaaRoomsShowcaseTab> createState() => _HalaaRoomsShowcaseTabState();
}
class _RoomItem {
  const _RoomItem({
    required this.name,
    required this.description,
    required this.countryFlag,
    required this.categoryTag,
    required this.filterCategory,
    required this.subTab,
    required this.onlineCount,
    required this.badges,
    required this.imageAsset,
    required this.accentColor,
    required this.icon,
  });

  final String name;
  final String description;
  final String countryFlag;
  final String categoryTag;
  final String filterCategory;
  final int subTab;
  final int onlineCount;
  final List<String> badges;
  final String imageAsset;
  final Color accentColor;
  final IconData icon;
}

class _HalaaRoomsShowcaseTabState extends State<HalaaRoomsShowcaseTab> with SingleTickerProviderStateMixin {
  int _selectedSubTab = 1; // «موصى بها» نشط افتراضياً
  int _bannerPage = 0;
  String _selectedCategory = 'الجميع';
  bool _showSearch = false;
  String _searchQuery = '';

  final TextEditingController _searchController = TextEditingController();
  final PageController _bannerController = PageController();

  static const List<String> _subTabs = [
    'الخاص بي',
    'موصى بها',
    'رائج',
  ];

  static const List<String> _categories = [
    'الجميع',
    'السعودية ▾',
    'تحديات',
    'نشاطات الغرفة',
    'ترفيه',
  ];

  static const List<_RoomItem> _rooms = [
    _RoomItem(
      name: 'ديوانية نجوم هلا',
      description: 'سوالف مسائية وتحديات تفاعلية مع الجوائز',
      countryFlag: '🇸🇦',
      categoryTag: 'يلا نلعب',
      filterCategory: 'تحديات',
      subTab: 1,
      onlineCount: 184,
      badges: ['👑', '🔥'],
      imageAsset: 'assets/images/welcome-gallery/ludo-friends.webp',
      accentColor: Color(0xFF14B8A6),
      icon: Icons.casino_rounded,
    ),
    _RoomItem(
      name: 'مجلس الأحبة',
      description: 'تعارف راقٍ وأجواء هادئة للجميع',
      countryFlag: '🇸🇦',
      categoryTag: 'يلا صداقة',
      filterCategory: 'السعودية ▾',
      subTab: 1,
      onlineCount: 142,
      badges: ['💎', '✨'],
      imageAsset: 'assets/images/welcome-gallery/chessboard.webp',
      accentColor: Color(0xFF06B6D4),
      icon: Icons.favorite_rounded,
    ),
    _RoomItem(
      name: 'تحدي الذكاء السريع',
      description: 'أسئلة ثقافية وسرعة بديهة كل ليلة',
      countryFlag: '🇦🇪',
      categoryTag: 'سؤال وجواب',
      filterCategory: 'نشاطات الغرفة',
      subTab: 1,
      onlineCount: 96,
      badges: ['🏆'],
      imageAsset: 'assets/images/welcome-gallery/pool-table.webp',
      accentColor: Color(0xFFF59E0B),
      icon: Icons.quiz_rounded,
    ),
    _RoomItem(
      name: 'سهرة الرياض',
      description: 'دردشة مفتوحة وضحك ومشاركات صوتية',
      countryFlag: '🇸🇦',
      categoryTag: 'دردشة',
      filterCategory: 'ترفيه',
      subTab: 2,
      onlineCount: 215,
      badges: ['🔥', '🎙️'],
      imageAsset: 'assets/images/welcome-gallery/game-table.webp',
      accentColor: Color(0xFF8B5CF6),
      icon: Icons.mic_rounded,
    ),
    _RoomItem(
      name: 'غرفتي الخاصة',
      description: 'استضافة الأصدقاء المفضلين والألعاب الجماعية',
      countryFlag: '🇸🇦',
      categoryTag: 'يلا صداقة',
      filterCategory: 'السعودية ▾',
      subTab: 0,
      onlineCount: 38,
      badges: ['⭐'],
      imageAsset: 'assets/images/welcome-gallery/ludo-friends.webp',
      accentColor: Color(0xFF10B981),
      icon: Icons.groups_rounded,
    ),
    _RoomItem(
      name: 'بطولة البلوت والترفيه',
      description: 'جولات حماسية وتصفيات أسبوعية مباشرة',
      countryFlag: '🇰🇼',
      categoryTag: 'يلا نلعب',
      filterCategory: 'تحديات',
      subTab: 2,
      onlineCount: 163,
      badges: ['👑', '⚡'],
      imageAsset: 'assets/images/welcome-gallery/chessboard.webp',
      accentColor: Color(0xFFEC4899),
      icon: Icons.sports_esports_rounded,
    ),
  ];
  late final AnimationController _waveController;
  Timer? _presenceTimer;
  Map<String, int> _presenceCounts = {};
    @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
    _fetchPresence();
    _presenceTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _fetchPresence(),
    );
  }

  Future<void> _fetchPresence() async {
    final base = widget.serverEndpoint.trim().replaceAll(RegExp(r'/+$'), '');
    if (base.isEmpty) return;
    try {
      final uri = Uri.parse('$base/api/presence');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return;
      final decoded = jsonDecode(response.body);
      final Map<String, int> counts = {};
      void addEntry(String key, dynamic val) {
        if (val is int) {
          counts[key] = val;
        } else if (val is num) {
          counts[key] = val.toInt();
        } else if (val is List) {
          counts[key] = val.length;
        } else if (val is Map) {
          final c = val['count'] ?? val['onlineCount'] ?? val['users'] ?? val['members'];
          if (c is num) {
            counts[key] = c.toInt();
          } else if (c is List) {
            counts[key] = c.length;
          }
        }
      }
      if (decoded is Map) {
        final raw = decoded['rooms'] ?? decoded['presence'] ?? decoded;
        if (raw is Map) {
          raw.forEach((k, v) => addEntry(k.toString(), v));
        } else if (raw is List) {
          for (final item in raw) {
            if (item is Map) {
              final name = (item['name'] ?? item['room'] ?? item['roomName'] ?? item['id'] ?? '').toString();
              if (name.isNotEmpty) addEntry(name, item);
            }
          }
        }
      } else if (decoded is List) {
        for (final item in decoded) {
          if (item is Map) {
            final name = (item['name'] ?? item['room'] ?? item['roomName'] ?? item['id'] ?? '').toString();
            if (name.isNotEmpty) addEntry(name, item);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _presenceCounts = counts;
      });
    } catch (_) {}
  }

  int _onlineCountFor(_RoomItem room) => _presenceCounts[room.name] ?? 0;

  Widget _buildAnimatedSoundWave(Color color) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, _) {
        final t = _waveController.value * 2 * math.pi;
        return SizedBox(
          height: 14,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(4, (i) {
              final height = 4.0 + 9.0 * ((math.sin(t + i * 0.9) + 1) / 2);
              return Container(
                width: 2.5,
                height: height,
                margin: const EdgeInsets.symmetric(horizontal: 1),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    _bannerController.dispose()
    _waveController.dispose();
    _presenceTimer?.cancel();;
    super.dispose();
  }

  List<_RoomItem> get _filteredRooms {
    return _rooms.where((room) {
      final matchesCategory = _selectedCategory == 'الجميع' ||
          room.filterCategory == _selectedCategory;
      final matchesSubTab =
          _selectedSubTab == 1 || room.subTab == _selectedSubTab;
      final q = _searchQuery.trim().toLowerCase();
      final matchesQuery = q.isEmpty ||
          room.name.toLowerCase().contains(q) ||
          room.description.toLowerCase().contains(q) ||
          room.categoryTag.toLowerCase().contains(q);
      return matchesCategory && matchesSubTab && matchesQuery;
    }).toList();
  }

  void _showComingSoonDialog() {
    final cs = Theme.of(context).colorScheme;
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: cs.primary.withOpacity(0.45), width: 1.2),
          ),
          icon: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  cs.primary.withOpacity(0.28),
                  cs.secondary.withOpacity(0.18),
                ],
              ),
              border: Border.all(color: cs.primary.withOpacity(0.5)),
            ),
            child: Icon(Icons.meeting_room_rounded, color: cs.primary, size: 28),
          ),
          content: Text(
            'يتم العمل قريباً بعد تركيب نظام الغرف',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
              ),
              child: const Text(
                'حسناً',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rooms = _filteredRooms;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
        children: [
                   Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xB3071B21),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withAlpha(42)),
            ),
            child: Column(
              children: [
                _buildTopBar(cs),
          if (_showSearch) ...[
            const SizedBox(height: 10),
            _buildSearchField(cs),
          ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildEventBanner(cs),
          const SizedBox(height: 12),
          _buildRankingCards(cs),
          const SizedBox(height: 14),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: const Color(0xB3071B21), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.white.withAlpha(42))), child: _buildCategoriesBar(cs)),
          const SizedBox(height: 12),
          if (rooms.isEmpty)
            _buildEmptyState(cs)
          else
            ...rooms.map(
              (room) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildRoomCard(cs, room),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopBar(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: List.generate(_subTabs.length, (index) {
              final isSelected = _selectedSubTab == index;
              return Padding(
                padding: const EdgeInsets.only(left: 14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedSubTab = index),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _subTabs[index],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Colors.white.withAlpha(200),
                            fontSize: isSelected ? 16 : 14,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 5),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          height: 3.5,
                          width: isSelected ? 26 : 0,
                          decoration: BoxDecoration(
                            color: cs.primary,
                            borderRadius: BorderRadius.circular(99),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.75),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchController.clear();
              }
            });
          },
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.75),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _showSearch
                    ? cs.primary
                    : cs.primary.withOpacity(0.28),
              ),
            ),
            child: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
              color: cs.primary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchField(ColorScheme cs) {
    return TextField(
      controller: _searchController,
      onChanged: (value) => setState(() => _searchQuery = value),
      style: TextStyle(color: cs.onSurface, fontSize: 13.5),
      decoration: InputDecoration(
        hintText: 'ابحث عن غرفة أو موضوع...',
        hintStyle: TextStyle(color: cs.onSurface.withOpacity(0.5)),
        prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 20),
        filled: true,
        fillColor: cs.surface.withOpacity(0.75),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary.withOpacity(0.28)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: cs.primary, width: 1.4),
        ),
      ),
    );
  }

  Widget _buildEventBanner(ColorScheme cs) {
    const List<String> bannerSubtitles = [
      'تألق في الغرف الصوتية واجمع النقاط للفوز بالجوائز',
      'مكافآت يومية لأكثر الغرف تفاعلاً ونشاطاً',
      'تحديات مباشرة بين نجوم هلا على مدار الشهر',
      'هدايا حصرية وإطارات ذهبية للمتصدرين',
      'شارك أصدقاءك وارتقِ في الترتيب العالمي',
    ];

    return Column(
      children: [
        SizedBox(
          height: 120,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: PageView.builder(
              controller: _bannerController,
              itemCount: 5,
              onPageChanged: (index) => setState(() => _bannerPage = index),
              itemBuilder: (context, index) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        cs.primary.withOpacity(0.92),
                        cs.secondary.withOpacity(0.78),
                        cs.primaryContainer.withOpacity(0.95),
                      ],
                    ),
                    border: Border.all(
                      color: cs.primary.withOpacity(0.4),
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.22),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'فعالية الشهر',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'سباق نجوم هلا الشهري',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              bannerSubtitles[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.88),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.18),
                          border: Border.all(
                            color: const Color(0xFFFFD700).withOpacity(0.8),
                            width: 1.6,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: Color(0xFFFFD700),
                          size: 30,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isActive = _bannerPage == index;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? cs.primary : cs.onSurface.withOpacity(0.28),
                borderRadius: BorderRadius.circular(99),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildRankingCards(ColorScheme cs) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  cs.surface.withOpacity(0.92),
                  cs.primary.withOpacity(0.16),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.primary.withOpacity(0.32)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.workspace_premium_rounded,
                        color: const Color(0xFFFFD700), size: 18),
                    const SizedBox(width: 5),
                    Text(
                      'ملياردير',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    _GoldAvatar(label: '1', size: 32),
                    _GoldAvatar(label: '2', size: 36),
                    _GoldAvatar(label: '3', size: 32),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  cs.surface.withOpacity(0.92),
                  cs.secondary.withOpacity(0.18),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.secondary.withOpacity(0.34)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, color: cs.primary, size: 17),
                    const SizedBox(width: 5),
                    Text(
                      'ترتيب الثنائي',
                      style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CoupleAvatar(cs: cs, icon: Icons.person_rounded),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.primary.withOpacity(0.18),
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withOpacity(0.65),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.favorite_rounded,
                          color: cs.primary,
                          size: 16,
                        ),
                      ),
                    ),
                    _CoupleAvatar(cs: cs, icon: Icons.person_outline_rounded),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesBar(ColorScheme cs) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;
          return InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: () => setState(() => _selectedCategory = category),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSelected
                    ? cs.primary
                    : cs.surface.withOpacity(0.72),
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: isSelected
                      ? cs.primary
                      : cs.primary.withOpacity(0.28),
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: cs.primary.withOpacity(0.35),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                category,
                style: TextStyle(
                  color: isSelected
                      ? cs.onPrimary
                      : cs.onSurface.withOpacity(0.85),
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(ColorScheme cs, _RoomItem room) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: _showComingSoonDialog,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: cs.surface.withOpacity(0.78),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.primary.withOpacity(0.22)),
        ),
        child: Row(
          children: [
            // اليمين: صورة الغرفة المربعة بزوايا مستديرة 16
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: 72,
                height: 72,
                child: Image.asset(
                  room.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          room.accentColor.withOpacity(0.85),
                          cs.primaryContainer,
                        ],
                      ),
                    ),
                    child: Icon(room.icon, color: Colors.white, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // الوسط: علم الدولة واسم الغرفة ثم الوصف ثم شارة التصنيف
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        room.countryFlag,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          room.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    room.description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: cs.onSurface.withOpacity(0.68),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: cs.primary.withOpacity(0.32)),
                    ),
                    child: Text(
                      room.categoryTag,
                      style: TextStyle(
                        color: cs.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // اليسار: شارات الغرفة الصغيرة بالأعلى وعدد المتواجدين مع أيقونة موجة صوتية بالأسفل
            SizedBox(
              height: 72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: room.badges
                        .map(
                          (badge) => Container(
                            margin: const EdgeInsets.only(right: 4),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: cs.primary.withOpacity(0.28),
                              ),
                            ),
                            child: Text(
                              badge,
                              style: const TextStyle(fontSize: 10.5),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_onlineCountFor(room) > 0) ...[Container(width: 7, height: 7, decoration: const BoxDecoration(color: Color(0xFF22C55E), shape: BoxShape.circle)), const SizedBox(width: 4)], _buildAnimatedSoundWave(cs.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${_onlineCountFor(room)}',
                          style: TextStyle(
                            color: cs.onSurface,
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface.withOpacity(0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(Icons.meeting_room_outlined, color: cs.primary, size: 34),
          const SizedBox(height: 8),
          Text(
            'لا توجد غرف مطابقة للفلتر الحالي',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.8),
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoldAvatar extends StatelessWidget {
  const _GoldAvatar({required this.label, required this.size});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            cs.primary.withOpacity(0.35),
            cs.secondary.withOpacity(0.25),
          ],
        ),
        border: Border.all(color: const Color(0xFFFFD700), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.35),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: cs.onSurface,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _CoupleAvatar extends StatelessWidget {
  const _CoupleAvatar({required this.cs, required this.icon});

  final ColorScheme cs;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: cs.primary.withOpacity(0.2),
        border: Border.all(color: cs.primary.withOpacity(0.75), width: 1.6),
      ),
      child: Icon(icon, color: cs.onSurface, size: 18),
    );
  }
}
