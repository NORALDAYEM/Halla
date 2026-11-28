import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/halaa_models.dart';
import '../../services/halaa_storage.dart';
import '../../theme/halaa_themes.dart';
import '../../widgets/welcome_gallery_bg.dart';
import '../../core/api/halaa_central_admin_api.dart';
import '../../features/security_center/central_control_panel_widget.dart';

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
  final HalaaCentralAdminApi _centralApi = HalaaCentralAdminApi();
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
final TextEditingController _roomIdCtrl = TextEditingController();
final TextEditingController _roomWelcomeCtrl = TextEditingController();
bool _roomsLoading = false;
bool _roomsSaving = false;
String? _roomsStatusMsg;
bool _roomsStatusError = false;
int _roomMaxMics = 8;
int _roomLevel = 1;
bool _allowGuestMic = true;
bool _allowGuestGifts = true;
bool _allowGifts = true;
bool _allowChat = true;
List<dynamic> _roomLevels = const [];

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
_roomIdCtrl.dispose();
_roomWelcomeCtrl.dispose();
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
  Future<void> _openCentralControlPanel() async {
    if (!_centralApi.isAuthenticated) {
      final userCtrl = TextEditingController();
final passCtrl = TextEditingController();
final totpCtrl = TextEditingController();
String? errorText;
bool loading = false;
final ok = await showDialog<bool>(
context: context,
builder: (ctx) => StatefulBuilder(
builder: (ctx, setDialogState) => AlertDialog(
title: const Text('تسجيل الدخول للخادم المركزي'),
content: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
TextField(controller: userCtrl, decoration: const InputDecoration(labelText: 'اسم المستخدم')),
const SizedBox(height: 8),
TextField(controller: passCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'كلمة المرور')),
const SizedBox(height: 8),
TextField(controller: totpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'رمز TOTP')),
if (errorText != null) ...[
const SizedBox(height: 8),
Text(errorText!, style: const TextStyle(color: Colors.red)),
],
],
),
),
actions: [
TextButton(onPressed: loading ? null : () => Navigator.of(ctx).pop(false), child: const Text('إلغاء')),
ElevatedButton(
onPressed: loading ? null : () async {
setDialogState(() { loading = true; errorText = null; });
try {
await _centralApi.login(username: userCtrl.text.trim(), password: passCtrl.text, totpCode: totpCtrl.text.trim());
if (ctx.mounted) Navigator.of(ctx).pop(true);
} catch (e) {
setDialogState(() { loading = false; errorText = e.toString(); });
}
},
child: loading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('دخول'),
),
],
),
),
);
userCtrl.dispose();
passCtrl.dispose();
totpCtrl.dispose();
if (ok != true || !_centralApi.isAuthenticated) return;
}
if (!mounted) return;
Navigator.of(context).push(
MaterialPageRoute(
builder: (_) => Scaffold(
appBar: AppBar(title: const Text('مركز التحكم المركزي والأمان')),
body: CentralControlPanelWidget(api: _centralApi),
),
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
tooltip: 'مركز التحكم المركزي والأمان',
onPressed: _openCentralControlPanel,
icon: const Icon(Icons.security_rounded, color: Colors.white),
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
const SizedBox(height: 12),
_buildRoomsConfigCard(theme),
      ],
    );
  }

Future<void> _fetchRoomsConfig() async {
setState(() {
_roomsLoading = true;
_roomsStatusMsg = null;
_roomsStatusError = false;
});
try {
final room = _roomIdCtrl.text.trim();
final res = await _centralApi.getRoomsConfig(room: room.isEmpty ? null : room);
final cfg = res['config'] is Map<String, dynamic>
? res['config'] as Map<String, dynamic>
: res;
if (!mounted) return;
setState(() {
_roomMaxMics = ((cfg['maxMics'] as num?)?.toInt() ?? _roomMaxMics).clamp(2, 16);
_roomLevel = ((cfg['level'] ?? cfg['roomLevel']) as num?)?.toInt().clamp(1, 10) ?? _roomLevel;
_allowGuestMic = cfg['allowGuestMic'] as bool? ?? _allowGuestMic;
_allowGuestGifts = cfg['allowGuestGifts'] as bool? ?? _allowGuestGifts;
_allowGifts = cfg['allowGifts'] as bool? ?? _allowGifts;
_allowChat = cfg['allowChat'] as bool? ?? _allowChat;
_roomWelcomeCtrl.text = (cfg['welcomeMessage'] ?? _roomWelcomeCtrl.text).toString();
if (res['levels'] is List) {
_roomLevels = res['levels'] as List<dynamic>;
} else if (cfg['levels'] is List) {
_roomLevels = cfg['levels'] as List<dynamic>;
}
_roomsLoading = false;
_roomsStatusMsg = 'تم جلب إعدادات الغرف من الخادم بنجاح';
_roomsStatusError = false;
});
} catch (e) {
if (!mounted) return;
setState(() {
_roomsLoading = false;
_roomsStatusMsg = 'تعذر جلب إعدادات الغرف: $e';
_roomsStatusError = true;
});
}
}

