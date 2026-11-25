import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/halaa_models.dart';

/// Frosted mint-glass dialog container matching exact CSS:
/// `dialog:is(#email-access, #account-panel, #help, #reset-options, #service-terms)`
Future<T?> showHalaaGlassDialog<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  bool darkMode = false,
}) {
  return showDialog<T>(
    context: context,
    barrierColor: darkMode
        ? const Color.fromRGBO(5, 15, 20, 0.65)
        : const Color(0x6612383C),
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380, maxHeight: 620),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              decoration: BoxDecoration(
                color: darkMode
                    ? const Color.fromRGBO(12, 35, 43, 0.92)
                    : const Color.fromRGBO(235, 252, 247, 0.78),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: darkMode
                      ? const Color.fromRGBO(255, 255, 255, 0.35)
                      : const Color(0xAEFFFFFF),
                ),
              ),
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 40),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: darkMode
                                  ? Colors.white
                                  : const Color(0xFF10343B),
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
                          gradient: darkMode
                              ? null
                              : const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xEDF8FFFD),
                                    Color(0xE6C0E3DD),
                                  ],
                                ),
                          color: darkMode
                              ? const Color.fromRGBO(255, 255, 255, 0.14)
                              : null,
                          border: Border.all(
                            color: const Color(0xAEFFFFFF),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '×',
                            style: TextStyle(
                              fontSize: 20,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              color: darkMode
                                  ? Colors.white
                                  : const Color(0xFF123941),
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

  return showHalaaGlassDialog<void>(
    context: context,
    title: isSignup ? 'إنشاء حساب جديد' : 'تسجيل الدخول',
    child: StatefulBuilder(
      builder: (ctx, setState) {
        InputDecoration fieldDeco(String label) => InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(
                color: Color(0xFF10343B),
                fontWeight: FontWeight.w600,
              ),
              filled: true,
              fillColor: const Color.fromRGBO(255, 255, 255, 0.78),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF9ACFD0)),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            );

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isSignup) ...[
              TextField(
                controller: nickCtrl,
                style: const TextStyle(color: Color(0xFF10343B)),
                decoration: fieldDeco('اسم المستخدم'),
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr,
              style: const TextStyle(color: Color(0xFF10343B)),
              decoration: fieldDeco('البريد الإلكتروني'),
            ),
            const SizedBox(height: 10),
            if (isSignup) ...[
              DropdownButtonFormField<String>(
                value: gender.isEmpty ? null : gender,
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF10343B)),
                decoration: fieldDeco('الجنس'),
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
                dropdownColor: Colors.white,
                style: const TextStyle(color: Color(0xFF10343B)),
                decoration: fieldDeco('الدولة'),
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
              style: const TextStyle(color: Color(0xFF10343B)),
              decoration: fieldDeco('كلمة المرور'),
            ),
            if (isSignup) ...[
              const SizedBox(height: 10),
              TextField(
                controller: confirmCtrl,
                obscureText: true,
                style: const TextStyle(color: Color(0xFF10343B)),
                decoration: fieldDeco('تأكيد كلمة المرور'),
              ),
            ],
            if (errorMsg != null) ...[
              const SizedBox(height: 10),
              Text(
                errorMsg!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFDC2626),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
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
                  setState(() => errorMsg = 'البريد الإلكتروني أو اسم المستخدم غير صحيح');
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
                    : const Color(0xFF16844E),
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
Future<void> showResetPasswordPopup(BuildContext context, {bool darkMode = false}) {
  return showHalaaGlassDialog<void>(
    context: context,
    darkMode: darkMode,
    title: 'استعادة كلمة المرور',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'كيف تريد استعادة حسابك؟',
          style: TextStyle(
            fontSize: 14,
            color: darkMode ? const Color(0xFFD2EDF0) : const Color(0xFF10343B),
          ),
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
            backgroundColor: const Color(0xFF14B8A6),
            foregroundColor: Colors.white,
          ),
          child: const Text('إرسال رابط إلى بريدي الإلكتروني'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم إرسال رمز التحقق إلى رقم هاتفك.'),
              ),
            );
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: darkMode ? Colors.white : const Color(0xFF10343B),
          ),
          child: const Text('إرسال رمز إلى رقم هاتفي'),
        ),
      ],
    ),
  );
}

/// 3. Service Terms Popup (#service-terms) — Verbatim 7 sections from halla-web/index.html
Future<void> showServiceTermsPopup(BuildContext context, {bool darkMode = false}) {
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

  final textColor = darkMode ? Colors.white : const Color(0xFF10343B);
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
                  bottom: BorderSide(color: Color(0x3834665C)),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.$1,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.$2,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.65,
                      color: textColor,
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

  return showHalaaGlassDialog<void>(
    context: context,
    darkMode: darkMode,
    title: 'الدعم الفني',
    child: StatefulBuilder(
      builder: (ctx, setState) {
        final fg = darkMode ? Colors.white : const Color(0xFF10343B);
        InputDecoration deco(String hint) => InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: darkMode
                  ? const Color.fromRGBO(255, 255, 255, 0.12)
                  : const Color.fromRGBO(255, 255, 255, 0.8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            );

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
                    color: const Color.fromRGBO(16, 185, 129, 0.18),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'تم استلام تذكرتك بنجاح! احتفظ برقم التذكرة للمتابعة:',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: fg, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        createdId!,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F7682),
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
                  decoration: deco('اختر سبب المشكلة...'),
                  items: reasons
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setState(() => reason = v ?? ''),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: contactCtrl,
                  decoration: deco('اسم المستخدم أو البريد أو رقم الجوال'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: detailsCtrl,
                  maxLines: 3,
                  decoration: deco('اكتب تفاصيل المشكلة لمساعدتك بشكل أسرع...'),
                ),
                if (formError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    formError!,
                    style: const TextStyle(
                      color: Color(0xFFDC2626),
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
                    backgroundColor: const Color(0xFF0F7682),
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
                      decoration: deco('مثال: HLA-123456'),
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
                      color: Color(0xFFDC2626),
                      fontWeight: FontWeight.w700,
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(255, 255, 255, 0.55),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${foundTicket!.id} — ${foundTicket!.status}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF10343B),
                          ),
                        ),
                        Text(
                          'السبب: ${foundTicket!.reason}',
                          style: const TextStyle(color: Color(0xFF10343B)),
                        ),
                        if (foundTicket!.reply.isNotEmpty)
                          Text(
                            'رد الإدارة: ${foundTicket!.reply}',
                            style: const TextStyle(
                              color: Color(0xFF0F7682),
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
