import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/halaa_identity_service.dart';

class HalaaProfilePage extends StatefulWidget {
  final String displayName;
  final VoidCallback onLogout;

  const HalaaProfilePage({
    super.key,
    required this.displayName,
    required this.onLogout,
  });

  @override
  State<HalaaProfilePage> createState() => _HalaaProfilePageState();
}

class _HalaaProfilePageState extends State<HalaaProfilePage> {
  final ScrollController _scrollCtrl = ScrollController();
  final HalaaIdentityService _identityService = HalaaIdentityService();

  HalaaUserIdentity? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadIdentity();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIdentity() async {
    final user = await _identityService.resolveOrCreateUser(
      identifier: widget.displayName,
    );
    if (!mounted) return;
    setState(() {
      _user = user;
      _loading = false;
    });
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return 'إدارة';
      case 'moderator':
        return 'مشرف';
      default:
        return 'عضو';
    }
  }

  void _copyUserId(String userId) {
    Clipboard.setData(ClipboardData(text: userId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ المعرّف: $userId'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showFeatureNotice(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A1E26),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF99F6E4))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openVipIdStore() async {
    final currentUser = _user;
    if (currentUser == null) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A1E26),
          title: const Text(
            'متجر الأرقام المميزة VIP IDs',
            style: TextStyle(color: Color(0xFFFBBF24), fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(251, 191, 36, 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color.fromRGBO(251, 191, 36, 0.4),
                      ),
                    ),
                    child: const Text(
                      'ملاحظة: الأرقام الأقل من 8 خانات والأرقام المميزة مخصصة للإدارة والمشرفين وللبيع فقط.',
                      style: TextStyle(color: Color(0xFFFDE68A), fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...HalaaIdentityService.vipIdCatalog.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color.fromRGBO(255, 255, 255, 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color.fromRGBO(153, 246, 228, 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID: ${item.id}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${item.classification} • ${item.priceGems} جوهرة',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFBBF24),
                              foregroundColor: Colors.black,
                            ),
                            onPressed: () async {
                              try {
                                final updated = await _identityService.purchaseVipId(
                                  currentUser.userId,
                                  item.id,
                                  item.priceGems,
                                );
                                if (!mounted) return;
                                setState(() => _user = updated);
                                Navigator.of(ctx).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('تم شراء المعرّف المميز ${item.id} بنجاح'),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('تعذر الشراء: $e')),
                                );
                              }
                            },
                            child: const Text('شراء'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF99F6E4))),
            ),
          ],
        ),
      ),
    );
  }

  void _openBadgesDialog(HalaaUserIdentity user) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A1E26),
          title: const Text(
            'الشارات والصلاحيات والهدايا',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'المعرّف المرتبط: ${user.userId}',
                  style: const TextStyle(color: Color(0xFF99F6E4), fontSize: 13),
                ),
                const SizedBox(height: 10),
                const Text('الشارات:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: (user.badges.isEmpty ? ['عضو جديد'] : user.badges)
                      .map((b) => Chip(
                            label: Text(b, style: const TextStyle(color: Colors.black, fontSize: 12)),
                            backgroundColor: const Color(0xFFFBBF24),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 10),
                const Text('الصلاحيات:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  user.permissions.isEmpty ? 'صلاحيات العضو القياسية' : user.permissions.join(' • '),
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  'الهدايا المستلمة: ${user.giftsReceived}',
                  style: const TextStyle(color: Color(0xFFFDE68A), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF99F6E4))),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSettingsDialog(HalaaUserIdentity user) async {
    final allUsers = await _identityService.getAllUsers();
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF0A1E26),
          title: const Text(
            'الإعدادات والحماية',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('حالة الحماية: ', style: TextStyle(color: Colors.white70)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.isProtected
                              ? const Color.fromRGBO(16, 185, 129, 0.2)
                              : const Color.fromRGBO(239, 68, 68, 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user.isProtected ? 'محمي' : 'غير محمي',
                          style: TextStyle(
                            color: user.isProtected ? const Color(0xFF34D399) : const Color(0xFFF87171),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'الأسماء المترابطة:',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  ...allUsers.map(
                    (u) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• ${u.username} (ID: ${u.userId})',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                widget.onLogout();
              },
              child: const Text('تسجيل الخروج', style: TextStyle(color: Color(0xFFF87171))),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('إغلاق', style: TextStyle(color: Color(0xFF99F6E4))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(10, 30, 38, 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color.fromRGBO(153, 246, 228, 0.2)),
      ),
      child: child,
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withOpacity(0.16),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF99F6E4), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(width: 6),
            ],
            const Icon(Icons.chevron_left, color: Colors.white38, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF99F6E4)),
      );
    }

    final user = _user!;
    final initial = user.username.isNotEmpty ? user.username[0].toUpperCase() : 'H';

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scrollbar(
        controller: _scrollCtrl,
        thumbVisibility: true,
        interactive: true,
        child: SingleChildScrollView(
          controller: _scrollCtrl,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // القسم العلوي
              _buildCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFFBBF24),
                              width: 2.5,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 30,
                            backgroundColor: const Color(0xFF134E4A),
                            child: Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.username,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(251, 191, 36, 0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      'LV.${user.level}',
                                      style: const TextStyle(
                                        color: Color(0xFFFBBF24),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color.fromRGBO(153, 246, 228, 0.16),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      _roleLabel(user.role),
                                      style: const TextStyle(
                                        color: Color(0xFF99F6E4),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () => _copyUserId(user.userId),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ID: ${user.userId}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.copy,
                                      size: 14,
                                      color: Color(0xFF99F6E4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildStatItem('زائر', user.visitors),
                        Container(width: 1, height: 24, color: Colors.white12),
                        _buildStatItem('متابعة', user.following),
                        Container(width: 1, height: 24, color: Colors.white12),
                        _buildStatItem('متابعين', user.followers),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // بطاقة المحفظة
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'المحفظة',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(251, 191, 36, 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'مكافآت إعادة الشحن',
                            style: TextStyle(
                              color: Color(0xFFFBBF24),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on, color: Color(0xFFFBBF24)),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'العملات الذهبية',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    Text(
                                      '${user.goldCoins}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(255, 255, 255, 0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.diamond, color: Color(0xFF38BDF8)),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'الجواهر',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                    Text(
                                      '${user.gems}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showFeatureNotice(
                              'مستوى الثروة',
                              'مستوى الثروة الحالي: LV.${user.wealthLevel}',
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(251, 191, 36, 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'مستوى الثروة',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'إلغاء القفل الآن (LV.${user.wealthLevel})',
                                    style: const TextStyle(
                                      color: Color(0xFFFBBF24),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => _showFeatureNotice(
                              'نادي VIP',
                              'انضم إلى نادي VIP للحصول على مزايا حصرية.',
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color.fromRGBO(153, 246, 228, 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'نادي VIP',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'انضم الآن',
                                    style: TextStyle(
                                      color: Color(0xFF99F6E4),
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // شبكة الأيقونات الأربع
              _buildCard(
                child: Row(
                  children: [
                    _buildQuickAction(
                      icon: Icons.task_alt,
                      label: 'المهمات',
                      color: const Color(0xFF34D399),
                      onTap: () => _showFeatureNotice('المهمات', 'تابع مهماتك اليومية لكسب المكافآت.'),
                    ),
                    _buildQuickAction(
                      icon: Icons.storefront,
                      label: 'المتجر',
                      color: const Color(0xFFFBBF24),
                      onTap: _openVipIdStore,
                    ),
                    _buildQuickAction(
                      icon: Icons.auto_awesome,
                      label: 'اكسسواراتي',
                      color: const Color(0xFFF472B6),
                      onTap: () => _showFeatureNotice('اكسسواراتي', 'استعرض إطاراتك وملحقاتك المفعلة.'),
                    ),
                    _buildQuickAction(
                      icon: Icons.military_tech,
                      label: 'المستوى',
                      color: const Color(0xFF38BDF8),
                      onTap: () => _showFeatureNotice('المستوى', 'مستواك الحالي: LV.${user.level}'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // بطاقة القائمة الأولى
              _buildCard(
                child: Column(
                  children: [
                    _buildMenuRow(
                      icon: Icons.favorite_border,
                      title: 'مساحة الثنائي',
                      trailingText: 'لا توجد علاقة ثنائية',
                      onTap: () => _showFeatureNotice('مساحة الثنائي', 'لا توجد علاقة ثنائية حالياً.'),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildMenuRow(
                      icon: Icons.workspace_premium,
                      title: 'هلا بريميوم',
                      trailingText: 'انضم الآن',
                      onTap: () => _showFeatureNotice('هلا بريميوم', 'اشترك في هلا بريميوم لمزايا إضافية.'),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildMenuRow(
                      icon: Icons.emoji_events_outlined,
                      title: 'ألقاب الشرف',
                      onTap: () => _showFeatureNotice('ألقاب الشرف', 'ألقاب الشرف الخاصة بحسابك.'),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildMenuRow(
                      icon: Icons.verified_outlined,
                      title: 'الشارة',
                      onTap: () => _openBadgesDialog(user),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildMenuRow(
                      icon: Icons.card_giftcard,
                      title: 'استدعِ واحصل على مكافآت',
                      onTap: () => _showFeatureNotice('استدعِ واحصل على مكافآت', 'شارك رمز الدعوة مع أصدقائك.'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // بطاقة القائمة الثانية
              _buildCard(
                child: Column(
                  children: [
                    _buildMenuRow(
                      icon: Icons.language,
                      title: 'اللغة',
                      trailingText: 'العربية',
                      onTap: () => _showFeatureNotice('اللغة', 'اللغة الحالية للتطبيق: العربية.'),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildMenuRow(
                      icon: Icons.confirmation_number_outlined,
                      title: 'كود الاستبدال',
                      onTap: () => _showFeatureNotice('كود الاستبدال', 'أدخل كود الاستبدال للحصول على هدايا.'),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildMenuRow(
                      icon: Icons.support_agent,
                      title: 'خدمة العملاء والأسئلة الشائعة',
                      onTap: () => _showFeatureNotice('خدمة العملاء', 'فريق الدعم متاح لمساعدتك على مدار الساعة.'),
                    ),
                    const Divider(color: Colors.white12, height: 1),
                    _buildMenuRow(
                      icon: Icons.settings_outlined,
                      title: 'الإعدادات',
                      trailingText: user.isProtected ? 'محمي' : 'غير محمي',
                      onTap: () => _openSettingsDialog(user),
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
