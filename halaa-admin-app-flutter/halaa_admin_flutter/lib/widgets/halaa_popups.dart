import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/halaa_models.dart';

/// Translucent frosted-glass dialog that automatically adapts to the active page theme.
Future<T?> showHalaaGlassDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool darkMode = false,
}) {
  final scheme = Theme.of(context).colorScheme;
  final tint = Color.lerp(
    darkMode ? const Color(0xFF071B21) : const Color(0xFF0B2E38),
    scheme.primary,
    0.22,
  )!;
  final glassFill = Color.fromRGBO(
    (tint.r * 255).round(),
    (tint.g * 255).round(),
    (tint.b * 255).round(),
    0.56,
  );
  final borderCol = Color.fromRGBO(
    (scheme.primary.r * 255).round(),
    (scheme.primary.g * 255).round(),
    (scheme.primary.b * 255).round(),
    0.52,
  );

  return showDialog<T>(
    context: context,
    barrierColor: const Color.fromRGBO(4, 15, 22, 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 620),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: glassFill,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderCol, width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.32),
                    blurRadius: 24,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        child,
                      ],
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: InkWell(
                      onTap: () => Navigator.of(ctx).pop(),
                      customBorder: const CircleBorder(),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color.fromRGBO(255, 255, 255, 0.18),
                          border: Border.all(
                            color: const Color.fromRGBO(255, 255, 255, 0.45),
                          ),
                        ),
                        child: const Center(
                          child: Text(
                            '×',
                            style: TextStyle(
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

InputDecoration _glassFieldDeco(String label, Color primary) => InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFFE0F2FE),
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: const Color.fromRGBO(255, 255, 255, 0.14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.30)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: primary, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
    );

/// 1. Email Access Popup (#email-access) — Login & Signup modes
Future<void> showEmailAccessPopup({
  required BuildContext context,
  required bool isSignup,
  required void Function(AppUserRecord user) onSuccess,
}) {
  final nickCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();
  String gender = '';
  String country = 'السعودية';
  String? errorMsg;

  const countries = [
    'السعودية',
    'الإمارات العربية المتحدة',
    'الكويت',
    'قطر',
    'البحرين',
    'عمان',
    'مصر',
    'الأردن',
    'العراق',
    'المغرب',
    'الجزائر',
    'تونس',
    'لبنان',
    'اليمن',
    'السودان',
    'تركيا',
  ];

  final primary = Theme.of(context).colorScheme.primary;
  return showHalaaGlassDialog<void>(
    context: context,
    title: isSignup ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
    child: StatefulBuilder(
      builder: (ctx, setState) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSignup) ...[
              TextField(
                controller: nickCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: _glassFieldDeco('اسم المستخدم', primary),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Colors.white),
              decoration: _glassFieldDeco('البريد الإلكتروني', primary),
            ),
            const SizedBox(height: 10),
            if (isSignup) ...[
              DropdownButtonFormField<String>(
                value: gender.isEmpty ? null : gender,
                dropdownColor: const Color(0xFF0A242E),
                style: const TextStyle(color: Colors.white),
                decoration: _glassFieldDeco('الجنس', primary),
                items: const [
                  DropdownMenuItem(value: 'ذكر', child: Text('ذكر')),
                  DropdownMenuItem(value: 'أنثى', child: Text('أنثى')),
                  DropdownMenuItem(
                    value: 'أفضل عدم الإفصاح',
                    child: Text('أفضل عدم الإفصاح'),
                  ),
                ],
                onChanged: (v) => setState(() => gender = v ?? ''),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: country,
                dropdownColor: const Color(0xFF0A242E),
                style: const TextStyle(color: Colors.white),
                decoration: _glassFieldDeco('الدولة', primary),
                items: countries
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => country = v);
                },
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: passCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: _glassFieldDeco('كلمة المرور', primary),
            ),
            if (isSignup) ...[
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _glassFieldDeco('تأكيد كلمة المرور', primary),
              ),
            ],
            if (errorMsg != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(220, 38, 38, 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFDC2626)),
                ),
                child: Text(
                  errorMsg!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFFCA5A5),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 14),
            ElevatedButton(
              onPressed: () {
                final email = emailCtrl.text.trim();
                final pass = passCtrl.text.trim();
                final nick = nickCtrl.text.trim();
                if (isSignup && nick.isEmpty) {
                  setState(() => errorMsg = 'اسم المستخدم غير صحيح');
                  return;
                }
                if (email.isEmpty || !email.contains('@')) {
                  setState(
                    () => errorMsg = 'البريد الإلكتروني أو اسم المستخدم غير صحيح',
                  );
                  return;
                }
                if (pass.length < 4) {
                  setState(() => errorMsg = 'كلمة المرور غير صحيحة');
                  return;
                }
                if (isSignup && pass != confirmCtrl.text.trim()) {
                  setState(() => errorMsg = 'تأكيد كلمة المرور غير مطابق');
                  return;
                }
                Navigator.of(ctx).pop();
                onSuccess(
                  AppUserRecord(
                    nickname: isSignup ? nick : email.split('@').first,
                    email: email,
                    gender: gender.isEmpty ? 'غير محدد' : gender,
                    country: country,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isSignup
                    ? const Color(0xFFB5530B)
                    : primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isSignup ? 'إنشاء الحساب' : 'تسجيل الدخول',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
            ),
          ],
        );
      },
    ),
  );
}

