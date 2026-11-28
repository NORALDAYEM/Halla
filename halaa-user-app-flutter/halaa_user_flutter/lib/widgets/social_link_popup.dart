import 'package:flutter/material.dart';
import '../services/supabase_auth_service.dart';

Future<void> showSocialLinkPopup(BuildContext context) {
return showDialog<void>(
context: context,
barrierDismissible: true,
builder: (ctx) => const Directionality(
textDirection: TextDirection.rtl,
child: _SocialLinkDialog(),
),
);
}

class _SocialLinkDialog extends StatefulWidget {
const _SocialLinkDialog();

@override
State<_SocialLinkDialog> createState() => _SocialLinkDialogState();
}

class _SocialLinkDialogState extends State<_SocialLinkDialog> {
final _auth = SupabaseAuthService.instance;
bool _loadingGoogle = false;
bool _loadingFacebook = false;
bool _syncing = false;
String? _statusMessage;
bool _isError = false;

bool get _busy => _loadingGoogle || _loadingFacebook || _syncing;

Future<void> _handleGoogleLink() async {
setState(() {
_loadingGoogle = true;
_statusMessage = null;
_isError = false;
});
try {
final started = await _auth.linkWithGoogle();
if (!mounted) return;
if (started) {
await _auth.syncCurrentUserToServer(force: true);
if (!mounted) return;
setState(() {
_statusMessage = 'تم فتح اختيار حساب Gmail وبدء المزامنة مع الخادم.';
_isError = false;
});
} else {
setState(() {
_statusMessage = 'تعذر بدء الربط مع Gmail. حاول مرة أخرى.';
_isError = true;
});
}
} catch (e) {
if (!mounted) return;
setState(() {
_statusMessage = 'حدث خطأ أثناء الربط مع Gmail: $e';
_isError = true;
});
} finally {
if (mounted) {
setState(() => _loadingGoogle = false);
}
}
}

Future<void> _handleFacebookLink() async {
setState(() {
_loadingFacebook = true;
_statusMessage = null;
_isError = false;
});
try {
final started = await _auth.linkWithFacebook();
if (!mounted) return;
if (started) {
await _auth.syncCurrentUserToServer(force: true);
if (!mounted) return;
setState(() {
_statusMessage = 'تم فتح صفحة Facebook وبدء المزامنة مع الخادم.';
_isError = false;
});
} else {
setState(() {
_statusMessage = 'تعذر بدء الربط مع Facebook. حاول مرة أخرى.';
_isError = true;
});
}
} catch (e) {
if (!mounted) return;
setState(() {
_statusMessage = 'حدث خطأ أثناء الربط مع Facebook: $e';
_isError = true;
});
} finally {
if (mounted) {
setState(() => _loadingFacebook = false);
}
}
}

Future<void> _handleSync() async {
setState(() {
_syncing = true;
_statusMessage = null;
_isError = false;
});
try {
final result = await _auth.syncCurrentUserToServer(force: true);
if (!mounted) return;
if (result != null) {
setState(() {
_statusMessage = 'تمت مزامنة وحفظ بيانات الحساب في الخادم بنجاح.';
_isError = false;
});
} else {
setState(() {
_statusMessage = 'لا يوجد مستخدم مسجل حالياً أو تعذرت المزامنة.';
_isError = true;
});
}
} catch (e) {
if (!mounted) return;
setState(() {
_statusMessage = 'تعذر حفظ البيانات في الخادم: $e';
_isError = true;
});
} finally {
if (mounted) {
setState(() => _syncing = false);
}
}
}

@override
Widget build(BuildContext context) {
return AlertDialog(
shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
title: const Row(
children: [
Icon(Icons.link, color: Colors.deepPurple),
SizedBox(width: 8),
Expanded(
child: Text(
'ربط الحسابات الاجتماعية',
style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
),
),
],
),
content: Column(
mainAxisSize: MainAxisSize.min,
crossAxisAlignment: CrossAxisAlignment.stretch,
children: [
const Text(
'اربط حسابك مباشرة مع Gmail أو Facebook وقم بمزامنة بياناتك وحفظها في خادم التطبيق.',
style: TextStyle(fontSize: 13.5, color: Colors.black87),
),
const SizedBox(height: 16),
ElevatedButton.icon(
onPressed: _busy ? null : _handleGoogleLink,
icon: _loadingGoogle
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(strokeWidth: 2),
)
: const Icon(Icons.mail_outline),
label: const Text('الربط المباشر مع Gmail'),
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFDB4437),
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
const SizedBox(height: 10),
ElevatedButton.icon(
onPressed: _busy ? null : _handleFacebookLink,
icon: _loadingFacebook
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(strokeWidth: 2),
)
: const Icon(Icons.facebook),
label: const Text('الربط المباشر مع Facebook'),
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFF1877F2),
foregroundColor: Colors.white,
padding: const EdgeInsets.symmetric(vertical: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
const SizedBox(height: 10),
OutlinedButton.icon(
onPressed: _busy ? null : _handleSync,
icon: _syncing
? const SizedBox(
width: 18,
height: 18,
child: CircularProgressIndicator(strokeWidth: 2),
)
: const Icon(Icons.sync),
label: const Text('مزامنة وحفظ البيانات الآن'),
style: OutlinedButton.styleFrom(
padding: const EdgeInsets.symmetric(vertical: 12),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(12),
),
),
),
if (_statusMessage != null) ...[
const SizedBox(height: 12),
Container(
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
color: _isError ? Colors.red.shade50 : Colors.green.shade50,
borderRadius: BorderRadius.circular(10),
),
child: Text(
_statusMessage!,
style: TextStyle(
fontSize: 12.5,
color: _isError ? Colors.red.shade800 : Colors.green.shade800,
),
),
),
],
],
),
actions: [
TextButton(
onPressed: _busy ? null : () => Navigator.of(context).pop(),
child: const Text('إغلاق'),
),
],
);
}
}
