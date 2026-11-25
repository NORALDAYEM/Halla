import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/halaa_models.dart';
import '../../services/halaa_storage.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/welcome_gallery_bg.dart';

/// Exact 9-tab Admin Dashboard matching `admin/index.html`:
/// 1. 🎨 الثيمات والتصميم
/// 2. 📱 ضبط التطبيق
/// 3. 🌐 السيرفرات والربط
/// 4. 🎁 الهدايا والعملات
/// 5. 👥 مستخدمو التطبيق
/// 6. 🛡️ مستخدمو الإدارة والصلاحيات
/// 7. 🎫 تذاكر الدعم
/// 8. 💻 التعديلات البرمجية (قوائم سهلة بدون كود)
/// 9. 🛡️ الأمان وكلمة المرور
class AdminDashboardScreen extends StatefulWidget {
  final String username;
  final HalaaConfig initialConfig;
  final HalaaStorage storage;
  final ValueChanged<HalaaConfig> onConfigUpdated;
  final VoidCallback onLogout;

  const AdminDashboardScreen({
    super.key,
    required this.username,
    required this.initialConfig,
    required this.storage,
    required this.onConfigUpdated,
    required this.onLogout,
  });

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late HalaaConfig _cfg;
  late TextEditingController _serverCtrl;
  late TextEditingController _tokenCtrl;
  final _imgTitleCtrl = TextEditingController();
  final _imgUrlCtrl = TextEditingController();
  final _newAdminCtrl = TextEditingController();
  String _imgCat = 'شطرنج';
  String _newAdminRole = 'رئيس دولة';
  String _ruleTarget = 'زر وضع الضيف';
  String _ruleAction = 'تغيير اللون';
  List<String> _logs = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 9, vsync: this);
    _cfg = widget.initialConfig;
    _serverCtrl = TextEditingController(text: _cfg.serverEndpoint);
    _tokenCtrl = TextEditingController();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final l = await widget.storage.loadLogs();
    if (!mounted) return;
    setState(() => _logs = l);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _serverCtrl.dispose();
    _tokenCtrl.dispose();
    _imgTitleCtrl.dispose();
    _imgUrlCtrl.dispose();
    _newAdminCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll(String note) async {
    setState(() => _saving = true);
    final next = _cfg.copyWith(serverEndpoint: _serverCtrl.text.trim());
    await widget.storage.saveConfig(next);
    await widget.storage.addLog(note);
    final msg = await widget.storage.pushToServer(next, _tokenCtrl.text);
    widget.onConfigUpdated(next);
    await _loadLogs();
    if (!mounted) return;
    setState(() {
      _cfg = next;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(13, 38, 47, 0.78),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color.fromRGBO(255, 255, 255, 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF99F6E4),
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = findThemePreset(_cfg.activeTheme);
    return Scaffold(
      body: WelcomeGalleryBackground(
        images: _cfg.bgImages,
        rotationSeconds: _cfg.rotationSeconds,
        darkAdminScrim: true,
        child: SafeArea(
          child: Column(
            children: [
              // Sticky Topbar matching admin/index.html
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                color: const Color.fromRGBO(8, 26, 33, 0.94),
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/halaa-clear.webp',
                      width: 38,
                      height: 38,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إدارة هلاا',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'متصل • المشرف: ${widget.username}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF86EFAC),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _saving
                          ? null
                          : () => _saveAll('حفظ وتطبيق فوري من لوحة الإدارة'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(_saving ? '...' : 'حفظ وتطبيق'),
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
              Container(
                color: const Color.fromRGBO(7, 22, 28, 0.86),
                child: TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicatorColor: const Color(0xFF5EEAD4),
                  labelColor: Colors.white,
                  unselectedLabelColor: const Color(0xFFCDE8EC),
                  tabs: const [
                    Tab(text: '🎨 الثيمات والتصميم'),
                    Tab(text: '📱 ضبط التطبيق'),
                    Tab(text: '🌐 السيرفرات والربط'),
                    Tab(text: '🎁 الهدايا والعملات'),
                    Tab(text: '👥 مستخدمو التطبيق'),
                    Tab(text: '🛡️ مستخدمو الإدارة والصلاحيات'),
                    Tab(text: '🎫 تذاكر الدعم'),
                    Tab(text: '💻 التعديلات البرمجية'),
                    Tab(text: '🛡️ الأمان وكلمة المرور'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _tabThemes(theme),
                    _tabAppSettings(theme),
                    _tabServers(),
                    _tabGifts(),
                    _tabAppUsers(),
                    _tabAdminUsers(),
                    _tabTickets(),
                    _tabNoCode(),
                    _tabSecurity(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tabThemes(HalaaThemePreset theme) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'الثيمات الجاهزة (8 ثيمات)',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kHalaaThemes.map((t) {
              final active = t.name == _cfg.activeTheme;
              return InkWell(
                onTap: () =>
                    setState(() => _cfg = _cfg.copyWith(activeTheme: t.name)),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 148,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color.fromRGBO(20, 184, 166, 0.22)
                        : const Color.fromRGBO(255, 255, 255, 0.06),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: active
                          ? const Color(0xFF5EEAD4)
                          : const Color.fromRGBO(255, 255, 255, 0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 8, backgroundColor: t.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          t.name,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        _card(
          title: 'إدارة صور الخلفية وسرعة التقلب (${_cfg.rotationSeconds} ثوانٍ)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Slider(
                min: 2,
                max: 30,
                divisions: 28,
                value: _cfg.rotationSeconds.toDouble().clamp(2, 30),
                activeColor: theme.primary,
                onChanged: (v) => setState(
                  () => _cfg = _cfg.copyWith(rotationSeconds: v.round()),
                ),
              ),
              TextField(
                controller: _imgTitleCtrl,
                decoration: const InputDecoration(
                  labelText: 'عنوان الصورة الجديدة',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _imgUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط الصورة (URL)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _imgCat,
                      decoration: const InputDecoration(
                        labelText: 'التصنيف',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['شطرنج', 'ليدو', 'بلياردو', 'ضومينو', 'غرف صوتية']
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _imgCat = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final u = _imgUrlCtrl.text.trim();
                      if (u.isEmpty) return;
                      setState(() {
                        _cfg = _cfg.copyWith(
                          bgImages: [
                            ..._cfg.bgImages,
                            BackgroundItem(
                              title: _imgTitleCtrl.text.trim().isEmpty
                                  ? _imgCat
                                  : _imgTitleCtrl.text.trim(),
                              category: _imgCat,
                              path: u,
                              isAsset: !u.startsWith('http'),
                            ),
                          ],
                        );
                        _imgTitleCtrl.clear();
                        _imgUrlCtrl.clear();
                      });
                    },
                    child: const Text('إضافة صورة'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ..._cfg.bgImages.asMap().entries.map((e) {
                final item = e.value;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.isAsset
                        ? Image.asset(item.path, width: 44, height: 44, fit: BoxFit.cover)
                        : Image.network(
                            item.path,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(Icons.image),
                          ),
                  ),
                  title: Text(item.title),
                  subtitle: Text(item.category),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Color(0xFFFCA5A5)),
                    onPressed: () {
                      final list = [..._cfg.bgImages]..removeAt(e.key);
                      setState(() => _cfg = _cfg.copyWith(bgImages: list));
                    },
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabAppSettings(HalaaThemePreset theme) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'إعدادات الغرف الصوتية والتطبيق',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('عدد مقاعد المايك في الغرف:'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [8, 10, 12]
                    .map(
                      (s) => ChoiceChip(
                        label: Text('$s مقاعد'),
                        selected: _cfg.micSeats == s,
                        onSelected: (_) =>
                            setState(() => _cfg = _cfg.copyWith(micSeats: s)),
                      ),
                    )
                    .toList(),
              ),
              SwitchListTile(
                title: const Text('منع النسخ غير المصرح به'),
                value: _cfg.disableCopy,
                onChanged: (v) =>
                    setState(() => _cfg = _cfg.copyWith(disableCopy: v)),
              ),
              SwitchListTile(
                title: const Text('تفعيل التوهج الزجاجي'),
                value: _cfg.enableGlow,
                onChanged: (v) =>
                    setState(() => _cfg = _cfg.copyWith(enableGlow: v)),
              ),
              SwitchListTile(
                title: const Text('تحديث صامت بدون ترميش'),
                value: _cfg.pullOnlyRefresh,
                onChanged: (v) =>
                    setState(() => _cfg = _cfg.copyWith(pullOnlyRefresh: v)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabServers() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'الربط المباشر بالسيرفر وبث live-config.json',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _serverCtrl,
                decoration: const InputDecoration(
                  labelText: 'رابط API السيرفر',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _tokenCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'مفتاح السيرفر / Token',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveAll('بث فوري إلى السيرفر'),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('حفظ وبث فوري'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _cfg.toPrettyJson()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ JSON الإعدادات')),
                      );
                    },
                    icon: const Icon(Icons.copy_rounded),
                    label: const Text('نسخ JSON'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabGifts() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'الهدايا والعملات (الذهب والكريستال)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('سعر العملات الذهبية لكل 1\$: ${_cfg.coinRatePerUsd}'),
              Text('سعر الكريستال لكل 1\$: ${_cfg.crystalRatePerUsd}'),
              const SizedBox(height: 8),
              const Text('باقات هلاا بريميوم: الشهم • الفارس • اللواء'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabAppUsers() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'مستخدمو التطبيق المسجلون (${_cfg.appUsers.length})',
          child: _cfg.appUsers.isEmpty
              ? const Text('لا يوجد مستخدمون مسجلون بالبريد بعد.')
              : Column(
                  children: _cfg.appUsers.asMap().entries.map((e) {
                    final u = e.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(u.nickname),
                      subtitle: Text('${u.email} • ${u.country}'),
                      trailing: TextButton(
                        onPressed: () {
                          final list = [..._cfg.appUsers];
                          list[e.key] = u.copyWith(banned: !u.banned);
                          setState(() => _cfg = _cfg.copyWith(appUsers: list));
                        },
                        child: Text(
                          u.banned ? 'فك الحظر' : 'حظر',
                          style: TextStyle(
                            color: u.banned
                                ? const Color(0xFF6EE7B7)
                                : const Color(0xFFFCA5A5),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _tabAdminUsers() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'إضافة مشرف وتوزيع الصلاحيات',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _newAdminCtrl,
                decoration: const InputDecoration(
                  labelText: 'اسم المشرف',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _newAdminRole,
                decoration: const InputDecoration(
                  labelText: 'الرتبة',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  'الرقابة العليا الشاملة',
                  'رئيس دولة',
                  'مشرف غرف',
                  'دعم فني',
                ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _newAdminRole = v);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  final u = _newAdminCtrl.text.trim();
                  if (u.isEmpty) return;
                  setState(() {
                    _cfg = _cfg.copyWith(
                      adminMembers: [
                        ..._cfg.adminMembers,
                        AdminMember(
                          username: u,
                          role: _newAdminRole,
                          country: 'السعودية',
                        ),
                      ],
                    );
                    _newAdminCtrl.clear();
                  });
                },
                child: const Text('إضافة مشرف'),
              ),
              const Divider(),
              ..._cfg.adminMembers.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(m.username),
                  subtitle: Text('${m.role} • ${m.country}'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabTickets() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'تذاكر الدعم الفني (${_cfg.tickets.length})',
          child: _cfg.tickets.isEmpty
              ? const Text('لا توجد تذاكر دعم فني حالياً.')
              : Column(
                  children: _cfg.tickets.asMap().entries.map((e) {
                    final t = e.value;
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${t.id} — ${t.reason}'),
                      subtitle: Text('${t.contact} — ${t.details}'),
                      trailing: TextButton(
                        onPressed: () {
                          final next = [..._cfg.tickets];
                          next[e.key] = t.copyWith(
                            status: 'تم الحل',
                            reply: 'تمت معالجة طلبك من قبل إدارة هلاا.',
                          );
                          setState(() => _cfg = _cfg.copyWith(tickets: next));
                        },
                        child: Text(t.status == 'تم الحل' ? 'مغلقة ✅' : 'حل التذكرة'),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }

  Widget _tabNoCode() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'قوائم التصميم والبرمجة السهلة (بدون كتابة كود)',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _cfg.buttonPosition,
                decoration: const InputDecoration(
                  labelText: 'موضع أزرار الدخول',
                  border: OutlineInputBorder(),
                ),
                items: const ['أسفل الشاشة', 'منتصف الشاشة', 'أعلى الشاشة']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _cfg = _cfg.copyWith(buttonPosition: v));
                  }
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _cfg.animationSpeed,
                decoration: const InputDecoration(
                  labelText: 'سرعة الحركات',
                  border: OutlineInputBorder(),
                ),
                items: const ['هادئة', 'متوسطة', 'سريعة']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _cfg = _cfg.copyWith(animationSpeed: v));
                  }
                },
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ruleTarget,
                      decoration: const InputDecoration(
                        labelText: 'العنصر',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        'زر وضع الضيف',
                        'زر تسجيل الدخول',
                        'زر جيميل',
                        'زر Facebook',
                        'الدوائر السفلية',
                        'شعار هلاا',
                      ].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _ruleTarget = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ruleAction,
                      decoration: const InputDecoration(
                        labelText: 'الإجراء',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['تغيير اللون', 'إظهار', 'إخفاء', 'تكبير']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _ruleAction = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _cfg = _cfg.copyWith(
                      rules: [
                        ..._cfg.rules,
                        VisualRule(
                          target: _ruleTarget,
                          action: _ruleAction,
                          color: '#14b8a6',
                        ),
                      ],
                    );
                  });
                },
                child: const Text('إضافة قاعدة'),
              ),
              ..._cfg.rules.asMap().entries.map(
                (e) => ListTile(
                  dense: true,
                  title: Text('${e.value.target} ← ${e.value.action}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      final next = [..._cfg.rules]..removeAt(e.key);
                      setState(() => _cfg = _cfg.copyWith(rules: next));
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tabSecurity() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        _card(
          title: 'سجل الأمان والعمليات',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _logs
                .map(
                  (l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text('• $l', style: const TextStyle(fontSize: 13)),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
