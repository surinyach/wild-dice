import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FutureFeaturePage extends StatelessWidget {
  const FutureFeaturePage({
    required this.title,
    required this.message,
    required this.details,
    required this.icon,
    required this.accentColor,
    super.key,
  });

  final String title;
  final String message;
  final String details;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFF11162D),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
          child: _MainMenuBackButton(accentColor: accentColor),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/main_menu_jungle.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x5511162D),
                  Color(0xB311162D),
                  Color(0xF211162D),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xE61D254A),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.75),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 12),
                        ),
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.18),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accentColor.withValues(alpha: 0.8),
                                width: 2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Icon(
                                icon,
                                size: 58,
                                color: accentColor,
                                semanticLabel: title,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            message,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.baloo2(
                              color: Colors.white,
                              fontSize: 27,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            details,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: Colors.white.withValues(alpha: 0.78),
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: 22),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 9,
                              ),
                              child: Text(
                                'COMING SOON',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: accentColor,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainMenuBackButton extends StatelessWidget {
  const _MainMenuBackButton({required this.accentColor});

  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.38),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          BoxShadow(color: accentColor.withValues(alpha: 0.28), blurRadius: 12),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(0xE61D254A),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.8),
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(15),
            child: const Tooltip(
              message: 'Back to main menu',
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
