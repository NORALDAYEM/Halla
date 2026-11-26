import 'package:flutter/material.dart';

class HalaaGamesShowcaseTab extends StatelessWidget {
  const HalaaGamesShowcaseTab({super.key, required this.openRoom, required this.showRooms});
  final void Function(String id, String title) openRoom;
  final VoidCallback showRooms;

  static const Color _bgDark = Color(0xFF071B21);
  static const Color _surfaceDark = Color(0xFF0C2730);
  static const Color _headerBar = Color(0xA8071B21);
  static const Color _accentTeal = Color(0xFF14D8C6);

  static const List<_GameCardData> _games = [
    _GameCardData(
      titleAr: 'غرفة بلياردو',
      roomId: 'r3',
      titleEn: 'BILLIARDS',
      imagePath: 'assets/images/welcome-gallery/pool-table.webp',
      tintColor: Color(0xFF0E7490),
    ),
    _GameCardData(
      titleAr: 'غرفة شطرنج',
      roomId: 'r2',
      titleEn: 'CHESS',
      imagePath: 'assets/images/welcome-gallery/chessboard.webp',
      tintColor: Color(0xFF115E59),
    ),
    _GameCardData(
      titleAr: 'غرفة ليدو',
      roomId: 'r1',
      titleEn: 'LUDO',
      imagePath: 'assets/images/welcome-gallery/ludo-friends.webp',
      tintColor: Color(0xFF0F766E),
    ),
    _GameCardData(
      titleAr: 'غرفة ضمينو',
      roomId: 'r6',
      titleEn: 'DOMINO',
      imagePath: 'assets/images/welcome-gallery/game-table.webp',
      tintColor: Color(0xFF155E75),
    ),
  ];

  static const List<_RoomActivityData> _activities = [
    _RoomActivityData(
      category: 'بلياردو',
      roomId: 'r3',
      title: 'تحدي البلياردو السريع',
      roomName: 'غرفة نجوم البلياردو',
      imagePath: 'assets/images/welcome-gallery/pool-friends.webp',
    ),
    _RoomActivityData(
      category: 'شطرنج',
      roomId: 'r2',
      title: 'بطولة الشطرنج المسائية',
      roomName: 'مجلس الشطرنج الملكي',
      imagePath: 'assets/images/welcome-gallery/chess-pieces.webp',
    ),
    _RoomActivityData(
      category: 'صوتية',
      roomId: 'r1',
      title: 'جلسة سوالف وألعاب',
      roomName: 'ديوانية هلا الصوتية',
      imagePath: 'assets/images/welcome-gallery/headphones.webp',
    ),
    _RoomActivityData(
      category: 'ضمينو',
      roomId: 'r6',
      title: 'دوري الضمينو المباشر',
      roomName: 'ساحة الألعاب الجماعية',
      imagePath: 'assets/images/welcome-gallery/game-table.webp',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _headerBar,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.sports_esports_rounded,
                  color: _accentTeal,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'الألعاب',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _games.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.75,
            ),
            itemBuilder: (context, index) {
              final game = _games[index];
              return _GameTile(
                game: game,
                onTap: () => openRoom(game.roomId, game.titleAr),
              );
            },
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _headerBar,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      color: _accentTeal,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'نشاطات الغرفة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: showRooms,
                  style: TextButton.styleFrom(
                    foregroundColor: _accentTeal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'أكثر ‹',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _activities.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.92,
            ),
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return _RoomActivityTile(
                activity: activity,
                onTap: () => openRoom(activity.roomId, activity.roomName),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _GameCardData {
  final String roomId;
  final String titleAr;
  final String titleEn;
  final String imagePath;
  final Color tintColor;

  const _GameCardData({
    required this.roomId,
    required this.titleAr,
    required this.titleEn,
    required this.imagePath,
    required this.tintColor,
  });
}

class _RoomActivityData {
  final String roomId;
  final String category;
  final String title;
  final String roomName;
  final String imagePath;

  const _RoomActivityData({
    required this.roomId,
    required this.category,
    required this.title,
    required this.roomName,
    required this.imagePath,
  });
}

class _GameTile extends StatelessWidget {
  final _GameCardData game;
  final VoidCallback onTap;

  const _GameTile({
    required this.game,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                game.imagePath,
                fit: BoxFit.cover,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      game.tintColor.withValues(alpha: 0.25),
                      const Color(0xCC071B21),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      game.titleAr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.titleEn,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF14D8C6),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomActivityTile extends StatelessWidget {
  final _RoomActivityData activity;
  final VoidCallback onTap;

  const _RoomActivityTile({
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0C2730),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      activity.imagePath,
                      fit: BoxFit.cover,
                    ),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            const Color(0xB3071B21),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xCC071B21),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xFF14D8C6)
                                .withValues(alpha: 0.55),
                          ),
                        ),
                        child: Text(
                          activity.category,
                          style: const TextStyle(
                            color: Color(0xFF14D8C6),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room_rounded,
                          color: Color(0xFF14D8C6),
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            activity.roomName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFB4D0D5),
                              fontSize: 11.5,
                            ),
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
    );
  }
}
