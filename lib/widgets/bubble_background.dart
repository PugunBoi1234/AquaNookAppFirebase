import 'dart:math';
import 'package:flutter/material.dart';

class BubbleBackground extends StatefulWidget {
  const BubbleBackground({super.key});

  @override
  State<BubbleBackground> createState() => _BubbleBackgroundState();
}

class _BubbleBackgroundState extends State<BubbleBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_BubbleModel> _bubbles = List.generate(10, (i) => _BubbleModel());

  @override
  void initState() {
    super.initState();
    for (var bubble in _bubbles) {
      bubble.reset(isInitial: true);
    }
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..addListener(() {
        setState(() {
          for (var bubble in _bubbles) {
            bubble.update();
          }
        });
      })..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubblePainter(_bubbles),
      child: Container(),
    );
  }
}

class _BubbleModel {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  late double swing;
  late double offset;

  void reset({bool isInitial = false}) {
    final rand = Random();
    x = rand.nextDouble();
    y = isInitial ? rand.nextDouble() : 1.0 + (rand.nextDouble() * 0.2);
    size = rand.nextDouble() * 8 + 4;
    speed = rand.nextDouble() * 0.0012 + 0.0006;
    opacity = rand.nextDouble() * 0.2 + 0.08;
    swing = rand.nextDouble() * 12 + 4;
    offset = rand.nextDouble() * pi * 2;
  }

  void update() {
    y -= speed;
    if (y < -0.1) {
      reset(isInitial: false);
    }
  }
}

class _BubblePainter extends CustomPainter {
  final List<_BubbleModel> bubbles;

  _BubblePainter(this.bubbles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var bubble in bubbles) {
      final currentY = bubble.y * size.height;
      final currentX = (bubble.x * size.width) + sin((bubble.y * 8) + bubble.offset) * bubble.swing;

      final paint = Paint()
        ..color = Colors.white.withOpacity(bubble.opacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(currentX, currentY), bubble.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BubblePainter oldDelegate) => true;
}