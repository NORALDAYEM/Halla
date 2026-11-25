import 'package:flutter/material.dart';

/// Exact 5-color Gmail M logo from halla-web/index.html
class GmailLogoIcon extends StatelessWidget {
  final double size;
  const GmailLogoIcon({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 0.75),
      painter: _GmailPainter(),
    );
  }
}

class _GmailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final sx = w / 24.0;
    final sy = h / 18.0;

    // Blue left pillar (#4285F4)
    final blue = Paint()..color = const Color(0xFF4285F4);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        0,
        3.5 * sy,
        5.45 * sx,
        18 * sy,
        bottomLeft: Radius.circular(1.6 * sx),
      ),
      blue,
    );

    // Green right pillar (#34A853)
    final green = Paint()..color = const Color(0xFF34A853);
    canvas.drawRRect(
      RRect.fromLTRBAndCorners(
        18.55 * sx,
        3.5 * sy,
        24 * sx,
        18 * sy,
        bottomRight: Radius.circular(1.6 * sx),
      ),
      green,
    );

    // Red center V (#EA4335)
    final red = Paint()..color = const Color(0xFFEA4335);
    final vPath = Path()
      ..moveTo(5.45 * sx, 7.64 * sy)
      ..lineTo(5.45 * sx, 0.82 * sy)
      ..lineTo(12 * sx, 5.73 * sy)
      ..lineTo(18.55 * sx, 0.82 * sy)
      ..lineTo(18.55 * sx, 7.64 * sy)
      ..lineTo(12 * sx, 12.55 * sy)
      ..close();
    canvas.drawPath(vPath, red);

    // Dark red top-left fold (#C5221F)
    final darkRed = Paint()..color = const Color(0xFFC5221F);
    final leftFold = Path()
      ..moveTo(0, 3.55 * sy)
      ..lineTo(0, 2.18 * sy)
      ..quadraticBezierTo(0, 0.2 * sy, 3.49 * sx, 0.43 * sy)
      ..lineTo(5.45 * sx, 1.9 * sy)
      ..lineTo(5.45 * sx, 8.72 * sy)
      ..close();
    canvas.drawPath(leftFold, darkRed);

    // Yellow top-right fold (#FBBC04)
    final yellow = Paint()..color = const Color(0xFFFBBC04);
    final rightFold = Path()
      ..moveTo(18.55 * sx, 1.9 * sy)
      ..lineTo(20.51 * sx, 0.43 * sy)
      ..quadraticBezierTo(24 * sx, 0.2 * sy, 24 * sx, 2.18 * sy)
      ..lineTo(24 * sx, 3.55 * sy)
      ..lineTo(18.55 * sx, 8.72 * sy)
      ..close();
    canvas.drawPath(rightFold, yellow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Exact Facebook blue circle (#0866FF) with crisp white 'f'
class FacebookLogoIcon extends StatelessWidget {
  final double size;
  const FacebookLogoIcon({super.key, this.size = 32});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFF0866FF),
        boxShadow: [
          BoxShadow(
            color: Color(0x45173F46),
            blurRadius: 3,
            offset: Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        'f',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.72,
          fontWeight: FontWeight.w900,
          height: 1.05,
        ),
      ),
    );
  }
}

/// Exact emerald phone SVG icon from halla-web/index.html (#35B394 + #D6FFF2)
class PhoneOptionIcon extends StatelessWidget {
  final double size;
  const PhoneOptionIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _PhonePainter());
  }
}

class _PhonePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6 * s, 1 * s, 20 * s, 30 * s),
        Radius.circular(4 * s),
      ),
      Paint()..color = const Color(0xFF35B394),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(8 * s, 4 * s, 16 * s, 20 * s),
        Radius.circular(1.5 * s),
      ),
      Paint()..color = const Color(0xFFD6FFF2),
    );
    canvas.drawCircle(
      Offset(16 * s, 27 * s),
      1.6 * s,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Exact golden exclamation Terms SVG icon from halla-web/index.html (#EFBD45 + #AA7416)
class TermsOptionIcon extends StatelessWidget {
  final double size;
  const TermsOptionIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _TermsPainter());
  }
}

class _TermsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;
    final fill = Paint()..color = const Color(0xFFEFBD45);
    final stroke = Paint()
      ..color = const Color(0xFFAA7416)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1 * s;

    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(12.2 * s, 2.2 * s, 7.6 * s, 18.2 * s),
      Radius.circular(3.8 * s),
    );
    canvas.drawRRect(body, fill);
    canvas.drawRRect(body, stroke);

    canvas.drawLine(
      Offset(14.4 * s, 5.5 * s),
      Offset(14.8 * s, 13.8 * s),
      Paint()
        ..color = const Color(0xFFFFF1BC)
        ..strokeWidth = 1.8 * s
        ..strokeCap = StrokeCap.round,
    );

    canvas.drawCircle(Offset(16 * s, 26.2 * s), 3.7 * s, fill);
    canvas.drawCircle(Offset(16 * s, 26.2 * s), 3.7 * s, stroke);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Exact blue support-agent headset SVG icon from halla-web/index.html
class HelpOptionIcon extends StatelessWidget {
  final double size;
  const HelpOptionIcon({super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size.square(size), painter: _HelpPainter());
  }
}

class _HelpPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 32.0;
    // Shoulders (#338BC1)
    final shoulders = Path()
      ..moveTo(4 * s, 29 * s)
      ..quadraticBezierTo(5 * s, 20.5 * s, 13 * s, 19.5 * s)
      ..lineTo(19 * s, 19.5 * s)
      ..quadraticBezierTo(27 * s, 20.5 * s, 28 * s, 29 * s)
      ..close();
    canvas.drawPath(shoulders, Paint()..color = const Color(0xFF338BC1));

    // Head (#318CC4)
    canvas.drawCircle(
      Offset(16 * s, 12 * s),
      6.8 * s,
      Paint()..color = const Color(0xFF318CC4),
    );

    // Headset arc (#2675A6)
    final arc = Path()
      ..moveTo(6 * s, 13 * s)
      ..arcToPoint(
        Offset(26 * s, 13 * s),
        radius: Radius.circular(10 * s),
      )
      ..lineTo(26 * s, 16 * s)
      ..quadraticBezierTo(26 * s, 21 * s, 18 * s, 21 * s);
    canvas.drawPath(
      arc,
      Paint()
        ..color = const Color(0xFF2675A6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * s
        ..strokeCap = StrokeCap.round,
    );

    // Ear cups (#438DB6)
    final cupPaint = Paint()..color = const Color(0xFF438DB6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(3 * s, 11 * s, 4.8 * s, 8 * s),
        Radius.circular(2 * s),
      ),
      cupPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(24.2 * s, 11 * s, 4.8 * s, 8 * s),
        Radius.circular(2 * s),
      ),
      cupPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
