import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'live_room_web.dart' if (dart.library.io) 'live_room_native.dart';

class HalaaLiveRoomScreen extends StatefulWidget {
  const HalaaLiveRoomScreen({super.key, required this.roomId, required this.title,
    required this.serverEndpoint, this.accessToken, this.onSignIn});
  final String roomId, title, serverEndpoint;
  final VoidCallback? onSignIn;
  final Future<String> Function()? accessToken;
  @override
  State<HalaaLiveRoomScreen> createState() => _HalaaLiveRoomScreenState();
}

class _HalaaLiveRoomScreenState extends State<HalaaLiveRoomScreen> {
  late final Future<Map<String, dynamic>> _session = _loadSession();
  Map<String, dynamic>? _lastSession;
  Map<String, dynamic> get _roomConfig => (_lastSession?['roomConfig'] is Map) ? Map<String, dynamic>.from(_lastSession!['roomConfig'] as Map) : const <String, dynamic>{};
  bool _boolConfig(String key, {bool fallback = true}) => _roomConfig[key] is bool ? _roomConfig[key] as bool : fallback;
  Timer? _giftPoll, _effectTimer;
  final Set<String> _seenGifts = {};
  bool _giftBaseline = false, _polling = false;
  String? _effect;
  late final String _guestId = 'guest_${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}_${identityHashCode(this).toRadixString(36)}';
  Future<String> _resolveToken() async { final auth = widget.accessToken; if (auth == null) return ''; try { return (await auth()).trim(); } catch (_) { return ''; } }
  @override
  void initState() {
    super.initState();
    _giftPoll = Timer.periodic(const Duration(seconds: 3), (_) => _pollGifts());
  }
  Future<Map<String, dynamic>> _request(String path, {Map<String, dynamic>? body}) async {
    final token = await _resolveToken();
    final isGuest = token.isEmpty;
    final base = Uri.parse(widget.serverEndpoint);
    if (base.scheme != 'https' || base.host != 'halla.onrender.com') throw Exception('عنوان الخادم غير صالح');
    final headers = {'Content-Type': 'application/json', if (!isGuest) 'Authorization': 'Bearer $token', if (isGuest) 'X-Guest-Id': _guestId};
    if (body != null && isGuest) body = <String, dynamic>{...body, 'guest': true};
    final response = body == null
      ? await http.get(base.resolve(path), headers: headers).timeout(const Duration(seconds: 20))
      : await http.post(base.resolve(path), headers: headers, body: jsonEncode(body)).timeout(const Duration(seconds: 20));
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(data['error'] ?? 'فشل تنفيذ الطلب');
    return data;
  }
  Future<Map<String, dynamic>> _updateSeat(int? index) async {
    if (index != null && (await _resolveToken()).isEmpty && !_boolConfig('allowGuestMic')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('المشاركة بالمايك غير متاحة للضيوف في هذه الغرفة')));
      return _lastSession ?? await _loadSession();
    }
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
    if (!_boolConfig('allowGifts')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الهدايا معطلة في هذه الغرفة')));
      return;
    }
    if ((await _resolveToken()).isEmpty && !_boolConfig('allowGuestGifts')) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('إرسال الهدايا غير متاح للضيوف في هذه الغرفة')));
      return;
    }
    final giftId = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(padding: EdgeInsets.all(12), child: Text('اختر هدية', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
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
    var token = ''; if (auth != null) { try { token = (await auth()).trim(); } catch (_) { /* guest fallback */ } } final isGuest = token.isEmpty;
    final base = Uri.parse(widget.serverEndpoint);
    if (base.scheme != 'https' || base.host != 'halla.onrender.com') {
        throw Exception('عنوان الخادم غير صالح');
    }
    final response = await http.post(base.resolve('/api/zego-token'),
      headers: {'Content-Type': 'application/json', if (!isGuest) 'Authorization': 'Bearer $token' , if (isGuest) 'X-Guest-Id': _guestId }, 
      body: jsonEncode({'room': widget.roomId, if (isGuest) 'guest': true})).timeout(const Duration(seconds: 20));
    final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      if (response.statusCode != 200) throw Exception(data['error'] ?? 'فشل تحميل بيانات الغرفة');
      if (data['appID'] != 828861219) throw Exception('بيانات الغرفة غير صالحة');
    _lastSession = data;
    return data;
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<Map<String, dynamic>>(
      future: _session,
      builder: (context, snapshot) {
        if (snapshot.hasError && widget.onSignIn != null) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('انتهت الجلسة أو يلزم تسجيل الدخول'),
            const SizedBox(height: 12),
            FilledButton(onPressed: () {
              Navigator.of(context).pop();
              widget.onSignIn?.call();
          }, child: const Text('تسجيل الدخول')),
          ]));
        }
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
