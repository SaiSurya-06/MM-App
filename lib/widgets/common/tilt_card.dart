import 'dart:math' as math;
import 'package:flutter/material.dart';

class TiltCard extends StatefulWidget {
  final Widget child;
  final double maxTilt; // Maximum tilt angle in degrees
  final bool enabled;

  const TiltCard({
    super.key,
    required this.child,
    this.maxTilt = 8.0,
    this.enabled = true,
  });

  @override
  State<TiltCard> createState() => _TiltCardState();
}

class _TiltCardState extends State<TiltCard> {
  double _rotateX = 0.0;
  double _rotateY = 0.0;
  bool _isTapped = false;

  void _onPanUpdate(DragUpdateDetails details, Size size) {
    if (size.width == 0 || size.height == 0) return;

    // Calculate position relative to center of the card
    final localPos = details.localPosition;
    
    // Normalize coordinates to range [-1.0, 1.0]
    final dx = (localPos.dx - (size.width / 2)) / (size.width / 2);
    final dy = (localPos.dy - (size.height / 2)) / (size.height / 2);

    // Bound values
    final double clampedDx = dx.clamp(-1.0, 1.0);
    final double clampedDy = dy.clamp(-1.0, 1.0);

    setState(() {
      // Rotate Y based on horizontal movement (X), rotate X based on vertical movement (Y)
      _rotateX = -clampedDy * (widget.maxTilt * math.pi / 180);
      _rotateY = clampedDx * (widget.maxTilt * math.pi / 180);
    });
  }

  void _onPanEnd() {
    setState(() {
      _rotateX = 0.0;
      _rotateY = 0.0;
      _isTapped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (!widget.enabled || disableAnimations) {
      return widget.child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        
        return GestureDetector(
          onPanStart: (_) => setState(() => _isTapped = true),
          onPanUpdate: (details) => _onPanUpdate(details, size),
          onPanEnd: (_) => _onPanEnd(),
          onPanCancel: () => _onPanEnd(),
          child: TweenAnimationBuilder<Matrix4>(
            duration: Duration(milliseconds: _isTapped ? 50 : 350),
            curve: _isTapped ? Curves.linear : Curves.easeOutBack, // spring-like deceleration curve
            tween: Matrix4Tween(
              begin: Matrix4.identity(),
              end: Matrix4.identity()
                ..setEntry(3, 2, 0.0015) // Perspective coefficient
                ..rotateX(_rotateX)
                ..rotateY(_rotateY),
            ),
            builder: (context, matrix, child) {
              return Transform(
                transform: matrix,
                alignment: FractionalOffset.center,
                child: child,
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }
}
