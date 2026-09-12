import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FutureFeaturePage extends StatefulWidget {
  const FutureFeaturePage({
    required this.title,
    required this.message,
    required this.details,
    required this.icon,
    required this.accentColor,
    this.onBack,
    super.key,
  });

  final String title;
  final String message;
  final String details;
  final IconData icon;
  final Color accentColor;
  final Future<void> Function()? onBack;

  @override
  State<FutureFeaturePage> createState() => _FutureFeaturePageState();
}

class _FutureFeaturePageState extends State<FutureFeaturePage> {
  bool _leaving = false;
  bool _canPop = false;

  Future<void> _handleBack() async {
    if (_leaving) return;
    if (widget.onBack == null) {
      Navigator.of(context).maybePop();
      return;
    }
    setState(() => _leaving = true);
    try {
      await widget.onBack!();
      if (!mounted) return;
      setState(() => _canPop = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).maybePop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _leaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return PopScope<void>(
      canPop: widget.onBack == null || _canPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _handleBack();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF11162D),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          toolbarHeight: 64,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
            child: _MainMenuBackButton(
              accentColor: widget.accentColor,
              onPressed: _leaving ? null : _handleBack,
            ),
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
                          color: widget.accentColor.withValues(alpha: 0.75),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 12),
                          ),
                          BoxShadow(
                            color: widget.accentColor.withValues(alpha: 0.18),
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
                                color: widget.accentColor.withValues(
                                  alpha: 0.2,
                                ),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.accentColor.withValues(
                                    alpha: 0.8,
                                  ),
                                  width: 2,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24),
                                child: Icon(
                                  widget.icon,
                                  size: 58,
                                  color: widget.accentColor,
                                  semanticLabel: widget.title,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            Text(
                              widget.message,
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
                              widget.details,
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.78),
                                height: 1.45,
                              ),
                            ),
                            const SizedBox(height: 22),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: widget.accentColor.withValues(
                                  alpha: 0.16,
                                ),
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
                                    color: widget.accentColor,
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
      ),
    );
  }
}

class _MainMenuBackButton extends StatelessWidget {
  const _MainMenuBackButton({
    required this.accentColor,
    required this.onPressed,
  });

  final Color accentColor;
  final VoidCallback? onPressed;

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
            onTap: onPressed,
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
