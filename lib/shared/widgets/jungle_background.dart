import 'package:flutter/material.dart';

class JungleBackground extends StatelessWidget {
  const JungleBackground({
    this.assetPath = 'assets/images/main_menu_jungle.png',
    this.alignment = Alignment.center,
    super.key,
  });

  final String assetPath;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          assetPath,
          fit: BoxFit.cover,
          alignment: alignment,
          errorBuilder: (_, _, _) => const ColoredBox(color: Color(0xFF11162D)),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.08),
                Colors.black.withValues(alpha: 0.18),
                Colors.black.withValues(alpha: 0.36),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
