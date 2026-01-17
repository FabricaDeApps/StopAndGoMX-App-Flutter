import 'package:flutter/material.dart';

class LiveBreathingBadge extends StatefulWidget {
  final String label;
  final Color color;
  final bool animate;

  const LiveBreathingBadge({
    super.key,
    required this.label,
    required this.color,
    this.animate = true,
  });

  @override
  State<LiveBreathingBadge> createState() => _LiveBreathingBadgeState();
}

class _LiveBreathingBadgeState extends State<LiveBreathingBadge>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    if (widget.animate) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
      )..repeat(reverse: true);

      _scale = Tween<double>(
        begin: 0.95,
        end: 1.05,
      ).animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    } else {
      // Escala fija cuando no hay animación
      _scale = const AlwaysStoppedAnimation(1.0);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
