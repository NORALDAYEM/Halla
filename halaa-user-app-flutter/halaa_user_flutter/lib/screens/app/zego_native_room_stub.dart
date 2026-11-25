import 'package:flutter/material.dart';

class ZegoNativeRoomPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(roomTitle),
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'الغرفة الصوتية الأصلية تعمل على تطبيق الجوال.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
