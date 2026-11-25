import 'dart:async';
import 'package:flutter/material.dart';
import '../models/halaa_config.dart';
import '../theme/halaa_themes.dart';

/// Shared rotating real-photo glassmorphic background used identically across
/// Login, Post-Login App, and Admin screens.
class HalaaBackground extends StatefulWidget {
  final List<BackgroundItem> images;
  final int rotationSeconds;
  final HalaaThemePreset theme;
  final Widget child;

  const HalaaBackground({
    super.key,
    required this.images,
    required this.rotationSeconds,
    required this.theme,
    required this.child,
  });

  @override
  State<HalaaBackground> createState() => _HalaaBackgroundState();
}

class _HalaaBackgroundState extends State<HalaaBackground> {
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restart();
  }

  @override
  void didUpdateWidget(covariant HalaaBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rotationSeconds != widget.rotationSeconds ||
        oldWidget.images.length != widget.images.length) {
      _index = 0;
      _restart();
    }
  }

  void _restart() {
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
    final currentUrl = widget.images.isNotEmpty
        ? widget.images[_index % widget.images.length].url
        : '';

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [widget.theme.bgTop, widget.theme.bgBottom],
            ),
          ),
        ),
        if (currentUrl.isNotEmpty)
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 900),
            child: Image.network(
              currentUrl,
              key: ValueKey(currentUrl),
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color.fromRGBO(4, 15, 26, 0.44),
                const Color.fromRGBO(4, 15, 26, 0.72),
              ],
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}
