import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/routing/app_router.dart';
import '../../../../services/game_service.dart';
import '../../../../shared/widgets/jungle_action_button.dart';
import '../../../../shared/widgets/jungle_background.dart';
import '../../../../shared/widgets/wild_dice_logo.dart';
import '../../../main_menu/domain/main_menu_identity.dart';

class JoinGamePage extends StatefulWidget {
  const JoinGamePage({
    required this.identityController,
    required this.gameService,
    super.key,
  });

  final MainMenuIdentityController identityController;
  final GameJoiner gameService;

  @override
  State<JoinGamePage> createState() => _JoinGamePageState();
}

class _JoinGamePageState extends State<JoinGamePage> {
  final _codeController = TextEditingController();
  bool _joining = false;
  String? _error;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    if (_joining) return;
    final code = _codeController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() => _error = 'Enter a game code.');
      return;
    }
    if (!widget.identityController.isValid) {
      setState(
        () =>
            _error = 'Choose your nickname and avatar on the Main Menu first.',
      );
      return;
    }
    final nickname = widget.identityController.nickname;
    final avatarId = widget.identityController.avatarId;
    FocusScope.of(context).unfocus();
    setState(() {
      _joining = true;
      _error = null;
    });
    try {
      final game = await widget.gameService.findGameByJoinCode(code);
      if (!mounted) return;
      if (game == null) {
        throw const GameServiceException(
          GameServiceErrorCode.gameNotFound,
          'No game found. Check the code and try again.',
        );
      }
      if (game.status != GameStatus.lobby) {
        throw const GameServiceException(
          GameServiceErrorCode.gameUnavailable,
          'This game is no longer available to join.',
        );
      }
      await widget.gameService.joinGame(
        game.id,
        nickname: nickname,
        avatarId: avatarId,
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacementNamed(AppRouter.gameLobby, arguments: game);
    } on GameServiceException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not join the game. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_joining,
    child: Scaffold(
      backgroundColor: const Color(0xFF11162D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const JungleBackground(),
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
                          Container(
                            width: buttonWidth,
                            height: buttonHeight,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: const Color(0xFFDADDD7),
                                width: 3,
                              ),
                              gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white,
                                  Color(0xFFF4F5F1),
                                  Color(0xFFE1E4DC),
                                ],
                                stops: [0, 0.5, 1],
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x99061109),
                                  blurRadius: 14,
                                  offset: Offset(0, 7),
                                ),
                                BoxShadow(
                                  color: Color(0x33FFFFFF),
                                  blurRadius: 14,
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: TextField(
                              key: const Key('game-code-field'),
                              controller: _codeController,
                              enabled: !_joining,
                              textCapitalization: TextCapitalization.characters,
                              textInputAction: TextInputAction.done,
                              autocorrect: false,
                              enableSuggestions: false,
                              textAlign: TextAlign.center,
                              textAlignVertical: TextAlignVertical.center,
                              style: GoogleFonts.baloo2(
                                color: const Color(0xFF30382D),
                                fontSize: 22,
                                height: 1,
                                fontWeight: FontWeight.w800,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'GAME CODE',
                                hintStyle: TextStyle(color: Color(0xFF62695E)),
                                isCollapsed: true,
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              onSubmitted: (_) => _join(),
                              onChanged: (_) {
                                if (_error != null) {
                                  setState(() => _error = null);
                                }
                              },
                            ),
                          ),
                          SizedBox(height: compact ? 24 : 30),
                          JungleActionButton(
                            key: const Key('confirm-join-game'),
                            label: 'JOIN GAME',
                            width: buttonWidth,
                            height: buttonHeight,
                            loading: _joining,
                            semanticsLabel: _joining
                                ? 'Joining game'
                                : 'Join game',
                            onPressed: _joining ? null : _join,
                          ),
                          // Reserve the same space as Create Game's extra round
                          // options so the centered logo has the same position.
                          SizedBox(
                            height: 2 * (buttonHeight + gap),
                            child: _error == null
                                ? null
                                : SingleChildScrollView(
                                    child: Column(
                                      children: [
                                        const SizedBox(height: 16),
                                        Semantics(
                                          liveRegion: true,
                                          child: Text(
                                            _error!,
                                            key: const Key('join-error'),
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Color(0xFFFFC2B8),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: SizedBox.square(
                  dimension: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xE61D254A),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xCC8BCB2A),
                        width: 2,
                      ),
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
                        key: const Key('join-game-back-button'),
                        onTap: _joining
                            ? null
                            : () => Navigator.of(context).maybePop(),
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
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
