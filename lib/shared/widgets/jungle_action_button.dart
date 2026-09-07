import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class JungleActionButton extends StatelessWidget {
  const JungleActionButton({
    required this.label,
    required this.width,
    required this.height,
    required this.onPressed,
    this.loading = false,
    this.semanticsLabel,
    this.borderColor = const Color(0xFFD2A42B),
    this.gradientColors = const [
      Color(0xFFAE831C),
      Color(0xFF88620F),
      Color(0xFF5F4309),
    ],
    this.glowColor = const Color(0x668D6815),
    super.key,
  });

  final String label;
  final double width;
  final double height;
  final VoidCallback? onPressed;
  final bool loading;
  final String? semanticsLabel;
  final Color borderColor;
  final List<Color> gradientColors;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticsLabel ?? label,
      child: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 3),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradientColors,
              stops: const [0, 0.5, 1],
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x99061109),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
              BoxShadow(color: glowColor, blurRadius: 14),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: onPressed,
              child: Stack(
                children: [
                  Positioned(
                    left: 10,
                    right: 10,
                    top: 6,
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Center(
                    child: loading
                        ? const SizedBox.square(
                            dimension: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            label,
                            style: GoogleFonts.baloo2(
                              color: Colors.white,
                              fontSize: 22,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              shadows: const [
                                Shadow(
                                  color: Colors.black45,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
