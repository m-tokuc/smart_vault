import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;
  final double borderRadius;
  final double blur;
  final double border;
  final Color? color;

  const GlassmorphicContainer({
    super.key,
    this.width,
    this.height,
    required this.child,
    this.borderRadius = 20,
    this.blur = 10,
    this.border = 1.5,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        width: width,
        height: height,
        color: Colors.transparent,
        child: Stack(
          children: [
            // Blob/Background effect can be added behind this widget in specific screens
            // This widget provides the glass effect itself
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: border,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      (color ?? Colors.white).withOpacity(0.1),
                      (color ?? Colors.white).withOpacity(0.05),
                    ],
                  ),
                ),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
