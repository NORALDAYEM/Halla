import 'package:flutter/material.dart';

// The Flutter Live Audio Room Kit supports Android and iOS only.
// Keep the existing web app buildable without importing native ZEGO plugins.
class HalaaRoomKit extends StatelessWidget {
  const HalaaRoomKit({super.key, required this.session, required this.renew, required this.updateSeat, required this.sendGift});
  final Map<String, dynamic> session;
  final Future<Map<String, dynamic>> Function() renew;
  final Future<Map<String, dynamic>> Function(int?) updateSeat;
  final Future<void> Function(String) sendGift;
  @override
  Widget build(BuildContext context) => const Center(child: Padding(
    padding: EdgeInsets.all(24), child: Text('الغرف الصوتية متاحة في تطبيق الهاتف. نسخة الويب لهذا المحرك غير مدعومة بعد.', textAlign: TextAlign.center)));
}
