import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const apiBaseUrl = String.fromEnvironment('HALAA_API_URL');
const bg = Color(0xFF170A29);
const gold = Color(0xFFFFD57A);
const purple = Color(0xFF6632A2);

void main() => runApp(const HalaaApp());

class HalaaApp extends StatelessWidget {
  const HalaaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هلاا Halaa',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: purple,
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(backgroundColor: bg, foregroundColor: gold),
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HalaaHome(),
      ),
    );
  }
}

class HalaaHome extends StatefulWidget {
  const HalaaHome({super.key});

  @override
  State<HalaaHome> createState() => _HalaaHomeState();
}

class _HalaaHomeState extends State<HalaaHome> {
  int page = 0;
  String country = 'الكل';
  String search = '';
  late final Future<int>? roomCount = apiBaseUrl.isEmpty ? null : _fetchRoomCount();

  final rooms = const [
    ('المجلس الملكي', '🇸🇦', 'السعودية', 256),
    ('لمة الأصدقاء', '🇸🇩', 'السودان', 189),
    ('نجوم هلاا', '🇮🇶', 'العراق', 412),
    ('سهرات عربية', '🇪🇬', 'مصر', 97),
  ];
  final games = const ['🎲 ليدو', '🎱 بلياردو', '♟️ شطرنج', '🁫 دومينو', '🃏 طرنيب'];

  Future<int> _fetchRoomCount() async {
    final response = await http
        .get(Uri.parse('$apiBaseUrl/v1/rooms'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) {
      throw Exception('API unavailable');
    }
    final data = jsonDecode(utf8.decode(response.bodyBytes));
    if (data is List) return data.length;
    if (data is Map && data['rooms'] is List) {
      return (data['rooms'] as List).length;
    }
    throw const FormatException('Unexpected rooms response');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👑 هلاا  Halaa', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          const Center(child: Text('🪙 رصيد تجريبي', style: TextStyle(color: gold))),
          IconButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('الإشعارات قيد التطوير')),
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [Color(0xFF6632A2), Color(0xFF28103F)],
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.mic, size: 54, color: gold),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('هلاا — عالمك الصوتي',
                            style: TextStyle(color: gold, fontSize: 21, fontWeight: FontWeight.bold)),
                        Text('غرف صوتية • ألعاب • هدايا فاخرة'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: page == 0
                  ? _rooms()
                  : page == 1
                      ? ListView(
                          children: games.map((g) => Card(
                            child: ListTile(
                              title: Text(g),
                              subtitle: const Text('قيد التطوير'),
                              trailing: const Icon(Icons.sports_esports),
                            ),
                          )).toList(),
                        )
                      : Center(
                          child: Text('${['الغرف', 'الألعاب', 'اللحظات', 'المتجر', 'حسابي'][page]} — قيد التطوير'),
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: page,
        onDestinationSelected: (i) => setState(() => page = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.mic), label: 'الغرف'),
          NavigationDestination(icon: Icon(Icons.sports_esports), label: 'الألعاب'),
          NavigationDestination(icon: Icon(Icons.auto_awesome), label: 'اللحظات'),
          NavigationDestination(icon: Icon(Icons.store), label: 'المتجر'),
          NavigationDestination(icon: Icon(Icons.person), label: 'حسابي'),
        ],
      ),
    );
  }

  Widget _rooms() {
    final visible = rooms.where((r) =>
        (country == 'الكل' || r.$3 == country) && r.$1.contains(search)).toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: TextField(
            onChanged: (v) => setState(() => search = v),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ابحث عن غرفة',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(18)),
            ),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['الكل', 'السعودية', 'السودان', 'العراق', 'مصر'].map((c) =>
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: ChoiceChip(
                  label: Text(c),
                  selected: country == c,
                  onSelected: (_) => setState(() => country = c),
                ),
              ),
            ).toList(),
          ),
        ),
        if (roomCount != null)
          FutureBuilder<int>(
            future: roomCount,
            builder: (context, snapshot) => Text(
              snapshot.hasError
                  ? 'تعذر الاتصال بالخادم التجريبي'
                  : snapshot.hasData
                      ? 'الغرف على الخادم: ${snapshot.data}'
                      : 'جاري الاتصال بالخادم...',
              style: const TextStyle(color: gold),
            ),
          ),
        Expanded(
          child: ListView(
            children: visible.map((r) => Card(
              margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              child: ListTile(
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: purple,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.mic, color: gold),
                ),
                title: Text(r.$1, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${r.$2}  ${r.$4} مشارك (تجريبي)'),
                trailing: const Icon(Icons.chevron_left, color: gold),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => RoomPreview(name: r.$1)),
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }
}

class RoomPreview extends StatelessWidget {
  final String name;
  const RoomPreview({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: Text(name)),
        body: Column(
          children: [
            const SizedBox(height: 28),
            const CircleAvatar(
              radius: 44,
              backgroundColor: purple,
              child: Icon(Icons.workspace_premium, size: 50, color: gold),
            ),
            const SizedBox(height: 10),
            const Text('غرفة صوتية تجريبية',
                style: TextStyle(fontSize: 22, color: gold)),
            const SizedBox(height: 28),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                children: List.generate(8, (i) => Column(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: purple,
                      child: Icon(i < 4 ? Icons.person : Icons.add, color: gold),
                    ),
                    Text(i < 4 ? 'مشارك ${i + 1}' : 'مقعد فارغ',
                        style: const TextStyle(fontSize: 11)),
                  ],
                )),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('هذه معاينة محلية. الصوت والهدايا والمحادثة الحقيقية غير متصلة بعد.'),
            ),
          ],
        ),
      ),
    );
  }
}