Future<void> _saveRoomsConfig() async {
setState(() {
_roomsSaving = true;
_roomsStatusMsg = null;
_roomsStatusError = false;
});
try {
final room = _roomIdCtrl.text.trim();
final payload = <String, dynamic>{
if (room.isNotEmpty) 'room': room,
'maxMics': _roomMaxMics,
'level': _roomLevel,
'allowGuestMic': _allowGuestMic,
'allowGuestGifts': _allowGuestGifts,
'allowGifts': _allowGifts,
'allowChat': _allowChat,
'welcomeMessage': _roomWelcomeCtrl.text.trim(),
};
await _centralApi.saveRoomsConfig(payload);
if (!mounted) return;
setState(() {
_roomsSaving = false;
_roomsStatusMsg = 'تم حفظ وتطبيق إعدادات الغرف بنجاح';
_roomsStatusError = false;
});
ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('تم حفظ وتطبيق إعدادات الغرف بنجاح'),
behavior: SnackBarBehavior.floating,
),
);
} catch (e) {
if (!mounted) return;
setState(() {
_roomsSaving = false;
_roomsStatusMsg = 'فشل حفظ إعدادات الغرف: $e';
_roomsStatusError = true;
});
ScaffoldMessenger.of(context).showSnackBar(
SnackBar(
content: Text('فشل حفظ إعدادات الغرف: $e'),
behavior: SnackBarBehavior.floating,
),
);
}
}

