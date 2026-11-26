import 'package:flutter/material.dart';
import '../../core/api/halaa_central_admin_api.dart';

/// Drop-in Central Control, Sync Monitor, Remote Feature Switches & Emergency Panel
/// for Halaa Admin App (Sections 11, 14, 23, 34, 39).
/// Every toggle is wired directly to the central server and includes an Arabic info button.
class CentralControlPanelWidget extends StatefulWidget {
  final HalaaCentralAdminApi api;
  const CentralControlPanelWidget({super.key, required this.api});

  @override
  State<CentralControlPanelWidget> createState() => _CentralControlPanelWidgetState();
}

class _CentralControlPanelWidgetState extends State<CentralControlPanelWidget> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _syncStatus = const {};
  Map<String, dynamic> _features = const {};
  List<dynamic> _auditLogs = const [];

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  Future<void> _refreshAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        widget.api.fetchSyncStatus(),
        widget.api.fetchConfig(),
        widget.api.fetchAuditLogs(),
      ]);
      if (!mounted) return;
      final cfg = (results[1]['config'] as Map<String, dynamic>?)?['value'] as Map<String, dynamic>?;
      setState(() {
        _syncStatus = (results[0]['status'] as Map<String, dynamic>?) ?? const {};
        _features = (cfg?['features'] as Map<String, dynamic>?) ?? const {};
        _auditLogs = (results[2]['logs'] as List<dynamic>?) ?? const [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _manageRoom() async {
    final room = TextEditingController(text: 'r1');
    final target = TextEditingController();
    var action = 'listener';
    final confirmed = await showDialog<bool>(context: context, builder: (context) => StatefulBuilder(
      builder: (context, update) => AlertDialog(title: const Text('إدارة عضو في غرفة صوتية'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: room, decoration: const InputDecoration(labelText:'معرّف الغرفة')),
          TextField(controller: target, decoration: const InputDecoration(labelText:'معرّف العضو')),
          DropdownButton<String>(value:action, isExpanded:true, items: const [
            DropdownMenuItem(value:'listener',child:Text('إيقاف الميكروفون')),
            DropdownMenuItem(value:'speaker',child:Text('السماح بالميكروفون')),
            DropdownMenuItem(value:'ban',child:Text('منع الدخول')),
            DropdownMenuItem(value:'unban',child:Text('رفع المنع')),
          ], onChanged:(value) => update(() => action=value!)),
        ]), actions:[TextButton(onPressed:()=>Navigator.pop(context,false),child:const Text('إلغاء')),
          FilledButton(onPressed:()=>Navigator.pop(context,true),child:const Text('تطبيق'))]),
    ));
    if (confirmed == true) {
      try {
        await widget.api.manageVoiceRoom(room:room.text.trim(),target:target.text.trim(),action:action);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('تم حفظ التحكم؛ يتزامن التطبيق خلال 20 ثانية')));
      } catch (error) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text(error.toString())));
      }
    }
    room.dispose(); target.dispose();
  }

  Future<void> _toggleFeature({
    required String label,
    required Map<String, dynamic> patch,
  }) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('تأكيد تعديل: $label'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            labelText: 'سبب التعديل (إلزامي للسجل الرقابي)',
            hintText: 'مثال: صيانة مؤقتة للعبة',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('تطبيق ومزامنة')),
        ],
      ),
    );
    if (confirmed != true) return;
    final reason = reasonController.text.trim();
    if (reason.length < 3) return;

    try {
      await widget.api.updateConfig(patch: {'features': patch}, reason: reason);
      await _refreshAll();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('فشل التعديل: $e')));
    }
  }

  void _showPermissionInfo({
    required String title,
    required String code,
    required String risk,
    required String impact,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('المعرف البرمجي: $code'),
            const SizedBox(height: 6),
            Text('مستوى الخطورة: $risk'),
            const SizedBox(height: 6),
            Text('التأثير: $impact'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('إغلاق')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('تعذر الاتصال بالخادم المركزي:\n$_error', textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _refreshAll, child: const Text('إعادة المحاولة')),
          ],
        ),
      );
    }

    final games = (_features['games'] as Map<String, dynamic>?) ?? const {};

    return Directionality(
      textDirection: TextDirection.rtl,
      child: RefreshIndicator(
        onRefresh: _refreshAll,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(child: ListTile(leading: const Icon(Icons.mic), title: const Text('إدارة الغرف والميكروفونات'),
              trailing: const Icon(Icons.chevron_right), onTap: _manageRoom)),
            Card(
              child: ListTile(
                title: const Text('مركز المزامنة والتحديثات المباشرة'),
                subtitle: Text(
                  'إصدار الإعدادات: ${_syncStatus['configVersion'] ?? '-'} • '
                  'إصدار الثيم: ${_syncStatus['themeVersion'] ?? '-'} • '
                  'الأجهزة المتصلة: ${_syncStatus['connectedListeners'] ?? 0} • '
                  'تأكيدات الاستقبال: ${_syncStatus['latestEventAcknowledgedDevices'] ?? 0}',
                ),
                trailing: IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshAll),
              ),
            ),
            const SizedBox(height: 12),
            const Text('التحكم المباشر في خصائص وألعاب التطبيق', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSwitchRow(
              title: 'الغرف الصوتية',
              value: _features['voiceRooms'] == true,
              permCode: 'config.update',
              risk: 'المستوى 3 (حساس)',
              impact: 'تفعيل أو إيقاف الغرف الصوتية عن بعد على الخادم والأجهزة فورًا',
              onChanged: (v) => _toggleFeature(label: 'الغرف الصوتية', patch: {'voiceRooms': v}),
            ),
            _buildSwitchRow(
              title: 'الهدايا والمؤثرات',
              value: _features['gifts'] == true,
              permCode: 'config.update',
              risk: 'المستوى 3 (حساس)',
              impact: 'تفعيل أو إيقاف إرسال الهدايا داخل التطبيق فورًا',
              onChanged: (v) => _toggleFeature(label: 'الهدايا', patch: {'gifts': v}),
            ),
            for (final entry in const [
              ('ludo', 'لعبة ليدو'),
              ('billiards', 'لعبة البلياردو'),
              ('chess', 'لعبة الشطرنج'),
              ('domino', 'لعبة الدومينو'),
              ('tarneeb', 'لعبة الطرنيب'),
            ])
              _buildSwitchRow(
                title: entry.$2,
                value: games[entry.$1] == true,
                permCode: 'games.config.update',
                risk: 'المستوى 2 (تشغيلي)',
                impact: 'إيقاف أو تشغيل ${entry.$2} دون التأثير على بقية الألعاب أو الغرف',
                onChanged: (v) => _toggleFeature(
                  label: entry.$2,
                  patch: {
                    'games': {entry.$1: v},
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text('آخر عمليات السجل الرقابي (${_auditLogs.length})', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            for (final log in _auditLogs.take(10))
              ListTile(
                dense: true,
                leading: const Icon(Icons.verified_user, size: 18),
                title: Text('${log['action']} — ${log['result']}'),
                subtitle: Text('السبب: ${log['reason'] ?? '-'} • ${log['createdAt'] ?? ''}'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required String title,
    required bool value,
    required String permCode,
    required String risk,
    required String impact,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      child: ListTile(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.info_outline),
          tooltip: 'شرح الصلاحية ومستوى الخطورة',
          onPressed: () => _showPermissionInfo(title: title, code: permCode, risk: risk, impact: impact),
        ),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}
