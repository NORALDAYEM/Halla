import 'package:flutter/material.dart';

void main() => runApp(const HalaaAdmin());

class HalaaAdmin extends StatelessWidget {
  const HalaaAdmin({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Halaa Control Center', debugShowCheckedModeBanner: false,
    theme: ThemeData.dark(useMaterial3: true),
    home: const Directionality(textDirection: TextDirection.rtl, child: AdminScreen()),
  );
}

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  String selectedTheme = 'البنفسجي الملكي';
  bool banner = true;
  final themes = const ['البنفسجي الملكي', 'الأسود الذهبي', 'الأزرق الألماسي', 'الأحمر المميز', 'الأخضر الهادئ', 'الوردي الأنيق'];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('👑 مركز تحكم هلاا')),
    body: ListView(padding: const EdgeInsets.all(16), children: [
      const Text('لوحة الإدارة التجريبية', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      const Text('هذه واجهة محلية للتصميم، وليست نظام دخول أو إدارة متصلاً بالخادم.'),
      const SizedBox(height: 22),
      const Text('استوديو الثيمات', style: TextStyle(fontSize: 20)),
      DropdownButton<String>(isExpanded: true, value: selectedTheme, items: themes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(), onChanged: (v) => setState(() => selectedTheme = v!)),
      SwitchListTile(title: const Text('إظهار البنر الرئيسي'), value: banner, onChanged: (v) => setState(() => banner = v)),
      const Divider(),
      for (final item in ['المستخدمون والصلاحيات', 'الغرف والمقاعد', 'الألعاب', 'الهدايا والعملات', 'اللحظات', 'التقارير المالية', 'الإعدادات والأمان'])
        ListTile(title: Text(item), trailing: const Icon(Icons.chevron_left), onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$item — قيد التطوير')))),
    ]),
  );
}