Widget _buildRoomsConfigCard(HalaaThemePreset theme) {
final levelsList = _roomLevels.isNotEmpty
? _roomLevels
: List.generate(10, (i) {
final lvl = i + 1;
final mics = (4 + lvl).clamp(2, 16);
return {'level': lvl, 'maxMics': mics, 'limit': lvl * 50};
});
return _card(
title: 'إدارة الغرف الصوتية والمستويات',
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
TextField(
controller: _roomIdCtrl,
decoration: const InputDecoration(
labelText: 'معرّف الغرفة (اختياري - اتركه فارغاً للإعدادات العامة)',
border: OutlineInputBorder(),
isDense: true,
),
),
const SizedBox(height: 10),
ElevatedButton.icon(
onPressed: _roomsLoading ? null : _fetchRoomsConfig,
icon: _roomsLoading
? const SizedBox(
width: 16,
height: 16,
child: CircularProgressIndicator(strokeWidth: 2),
)
: const Icon(Icons.cloud_download_outlined),
label: const Text('جلب الإعدادات الحالية من الخادم'),
),
const SizedBox(height: 14),
Text(
'عدد المايكات: $_roomMaxMics',
style: const TextStyle(fontWeight: FontWeight.w700),
),
Slider(
value: _roomMaxMics.toDouble(),
min: 2,
max: 16,
divisions: 14,
label: '$_roomMaxMics',
onChanged: (v) => setState(() => _roomMaxMics = v.round()),
),
Wrap(
spacing: 8,
runSpacing: 8,
children: [5, 8, 9, 10, 12, 16]
.map(
(m) => ChoiceChip(
label: Text('$m مايك'),
selected: _roomMaxMics == m,
onSelected: (_) => setState(() => _roomMaxMics = m),
),
)
.toList(),
),
const SizedBox(height: 14),
Text(
'مستوى الغرفة: $_roomLevel',
style: const TextStyle(fontWeight: FontWeight.w700),
),
Slider(
value: _roomLevel.toDouble(),
min: 1,
max: 10,
divisions: 9,
label: '$_roomLevel',
onChanged: (v) => setState(() => _roomLevel = v.round()),
),
Wrap(
spacing: 6,
runSpacing: 6,
children: List.generate(10, (i) => i + 1)
.map(
(lvl) => ChoiceChip(
label: Text('مستوى $lvl'),
selected: _roomLevel == lvl,
onSelected: (_) => setState(() => _roomLevel = lvl),
),
)
.toList(),
),
const SizedBox(height: 12),
const Text(
'مستويات الغرف وعدد مايكاتها وحدودها:',
style: TextStyle(fontWeight: FontWeight.w700),
),
const SizedBox(height: 6),
Wrap(
spacing: 8,
runSpacing: 8,
children: levelsList.map((item) {
final map = item is Map ? item : <String, dynamic>{};
final lvl = map['level'] ?? '-';
final mics = map['maxMics'] ?? map['mics'] ?? '-';
final limit = map['limit'] ?? map['maxMembers'] ?? map['minCoins'] ?? '-';
return Chip(
label: Text('المستوى $lvl: $mics مايك | الحد $limit'),
);
}).toList(),
),
const SizedBox(height: 8),
SwitchListTile(
title: const Text('السماح للضيف بالمايك (allowGuestMic)'),
value: _allowGuestMic,
onChanged: (v) => setState(() => _allowGuestMic = v),
),
SwitchListTile(
title: const Text('السماح للضيف بالهدايا (allowGuestGifts)'),
value: _allowGuestGifts,
onChanged: (v) => setState(() => _allowGuestGifts = v),
),
SwitchListTile(
title: const Text('تفعيل الهدايا (allowGifts)'),
value: _allowGifts,
onChanged: (v) => setState(() => _allowGifts = v),
),
SwitchListTile(
title: const Text('تفعيل الدردشة (allowChat)'),
value: _allowChat,
onChanged: (v) => setState(() => _allowChat = v),
),
const SizedBox(height: 8),
TextField(
controller: _roomWelcomeCtrl,
maxLines: 2,
decoration: const InputDecoration(
labelText: 'الرسالة الترحيبية للغرفة (welcomeMessage)',
border: OutlineInputBorder(),
),
),
if (_roomsStatusMsg != null) ...[
const SizedBox(height: 10),
Text(
_roomsStatusMsg!,
style: TextStyle(
color: _roomsStatusError ? Colors.redAccent : Colors.green,
fontWeight: FontWeight.w700,
),
),
],
const SizedBox(height: 12),
ElevatedButton.icon(
onPressed: _roomsSaving ? null : _saveRoomsConfig,
icon: _roomsSaving
? const SizedBox(
width: 16,
height: 16,
child: CircularProgressIndicator(strokeWidth: 2),
)
: const Icon(Icons.save_outlined),
label: const Text('حفظ وتطبيق إعدادات الغرف'),
),
],
),
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

  Widget _tabAppUsers() => _AppUsersTab(api: _centralApi);

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

class _AppUsersTab extends StatefulWidget {
final HalaaCentralAdminApi api;
const _AppUsersTab({required this.api});
@override
State<_AppUsersTab> createState() => _AppUsersTabState();
}

