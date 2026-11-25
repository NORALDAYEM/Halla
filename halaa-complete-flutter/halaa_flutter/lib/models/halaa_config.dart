import 'dart:convert';

class BackgroundItem {
  final String title;
  final String category;
  final String url;

  const BackgroundItem({
    required this.title,
    required this.category,
    required this.url,
  });

  Map<String, dynamic> toJson() => {
        'title': title,
        'category': category,
        'url': url,
      };

  factory BackgroundItem.fromJson(Map<String, dynamic> json) => BackgroundItem(
        title: (json['title'] ?? '').toString(),
        category: (json['category'] ?? 'عام').toString(),
        url: (json['url'] ?? '').toString(),
      );
}

class VisualRule {
  final String target;
  final String action;
  final String value;

  const VisualRule({
    required this.target,
    required this.action,
    required this.value,
  });

  Map<String, dynamic> toJson() => {
        'target': target,
        'action': action,
        'value': value,
      };

  factory VisualRule.fromJson(Map<String, dynamic> json) => VisualRule(
        target: (json['target'] ?? '').toString(),
        action: (json['action'] ?? '').toString(),
        value: (json['value'] ?? '').toString(),
      );
}

class AdminAccount {
  final String username;
  final String role;
  final String country;

  const AdminAccount({
    required this.username,
    required this.role,
    required this.country,
  });

  Map<String, dynamic> toJson() => {
        'username': username,
        'role': role,
        'country': country,
      };

  factory AdminAccount.fromJson(Map<String, dynamic> json) => AdminAccount(
        username: (json['username'] ?? '').toString(),
        role: (json['role'] ?? 'مشرف').toString(),
        country: (json['country'] ?? 'السعودية').toString(),
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
  final double coinRateUsd;
  final double crystalRateUsd;
  final List<BackgroundItem> bgImages;
  final List<VisualRule> rules;
  final List<AdminAccount> admins;
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
    required this.coinRateUsd,
    required this.crystalRateUsd,
    required this.bgImages,
    required this.rules,
    required this.admins,
    required this.updatedAt,
  });

  /// Exact 7 welcome-gallery assets from NORALDAYEM/Halla
  static List<BackgroundItem> defaultGallery({required bool isAdminSubpath}) {
    final prefix = isAdminSubpath
        ? '../halla-web/assets/welcome-gallery/'
        : 'assets/welcome-gallery/';
    return [
      BackgroundItem(
        title: 'الشطرنج الملكي',
        category: 'شطرنج',
        url: '${prefix}chessboard.webp',
      ),
      BackgroundItem(
        title: 'أصدقاء الليدو',
        category: 'ليدو',
        url: '${prefix}ludo-friends.webp',
      ),
      BackgroundItem(
        title: 'طاولة البلياردو',
        category: 'بلياردو',
        url: '${prefix}pool-table.webp',
      ),
      BackgroundItem(
        title: 'طاولة الضومينو',
        category: 'ضومينو',
        url: '${prefix}game-table.webp',
      ),
      BackgroundItem(
        title: 'تحدي البلياردو',
        category: 'بلياردو',
        url: '${prefix}pool-friends.webp',
      ),
      BackgroundItem(
        title: 'قطع الشطرنج',
        category: 'شطرنج',
        url: '${prefix}chess-pieces.webp',
      ),
      BackgroundItem(
        title: 'استوديو الصوت',
        category: 'غرف صوتية',
        url: '${prefix}headphones.webp',
      ),
    ];
  }

  static HalaaConfig defaults({bool isAdminSubpath = false}) => HalaaConfig(
        activeTheme: 'الفيروزي الملكي',
        rotationSeconds: 5,
        micSeats: 10,
        buttonPosition: 'أسفل الشاشة',
        animationSpeed: 'متوسطة',
        disableCopy: true,
        enableGlow: true,
        pullOnlyRefresh: true,
        serverEndpoint: '',
        coinRateUsd: 1000,
        crystalRateUsd: 100,
        bgImages: defaultGallery(isAdminSubpath: isAdminSubpath),
        rules: const [],
        admins: const [
          AdminAccount(
            username: 'ADMIN',
            role: 'الإدارة العليا (Root)',
            country: 'المملكة العربية السعودية',
          ),
        ],
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
    double? coinRateUsd,
    double? crystalRateUsd,
    List<BackgroundItem>? bgImages,
    List<VisualRule>? rules,
    List<AdminAccount>? admins,
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
      coinRateUsd: coinRateUsd ?? this.coinRateUsd,
      crystalRateUsd: crystalRateUsd ?? this.crystalRateUsd,
      bgImages: bgImages ?? this.bgImages,
      rules: rules ?? this.rules,
      admins: admins ?? this.admins,
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
        'coinRateUsd': coinRateUsd,
        'crystalRateUsd': crystalRateUsd,
        'bgImages': bgImages.map((e) => e.toJson()).toList(),
        'rules': rules.map((e) => e.toJson()).toList(),
        'admins': admins.map((e) => e.toJson()).toList(),
        'updatedAt': updatedAt,
      };

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  factory HalaaConfig.fromJson(
    Map<String, dynamic> json, {
    bool isAdminSubpath = false,
  }) {
    final def = HalaaConfig.defaults(isAdminSubpath: isAdminSubpath);
    final rawBgs = json['bgImages'];
    final rawRules = json['rules'];
    final rawAdmins = json['admins'];
    return HalaaConfig(
      activeTheme: (json['activeTheme'] ?? def.activeTheme).toString(),
      rotationSeconds: (json['rotationSeconds'] is num)
          ? (json['rotationSeconds'] as num).toInt()
          : def.rotationSeconds,
      micSeats: (json['micSeats'] is num)
          ? (json['micSeats'] as num).toInt()
          : def.micSeats,
      buttonPosition: (json['buttonPosition'] ?? def.buttonPosition).toString(),
      animationSpeed: (json['animationSpeed'] ?? def.animationSpeed).toString(),
      disableCopy: json['disableCopy'] is bool
          ? json['disableCopy'] as bool
          : def.disableCopy,
      enableGlow: json['enableGlow'] is bool
          ? json['enableGlow'] as bool
          : def.enableGlow,
      pullOnlyRefresh: json['pullOnlyRefresh'] is bool
          ? json['pullOnlyRefresh'] as bool
          : def.pullOnlyRefresh,
      serverEndpoint: (json['serverEndpoint'] ?? '').toString(),
      coinRateUsd: (json['coinRateUsd'] is num)
          ? (json['coinRateUsd'] as num).toDouble()
          : def.coinRateUsd,
      crystalRateUsd: (json['crystalRateUsd'] is num)
          ? (json['crystalRateUsd'] as num).toDouble()
          : def.crystalRateUsd,
      bgImages: rawBgs is List && rawBgs.isNotEmpty
          ? rawBgs
              .whereType<Map<String, dynamic>>()
              .map(BackgroundItem.fromJson)
              .toList()
          : def.bgImages,
      rules: rawRules is List
          ? rawRules
              .whereType<Map<String, dynamic>>()
              .map(VisualRule.fromJson)
              .toList()
          : def.rules,
      admins: rawAdmins is List && rawAdmins.isNotEmpty
          ? rawAdmins
              .whereType<Map<String, dynamic>>()
              .map(AdminAccount.fromJson)
              .toList()
          : def.admins,
      updatedAt: (json['updatedAt'] ?? def.updatedAt).toString(),
    );
  }
}
