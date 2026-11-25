import 'dart:async';
import 'package:flutter/material.dart';
import '../models/halaa_models.dart';

/// Exact replica of `.welcome-gallery` & `.bg-stage` from NORALDAYEM/Halla.
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

class _WelcomeGalleryBackgroundState extends State<WelcomeGalleryBackground> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.images.isNotEmpty
        ? widget.images[_index % widget.images.length]
        : null;

    return Stack(
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
        // Exact overlay scrim matching welcome-gallery.css / admin/index.html
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
      ],
    );
  }
}
