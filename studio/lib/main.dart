// This application targets Flutter Web.
import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';

const ink = Color(0xff18141c);
const paper = Color(0xfffff4eb);
const coral = Color(0xffffa081);
const lilac = Color(0xffc7acf6);

void main() => runApp(const Halla());
void openApp(String destination) {
  final uri = Uri.base
      .resolve('../app.html')
      .replace(queryParameters: {'view': destination});
  html.window.location.assign(uri.toString());
}

class Halla extends StatelessWidget {
  const Halla({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'هلاا',
    theme: ThemeData.dark(
      useMaterial3: true,
    ).copyWith(scaffoldBackgroundColor: ink),
    home: const Directionality(
      textDirection: TextDirection.rtl,
      child: Welcome(),
    ),
  );
}

// A microphone capsule forms the body of a game pad.
class Emblem extends CustomPainter {
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 64, size.height / 64);
    final fill = Paint()..color = coral;
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(3, 3, 58, 58),
        const Radius.circular(19),
      ),
      fill,
    );
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.5;
    final pad = Path()
      ..moveTo(13, 37)
      ..quadraticBezierTo(15, 25, 22, 26)
      ..quadraticBezierTo(32, 30, 42, 26)
      ..quadraticBezierTo(49, 25, 51, 39)
      ..quadraticBezierTo(53, 50, 44, 44)
      ..lineTo(38, 39)
      ..lineTo(26, 39)
      ..lineTo(20, 44)
      ..quadraticBezierTo(10, 50, 13, 37)
      ..close();
    c.drawPath(pad, line);
    c.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(27, 12, 10, 17),
        const Radius.circular(5),
      ),
      line,
    );
    c.drawLine(const Offset(19, 34), const Offset(25, 34), line);
    c.drawLine(const Offset(22, 31), const Offset(22, 37), line);
    c.drawCircle(const Offset(40, 35), 2, Paint()..color = ink);
    c.drawCircle(const Offset(45, 32), 2, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(Emblem oldDelegate) => false;
}

