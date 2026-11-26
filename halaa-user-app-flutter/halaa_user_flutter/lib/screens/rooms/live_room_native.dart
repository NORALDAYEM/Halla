import 'dart:async';
import 'package:flutter/material.dart';
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
    _config.background = ColoredBox(color: Theme.of(context).colorScheme.surface);
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
    ), Positioned(right: 16, bottom: 90, child: FloatingActionButton.small(
      onPressed: _chooseRecipient, tooltip: 'إرسال هدية', child: const Icon(Icons.card_giftcard)))]);
  }
}
