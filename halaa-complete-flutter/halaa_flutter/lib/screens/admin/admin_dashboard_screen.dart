import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/halaa_config.dart';
import '../../services/halaa_storage.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/glass_box.dart';
import '../../widgets/halaa_background.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String username;
  final HalaaConfig initialConfig;
  final HalaaStorage storage;
  final ValueChanged<HalaaConfig> onConfigUpdated;
  final VoidCallback onLogout;
  final VoidCallback onPreviewApp;

  const AdminDashboardScreen({
    super.key,
    required this.username,
    required this.initialConfig,
    required this.storage,
    required this.onConfigUpdated,
    required this.onLogout,
    required this.onPreviewApp,
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
  final _adminUserCtrl = TextEditingController();
  String _imgCat = 'شطرنج';
  String _adminRole = 'رئيس دولة';
  String _ruleTarget = 'زر وضع الضيف';
  String _ruleAction = 'تغيير اللون';
  List<String> _logs = const [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 8, vsync: this);
    _cfg = widget.initialConfig;
    _serverCtrl = TextEditingController(text: _cfg.serverEndpoint);
    _tokenCtrl = TextEditingController();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final items = await widget.storage.loadLogs();
    if (!mounted) return;
    setState(() => _logs = items);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _serverCtrl.dispose();
    _tokenCtrl.dispose();
    _imgTitleCtrl.dispose();
    _imgUrlCtrl.dispose();
    _adminUserCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveAll(String note) async {
    setState(() => _saving = true);
    final next = _cfg.copyWith(serverEndpoint: _serverCtrl.text.trim());
    await widget.storage.saveConfig(next);
    await widget.storage.addLog(note);
    final status = await widget.storage.pushToServer(next, _tokenCtrl.text);
    widget.onConfigUpdated(next);
    await _loadLogs();
    if (!mounted) return;
    setState(() {
      _cfg = next;
      _saving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(status), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = findThemePreset(_cfg.activeTheme);

    return Scaffold(
      body: HalaaBackground(
        images: _cfg.bgImages,
        rotationSeconds: _cfg.rotationSeconds,
        theme: theme,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: theme.primary,
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'لوحة إدارة هلاا (Flutter)',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            'المشرف: ${widget.username} • ${_cfg.activeTheme}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFFBAE6FD),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'معاينة التطبيق',
                      onPressed: widget.onPreviewApp,
                      icon: const Icon(
                        Icons.phone_android_rounded,
                        color: Color(0xFF7DD3FC),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _saving
                          ? null
                          : () => _saveAll('حفظ وتطبيق إعدادات هلاا'),
                      icon: const Icon(Icons.cloud_upload_outlined, size: 17),
                      label: const Text('حفظ'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primary,
                        foregroundColor: Colors.white,
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
              TabBar(
                controller: _tabs,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: theme.accent,
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xFF94A3B8),
                tabs: const [
                  Tab(text: 'نظرة عامة'),
                  Tab(text: 'الثيمات'),
                  Tab(text: 'الخلفيات والصور'),
                  Tab(text: 'البرمجة السهلة'),
                  Tab(text: 'المشرفون'),
                  Tab(text: 'المتجر والعملات'),
                  Tab(text: 'السيرفر والربط'),
                  Tab(text: 'الأمان والسجل'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _overviewTab(theme),
                    _themesTab(),
                    _backgroundsTab(theme),
                    _noCodeTab(),
                    _adminsTab(),
                    _storeTab(),
                    _serverTab(),
                    _logsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _overviewTab(HalaaThemePreset theme) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _statChip('الثيم النشط', _cfg.activeTheme, theme.accent),
              _statChip('تقلب الصور', '${_cfg.rotationSeconds} ثوانٍ', theme.primary),
              _statChip('صور الخلفية', '${_cfg.bgImages.length}', const Color(0xFF10B981)),
              _statChip('مقاعد المايك', '${_cfg.micSeats}', const Color(0xFFF59E0B)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'عدد مقاعد المايك في الغرف الصوتية',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                children: [8, 10, 12].map((s) {
                  return ChoiceChip(
                    label: Text('$s مقاعد'),
                    selected: _cfg.micSeats == s,
                    onSelected: (_) =>
                        setState(() => _cfg = _cfg.copyWith(micSeats: s)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromRGBO(6, 26, 41, 0.72),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
        ],
      ),
    );
  }

  Widget _themesTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: kHalaaThemes.map((p) {
              final selected = p.name == _cfg.activeTheme;
              return InkWell(
                onTap: () =>
                    setState(() => _cfg = _cfg.copyWith(activeTheme: p.name)),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 152,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [p.bgTop, p.bgBottom]),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? p.accent : const Color.fromRGBO(255, 255, 255, 0.2),
                      width: selected ? 2.2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(radius: 9, backgroundColor: p.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _backgroundsTab(HalaaThemePreset theme) {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'سرعة تقلب الخلفيات بالثانية: ${_cfg.rotationSeconds} ثوانٍ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              Slider(
                min: 2,
                max: 30,
                divisions: 28,
                value: _cfg.rotationSeconds.toDouble().clamp(2, 30),
                activeColor: theme.primary,
                onChanged: (v) =>
                    setState(() => _cfg = _cfg.copyWith(rotationSeconds: v.round())),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة صورة خلفية جديدة', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _imgTitleCtrl,
                decoration: const InputDecoration(labelText: 'اسم الصورة', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _imgUrlCtrl,
                decoration: const InputDecoration(labelText: 'رابط الصورة', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _imgCat,
                      decoration: const InputDecoration(labelText: 'التصنيف', border: OutlineInputBorder()),
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
                      final url = _imgUrlCtrl.text.trim();
                      if (url.isEmpty) return;
                      setState(() {
                        _cfg = _cfg.copyWith(
                          bgImages: [
                            ..._cfg.bgImages,
                            BackgroundItem(
                              title: _imgTitleCtrl.text.trim().isEmpty
                                  ? _imgCat
                                  : _imgTitleCtrl.text.trim(),
                              category: _imgCat,
                              url: url,
                            ),
                          ],
                        );
                        _imgTitleCtrl.clear();
                        _imgUrlCtrl.clear();
                      });
                    },
                    child: const Text('إضافة'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ..._cfg.bgImages.asMap().entries.map((entry) {
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlassBox(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.url,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image_outlined),
                  ),
                ),
                title: Text(item.title),
                subtitle: Text(item.category),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFF87171)),
                  onPressed: () {
                    final next = [..._cfg.bgImages]..removeAt(entry.key);
                    setState(() => _cfg = _cfg.copyWith(bgImages: next));
                  },
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _noCodeTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'قوائم البرمجة السهلة بدون كتابة كود',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _cfg.buttonPosition,
                decoration: const InputDecoration(labelText: 'موضع أزرار الدخول', border: OutlineInputBorder()),
                items: const ['أسفل الشاشة', 'منتصف الشاشة', 'أعلى الشاشة']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _cfg = _cfg.copyWith(buttonPosition: v));
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _cfg.animationSpeed,
                decoration: const InputDecoration(labelText: 'سرعة الحركات', border: OutlineInputBorder()),
                items: const ['هادئة', 'متوسطة', 'سريعة']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _cfg = _cfg.copyWith(animationSpeed: v));
                },
              ),
              SwitchListTile(
                title: const Text('منع النسخ'),
                value: _cfg.disableCopy,
                onChanged: (v) => setState(() => _cfg = _cfg.copyWith(disableCopy: v)),
              ),
              SwitchListTile(
                title: const Text('التوهج الزجاجي'),
                value: _cfg.enableGlow,
                onChanged: (v) => setState(() => _cfg = _cfg.copyWith(enableGlow: v)),
              ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ruleTarget,
                      decoration: const InputDecoration(labelText: 'العنصر', border: OutlineInputBorder()),
                      items: const ['زر وضع الضيف', 'زر جوجل', 'زر Facebook', 'الدوائر السفلية', 'شعار هلاا']
                          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _ruleTarget = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _ruleAction,
                      decoration: const InputDecoration(labelText: 'الإجراء', border: OutlineInputBorder()),
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
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _cfg = _cfg.copyWith(
                      rules: [
                        ..._cfg.rules,
                        VisualRule(target: _ruleTarget, action: _ruleAction, value: 'auto'),
                      ],
                    );
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text('إضافة قاعدة'),
              ),
              ..._cfg.rules.asMap().entries.map((e) => ListTile(
                    dense: true,
                    title: Text('${e.value.target} ← ${e.value.action}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        final next = [..._cfg.rules]..removeAt(e.key);
                        setState(() => _cfg = _cfg.copyWith(rules: next));
                      },
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _adminsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إضافة مشرف جديد وتحديد صلاحياته', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _adminUserCtrl,
                decoration: const InputDecoration(labelText: 'اسم المشرف', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _adminRole,
                decoration: const InputDecoration(labelText: 'الرتبة', border: OutlineInputBorder()),
                items: const ['الرقابة العليا الشاملة', 'رئيس دولة', 'مشرف غرف', 'دعم فني']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _adminRole = v);
                },
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  final u = _adminUserCtrl.text.trim();
                  if (u.isEmpty) return;
                  setState(() {
                    _cfg = _cfg.copyWith(
                      admins: [
                        ..._cfg.admins,
                        AdminAccount(username: u, role: _adminRole, country: 'السعودية'),
                      ],
                    );
                    _adminUserCtrl.clear();
                  });
                },
                child: const Text('إضافة مشرف'),
              ),
              const Divider(),
              ..._cfg.admins.map((a) => ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: Text(a.username),
                    subtitle: Text('${a.role} • ${a.country}'),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _storeTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('المتجر والعملات (الذهب والكريستال)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('سعر العملات الذهبية لكل 1\$: ${_cfg.coinRateUsd.toInt()}'),
              Text('سعر الكريستال لكل 1\$: ${_cfg.crystalRateUsd.toInt()}'),
              const SizedBox(height: 8),
              const Text('باقات هلاا بريميوم: الشهم • الفارس • اللواء'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _serverTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('السيرفر والبث الفوري (live-config.json)', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              TextField(
                controller: _serverCtrl,
                decoration: const InputDecoration(labelText: 'رابط API السيرفر', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'مفتاح السيرفر / Token', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _saveAll('بث إعدادات live-config.json'),
                      icon: const Icon(Icons.send_rounded),
                      label: const Text('حفظ وبث فوري'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _cfg.toPrettyJson()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ live-config.json')),
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

  Widget _logsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        GlassBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سجل الأمان والعمليات', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ..._logs.map(
                (l) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $l', style: const TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
