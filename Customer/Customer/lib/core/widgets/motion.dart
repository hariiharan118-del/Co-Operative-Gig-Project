import 'package:flutter/material.dart';

const kMotionFast = Duration(milliseconds: 120);
const kMotionShort = Duration(milliseconds: 250);
const kStaggerStep = Duration(milliseconds: 50);

/// Fade + slight upward slide, delayed by [index] so list items enter in sequence.
class StaggeredFadeSlide extends StatefulWidget {
  const StaggeredFadeSlide({
    super.key,
    required this.child,
    this.index = 0,
    this.duration = kMotionShort,
    this.delayStep = kStaggerStep,
  });

  final Widget child;
  final int index;
  final Duration duration;
  final Duration delayStep;

  @override
  State<StaggeredFadeSlide> createState() => _StaggeredFadeSlideState();
}

class _StaggeredFadeSlideState extends State<StaggeredFadeSlide> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    final delay = widget.delayStep * widget.index.clamp(0, 8);
    Future<void>.delayed(delay, () {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _visible ? Offset.zero : const Offset(0, 0.06),
      duration: widget.duration,
      curve: Curves.easeOut,
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: widget.duration,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// Scales to 0.96 while pressed for tactile primary-button feedback.
class PressScale extends StatefulWidget {
  const PressScale({
    super.key,
    required this.child,
    this.enabled = true,
  });

  final Widget child;
  final bool enabled;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    // Pointer events (same moments as GestureDetector onTapDown/onTapUp)
    // without joining the gesture arena, so FilledButtons still receive taps.
    return Listener(
      onPointerDown: widget.enabled ? (_) => _setPressed(true) : null,
      onPointerUp: widget.enabled ? (_) => _setPressed(false) : null,
      onPointerCancel: widget.enabled ? (_) => _setPressed(false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: kMotionFast,
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
