import 'package:flutter/material.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Back to main menu',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _joining ? null : () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const JungleBackground(),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const WildDiceLogo(size: 240),
                      const Text(
                        'JOIN GAME',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        key: const Key('game-code-field'),
                        controller: _codeController,
                        enabled: !_joining,
                        textCapitalization: TextCapitalization.characters,
                        textInputAction: TextInputAction.done,
                        autocorrect: false,
                        enableSuggestions: false,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          labelText: 'Game code',
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _join(),
                        onChanged: (_) {
                          if (_error != null) setState(() => _error = null);
                        },
                      ),
                      const SizedBox(height: 24),
                      JungleActionButton(
                        key: const Key('confirm-join-game'),
                        label: 'JOIN GAME',
                        width: 300,
                        height: 58,
                        loading: _joining,
                        semanticsLabel: _joining ? 'Joining game' : 'Join game',
                        onPressed: _joining ? null : _join,
                      ),
                      if (_error != null) ...[
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
                    ],
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