class Lobby extends StatelessWidget {
  const Lobby({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final wide = box.maxWidth >= 760;
          return SingleChildScrollView(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: wide ? 40 : 20,
                    vertical: 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CustomPaint(
                            size: const Size.square(50),
                            painter: Emblem(),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'هلاا',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: paper,
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed: () => openApp('login'),
                            icon: const Icon(Icons.person_outline),
                            label: const Text('دخول الأعضاء'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: paper,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: wide ? 46 : 28),
                      Text(
                        'الصوت واللعب',
                        style: TextStyle(
                          fontSize: wide ? 54 : 36,
                          fontWeight: FontWeight.w900,
                          color: paper,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (wide)
                        const Row(
                          children: [
                            Expanded(child: ChannelCard(voice: true)),
                            SizedBox(width: 18),
                            Expanded(child: ChannelCard(voice: false)),
                          ],
                        )
                      else
                        const Column(
                          children: [
                            ChannelCard(voice: true),
                            SizedBox(height: 14),
                            ChannelCard(voice: false),
                          ],
                        ),
                      const SizedBox(height: 26),
                      const Divider(color: Color(0xff443944)),
                      Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () => openApp('store'),
                            icon: const Icon(Icons.card_giftcard),
                            label: const Text('متجر الهدايا'),
                          ),
                          TextButton.icon(
                            onPressed: () => openApp('home'),
                            icon: const Icon(Icons.explore_outlined),
                            label: const Text('تصفح هلاا كضيف'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}

class ChannelCard extends StatelessWidget {
  final bool voice;
  const ChannelCard({super.key, required this.voice});
  @override
  Widget build(BuildContext context) {
    final title = voice ? 'الغرف الصوتية' : 'صالة الألعاب';
    final action = voice ? 'استكشف الغرف' : 'اختر لعبة';
    final color = voice ? coral : lilac;
    return Semantics(
      button: true,
      label: '$title، $action',
      child: Material(
        color: ink,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openApp(voice ? 'rooms' : 'games'),
          child: ExcludeSemantics(
            child: AspectRatio(
              aspectRatio: MediaQuery.sizeOf(context).width >= 760
                  ? 1.22
                  : 1.52,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'art/${voice ? 'voice' : 'games'}.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, -.12),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Color(0x12100c16),
                          Color(0xf9110c17),
                        ],
                        stops: [0, .35, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 22,
                    left: 22,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                action,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        CircleAvatar(
                          backgroundColor: color,
                          foregroundColor: ink,
                          child: const Icon(Icons.arrow_back),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Welcome extends StatefulWidget {
  const Welcome({super.key});
  @override
  State<Welcome> createState() => _WelcomeState();
}

class _WelcomeState extends State<Welcome> {
  static const photos = ['art/lounge.jpg', 'art/voice.jpg', 'art/games.jpg'];
  int selected = 0;
  Timer? rotation;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    rotation?.cancel();
    if (!MediaQuery.disableAnimationsOf(context)) {
      rotation = Timer.periodic(const Duration(seconds: 5), (_) {
        if (html.document.visibilityState == 'visible')
          setState(() => selected = (selected + 1) % photos.length);
      });
    }
  }

  @override
  void dispose() {
    rotation?.cancel();
    super.dispose();
  }

  void go(String action) => html.window.location.assign(
    Uri.base.resolve('../member.html?view=$action').toString(),
  );
  Widget primary(String label, IconData icon, bool dark, String action) =>
      SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton.icon(
          onPressed: () => go(action),
          icon: Icon(icon),
          label: Text(label),
          style: FilledButton.styleFrom(
            backgroundColor: dark
                ? const Color(0xff111619)
                : const Color(0xffecf1f3),
            foregroundColor: dark ? Colors.white : ink,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
  Widget shortcut(String label, IconData icon, String action, Color color) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            tooltip: label,
            onPressed: () => go(action),
            icon: Icon(icon, color: color),
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xffeff4f5),
              minimumSize: const Size.square(46),
            ),
          ),
          Text(
            label,
            style: const TextStyle(color: Color(0xff404b50), fontSize: 12),
          ),
        ],
      );
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, box) {
          final height = box.maxHeight.clamp(595.0, 950.0).toDouble();
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: SingleChildScrollView(
                child: SizedBox(
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: height * .61,
                        child: ClipRect(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 950),
                            layoutBuilder: (current, previous) => Stack(
                              fit: StackFit.expand,
                              children: [
                                ...previous,
                                if (current != null) current,
                              ],
                            ),
                            child: Image.asset(
                              photos[selected],
                              key: ValueKey(selected),
                              fit: BoxFit.cover,
                              alignment: const Alignment(0, -.3),
                            ),
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x995ef4e0),
                              Color(0x75e0fff7),
                              Colors.white,
                              Colors.white,
                            ],
                            stops: [0, .24, .57, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 16,
                        child: FilledButton(
                          onPressed: () => go('guest'),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(.94),
                            foregroundColor: const Color(0xff057e76),
                          ),
                          child: const Text('وضع الضيف'),
                        ),
                      ),
                      Positioned(
                        top: height * .226,
                        left: 0,
                        right: 0,
                        child: Column(
                          children: [
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: const Color(0xff102b34),
                                borderRadius: BorderRadius.circular(23),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x33213941),
                                    blurRadius: 22,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(7),
                                child: CustomPaint(
                                  size: const Size.square(62),
                                  painter: Emblem(),
                                ),
                              ),
                            ),
                            const Text(
                              'هلاا',
                              style: TextStyle(
                                color: ink,
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                                height: 1.35,
                              ),
                            ),
                            const Text(
                              'غرف صوتية وألعاب',
                              style: TextStyle(
                                color: Color(0xff334449),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: height * .058,
                        left: 28,
                        right: 28,
                        child: Column(
                          children: [
                            primary(
                              'دخول بالبريد الإلكتروني',
                              Icons.alternate_email,
                              true,
                              'login',
                            ),
                            const SizedBox(height: 12),
                            primary(
                              'إنشاء حساب',
                              Icons.person_add_alt_1,
                              false,
                              'signup',
                            ),
                            const SizedBox(height: 18),
                            const Row(
                              children: [
                                Expanded(child: Divider()),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'أو',
                                    style: TextStyle(color: Colors.black54),
                                  ),
                                ),
                                Expanded(child: Divider()),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                shortcut(
                                  'الهاتف',
                                  Icons.phone_android,
                                  'phone',
                                  const Color(0xff078971),
                                ),
                                shortcut(
                                  'اسم المستخدم',
                                  Icons.person_outline,
                                  'username',
                                  const Color(0xff755fa0),
                                ),
                                shortcut(
                                  'استعادة الحساب',
                                  Icons.lock_reset,
                                  'reset',
                                  const Color(0xff8b631d),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    ),
  );
}
