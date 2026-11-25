import 'dart:convert';

class BackgroundItem {
  final String title;
  final String category;
  final String path;
  final bool isAsset;

  const BackgroundItem({
    required this.title,
    required this.category,
    required this.path,
    this.isAsset = true,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'path': path,
        'isAsset': isAsset,
      };

  factory BackgroundItem.fromJson(Map<String, dynamic> j) => BackgroundItem(
        title: (j['title'] ?? '').toString(),
        category: (j['category'] ?? 'عام').toString(),
        path: (j['path'] ?? j['url'] ?? '').toString(),
        isAsset: j['isAsset'] is bool
            ? j['isAsset'] as bool
            : !(j['path'] ?? j['url'] ?? '').toString().startsWith('http'),
      );
}

class SupportTicket {
  final String id;
  final String reason;
  final String contact;
  final String details;
  final String status;
  final String reply;
  final String createdAt;

  const SupportTicket({
    required this.id,
    required this.reason,
    required this.contact,
    required this.details,
    this.status = 'قيد المراجعة',
    this.reply = '',
    required this.createdAt,
  });

  SupportTicket copyWith({String? status, String? reply}) => SupportTicket(
        id: id,
        reason: reason,
        contact: contact,
        details: details,
        status: status ?? this.status,
        reply: reply ?? this.reply,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'reason': reason,
        'contact': contact,
        'details': details,
        'status': status,
        'reply': reply,
        'createdAt': createdAt,
      };

  factory SupportTicket.fromJson(Map<String, dynamic> j) => SupportTicket(
        id: (j['id'] ?? '').toString(),
        reason: (j['reason'] ?? '').toString(),
        contact: (j['contact'] ?? '').toString(),
        details: (j['details'] ?? '').toString(),
        status: (j['status'] ?? 'قيد المراجعة').toString(),
        reply: (j['reply'] ?? '').toString(),
        createdAt: (j['createdAt'] ?? '').toString(),
      );
}

class VisualRule {
  final String target;
  final String action;
  final String color;

  const VisualRule({
    required this.target,
    required this.action,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'target': target,
        'action': action,
        'color': color,
      };

  factory VisualRule.fromJson(Map<String, dynamic> j) => VisualRule(
        target: (j['target'] ?? '').toString(),
        action: (j['action'] ?? '').toString(),
        color: (j['color'] ?? '#14b8a6').toString(),
      );
}

class AppUserRecord {
  final String nickname;
  final String email;
  final String gender;
  final String country;
  final bool banned;

  const AppUserRecord({
    required this.nickname,
    required this.email,
    required this.gender,
    required this.country,
    this.banned = false,
  });

  AppUserRecord copyWith({bool? banned}) => AppUserRecord(
        nickname: nickname,
        email: email,
        gender: gender,
        country: country,
        banned: banned ?? this.banned,
      );

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'email': email,
        'gender': gender,
        'country': country,
        'banned': banned,
      };

  factory AppUserRecord.fromJson(Map<String, dynamic> j) => AppUserRecord(
        nickname: (j['nickname'] ?? '').toString(),
        email: (j['email'] ?? '').toString(),
        gender: (j['gender'] ?? '').toString(),
        country: (j['country'] ?? 'السعودية').toString(),
        banned: j['banned'] == true,
      );
}

class AdminMember {
  final String username;
  final String role;
  final String country;

  const AdminMember({
    required this.username,
    required this.role,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'role': role,
        'country': country,
      };

  factory AdminMember.fromJson(Map<String, dynamic> j) => AdminMember(
        username: (j['username'] ?? '').toString(),
        role: (j['role'] ?? 'مشرف').toString(),
        country: (j['country'] ?? 'السعودية').toString(),
      );
}

class HalaaConfig {
  final String activeTheme;
  final int rotationSeconds;
  final int micSeats;
  final String buttonPosition;
  final String animationSpeed;
  final bool disableCopy;
  final bool enableGlow;
  final bool pullOnlyRefresh;
  final String serverEndpoint;
  final int coinRatePerUsd;
  final int crystalRatePerUsd;
  final List<BackgroundItem> bgImages;
  final List<VisualRule> rules;
  final List<AppUserRecord> appUsers;
  final List<AdminMember> adminMembers;
  final List<SupportTicket> tickets;
  final String updatedAt;