class _AppUsersTabState extends State<_AppUsersTab> {
final TextEditingController _searchCtrl = TextEditingController();
String? _role;
String? _status;
String? _gender;
int? _level;
bool _loading = false;
String? _error;
List<Map<String, dynamic>> _users = [];
int _total = 0;

@override
void initState() {
super.initState();
_loadUsers();
}

@override
void dispose() {
_searchCtrl.dispose();
super.dispose();
}

Future<void> _loadUsers() async {
setState(() {
_loading = true;
_error = null;
});
try {
final q = _searchCtrl.text.trim();
final res = await widget.api.listUsers(
search: q.isEmpty ? null : q,
role: _role,
status: _status,
gender: _gender,
level: _level,
);
final raw = (res['users'] as List?) ?? const [];
if (!mounted) return;
setState(() {
_users = raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
_total = (res['total'] as num?)?.toInt() ?? _users.length;
});
} catch (e) {
if (!mounted) return;
setState(() => _error = 'تعذر تحميل المستخدمين: $e');
} finally {
if (mounted) setState(() => _loading = false);
}
}

String _roleAr(String? r) {
switch (r) {
case 'super_admin': return 'مدير عام';
case 'admin': return 'مشرف عام';
case 'moderator': return 'مراقب';
case 'vip': return 'VIP';
default: return 'مستخدم';
}
}

String _statusAr(String? s) {
switch (s) {
case 'suspended': return 'موقوف مؤقتاً';
case 'banned': return 'محظور';
default: return 'نشط';
}
}

String _genderAr(String? g) {
switch (g) {
case 'male': return 'ذكر';
case 'female': return 'أنثى';
case 'other': return 'آخر';
default: return g ?? 'غير محدد';
}
}

Future<void> _openAddUserDialog() async {
final created = await showDialog<bool>(
context: context,
builder: (_) => _AddUserDialog(api: widget.api),
);
if (created == true) _loadUsers();
}

Future<void> _openUserDetails(Map<String, dynamic> user) async {
final id = (user['id'] ?? '').toString();
if (id.isEmpty) return;
final changed = await showDialog<bool>(
context: context,
builder: (_) => _UserDetailsDialog(api: widget.api, userId: id, initialUser: user),
);
if (changed == true) _loadUsers();
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: ListView(
padding: const EdgeInsets.all(14),
children: [
Card(
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
Row(
children: [
Expanded(
child: Text('مستخدمو التطبيق ($_total)', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
),
IconButton(
tooltip: 'تحديث',
onPressed: _loading ? null : _loadUsers,
icon: const Icon(Icons.refresh),
),
const SizedBox(width: 6),
ElevatedButton.icon(
onPressed: _openAddUserDialog,
icon: const Icon(Icons.person_add, size: 18),
label: const Text('إضافة مستخدم جديد'),
),
],
),
const SizedBox(height: 10),
TextField(
controller: _searchCtrl,
onSubmitted: (_) => _loadUsers(),
decoration: InputDecoration(
hintText: 'بحث بالاسم أو الإيميل أو الهاتف أو IP...',
prefixIcon: const Icon(Icons.search),
suffixIcon: IconButton(
icon: const Icon(Icons.send),
onPressed: _loadUsers,
),
border: const OutlineInputBorder(),
isDense: true,
),
),
const SizedBox(height: 10),
Wrap(
spacing: 8,
runSpacing: 8,
children: [
SizedBox(
width: 145,
child: DropdownButtonFormField<String?>(
value: _role,
isDense: true,
decoration: const InputDecoration(labelText: 'الدور', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: null, child: Text('الكل')),
DropdownMenuItem(value: 'user', child: Text('مستخدم')),
DropdownMenuItem(value: 'vip', child: Text('VIP')),
DropdownMenuItem(value: 'moderator', child: Text('مراقب')),
DropdownMenuItem(value: 'admin', child: Text('مشرف عام')),
DropdownMenuItem(value: 'super_admin', child: Text('مدير عام')),
],
onChanged: (v) { setState(() => _role = v); _loadUsers(); },
),
),
SizedBox(
width: 145,
child: DropdownButtonFormField<String?>(
value: _status,
isDense: true,
decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: null, child: Text('الكل')),
DropdownMenuItem(value: 'active', child: Text('نشط')),
DropdownMenuItem(value: 'suspended', child: Text('موقوف مؤقتاً')),
DropdownMenuItem(value: 'banned', child: Text('محظور')),
],
onChanged: (v) { setState(() => _status = v); _loadUsers(); },
),
),
SizedBox(
width: 130,
child: DropdownButtonFormField<String?>(
value: _gender,
isDense: true,
decoration: const InputDecoration(labelText: 'الجنس', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: null, child: Text('الكل')),
DropdownMenuItem(value: 'male', child: Text('ذكر')),
DropdownMenuItem(value: 'female', child: Text('أنثى')),
DropdownMenuItem(value: 'other', child: Text('آخر')),
],
onChanged: (v) { setState(() => _gender = v); _loadUsers(); },
),
),
SizedBox(
width: 130,
child: DropdownButtonFormField<int?>(
value: _level,
isDense: true,
decoration: const InputDecoration(labelText: 'المستوى', border: OutlineInputBorder()),
items: [
const DropdownMenuItem<int?>(value: null, child: Text('الكل')),
for (int i = 1; i <= 10; i++) DropdownMenuItem<int?>(value: i, child: Text('المستوى $i')),
],
onChanged: (v) { setState(() => _level = v); _loadUsers(); },
),
),
],
),
],
),
),
),
const SizedBox(height: 10),
if (_loading) const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())),
if (_error != null)
Card(
color: Colors.red.shade50,
child: Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: const TextStyle(color: Colors.red))),
),
if (!_loading && _error == null && _users.isEmpty)
const Card(child: Padding(padding: EdgeInsets.all(20), child: Center(child: Text('لا يوجد مستخدمون مطابقون لخيارات البحث الحالية.')))),
..._users.map((u) {
final name = (u['display_name'] ?? u['username'] ?? u['id'] ?? '-').toString();
final username = (u['username'] ?? '-').toString();
final email = (u['email'] ?? '-').toString();
final phone = (u['phone'] ?? '-').toString();
final ip = (u['last_ip'] ?? '-').toString();
final country = (u['country_name'] ?? u['country_code'] ?? '-').toString();
final gender = _genderAr(u['gender']?.toString());
final level = (u['level'] ?? 1).toString();
final xp = (u['xp'] ?? 0).toString();
final role = _roleAr(u['role']?.toString());
final status = _statusAr(u['status']?.toString());
final fb = (u['facebook_id'] ?? '').toString();
final gmail = (u['gmail_email'] ?? u['google_id'] ?? '').toString();
return Card(
margin: const EdgeInsets.only(bottom: 10),
child: InkWell(
onTap: () => _openUserDetails(u),
borderRadius: BorderRadius.circular(12),
child: Padding(
padding: const EdgeInsets.all(12),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Row(
children: [
const CircleAvatar(child: Icon(Icons.person)),
const SizedBox(width: 10),
Expanded(
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
Text('$name (@$username)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
Text('المستوى $level • $xp XP • $role • $status', style: const TextStyle(fontSize: 12, color: Colors.black54)),
],
),
),
const Icon(Icons.chevron_left),
],
),
const Divider(height: 16),
Wrap(
spacing: 14,
runSpacing: 6,
children: [
Text('الإيميل: $email', style: const TextStyle(fontSize: 12)),
Text('الهاتف: $phone', style: const TextStyle(fontSize: 12)),
Text('آخر IP: $ip', style: const TextStyle(fontSize: 12)),
Text('الدولة: $country', style: const TextStyle(fontSize: 12)),
Text('الجنس: $gender', style: const TextStyle(fontSize: 12)),
Text('Facebook: ${fb.isEmpty ? "غير مرتبط" : fb}', style: const TextStyle(fontSize: 12)),
Text('Gmail: ${gmail.isEmpty ? "غير مرتبط" : gmail}', style: const TextStyle(fontSize: 12)),
],
),
],
),
),
),
);
}),
],
),
);
}
}

