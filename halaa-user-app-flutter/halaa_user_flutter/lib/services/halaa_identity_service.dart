import 'dart:convert';
import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class HalaaUserIdentity {
  final String userId;
  final String username;
  final String? email;
  final String? phone;
  final String role; // 'member' | 'moderator' | 'admin'
  final List<String> permissions;
  final int level;
  final int wealthLevel;
  final int goldCoins;
  final int gems;
  final List<String> badges;
  final int giftsReceived;
  final int visitors;
  final int following;
  final int followers;
  final bool isVipId;
  final bool isProtected;

  const HalaaUserIdentity({
    required this.userId,
    required this.username,
    this.email,
    this.phone,
    this.role = 'member',
    this.permissions = const [],
    this.level = 1,
    this.wealthLevel = 1,
    this.goldCoins = 0,
    this.gems = 0,
    this.badges = const [],
    this.giftsReceived = 0,
    this.visitors = 0,
    this.following = 0,
    this.followers = 0,
    this.isVipId = false,
    this.isProtected = false,
  });

  HalaaUserIdentity copyWith({
    String? userId,
    String? username,
    String? email,
    String? phone,
    String? role,
    List<String>? permissions,
    int? level,
    int? wealthLevel,
    int? goldCoins,
    int? gems,
    List<String>? badges,
    int? giftsReceived,
    int? visitors,
    int? following,
    int? followers,
    bool? isVipId,
    bool? isProtected,
  }) {
    return HalaaUserIdentity(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      permissions: permissions ?? List<String>.from(this.permissions),
      level: level ?? this.level,
      wealthLevel: wealthLevel ?? this.wealthLevel,
      goldCoins: goldCoins ?? this.goldCoins,
      gems: gems ?? this.gems,
      badges: badges ?? List<String>.from(this.badges),
      giftsReceived: giftsReceived ?? this.giftsReceived,
      visitors: visitors ?? this.visitors,
      following: following ?? this.following,
      followers: followers ?? this.followers,
      isVipId: isVipId ?? this.isVipId,
      isProtected: isProtected ?? this.isProtected,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'phone': phone,
      'role': role,
      'permissions': permissions,
      'level': level,
      'wealthLevel': wealthLevel,
      'goldCoins': goldCoins,
      'gems': gems,
      'badges': badges,
      'giftsReceived': giftsReceived,
      'visitors': visitors,
      'following': following,
      'followers': followers,
      'isVipId': isVipId,
      'isProtected': isProtected,
    };
  }

  factory HalaaUserIdentity.fromJson(Map<String, dynamic> json) {
    return HalaaUserIdentity(
      userId: (json['userId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      role: (json['role'] ?? 'member').toString(),
      permissions: (json['permissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      level: (json['level'] as num?)?.toInt() ?? 1,
      wealthLevel: (json['wealthLevel'] as num?)?.toInt() ?? 1,
      goldCoins: (json['goldCoins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      giftsReceived: (json['giftsReceived'] as num?)?.toInt() ?? 0,
      visitors: (json['visitors'] as num?)?.toInt() ?? 0,
      following: (json['following'] as num?)?.toInt() ?? 0,
      followers: (json['followers'] as num?)?.toInt() ?? 0,
      isVipId: json['isVipId'] as bool? ?? false,
      isProtected: json['isProtected'] as bool? ?? false,
    );
  }
}

class VipIdCatalogItem {
  final String id;
  final int priceCoins;
  final int priceGems;
  final String classification; // 'للبيع فقط' | 'إدارة ومشرفون'

  const VipIdCatalogItem({
    required this.id,
    required this.priceCoins,
    required this.priceGems,
    required this.classification,
  });

  bool get isShortVipId => id.length < 8;
}

class HalaaIdentityService {
  static const String _storageKey = 'halaa_unified_users_v1';

  static const List<VipIdCatalogItem> vipIdCatalog = [
    // أرقام أقل من 8 خانات - إدارة ومشرفون
    VipIdCatalogItem(
      id: '1',
      priceCoins: 0,
      priceGems: 0,
      classification: 'إدارة ومشرفون',
    ),
    VipIdCatalogItem(
      id: '10',
      priceCoins: 0,
      priceGems: 0,
      classification: 'إدارة ومشرفون',
    ),
    VipIdCatalogItem(
      id: '100',
      priceCoins: 0,
      priceGems: 0,
      classification: 'إدارة ومشرفون',
    ),
    VipIdCatalogItem(
      id: '1000',
      priceCoins: 0,
      priceGems: 0,
      classification: 'إدارة ومشرفون',
    ),
    // أرقام أقل من 8 خانات - للبيع فقط
    VipIdCatalogItem(
      id: '777',
      priceCoins: 500000,
      priceGems: 5000,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '8888',
      priceCoins: 350000,
      priceGems: 3500,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '12345',
      priceCoins: 250000,
      priceGems: 2500,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '999999',
      priceCoins: 180000,
      priceGems: 1800,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '7777777',
      priceCoins: 120000,
      priceGems: 1200,
      classification: 'للبيع فقط',
    ),
    // أرقام مميزة من 8 خانات - للبيع فقط
    VipIdCatalogItem(
      id: '88888888',
      priceCoins: 100000,
      priceGems: 1000,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '12345678',
      priceCoins: 90000,
      priceGems: 900,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '77700777',
      priceCoins: 75000,
      priceGems: 750,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '12344321',
      priceCoins: 65000,
      priceGems: 650,
      classification: 'للبيع فقط',
    ),
    VipIdCatalogItem(
      id: '55500000',
      priceCoins: 50000,
      priceGems: 500,
      classification: 'للبيع فقط',
    ),
  ];

  static bool isSpecialOrReservedId(String id) {
    final trimmed = id.trim();
    if (!RegExp(r'^\d+$').hasMatch(trimmed)) {
      return true;
    }

    // أقل من 8 خانات مخصّص للإدارة والمشرفين والبيع فقط
    if (trimmed.length < 8) {
      return true;
    }

    // ينتهي بـ 000
    if (trimmed.endsWith('000')) {
      return true;
    }

    // يحتوي على 3 أرقام متكررة متتالية (مثل 777)
    if (RegExp(r'(\d)\1\1').hasMatch(trimmed)) {
      return true;
    }

    // عدد أرقامه الفريدة 3 فأقل
    if (trimmed.split('').toSet().length <= 3) {
      return true;
    }

    // متناظر (palindrome)
    final reversed = trimmed.split('').reversed.join();
    if (trimmed == reversed) {
      return true;
    }

    // تسلسل رقمي تصاعدي أو تنازلي من 4 خانات فأكثر (مثل 1234 / 4321)
    for (int i = 0; i <= trimmed.length - 4; i++) {
      final d0 = int.parse(trimmed[i]);
      final d1 = int.parse(trimmed[i + 1]);
      final d2 = int.parse(trimmed[i + 2]);
      final d3 = int.parse(trimmed[i + 3]);

      final isAscending = (d1 - d0 == 1) && (d2 - d1 == 1) && (d3 - d2 == 1);
      final isDescending = (d0 - d1 == 1) && (d1 - d2 == 1) && (d2 - d3 == 1);
      if (isAscending || isDescending) {
        return true;
      }
    }

    return false;
  }

  static String generateOrdinary8DigitId(Set<String> existingIds) {
    final random = Random();
    for (int attempt = 0; attempt < 10000; attempt++) {
      final candidate = (10000000 + random.nextInt(90000000)).toString();
      if (!isSpecialOrReservedId(candidate) &&
          !existingIds.contains(candidate)) {
        return candidate;
      }
    }

    for (int n = 10000000; n <= 99999999; n++) {
      final candidate = n.toString();
      if (!isSpecialOrReservedId(candidate) &&
          !existingIds.contains(candidate)) {
        return candidate;
      }
    }

    throw StateError('No available ordinary 8-digit ID found.');
  }

  Future<List<HalaaUserIdentity>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return [];
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) =>
            HalaaUserIdentity.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
  }

  Future<void> _saveUsers(List<HalaaUserIdentity> users) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(users.map((u) => u.toJson()).toList());
    await prefs.setString(_storageKey, encoded);
  }

  Future<HalaaUserIdentity> resolveOrCreateUser({
    required String identifier,
    String? email,
    String? phone,
  }) async {
    final users = await getAllUsers();
    final normalizedIdentifier = identifier.trim().toLowerCase();
    final normalizedEmail = email?.trim().toLowerCase();
    final normalizedPhone = phone?.trim();

    final existingIndex = users.indexWhere((user) {
      if (user.userId.toLowerCase() == normalizedIdentifier) return true;
      if (user.username.trim().toLowerCase() == normalizedIdentifier) {
        return true;
      }
      if (user.email != null &&
          user.email!.trim().isNotEmpty &&
          (user.email!.trim().toLowerCase() == normalizedIdentifier ||
              (normalizedEmail != null &&
                  normalizedEmail.isNotEmpty &&
                  user.email!.trim().toLowerCase() == normalizedEmail))) {
        return true;
      }
      if (user.phone != null &&
          user.phone!.trim().isNotEmpty &&
          (user.phone!.trim() == identifier.trim() ||
              (normalizedPhone != null &&
                  normalizedPhone.isNotEmpty &&
                  user.phone!.trim() == normalizedPhone))) {
        return true;
      }
      return false;
    });

    if (existingIndex != -1) {
      final existing = users[existingIndex];
      final updated = existing.copyWith(
        email: (existing.email == null || existing.email!.isEmpty)
            ? email?.trim()
            : existing.email,
        phone: (existing.phone == null || existing.phone!.isEmpty)
            ? phone?.trim()
            : existing.phone,
      );
      if (updated.email != existing.email || updated.phone != existing.phone) {
        users[existingIndex] = updated;
        await _saveUsers(users);
      }
      return updated;
    }

    final existingIds = users.map((u) => u.userId).toSet();
    final newUserId = generateOrdinary8DigitId(existingIds);
    final derivedUsername = identifier.trim().isNotEmpty
        ? identifier.trim()
        : 'user_$newUserId';

    final newUser = HalaaUserIdentity(
      userId: newUserId,
      username: derivedUsername,
      email: email?.trim(),
      phone: phone?.trim(),
      role: 'member',
      isVipId: false,
    );

    users.add(newUser);
    await _saveUsers(users);
    return newUser;
  }

  Future<HalaaUserIdentity> purchaseVipId(
    String currentUserId,
    String vipId,
    int costGems,
  ) async {
    final users = await getAllUsers();
    final userIndex = users.indexWhere((u) => u.userId == currentUserId);
    if (userIndex == -1) {
      throw StateError('User with ID $currentUserId not found.');
    }

    final targetVipId = vipId.trim();
    final isAlreadyTaken = users.any(
      (u) => u.userId == targetVipId && u.userId != currentUserId,
    );
    if (isAlreadyTaken) {
      throw StateError('VIP ID $targetVipId is already owned by another user.');
    }

    final catalogMatches = vipIdCatalog.where((item) => item.id == targetVipId);
    if (catalogMatches.isNotEmpty &&
        catalogMatches.first.classification == 'إدارة ومشرفون') {
      final role = users[userIndex].role;
      if (role != 'admin' && role != 'moderator') {
        throw StateError('VIP ID $targetVipId is reserved for admin/moderators.');
      }
    }

    final currentUser = users[userIndex];
    if (currentUser.gems < costGems) {
      throw StateError('Insufficient gems to purchase VIP ID $targetVipId.');
    }

    final updatedUser = currentUser.copyWith(
      userId: targetVipId,
      gems: currentUser.gems - costGems,
      isVipId: true,
    );

    users[userIndex] = updatedUser;
    await _saveUsers(users);
    return updatedUser;
  }
}