  const HalaaConfig({
    required this.activeTheme,
    required this.rotationSeconds,
    required this.micSeats,
    required this.buttonPosition,
    required this.animationSpeed,
    required this.disableCopy,
    required this.enableGlow,
    required this.pullOnlyRefresh,
    required this.serverEndpoint,
    required this.coinRatePerUsd,
    required this.crystalRatePerUsd,
    required this.bgImages,
    required this.rules,
    required this.appUsers,
    required this.adminMembers,
    required this.tickets,
    required this.updatedAt,
  });

  static const List<BackgroundItem> kDefaultGallery = [
    BackgroundItem(
      title: 'أصدقاء البلياردو',
      category: 'بلياردو',
      path: 'assets/images/welcome-gallery/pool-friends.webp',
    ),
    BackgroundItem(
      title: 'الشطرنج الملكي',
      category: 'شطرنج',
      path: 'assets/images/welcome-gallery/chessboard.webp',
    ),
    BackgroundItem(
      title: 'أصدقاء الليدو',
      category: 'ليدو',
      path: 'assets/images/welcome-gallery/ludo-friends.webp',
    ),
    BackgroundItem(
      title: 'طاولة البلياردو',
      category: 'بلياردو',
      path: 'assets/images/welcome-gallery/pool-table.webp',
    ),
    BackgroundItem(
      title: 'طاولة الضومينو',
      category: 'ضومينو',
      path: 'assets/images/welcome-gallery/game-table.webp',
    ),
    BackgroundItem(
      title: 'قطع الشطرنج',
      category: 'شطرنج',
      path: 'assets/images/welcome-gallery/chess-pieces.webp',
    ),
    BackgroundItem(
      title: 'استوديو الصوت',
      category: 'غرف صوتية',
      path: 'assets/images/welcome-gallery/headphones.webp',
    ),
  ];

  static HalaaConfig defaults() => HalaaConfig(
        activeTheme: 'الفيروزي الملكي',
        rotationSeconds: 6,
        micSeats: 10,
        buttonPosition: 'أسفل الشاشة',
        animationSpeed: 'متوسطة',
        disableCopy: true,
        enableGlow: true,
        pullOnlyRefresh: true,
        serverEndpoint: '',
        coinRatePerUsd: 1000,
        crystalRatePerUsd: 100,
        bgImages: kDefaultGallery,
        rules: const [],
        appUsers: const [],
        adminMembers: const [
          AdminMember(
            username: 'ADMIN',
            role: 'الإدارة العليا (Root)',
            country: 'المملكة العربية السعودية',
          ),
        ],
        tickets: const [],
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );

  HalaaConfig copyWith({
    String? activeTheme,
    int? rotationSeconds,
    int? micSeats,
    String? buttonPosition,
    String? animationSpeed,
    bool? disableCopy,
    bool? enableGlow,
    bool? pullOnlyRefresh,
    String? serverEndpoint,
    int? coinRatePerUsd,
    int? crystalRatePerUsd,
    List<BackgroundItem>? bgImages,
    List<VisualRule>? rules,
    List<AppUserRecord>? appUsers,
    List<AdminMember>? adminMembers,
    List<SupportTicket>? tickets,
    String? updatedAt,
  }) {
    return HalaaConfig(
      activeTheme: activeTheme ?? this.activeTheme,
      rotationSeconds: rotationSeconds ?? this.rotationSeconds,
      micSeats: micSeats ?? this.micSeats,
      buttonPosition: buttonPosition ?? this.buttonPosition,
      animationSpeed: animationSpeed ?? this.animationSpeed,
      disableCopy: disableCopy ?? this.disableCopy,
      enableGlow: enableGlow ?? this.enableGlow,
      pullOnlyRefresh: pullOnlyRefresh ?? this.pullOnlyRefresh,
      serverEndpoint: serverEndpoint ?? this.serverEndpoint,
      coinRatePerUsd: coinRatePerUsd ?? this.coinRatePerUsd,
      crystalRatePerUsd: crystalRatePerUsd ?? this.crystalRatePerUsd,
      bgImages: bgImages ?? this.bgImages,
      rules: rules ?? this.rules,
      appUsers: appUsers ?? this.appUsers,
      adminMembers: adminMembers ?? this.adminMembers,
      tickets: tickets ?? this.tickets,
      updatedAt: updatedAt ?? DateTime.now().toUtc().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() => {
        'activeTheme': activeTheme,
        'rotationSeconds': rotationSeconds,
        'micSeats': micSeats,
        'buttonPosition': buttonPosition,
        'animationSpeed': animationSpeed,
        'disableCopy': disableCopy,
        'enableGlow': enableGlow,
        'pullOnlyRefresh': pullOnlyRefresh,
        'serverEndpoint': serverEndpoint,
        'coinRatePerUsd': coinRatePerUsd,
        'crystalRatePerUsd': crystalRatePerUsd,
        'bgImages': bgImages.map((e) => e.toJson()).toList(),
        'rules': rules.map((e) => e.toJson()).toList(),
        'appUsers': appUsers.map((e) => e.toJson()).toList(),
        'adminMembers': adminMembers.map((e) => e.toJson()).toList(),
        'tickets': tickets.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory HalaaConfig.fromJson(Map<String, dynamic> j) {
    final d = HalaaConfig.defaults();
    return HalaaConfig(
      activeTheme: (j['activeTheme'] ?? d.activeTheme).toString(),
      rotationSeconds: (j['rotationSeconds'] is num)
          ? (j['rotationSeconds'] as num).toInt()
          : d.rotationSeconds,
      micSeats:
          (j['micSeats'] is num) ? (j['micSeats'] as num).toInt() : d.micSeats,
      buttonPosition: (j['buttonPosition'] ?? d.buttonPosition).toString(),
      animationSpeed: (j['animationSpeed'] ?? d.animationSpeed).toString(),
      disableCopy:
          j['disableCopy'] is bool ? j['disableCopy'] as bool : d.disableCopy,
      enableGlow:
          j['enableGlow'] is bool ? j['enableGlow'] as bool : d.enableGlow,
      pullOnlyRefresh: j['pullOnlyRefresh'] is bool
          ? j['pullOnlyRefresh'] as bool
          : d.pullOnlyRefresh,
      serverEndpoint: (j['serverEndpoint'] ?? '').toString(),
      coinRatePerUsd: (j['coinRatePerUsd'] is num)
          ? (j['coinRatePerUsd'] as num).toInt()
          : d.coinRatePerUsd,
      crystalRatePerUsd: (j['crystalRatePerUsd'] is num)
          ? (j['crystalRatePerUsd'] as num).toInt()
          : d.crystalRatePerUsd,
      bgImages: j['bgImages'] is List && (j['bgImages'] as List).isNotEmpty
          ? (j['bgImages'] as List)
              .whereType<Map<String, dynamic>>()
              .map(BackgroundItem.fromJson)
              .toList()
          : d.bgImages,
      rules: j['rules'] is List
          ? (j['rules'] as List)
              .whereType<Map<String, dynamic>>()
              .map(VisualRule.fromJson)
              .toList()
          : d.rules,
      appUsers: j['appUsers'] is List
          ? (j['appUsers'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AppUserRecord.fromJson)
              .toList()
          : d.appUsers,
      adminMembers: j['adminMembers'] is List &&
              (j['adminMembers'] as List).isNotEmpty
          ? (j['adminMembers'] as List)
              .whereType<Map<String, dynamic>>()
              .map(AdminMember.fromJson)
              .toList()
          : d.adminMembers,
      tickets: j['tickets'] is List
          ? (j['tickets'] as List)
              .whereType<Map<String, dynamic>>()
              .map(SupportTicket.fromJson)
              .toList()
          : d.tickets,
      updatedAt: (j['updatedAt'] ?? d.updatedAt).toString(),
    );
  }
}
