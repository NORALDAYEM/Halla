import 'dart:math' as math;
import 'package:flutter/material.dart';

class HalaaAnimatedLogo extends StatefulWidget {
  final double height;
  final String assetPath;

  const HalaaAnimatedLogo({
    super.key,
    required this.height,
    this.assetPath = 'assets/images/halaa-clear.webp',
  });

  @override
  State<HalaaAnimatedLogo> createState() => _HalaaAnimatedLogoState();
}

class _HalaaAnimatedLogoState extends State<HalaaAnimatedLogo>
    with TickerProviderStateMixin {
  late final AnimationController _crownCtrl;
  late final AnimationController _particleCtrl;

  static const List<_MicParticle> _particles = [
    _MicParticle(symbol: '♪', isRose: false, phase: 0.00, side: -1.0, spread: 0.42, rise: 0.34, color: Color(0xFF118B97)),
    _MicParticle(symbol: '🌹', isRose: true, phase: 0.12, side: 1.0, spread: 0.38, rise: 0.32, color: Color(0xFFE11D48)),
    _MicParticle(symbol: '♫', isRose: false, phase: 0.24, side: 1.0, spread: 0.46, rise: 0.36, color: Color(0xFF54649F)),
    _MicParticle(symbol: '🌸', isRose: true, phase: 0.36, side: -1.0, spread: 0.40, rise: 0.30, color: Color(0xFFEC4899)),
    _MicParticle(symbol: '♬', isRose: false, phase: 0.48, side: -1.0, spread: 0.48, rise: 0.38, color: Color(0xFFD4A017)),
    _MicParticle(symbol: '🌹', isRose: true, phase: 0.60, side: -1.0, spread: 0.34, rise: 0.35, color: Color(0xFFE11D48)),
    _MicParticle(symbol: '♪', isRose: false, phase: 0.72, side: 1.0, spread: 0.44, rise: 0.33, color: Color(0xFF118B97)),
    _MicParticle(symbol: '🌸', isRose: true, phase: 0.85, side: 1.0, spread: 0.35, rise: 0.37, color: Color(0xFFEC4899)),
  ];

  @override
  void initState() {
    super.initState();
    _crownCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    )..repeat();
  }

  @override
  void dispose() {
    _crownCtrl.dispose();
    _particleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height;
    return SizedBox(
      height: h,
      width: h,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          ClipRect(
            clipper: const _VerticalSliceClipper(topFactor: 0.165, bottomFactor: 1.0),
            child: Image.asset(
              widget.assetPath,
              height: h,
              fit: BoxFit.contain,
            ),
          ),
          AnimatedBuilder(
            animation: _crownCtrl,
            builder: (context, child) {
              final angle = _crownCtrl.value * 2 * math.pi;
              return Transform(
                alignment: const Alignment(0, -0.82),
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0022)
                  ..rotateY(angle),
                child: child,
              );
            },
            child: ClipRect(
              clipper: const _VerticalSliceClipper(topFactor: 0.0, bottomFactor: 0.165),
              child: Image.asset(
                widget.assetPath,
                height: h,
                fit: BoxFit.contain,
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _particleCtrl,
              builder: (context, _) {
                return Stack(
                  clipBehavior: Clip.none,
                  children: _particles.map((p) {
                    final progress = (_particleCtrl.value + p.phase) % 1.0;
                    final opacity = progress < 0.18
                        ? progress / 0.18
                        : (progress > 0.72 ? (1.0 - progress) / 0.28 : 1.0);
                    final dx = p.side * (h * p.spread * progress) +
                        math.sin(progress * math.pi * 2) * (h * 0.03);
                    final dy = -(h * p.rise * progress);
                    final scale = 0.55 + (progress * 0.55);
                    final rot = math.sin(progress * math.pi * 2) * 0.22;
                    final baseSize = (h * (p.isRose ? 0.085 : 0.095)).clamp(12.0, 22.0);
                    return Positioned(
                      left: (h * 0.5) + dx - (baseSize * 0.5),
                      top: (h * 0.30) + dy - (baseSize * 0.5),
                      child: Opacity(
                        opacity: opacity.clamp(0.0, 1.0),
                        child: Transform.rotate(
                          angle: rot,
                          child: Transform.scale(
                            scale: scale,
                            child: Text(
                              p.symbol,
                              style: TextStyle(
                                fontSize: baseSize,
                                fontWeight: FontWeight.w700,
                                color: p.color,
                                shadows: const [
                                  Shadow(
                                    color: Color.fromRGBO(255, 255, 255, 0.8),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VerticalSliceClipper extends CustomClipper<Rect> {
  final double topFactor;
  final double bottomFactor;

  const _VerticalSliceClipper({
    required this.topFactor,
    required this.bottomFactor,
  });

  @override
  Rect getClip(Size size) {
    return Rect.fromLTRB(
      0,
      size.height * topFactor,
      size.width,
      size.height * bottomFactor,
    );
  }

  @override
  bool shouldReclip(covariant _VerticalSliceClipper oldClipper) {
    return oldClipper.topFactor != topFactor ||
        oldClipper.bottomFactor != bottomFactor;
  }
}

class _MicParticle {
  final String symbol;
  final bool isRose;
  final double phase;
  final double side;
  final double spread;
  final double rise;
  final Color color;

  const _MicParticle({
    required this.symbol,
    required this.isRose,
    required this.phase,
    required this.side,
    required this.spread,
    required this.rise,
    required this.color,
  });
}
