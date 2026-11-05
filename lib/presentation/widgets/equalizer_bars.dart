import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A small animated "now playing" equalizer: a row of bars that bounce while
/// [playing] is true and rest at a low height when paused.
class EqualizerBars extends StatefulWidget {
  final bool playing;
  final Color color;
  final double height;
  final int barCount;

  const EqualizerBars({
    super.key,
    required this.playing,
    this.color = Colors.white,
    this.height = 20,
    this.barCount = 4,
  });

  @override
  State<EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<double> _phases;

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _phases = List.generate(widget.barCount, (_) => random.nextDouble());
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playing != widget.playing) _syncAnimation();
  }

  void _syncAnimation() {
    if (widget.playing) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (i) {
              final t = widget.playing
                  ? (math.sin((_controller.value + _phases[i]) * math.pi * 2) +
                          1) /
                      2
                  : 0.2;
              final barHeight = widget.height * (0.25 + 0.75 * t);
              return Container(
                width: 3,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}