class _AddUserDialog extends StatefulWidget {
final HalaaCentralAdminApi api;
const _AddUserDialog({required this.api});
@override
State<_AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<_AddUserDialog> {
final _usernameCtrl = TextEditingController();
final _nameCtrl = TextEditingController();
final _emailCtrl = TextEditingController();
final _phoneCtrl = TextEditingController();
final _countryCtrl = TextEditingController(text: 'السعودية');
final _ipCtrl = TextEditingController();
final _fbCtrl = TextEditingController();
final _gmailCtrl = TextEditingController();
final _xpCtrl = TextEditingController(text: '0');
String _gender = 'male';
String _role = 'user';
String _status = 'active';
int _level = 1;
bool _saving = false;
String? _error;

@override
void dispose() {
_usernameCtrl.dispose();
_nameCtrl.dispose();
_emailCtrl.dispose();
_phoneCtrl.dispose();
_countryCtrl.dispose();
_ipCtrl.dispose();
_fbCtrl.dispose();
_gmailCtrl.dispose();
_xpCtrl.dispose();
super.dispose();
}

Future<void> _save() async {
if (_usernameCtrl.text.trim().isEmpty && _emailCtrl.text.trim().isEmpty) {
setState(() => _error = 'يرجى إدخال اسم المستخدم أو الإيميل على الأقل');
return;
}
setState(() { _saving = true; _error = null; });
try {
await widget.api.upsertUser({
if (_usernameCtrl.text.trim().isNotEmpty) 'username': _usernameCtrl.text.trim(),
if (_nameCtrl.text.trim().isNotEmpty) 'display_name': _nameCtrl.text.trim(),
if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
if (_phoneCtrl.text.trim().isNotEmpty) 'phone': _phoneCtrl.text.trim(),
if (_countryCtrl.text.trim().isNotEmpty) 'country_name': _countryCtrl.text.trim(),
if (_ipCtrl.text.trim().isNotEmpty) 'last_ip': _ipCtrl.text.trim(),
if (_fbCtrl.text.trim().isNotEmpty) 'facebook_id': _fbCtrl.text.trim(),
if (_gmailCtrl.text.trim().isNotEmpty) 'gmail_email': _gmailCtrl.text.trim(),
'gender': _gender,
'role': _role,
'status': _status,
'level': _level,
'xp': int.tryParse(_xpCtrl.text.trim()) ?? 0,
});
if (mounted) Navigator.pop(context, true);
} catch (e) {
if (mounted) setState(() => _error = 'فشل الحفظ: $e');
} finally {
if (mounted) setState(() => _saving = false);
}
}

@override
Widget build(BuildContext context) {
return Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: const Text('إضافة مستخدم جديد'),
content: SizedBox(
width: 460,
child: SingleChildScrollView(
child: Column(
mainAxisSize: MainAxisSize.min,
children: [
if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'اسم المستخدم', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'الاسم الظاهر', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'الإيميل', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: 'الهاتف', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
TextField(controller: _countryCtrl, decoration: const InputDecoration(labelText: 'الدولة', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
TextField(controller: _ipCtrl, decoration: const InputDecoration(labelText: 'عنوان IP', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
TextField(controller: _fbCtrl, decoration: const InputDecoration(labelText: 'حساب Facebook', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
TextField(controller: _gmailCtrl, decoration: const InputDecoration(labelText: 'حساب Gmail', border: OutlineInputBorder(), isDense: true)),
const SizedBox(height: 8),
Row(children: [
Expanded(
child: DropdownButtonFormField<String>(
value: _gender,
isDense: true,
decoration: const InputDecoration(labelText: 'الجنس', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: 'male', child: Text('ذكر')),
DropdownMenuItem(value: 'female', child: Text('أنثى')),
DropdownMenuItem(value: 'other', child: Text('آخر')),
],
onChanged: (v) => setState(() => _gender = v ?? 'male'),
),
),
const SizedBox(width: 8),
Expanded(
child: DropdownButtonFormField<int>(
value: _level,
isDense: true,
decoration: const InputDecoration(labelText: 'المستوى', border: OutlineInputBorder()),
items: [for (int i = 1; i <= 10; i++) DropdownMenuItem(value: i, child: Text('المستوى $i'))],
onChanged: (v) => setState(() => _level = v ?? 1),
),
),
]),
const SizedBox(height: 8),
Row(children: [
Expanded(
child: DropdownButtonFormField<String>(
value: _role,
isDense: true,
decoration: const InputDecoration(labelText: 'الدور', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: 'user', child: Text('مستخدم')),
DropdownMenuItem(value: 'vip', child: Text('VIP')),
DropdownMenuItem(value: 'moderator', child: Text('مراقب')),
DropdownMenuItem(value: 'admin', child: Text('مشرف عام')),
DropdownMenuItem(value: 'super_admin', child: Text('مدير عام')),
],
onChanged: (v) => setState(() => _role = v ?? 'user'),
),
),
const SizedBox(width: 8),
Expanded(
child: DropdownButtonFormField<String>(
value: _status,
isDense: true,
decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: 'active', child: Text('نشط')),
DropdownMenuItem(value: 'suspended', child: Text('موقوف مؤقتاً')),
DropdownMenuItem(value: 'banned', child: Text('محظور')),
],
onChanged: (v) => setState(() => _status = v ?? 'active'),
),
),
]),
const SizedBox(height: 8),
TextField(controller: _xpCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'نقاط الخبرة XP', border: OutlineInputBorder(), isDense: true)),
],
),
),
),
actions: [
TextButton(onPressed: _saving ? null : () => Navigator.pop(context, false), child: const Text('إلغاء')),
ElevatedButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'جاري الحفظ...' : 'حفظ')),
],
),
);
}
}

