import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zego_uikit_prebuilt_live_audio_room/zego_uikit_prebuilt_live_audio_room.dart';

class ZegoNativeRoomPage extends StatefulWidget {
  final String roomId;
  final String roomTitle;
  final String userId;
  final String userName;
  final bool isHost;
  final String serverEndpoint;

  const ZegoNativeRoomPage({
    super.key,
    required this.roomId,
    required this.roomTitle,
    required this.userId,
    required this.userName,
    required this.isHost,
    required this.serverEndpoint,
  });

  @override
  State<ZegoNativeRoomPage> createState() => _ZegoNativeRoomPageState();
}

class _ZegoNativeRoomPageState extends State<ZegoNativeRoomPage> {
  String? _token;
  bool _isLoading = true;
  String? _error;

  late final String _cleanRoomId;
  late final String _cleanUserId;

  String _sanitizeId(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
  }

  @override
  void initState() {
    super.initState();
    _cleanRoomId = _sanitizeId(widget.roomId);
    _cleanUserId = _sanitizeId(widget.userId);
    _fetchToken();
  }

  Future<void> _fetchToken() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final baseUrl = widget.serverEndpoint.endsWith('/')
          ? widget.serverEndpoint.substring(0, widget.serverEndpoint.length - 1)
          : widget.serverEndpoint;
      final role = widget.isHost ? 'host' : 'audience';
      final uri = Uri.parse(
        '$baseUrl/api/zego/token?roomID=$_cleanRoomId&userID=$_cleanUserId&role=$role',
      );

      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final token = (data['token'] ?? data['kitToken'] ?? '').toString();
      if (token.isEmpty) {
        throw Exception('Empty token received from server');
      }

      if (!mounted) return;
      setState(() {
        _token = token;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.roomTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _token == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.roomTitle)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تعذر الاتصال بالغرفة الصوتية\n${_error ?? ''}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _fetchToken,
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return SafeArea(
      child: ZegoUIKitPrebuiltLiveAudioRoom(
        appID: 400719759,
        token: _token!,
        userID: _cleanUserId,
        userName: widget.userName,
        roomID: _cleanRoomId,
        config: widget.isHost
            ? ZegoUIKitPrebuiltLiveAudioRoomConfig.host()
            : ZegoUIKitPrebuiltLiveAudioRoomConfig.audience(),
      ),
    );
  }
}
