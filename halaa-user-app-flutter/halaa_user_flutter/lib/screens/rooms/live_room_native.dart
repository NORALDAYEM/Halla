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
    '': 'بدون خلفية',
    'headphones': 'سماعات',
    'chessboard': 'رقعة شطرنج',
    'chess-pieces': 'قطع شطرنج',
    'game-table': 'طاولة ألعاب',
    'ludo-friends': 'أصدقاء لودو',
    'pool-friends': 'أصدقاء البلياردو',
    'pool-table': 'طاولة بلياردو',
  };

  Map<String, dynamic> get _roomConfig {
    final raw = widget.session['roomConfig'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  int get _micCount {
    final value = _roomConfig['micCount'];
    final parsed = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 1) return 9;
    return parsed;
  }

  int get _roomLevel {
    final value = _roomConfig['roomLevel'];
    final parsed = value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 1) return 1;
    return parsed;
  }

  List<Map<String, dynamic>> get _levels {
    final raw = _roomConfig['levels'];
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }
    return const [
      {'level': 1, 'name': 'برونزي'},
      {'level': 2, 'name': 'فضي'},
      {'level': 3, 'name': 'ذهبي'},
    ];
  }

  String get _roomLevelName {
    final currentLevel = _roomLevel;
    for (final item in _levels) {
      final lvl = item['level'] is num
          ? (item['level'] as num).toInt()
          : int.tryParse(item['level']?.toString() ?? '');
      if (lvl == currentLevel) {
        final name = (item['name'] ?? item['title'] ?? item['label'])?.toString().trim();
        if (name != null && name.isNotEmpty) return name;
      }
    }
    return 'المستوى $currentLevel';
  }

  bool get _allowGifts {
    final value = _roomConfig['allowGifts'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() != 'false';
    return true;
  }

  bool get _allowChat {
    final value = _roomConfig['allowChat'];
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() != 'false';
    return true;
  }

  String get _welcomeMessage {
    final value = _roomConfig['welcomeMessage']?.toString().trim();
    if (value != null && value.isNotEmpty) return value;
    return 'أهلاً بكم في غرفة هلاا الصوتية';
  }

  List<ZegoLiveAudioRoomLayoutRowConfig> _buildSeatRowConfigs(int micCount) {
    final total = micCount < 1 ? 1 : micCount;
    final rows = <ZegoLiveAudioRoomLayoutRowConfig>[
      ZegoLiveAudioRoomLayoutRowConfig(
        count: 1,
        alignment: ZegoLiveAudioRoomLayoutAlignment.center,
      ),
    ];
    var remaining = total - 1;
    while (remaining > 0) {
      final rowCount = remaining > 4 ? 4 : remaining;
      rows.add(
        ZegoLiveAudioRoomLayoutRowConfig(
          count: rowCount,
          alignment: ZegoLiveAudioRoomLayoutAlignment.spaceEvenly,
        ),
      );
      remaining -= rowCount;
    }
    return rows;
  }

  void _configureInnerText(ZegoUIKitPrebuiltLiveAudioRoomInnerText innerText) {
    innerText
      ..takeSeatMenuButton = 'أخذ المقعد'
      ..switchSeatMenuButton = 'تبديل المقعد'
      ..removeSpeakerMenuDialogButton = 'إزالة %0 من المقعد'
      ..muteSpeakerMenuDialogButton = 'كتم صوت %0'
      ..cancelMenuDialogButton = 'إلغاء'
      ..removeUserMenuDialogButton = 'إزالة %0 من الغرفة'
      ..memberListTitle = 'المستمعون'
      ..memberListRoleYou = 'أنت'
      ..memberListRoleHost = 'المضيف'
      ..memberListRoleSpeaker = 'متحدث'
      ..removeSpeakerFailedToast = 'تعذّر إزالة %0 من المقعد'
      ..messageEmptyToast = 'اكتب رسالة الدردشة...'
      ..cameraPermissionSettingDialogInfo = ZegoLiveAudioRoomDialogInfo(
        title: 'إذن الكاميرا',
        message: 'يرجى السماح بالوصول إلى الكاميرا من إعدادات الجهاز.',
        cancelButtonName: 'إلغاء',
        confirmButtonName: 'الإعدادات',
      )
      ..microphonePermissionSettingDialogInfo = ZegoLiveAudioRoomDialogInfo(
        title: 'إذن الميكروفون',
        message: 'يرجى السماح بالوصول إلى الميكروفون من إعدادات الجهاز.',
        cancelButtonName: 'إلغاء',
        confirmButtonName: 'الإعدادات',
      )
      ..removeFromSeatDialogInfo = ZegoLiveAudioRoomDialogInfo(
        title: 'إزالة من المقعد',
        message: 'هل تريد إزالة %0 من المقعد؟',
        cancelButtonName: 'إلغاء',
        confirmButtonName: 'إزالة',
      )
      ..leaveSeatDialogInfo = ZegoLiveAudioRoomDialogInfo(
        title: 'مغادرة المقعد',
        message: 'هل تريد مغادرة المقعد الصوتي؟',
        cancelButtonName: 'إلغاء',
        confirmButtonName: 'مغادرة',
      )
      ..applyToTakeSeatButton = 'طلب المايك'
      ..cancelTheTakeSeatApplicationButton = 'إلغاء طلب المايك'
      ..memberListAgreeButton = 'موافق'
      ..memberListDisagreeButton = 'رفض'
      ..inviteToTakeSeatMenuDialogButton = 'دعوة %0 للصعود للمايك'
      ..hostInviteTakeSeatDialog = ZegoLiveAudioRoomDialogInfo(
        title: 'دعوة للمايك',
        message: 'يدعوك المضيف للصعود إلى المقعد الصوتي.',
        cancelButtonName: 'رفض',
        confirmButtonName: 'موافق',
      )
      ..assignAsCoHostMenuDialogButton = 'تعيين %0 كمضيف مشارك'
      ..revokeCoHostPrivilegesMenuDialogButton = 'إلغاء صلاحية المضيف المشارك من %0'
      ..audioEffectTitle = 'المؤثرات الصوتية'
      ..audioEffectReverbTitle = 'الصدى'
      ..audioEffectVoiceChangingTitle = 'تغيير الصوت'
      ..voiceChangerNoneTitle = 'بدون'
      ..voiceChangerLittleBoyTitle = 'طفل'
      ..voiceChangerLittleGirlTitle = 'طفلة'
      ..voiceChangerDeepTitle = 'عميق'
      ..voiceChangerCrystalClearTitle = 'نقي'
      ..voiceChangerRobotTitle = 'روبوت'
      ..voiceChangerEtherealTitle = 'أثيري'
      ..voiceChangerFemaleTitle = 'أنثوي'
      ..voiceChangerMaleTitle = 'ذكوري'
      ..voiceChangerOptimusPrimeTitle = 'آلي عملاق'
      ..voiceChangerCMajorTitle = 'سلم دو الكبير'
      ..voiceChangerAMajorTitle = 'سلم لا الكبير'
      ..voiceChangerHarmonicMinorTitle = 'سلم هارمونيك الصغير'
      ..reverbTypeNoneTitle = 'بدون'
      ..reverbTypeKTVTitle = 'كاريوكي'
      ..reverbTypeHallTitle = 'قاعة'
      ..reverbTypeConcertTitle = 'حفلة'
      ..reverbTypeRockTitle = 'روك'
      ..reverbTypeSmallRoomTitle = 'غرفة صغيرة'
      ..reverbTypeLargeRoomTitle = 'غرفة كبيرة'
      ..reverbTypeValleyTitle = 'وادي'
      ..reverbTypeRecordingStudioTitle = 'استوديو تسجيل'
      ..reverbTypeBasementTitle = 'قبو'
      ..reverbTypePopularTitle = 'شائع'
      ..reverbTypeGramophoneTitle = 'فونوغراف'
      ..screenSharingTipText = 'أنت تشارك شاشتك الآن'
      ..stopScreenSharingButtonText = 'إيقاف المشاركة';
  }

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
            Text('مظهر الغرفة وتخصيصها', style: Theme.of(sheet).textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              ChoiceChip(label: const Text('الافتراضي فقط'), selected: theme == null,
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
    _config.seat.layout.rowConfigs = _buildSeatRowConfigs(_micCount);
    _config.confirmDialogInfo = ZegoLiveAudioRoomDialogInfo(
      title: 'تأكيد المغادرة',
      message: 'هل تريد مغادرة الغرفة الصوتية؟',
      cancelButtonName: 'البقاء',
      confirmButtonName: 'مغادرة',
    );
    _configureInnerText(_config.innerText);
    _config.background = Stack(fit: StackFit.expand, children: [
      Builder(builder: (context) {
        final colors = Theme.of(context).colorScheme;
        final base = _roomTheme?.surface ?? colors.surface;
        final top = _roomTheme?.primary ?? colors.primary;
        return Container(decoration: BoxDecoration(gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [base, top.withOpacity(0.18), base],
        )));
      }),
      if (_backdrop.isNotEmpty)
        Opacity(opacity: 0.24, child: Image.asset('assets/images/$_backdrop.png', fit: BoxFit.cover)),
    ]);
    _config.turnOnMicrophoneWhenJoining = widget.session['role'] == 'owner';
    _heartbeat = Timer.periodic(const Duration(seconds: 20), (_) => _renew());
  }

  Future<void> _renew() async {
    if (_renewing || !mounted) return;
    _renewing = true;
    try {
      final res = await widget.renew();
      final token = (res['token'] ?? '').toString();
      if (token.isNotEmpty) ZegoUIKit().renewToken(token);
    } finally {
      _renewing = false;
    }
  }

  @override
  void dispose() {
    _heartbeat?.cancel();
    super.dispose();
  }

  Future<void> _chooseRecipient() async {
    final me = (widget.session['userId'] ?? '').toString();
    final members = ZegoUIKit().getAllUsers().where((u) => u.id != me).toList();
    final target = await showModalBottomSheet<String>(
      context: context,
      builder: (sheet) => SafeArea(
        child: ListView(shrinkWrap: true, children: [
          const ListTile(title: Text('اختر مستلم الهدية')),
          if (members.isEmpty) const ListTile(title: Text('لا يوجد أعضاء متاحون لإرسال هدية')),
          for (final u in members)
            ListTile(title: Text(u.name.isEmpty ? u.id : u.name), onTap: () => Navigator.pop(sheet, u.id)),
        ]),
      ),
    );
    if (target != null && target.isNotEmpty) await widget.sendGift(target);
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.session;
    final colors = Theme.of(context).colorScheme;
    final base = _roomTheme?.surface ?? colors.surface;
    final primary = _roomTheme?.primary ?? colors.primary;
    return Stack(children: [
      ZegoUIKitPrebuiltLiveAudioRoom(
        appID: (s['appId'] as num).toInt(),
        appSign: (s['appSign'] ?? '').toString(),
        token: (s['token'] ?? '').toString(),
        userID: (s['userId'] ?? '').toString(),
        userName: (s['userName'] ?? 'عضو').toString(),
        roomID: (s['roomId'] ?? '').toString(),
        config: _config,
        events: ZegoUIKitPrebuiltLiveAudioRoomEvents(
          onLeaveConfirmation: (event, defaultAction) async {
            if (_seatIndex != null) {
              _seatIndex = null;
              await widget.updateSeat(null);
            }
            return defaultAction();
          },
          seat: ZegoLiveAudioRoomSeatEvents(
            onChanged: (takenSeats, untakenSeats) {
              final me = (s['userId'] ?? '').toString();
              final seat = takenSeats.entries.where((e) => e.value.id == me).map((e) => e.key).firstOrNull;
              if (seat != _seatIndex) {
                _seatIndex = seat;
                widget.updateSeat(seat);
              }
            },
          ),
        ),
        controller: _controller,
      ),
      Positioned(
        top: 52,
        left: 16,
        right: 16,
        child: SafeArea(
          bottom: false,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: base.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: primary.withOpacity(0.35)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.22),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium_rounded, size: 15, color: primary),
                              const SizedBox(width: 4),
                              Text(
                                'المستوى $_roomLevel • $_roomLevelName',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.secondaryContainer.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic_rounded, size: 15, color: colors.onSecondaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                '$_micCount مايك',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _welcomeMessage,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withOpacity(0.92),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      Positioned(right: 16, bottom: 146, child: FloatingActionButton.small(
        heroTag: 'room-theme',
        onPressed: _chooseAppearance,
        tooltip: 'مظهر الغرفة',
        child: const Icon(Icons.palette_outlined),
      )),
      if (_allowGifts)
        Positioned(right: 16, bottom: 90, child: FloatingActionButton.small(
          heroTag: 'room-gift',
          onPressed: _chooseRecipient,
          tooltip: 'إرسال هدية',
          child: const Icon(Icons.card_giftcard),
        )),
    ]);
  }
}
