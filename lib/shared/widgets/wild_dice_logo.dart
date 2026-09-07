import 'package:flutter/material.dart';

class WildDiceLogo extends StatelessWidget {
  const WildDiceLogo({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'WILD DICE',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: Image.asset(
              'assets/images/wild_dice_logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
      ),
    );
  }
}
