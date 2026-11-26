import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/halaa_themes.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_live_audio_room/zego_uikit_prebuilt_live_audio_room.dart';

class HalaaRoomKit extends StatefulWidget {
  const HalaaRoomKit({super.key, required this.session, required this.renew, required this.updateSeat, required this.sendGift});
  final Map<String, dynamic> session;
  final Future<Map<String, dynamic>> Function() renew;
  final Future<Map<String, dynamic>> Function(int?) updateSeat;
  final Future<void> Function(String) sendGift;
  @override
  State<HalaaRoomKit> createState() => _HalaaRoomKitState();
}

class _HalaaRoomKitState extends State<HalaaRoomKit> {
  HalaaThemePreset? _roomTheme;
  String _backdrop = '';
  static const _gallery = {
    '': 'تدرّج لوني',
    'headphones': 'سماعات',
    'chessboard': 'رقعة الشطرنج',
    'chess-pieces': 'قطع الشطرنج',
    'game-table': 'طاولة الألعاب',
    'ludo-friends': 'أصدقاء اللودو',
    'pool-friends': 'أصدقاء البلياردو',
    'pool-table': 'طاولة البلياردو',
  };

  Future<void> _chooseAppearance() async {
    var theme = _roomTheme;
    var backdrop = _backdrop;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(builder: (sheet, update) => SafeArea(
        child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('مظهر الغرفة على جهازك', style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('ثيم التطبيق'), selected: theme == null,
                onSelected: (_) => update(() => theme = null)),
              for (final preset in kHalaaThemes)
                ChoiceChip(label: Text(preset.name), selected: theme == preset,
                  avatar: CircleAvatar(backgroundColor: preset.primary),
                  onSelected: (_) => update(() => theme = preset)),
            ]),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: backdrop,
              decoration: const InputDecoration(labelText: 'خلفية الغرفة'),
              items: [for (final entry in _gallery.entries)
                DropdownMenuItem(value: entry.key, child: Text(entry.value))],
              onChanged: (value) => update(() => backdrop = value ?? ''),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(sheet, true), child: const Text('تطبيق')),
          ],
        )),
      )),
    );
    if (applied == true && mounted) setState(() {
      _roomTheme = theme;
      _backdrop = backdrop;
    });
  }

  Timer? _heartbeat;
  bool _renewing = false;
  int? _seatIndex;
  late final ZegoUIKitPrebuiltLiveAudioRoomConfig _config;
  final _controller = ZegoUIKitPrebuiltLiveAudioRoomController();
  @override
  void initState() {
    super.initState();
    _config = widget.session['role'] == 'owner'
      ? ZegoUIKitPrebuiltLiveAudioRoomConfig.host()
      : ZegoUIKitPrebuiltLiveAudioRoomConfig.audience();
    _config.seat.layout.rowConfigs = [
      ZegoLiveAudioRoomLayoutRowConfig(count: 1),
      ZegoLiveAudioRoomLayoutRowConfig(count: 4),
      ZegoLiveAudioRoomLayoutRowConfig(count: 4),
    ];
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) => _renew());
  }
  Future<void> _renew() async {
    if (_renewing) return;
    _renewing = true;
    try {
      final next = await widget.renew();
      if (!mounted) return;
      await _controller.room.renewToken(next['token'] as String);
      if (next['role'] == 'listener' && _seatIndex != null) {
        await _controller.seat.speaker.leave(showDialog: false);
      }
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    } finally { _renewing = false; }
  }
  Future<void> _seatChanged(int? index) async {
    if (_seatIndex == index) return;
    _seatIndex = index;
    try {
      final next = await widget.updateSeat(index);
      if (mounted) {
        await _controller.room.renewToken(next['token'] as String);
        if (index != null && next['role'] != 'listener') ZegoUIKit().turnMicrophoneOn(true);
      }
    } catch (_) {
      if (mounted) await _controller.seat.speaker.leave(showDialog: false);
    }
  }
  @override
  void dispose() { _heartbeat?.cancel(); super.dispose(); }
  Future<void> _chooseRecipient() async {
    final members = ZegoUIKit().getAllUsers().where((u) => u.id != widget.session['userID']).toList();
    final recipient = await showModalBottomSheet<String>(context: context, builder: (context) => SafeArea(
      child: ListView(shrinkWrap: true, children: [
        const ListTile(title: Text('إرسال هدية إلى')),
        if (members.isEmpty) const ListTile(title: Text('لا يوجد أعضاء آخرون في الغرفة')),
        for (final user in members) ListTile(title: Text(user.name), onTap: () => Navigator.of(context).pop(user.id)),
      ]),
    ));
    if (recipient != null && mounted) await widget.sendGift(recipient);
  }
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final base = _roomTheme?.bgDark ?? colors.surface;
    final tint = _roomTheme?.primaryDark ?? colors.primaryContainer;
    _config.background = DecoratedBox(decoration: BoxDecoration(
      gradient: LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
        colors: [tint, base]),
      image: _backdrop.isEmpty ? null : DecorationImage(
        image: AssetImage('assets/images/welcome-gallery/$_backdrop.webp'),
        fit: BoxFit.cover,
        colorFilter: ColorFilter.mode(base.withOpacity(0.75), BlendMode.srcATop),
      ),
    ), child: const SizedBox.expand());
    return Stack(children: [ZegoUIKitPrebuiltLiveAudioRoom(
      appID: widget.session['appID'] as int,
      token: widget.session['token'] as String,
      userID: widget.session['userID'] as String,
      userName: widget.session['userName'] as String,
      roomID: widget.session['roomID'] as String,
      config: _config,
      events: ZegoUIKitPrebuiltLiveAudioRoomEvents(
        seat: ZegoLiveAudioRoomSeatEvents(onChanged: (taken, empty) {
          int? index;
          for (final entry in taken.entries) {
            if (entry.value.id == widget.session['userID']) index = entry.key;
          }
          unawaited(_seatChanged(index));
        }),
        room: ZegoLiveAudioRoomRoomEvents(onTokenExpired: (_) { unawaited(_renew()); return null; }),
      ),
    ), Positioned(right: 16, bottom: 145, child: FloatingActionButton.small(
      heroTag: null, onPressed: _chooseAppearance, tooltip: 'تغيير المظهر', child: const Icon(Icons.palette_outlined))),
    Positioned(right: 16, bottom: 90, child: FloatingActionButton.small(
      heroTag: null,
      onPressed: _chooseRecipient, tooltip: 'إرسال هدية', child: const Icon(Icons.card_giftcard)))]);
  }
}
