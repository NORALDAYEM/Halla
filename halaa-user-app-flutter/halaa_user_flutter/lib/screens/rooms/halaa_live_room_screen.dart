import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'live_room_web.dart' if (dart.library.io) 'live_room_native.dart';

class HalaaLiveRoomScreen extends StatefulWidget {
  const HalaaLiveRoomScreen({super.key, required this.roomId, required this.title,
    required this.serverEndpoint, this.accessToken});
  final String roomId, title, serverEndpoint;
  final Future<String> Function()? accessToken;
  @override
  State<HalaaLiveRoomScreen> createState() => _HalaaLiveRoomScreenState();
}

class _HalaaLiveRoomScreenState extends State<HalaaLiveRoomScreen> {
  late final Future<Map<String, dynamic>> _session = _loadSession();
  Timer? _giftPoll, _effectTimer;
  final Set<String> _seenGifts = {};
  bool _giftBaseline = false, _polling = false;
  String? _effect;
  @override
  void initState() {
    super.initState();
    _giftPoll = Timer.periodic(const Duration(seconds: 3), (_) => _pollGifts());
  }
  Future<Map<String, dynamic>> _request(String path, {Map<String, dynamic>? body}) async {
    final auth = widget.accessToken;
    if (auth == null) throw Exception('سجّل الدخول للانضمام إلى الغرفة');
    final base = Uri.parse(widget.serverEndpoint);
    if (base.scheme != 'https' || base.host != 'halla.onrender.com') throw Exception('عنوان خادم غير معتمد');
    final headers = {'Authorization': 'Bearer ${await auth()}', 'Content-Type': 'application/json'};
    final response = body == null
      ? await http.get(base.resolve(path), headers: headers).timeout(const Duration(seconds: 20))
      : await http.post(base.resolve(path), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'تعذر إتمام العملية');
    return data;
  }
  Future<Map<String, dynamic>> _updateSeat(int? index) async {
    await _request('/api/seat', body: {'room': widget.roomId, 'action': index == null ? 'release' : 'take', 'index': index});
    return _loadSession();
  }
  Future<void> _pollGifts() async {
    if (_polling) return;
    _polling = true;
    try {
      final data = await _request('/api/gifts?room=${Uri.encodeQueryComponent(widget.roomId)}');
      for (final item in data['gifts'] as List<dynamic>) {
        final gift = item as Map<String, dynamic>;
        if (_seenGifts.add(gift['transactionGroup'] as String) && _giftBaseline && mounted) {
          _showEffect(gift['effect'] as String);
        }
      }
      _giftBaseline = true;
    } catch (_) { /* A temporary network failure must not interrupt the room. */ }
    finally { _polling = false; }
  }
  void _showEffect(String effect) {
    if (!mounted) return;
    _effectTimer?.cancel();
    setState(() => _effect = effect == 'crown' ? '👑' : '🌹');
    SystemSound.play(SystemSoundType.click);
    _effectTimer = Timer(const Duration(seconds: 3), () { if (mounted) setState(() => _effect = null); });
  }
  Future<void> _sendGift(String recipientId) async {
    final giftId = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: const Text('🌹 وردة — 10 عملات'), onTap: () => Navigator.pop(context, 'rose')),
        ListTile(title: const Text('👑 تاج — 100 عملة'), onTap: () => Navigator.pop(context, 'crown')),
      ]),
    ));
    if (giftId == null || !mounted) return;
    // A single key is retained for this operation; transport retries must reuse it.
    final key = List.generate(24, (_) => Random.secure().nextInt(16).toRadixString(16)).join();
    try {
      final result = await _request('/api/gifts', body: {'room':widget.roomId,'recipientId':recipientId,'giftId':giftId,'idempotencyKey':key});
      _seenGifts.add(result['transactionGroup'] as String);
      _showEffect(result['effect'] as String);
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }
  @override
  void dispose() {
    _giftPoll?.cancel(); _effectTimer?.cancel();
    unawaited(_request('/api/seat', body:{'room':widget.roomId,'action':'release'}).catchError((_) => <String,dynamic>{}));
    super.dispose();
  }
  Future<Map<String, dynamic>> _loadSession() async {
    final auth = widget.accessToken;
    final token = auth == null ? '' : (await auth()).trim(); final isGuest = token.isEmpty;
    final base = Uri.parse(widget.serverEndpoint);
    if (base.scheme != 'https' || base.host != 'halla.onrender.com') {
      throw Exception('عنوان خادم الغرف غير معتمد');
    }
    final response = await http.post(base.resolve('/api/zego-token'),
      headers: {'Content-Type': 'application/json', if (!isGuest) 'Authorization': 'Bearer $token'},
      body: jsonEncode({'room': widget.roomId, if (isGuest) 'guest': true})).timeout(const Duration(seconds: 20));
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    if (response.statusCode != 200) throw Exception(data['error'] ?? 'تعذر الاتصال بالغرفة');
    if (data['appID'] != 828861219) throw Exception('إعداد مشروع الصوت لا يطابق التطبيق');
    return data;
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24),
          child: Text(snapshot.error.toString(), textAlign: TextAlign.center)));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return Stack(children: [
          HalaaRoomKit(session: snapshot.data!, renew: _loadSession, updateSeat: _updateSeat, sendGift: _sendGift),
          IgnorePointer(child: Center(child: AnimatedSwitcher(duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: FadeTransition(opacity: animation, child: child)),
            child: _effect == null ? const SizedBox.shrink() : Text(_effect!, key: ValueKey(_effect), style: const TextStyle(fontSize: 110))))),
        ]);
      },
    ),
  );
}