class _UserDetailsDialog extends StatefulWidget {
final HalaaCentralAdminApi api;
final String userId;
final Map<String, dynamic> initialUser;
const _UserDetailsDialog({required this.api, required this.userId, required this.initialUser});
@override
State<_UserDetailsDialog> createState() => _UserDetailsDialogState();
}

class _UserDetailsDialogState extends State<_UserDetailsDialog> {
bool _loading = true;
bool _saving = false;
bool _dirty = false;
String? _error;
Map<String, dynamic> _profile = {};
List<Map<String, dynamic>> _levels = [];
List<Map<String, dynamic>> _permissions = [];
List<Map<String, dynamic>> _ipLogs = [];
List<Map<String, dynamic>> _rooms = [];
int _level = 1;
String _role = 'user';
String _status = 'active';
final TextEditingController _xpCtrl = TextEditingController();

@override
void initState() {
super.initState();
_profile = Map<String, dynamic>.from(widget.initialUser);
_syncControllers();
_loadAll();
}

void _syncControllers() {
_level = ((_profile['level'] as num?)?.toInt() ?? 1).clamp(1, 10);
_role = (_profile['role'] ?? 'user').toString();
_status = (_profile['status'] ?? 'active').toString();
_xpCtrl.text = (_profile['xp'] ?? 0).toString();
}

@override
void dispose() {
_xpCtrl.dispose();
super.dispose();
}

Future<void> _loadAll() async {
setState(() { _loading = true; _error = null; });
try {
final results = await Future.wait([
widget.api.getUserFullProfile(widget.userId),
widget.api.getUserLevelsAndPermissions(),
]);
final prof = results[0];
final lvlRes = results[1];
if (!mounted) return;
setState(() {
_profile = prof;
_syncControllers();
_levels = ((lvlRes['levels'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
final rawPerms = (prof['permissions'] as List?) ?? (lvlRes['permissions'] as List?) ?? const [];
_permissions = rawPerms.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
_ipLogs = ((prof['ip_logs'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
_rooms = ((prof['rooms'] as List?) ?? const []).whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
});
} catch (e) {
if (mounted) setState(() => _error = 'تعذر تحميل تفاصيل المستخدم: $e');
} finally {
if (mounted) setState(() => _loading = false);
}
}

Future<void> _saveChanges() async {
setState(() { _saving = true; _error = null; });
try {
await widget.api.updateUser(widget.userId, {
'level': _level,
'xp': int.tryParse(_xpCtrl.text.trim()) ?? 0,
'role': _role,
'status': _status,
});
_dirty = true;
await _loadAll();
if (mounted) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم تحديث بيانات المستخدم بنجاح')));
}
} catch (e) {
if (mounted) setState(() => _error = 'فشل تحديث البيانات: $e');
} finally {
if (mounted) setState(() => _saving = false);
}
}

Future<void> _togglePermission(String code, bool granted) async {
try {
await widget.api.setUserPermission(widget.userId, permissionCode: code, granted: granted, grantedBy: 'admin');
_dirty = true;
await _loadAll();
} catch (e) {
if (mounted) setState(() => _error = 'فشل تحديث الصلاحية: $e');
}
}

@override
Widget build(BuildContext context) {
final name = (_profile['display_name'] ?? _profile['username'] ?? widget.userId).toString();
final email = (_profile['email'] ?? '-').toString();
final phone = (_profile['phone'] ?? '-').toString();
final fb = (_profile['facebook_id'] ?? '').toString();
final gmail = (_profile['gmail_email'] ?? _profile['google_id'] ?? '').toString();
return Directionality(
textDirection: TextDirection.rtl,
child: AlertDialog(
title: Row(
children: [
Expanded(child: Text('ملف المستخدم: $name')),
IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _loadAll),
],
),
content: SizedBox(
width: 560,
height: 560,
child: _loading
? const Center(child: CircularProgressIndicator())
: SingleChildScrollView(
child: Column(
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
if (_error != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(_error!, style: const TextStyle(color: Colors.red))),
Text('المعرف: ${widget.userId} • الإيميل: $email • الهاتف: $phone', style: const TextStyle(fontSize: 12)),
Text('Facebook: ${fb.isEmpty ? "غير مرتبط" : fb} • Gmail: ${gmail.isEmpty ? "غير مرتبط" : gmail}', style: const TextStyle(fontSize: 12)),
const Divider(height: 18),
const Text('تعديل المستوى والدور والحالة', style: TextStyle(fontWeight: FontWeight.bold)),
const SizedBox(height: 8),
Row(children: [
Expanded(
child: DropdownButtonFormField<int>(
value: _level,
isDense: true,
decoration: const InputDecoration(labelText: 'المستوى (1-10)', border: OutlineInputBorder()),
items: [
for (int i = 1; i <= 10; i++)
DropdownMenuItem(
value: i,
child: Text(_levels.any((l) => (l['level'] as num?)?.toInt() == i)
? 'المستوى $i - ${_levels.firstWhere((l) => (l['level'] as num?)?.toInt() == i)['title_ar'] ?? ''}'
: 'المستوى $i'),
),
],
onChanged: (v) => setState(() => _level = v ?? 1),
),
),
const SizedBox(width: 8),
Expanded(
child: TextField(
controller: _xpCtrl,
keyboardType: TextInputType.number,
decoration: const InputDecoration(labelText: 'XP', border: OutlineInputBorder(), isDense: true),
),
),
]),
const SizedBox(height: 8),
Row(children: [
Expanded(
child: DropdownButtonFormField<String>(
value: ['user', 'vip', 'moderator', 'admin', 'super_admin'].contains(_role) ? _role : 'user',
isDense: true,
decoration: const InputDecoration(labelText: 'الدور', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: 'user', child: Text('مستخدم')),
DropdownMenuItem(value: 'vip', child: Text('VIP')),
DropdownMenuItem(value: 'moderator', child: Text('مراقب')),
DropdownMenuItem(value: 'admin', child: Text('مشرف عام')),
DropdownMenuItem(value: 'super_admin', child: Text('مدير عام')),
],
onChanged: (v) => setState(() => _role = v ?? 'user'),
),
),
const SizedBox(width: 8),
Expanded(
child: DropdownButtonFormField<String>(
value: ['active', 'suspended', 'banned'].contains(_status) ? _status : 'active',
isDense: true,
decoration: const InputDecoration(labelText: 'الحالة', border: OutlineInputBorder()),
items: const [
DropdownMenuItem(value: 'active', child: Text('نشط')),
DropdownMenuItem(value: 'suspended', child: Text('موقوف مؤقتاً')),
DropdownMenuItem(value: 'banned', child: Text('محظور')),
],
onChanged: (v) => setState(() => _status = v ?? 'active'),
),
),
]),
const SizedBox(height: 8),
ElevatedButton.icon(
onPressed: _saving ? null : _saveChanges,
icon: const Icon(Icons.save, size: 18),
label: Text(_saving ? 'جاري الحفظ...' : 'حفظ التعديلات'),
),
const Divider(height: 20),
Text('الصلاحيات الفردية (${_permissions.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
if (_permissions.isEmpty) const Text('لا توجد صلاحيات مسجلة', style: TextStyle(fontSize: 12, color: Colors.black54)),
..._permissions.map((p) {
final code = (p['code'] ?? '').toString();
final label = (p['label_ar'] ?? code).toString();
final granted = p['granted'] == true || p['granted'] == 1;
final source = (p['source'] ?? 'role').toString();
return SwitchListTile(
dense: true,
title: Text(label, style: const TextStyle(fontSize: 13)),
subtitle: Text('$code • المصدر: ${source == 'user' ? 'تخصيص فردي' : 'الدور'}', style: const TextStyle(fontSize: 11)),
value: granted,
onChanged: code.isEmpty ? null : (v) => _togglePermission(code, v),
);
}),
const Divider(height: 20),
Text('سجل عناوين IP (${_ipLogs.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
if (_ipLogs.isEmpty) const Text('لا يوجد سجل IP بعد', style: TextStyle(fontSize: 12, color: Colors.black54)),
..._ipLogs.map((ip) => ListTile(
dense: true,
leading: const Icon(Icons.public, size: 18),
title: Text('${ip['ip_address'] ?? '-'} (${ip['country'] ?? '-'})', style: const TextStyle(fontSize: 12)),
subtitle: Text('${ip['action'] ?? ''} • ${ip['created_at'] ?? ''}', style: const TextStyle(fontSize: 11)),
)),
const Divider(height: 20),
Text('الغرف التي أنشأها المستخدم (${_rooms.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
if (_rooms.isEmpty) const Text('لم ينشئ المستخدم غرفاً بعد', style: TextStyle(fontSize: 12, color: Colors.black54)),
..._rooms.map((r) => ListTile(
dense: true,
leading: const Icon(Icons.meeting_room, size: 18),
title: Text('${r['title_ar'] ?? r['room_id'] ?? '-'}', style: const TextStyle(fontSize: 12)),
subtitle: Text('المعرف: ${r['room_id'] ?? '-'} • المستوى: ${r['room_level'] ?? 1} • المايكات: ${r['mic_count'] ?? 0} • ${r['status'] ?? ''}', style: const TextStyle(fontSize: 11)),
)),
],
),
),
),
actions: [
TextButton(onPressed: () => Navigator.pop(context, _dirty), child: const Text('إغلاق')),
],
),
);
}
}

