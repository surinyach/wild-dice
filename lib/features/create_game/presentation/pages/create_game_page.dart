import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../services/game_service.dart';
import '../../../../shared/widgets/jungle_action_button.dart';
import '../../../../shared/widgets/jungle_background.dart';
import '../../../../shared/widgets/wild_dice_logo.dart';
import '../../../main_menu/domain/main_menu_identity.dart';

class CreateGamePage extends StatefulWidget {
  const CreateGamePage({
    required this.identityController,
    required this.gameService,
    super.key,
  });

  final MainMenuIdentityController identityController;
  final GameCreator gameService;

  @override
  State<CreateGamePage> createState() => _CreateGamePageState();
}

class _CreateGamePageState extends State<CreateGamePage> {
  int _totalRounds = 5;
  bool _isCreating = false;
  String? _errorMessage;

  Future<void> _createGame() async {
    if (_isCreating) return;
    setState(() {
      _isCreating = true;
      _errorMessage = null;
    });
    try {
      final game = await widget.gameService.createGame(
        nickname: widget.identityController.nickname,
        avatarId: widget.identityController.avatarId,
        totalRounds: _totalRounds,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRouter.gameLobby, arguments: game);
    } on GameServiceException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } catch (_) {
      if (mounted) {
        setState(
          () => _errorMessage = 'Could not create the game. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF11162D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const JungleBackground(key: Key('create-game-background')),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxHeight < 700;
                final logoSize = compact ? 300.0 : 405.0;
                final buttonWidth = math.min(
                  constraints.maxWidth * 0.68,
                  300.0,
                );
                final buttonHeight = compact ? 50.0 : 58.0;
                final gap = compact ? 10.0 : 14.0;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Transform.translate(
                      offset: Offset(0, compact ? -12 : -18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WildDiceLogo(size: logoSize),
                          SizedBox(height: compact ? 28 : 36),
                          for (final rounds in const [3, 5, 10]) ...[
                            _RoundButton(
                              key: Key('round-$rounds'),
                              rounds: rounds,
                              selected: _totalRounds == rounds,
                              width: buttonWidth,
                              height: buttonHeight,
                              onPressed: () =>
                                  setState(() => _totalRounds = rounds),
                            ),
                            if (rounds != 10) SizedBox(height: gap),
                          ],
                          SizedBox(height: compact ? 24 : 30),
                          JungleActionButton(
                            key: const Key('confirm-create-game'),
                            label: 'CREATE GAME',
                            semanticsLabel: 'Create game',
                            width: buttonWidth,
                            height: buttonHeight,
                            loading: _isCreating,
                            onPressed: _isCreating ? null : _createGame,
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _errorMessage!,
                              key: const Key('creation-error'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFFFFC2B8),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: _MainMenuBackButton(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MainMenuBackButton extends StatelessWidget {
  const _MainMenuBackButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 46,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xE61D254A),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xCC8BCB2A), width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x61000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const Key('create-game-back-button'),
            onTap: () => Navigator.of(context).maybePop(),
            borderRadius: BorderRadius.circular(12),
            child: const Tooltip(
              message: 'Back to main menu',
              child: Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.rounds,
    required this.selected,
    required this.width,
    required this.height,
    required this.onPressed,
    super.key,
  });

  final int rounds;
  final bool selected;
  final double width;
  final double height;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final gradient = selected
        ? const [Color(0xFF5C8F2B), Color(0xFF3D6C1D), Color(0xFF294C16)]
        : const [Color(0xFF28583A), Color(0xFF1A432B), Color(0xFF102E1D)];
    return Semantics(
      button: true,
      selected: selected,
      label: '$rounds rounds',
      child: SizedBox(
        width: width,
        height: height,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? const Color(0xFFA7D943)
                  : const Color(0xFF477354),
              width: 3,
            ),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradient,
              stops: const [0, 0.5, 1],
            ),
            boxShadow: [
              const BoxShadow(
                color: Color(0x99061109),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
              if (selected)
                const BoxShadow(color: Color(0x669DDB2F), blurRadius: 14),
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
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (selected) ...[
                          const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          '$rounds rounds',
                          style: GoogleFonts.baloo2(
                            color: Colors.white,
                            fontSize: 25,
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
                      ],
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