/// 2. Reset Password Popup (#reset-options)
Future<void> showResetPasswordPopup(
  BuildContext context, {
  bool darkMode = false,
}) {
  final primary = Theme.of(context).colorScheme.primary;
  return showHalaaGlassDialog<void>(
    context: context,
    darkMode: darkMode,
    title: 'استعادة كلمة المرور',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'كيف تريد استعادة حسابك؟',
          style: TextStyle(fontSize: 14, color: Color(0xFFE0F2FE)),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال رابط استعادة كلمة المرور إلى بريدك الإلكتروني.'),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('إرسال رابط إلى بريدي الإلكتروني'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('استعادة كلمة المرور برقم الهاتف غير مفعّلة حالياً — قريباً.'),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color.fromRGBO(255, 255, 255, 0.38)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text('إرسال رمز إلى رقم هاتفي (قريباً)'),
        ),
      ],
    ),
  );
}

/// 3. Service Terms Popup (#service-terms) — Verbatim 7 sections
Future<void> showServiceTermsPopup(
  BuildContext context, {
  bool darkMode = false,
}) {
  const sections = [
    (
      'الحساب وأمانه',
      'استخدم حسابك الشخصي واسمًا يميزك. احتفظ بكلمة المرور ورموز التحقق لنفسك. إذا وصلك طلب لهذه البيانات من شخص يدّعي أنه مشرف، فلا تشاركها معه.',
    ),
    (
      'المشاركة في الغرف الصوتية',
      'استأذن قبل فتح الميكروفون في الغرف التي تنظّم أدوار المتحدثين. أعطِ الآخرين فرصة للكلام، وتجنّب الضوضاء المتعمّدة أو العودة إلى الميكروفون بعد أن يطلب منك المشرف التوقف.',
    ),
    (
      'الاحترام والخصوصية',
      'يُحظر التنمّر والتهديد والتحرش وانتحال الهوية. لا تسجّل صوت مشارك أو تنشر صورته أو رسائله أو رقم هاتفه من دون إذنه، حتى لو كانت الغرفة عامة.',
    ),
    (
      'اللعب العادل',
      'التزم بقواعد اللعبة ودورك في المباراة. لا تستخدم برامج غش أو تستغل خللًا لتغيير النتيجة أو الرصيد. إذا لاحظت خطأ، اذكر اسم اللعبة وما حدث عند الإبلاغ عنه.',
    ),
    (
      'العملات والهدايا',
      'راجع اسم المستلم والهدية وعدد العملات قبل تأكيد الإرسال. عند الشراء، تحقّق من السعر والحساب المستخدم واحتفظ بالإيصال. تجنّب الروابط التي تطلب بيانات دخولك مقابل شحن مجاني.',
    ),
    (
      'المحتوى والروابط',
      'شارك ما تملكه أو لديك إذن بنشره. يُحظر إرسال روابط احتيالية أو ملفات ضارة أو إعلانات متكررة تعطل المحادثة.',
    ),
    (
      'الإبلاغ عن إساءة',
      'عند حدوث إساءة، يمكنك مغادرة الغرفة وإبلاغ مشرفها. اذكر اسم الغرفة ووقت الواقعة ووصفًا مختصرًا لما حدث، وتجنّب تضمين معلومات شخصية لا علاقة لها بالبلاغ.',
    ),
  ];

  return showHalaaGlassDialog<void>(
    context: context,
    darkMode: darkMode,
    title: 'شروط الخدمة',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: sections
          .map(
            (s) => Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color.fromRGBO(255, 255, 255, 0.16)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.$1,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF99F6E4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.$2,
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.65,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
}

/// 4. Support Tickets Popup (#help) — New Ticket + Track Ticket
Future<void> showSupportPopup({
  required BuildContext context,
  required List<SupportTicket> existingTickets,
  required ValueChanged<SupportTicket> onTicketCreated,
  bool darkMode = false,
}) {
  int activeTab = 0;
  String reason = '';
  final contactCtrl = TextEditingController();
  final detailsCtrl = TextEditingController();
  final trackCtrl = TextEditingController();
  String? formError;
  String? createdId;
  SupportTicket? foundTicket;
  bool searched = false;

  const reasons = [
    'حظر IP',
    'الحساب لا يعمل',
    'مشكلة في الدخول',
    'نسيان كلمة المرور',
    'نسيان البيانات',
    'شيء آخر',
  ];

  final primary = Theme.of(context).colorScheme.primary;
  return showHalaaGlassDialog<void>(
    context: context,
    darkMode: darkMode,
    title: 'الدعم الفني',
    child: StatefulBuilder(
      builder: (ctx, setState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('تذكرة جديدة')),
                    selected: activeTab == 0,
                    onSelected: (_) => setState(() => activeTab = 0),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Center(child: Text('متابعة تذكرة')),
                    selected: activeTab == 1,
                    onSelected: (_) => setState(() => activeTab = 1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (activeTab == 0) ...[
              if (createdId != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color.fromRGBO(16, 185, 129, 0.22),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF34D399)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'تم استلام تذكرتك بنجاح! احتفظ برقم التذكرة للمتابعة:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        createdId!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF99F6E4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: createdId!));
                            },
                            child: const Text('نسخ الرقم'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              trackCtrl.text = createdId!;
                              setState(() => activeTab = 1);
                            },
                            child: const Text('متابعة التذكرة'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ] else ...[
                DropdownButtonFormField<String>(
                  value: reason.isEmpty ? null : reason,
                  dropdownColor: const Color(0xFF0A242E),
                  style: const TextStyle(color: Colors.white),
                  decoration: _glassFieldDeco('اختر سبب المشكلة...', primary),
                  items: reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => reason = v ?? ''),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _glassFieldDeco(
                    'اسم المستخدم أو البريد أو رقم الجوال',
                    primary,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: _glassFieldDeco('تفاصيل المشكلة', primary),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    formError!,
                    style: const TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (reason.isEmpty) {
                      setState(() => formError = 'يرجى اختيار سبب المشكلة');
                      return;
                    }
                    final id = 'HLA-${100000 + Random().nextInt(899999)}';
                    final t = SupportTicket(
                      id: id,
                      reason: reason,
                      contact: contactCtrl.text.trim(),
                      details: detailsCtrl.text.trim(),
                      createdAt: DateTime.now().toIso8601String(),
                    );
                    onTicketCreated(t);
                    setState(() {
                      formError = null;
                      createdId = id;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('إرسال التذكرة'),
                ),
              ],
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: trackCtrl,
                      textDirection: TextDirection.ltr,
                      style: const TextStyle(color: Colors.white),
                      decoration: _glassFieldDeco('رقم التذكرة (HLA-...)', primary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final q = trackCtrl.text.trim().toUpperCase();
                      SupportTicket? match;
                      for (final t in existingTickets) {
                        if (t.id.toUpperCase() == q) {
                          match = t;
                          break;
                        }
                      }
                      setState(() {
                        searched = true;
                        foundTicket = match;
                      });
                    },
                    child: const Text('بحث'),
                  ),
                ],
              ),
              if (searched) ...[
                const SizedBox(height: 10),
                if (foundTicket == null)
                  const Text(
                    'لم يتم العثور على تذكرة بهذا الرقم.',
                    style: TextStyle(
                      color: Color(0xFFFCA5A5),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.14),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color.fromRGBO(255, 255, 255, 0.28),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${foundTicket!.id} — ${foundTicket!.status}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF99F6E4),
                          ),
                        ),
                        Text(
                          'السبب: ${foundTicket!.reason}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        if (foundTicket!.reply.isNotEmpty)
                          Text(
                            'رد الإدارة: ${foundTicket!.reply}',
                            style: const TextStyle(
                              color: Color(0xFF6EE7B7),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ],
          ],
        );
      },
    ),
  );
}
