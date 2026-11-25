import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/halaa_models.dart';

/// Exact replica of `.welcome-gallery` & `.bg-stage` + `.hala-petals`
/// floating animated musical notes on pull-down refresh (without default spinner).
class WelcomeGalleryBackground extends StatefulWidget {
  final List<BackgroundItem> images;
  final int rotationSeconds;
  final bool darkAdminScrim;
  final Widget child;

  const WelcomeGalleryBackground({
    super.key,
    required this.images,
    required this.rotationSeconds,
    this.darkAdminScrim = false,
    required this.child,
  });

  @override
  State<WelcomeGalleryBackground> createState() =>
      _WelcomeGalleryBackgroundState();
}

class _WelcomeGalleryBackgroundState extends State<WelcomeGalleryBackground>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  Timer? _hideNotesTimer;
  int _index = 0;
  double _pullOffset = 0;
  bool _showMelody = false;
  late final AnimationController _melodyCtrl;

  @override
  void initState() {
    super.initState();
    _melodyCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    )..repeat();
    _start();
  }

  @override
  void didUpdateWidget(covariant WelcomeGalleryBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotationSeconds != widget.rotationSeconds ||
        oldWidget.images.length != widget.images.length) {
      _index = 0;
      _start();
    }
  }

  void _start() {
    _timer?.cancel();
    if (widget.images.length <= 1) return;
    final secs = widget.rotationSeconds.clamp(2, 60);
    _timer = Timer.periodic(Duration(seconds: secs), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % widget.images.length);
    });
  }

  void _triggerMelodyRefresh() {
    _hideNotesTimer?.cancel();
    setState(() {
      _showMelody = true;
      _pullOffset = 0;
    });
    _hideNotesTimer = Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _showMelody = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hideNotesTimer?.cancel();
    _melodyCtrl.dispose();
    super.dispose();
  }

  Widget _buildFloatingMelody() {
    const notes = ['♪', '♫', '♬', '♪', '♫'];
    return AnimatedOpacity(
      opacity: _showMelody ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 180),
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _melodyCtrl,
          builder: (context, _) {
            final t = _melodyCtrl.value * 2 * math.pi;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(notes.length, (i) {
                final phase = t - (i * 0.72);
                final dy = math.sin(phase) * 3.5;
                final angle = math.sin(phase) * 0.16;
                final isAltColor = (i + 1) % 3 == 0;
                final isSmall = (i + 1) % 2 == 0;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Transform.translate(
                    offset: Offset(0, dy),
                    child: Transform.rotate(
                      angle: angle,
                      child: Text(
                        notes[i],
                        style: TextStyle(
                          fontSize: isSmall ? 24 : 30,
                          fontWeight: FontWeight.w700,
                          color: isAltColor
                              ? const Color(0xFF54649F)
                              : const Color(0xFF118B97),
                          shadows: const [
                            Shadow(
                              color: Color.fromRGBO(255, 255, 255, 0.75),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.images.isNotEmpty
        ? widget.images[_index % widget.images.length]
        : null;

    return Listener(
      onPointerMove: (event) {
        if (event.delta.dy > 0) {
          _pullOffset += event.delta.dy;
          if (_pullOffset > 48 && !_showMelody) {
            _triggerMelodyRefresh();
          }
        } else if (event.delta.dy < -6) {
          _pullOffset = 0;
        }
      },
      onPointerUp: (_) => _pullOffset = 0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: widget.darkAdminScrim
                ? const Color(0xFF071B21)
                : const Color(0xFFD5E1DD),
          ),
          if (item != null)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 1200),
              child: item.isAsset
                  ? Image.asset(
                      item.path,
                      key: ValueKey(item.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : Image.network(
                      item.path,
                      key: ValueKey(item.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: widget.darkAdminScrim
                  ? const RadialGradient(
                      center: Alignment(0, -0.55),
                      radius: 1.15,
                      colors: [
                        Color.fromRGBO(9, 32, 40, 0.22),
                        Color.fromRGBO(5, 18, 24, 0.76),
                      ],
                    )
                  : const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.0, 0.47, 0.82, 1.0],
                      colors: [
                        Color(0x1AEAFFF9),
                        Color(0x00FFFFFF),
                        Color(0x40F8FCFA),
                        Color(0x55F8FCFA),
                      ],
                    ),
            ),
          ),
          widget.child,
          Positioned(
            top: MediaQuery.of(context).padding.top + 24,
            left: 0,
            right: 0,
            child: Center(child: _buildFloatingMelody()),
          ),
        ],
      ),
    );
  }
}
