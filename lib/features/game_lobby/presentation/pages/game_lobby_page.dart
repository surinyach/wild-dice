import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../services/game_service.dart';
import '../../../../shared/widgets/jungle_action_button.dart';
import '../../../../shared/widgets/jungle_background.dart';
import '../../../../shared/widgets/future_feature_page.dart';

class GameLobbyPage extends StatefulWidget {
  const GameLobbyPage({
    required this.game,
    required this.gameService,
    super.key,
  });

  final Game game;
  final GameLobbyReader gameService;

  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  late Stream<List<GamePlayer>> _players;
  late Game game;
  StreamSubscription<Game?>? _gameSubscription;
  bool _leaving = false;
  bool _left = false;
  bool _starting = false;
  bool _navigated = false;
  String? _gameError;

  void _watchGame() {
    _gameSubscription?.cancel();
    _gameSubscription = widget.gameService
        .watchGame(game.id)
        .listen(
          (updated) {
            if (!mounted || _navigated) return;
            setState(() {
              _gameError = updated == null
                  ? 'This game no longer exists.'
                  : null;
              if (updated != null) game = updated;
            });
            if (updated?.status == GameStatus.inProgress) {
              _navigated = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    settings: RouteSettings(
                      name: '/gameplay',
                      arguments: updated,
                    ),
                    builder: (_) => const FutureFeaturePage(
                      title: 'Gameplay',
                      message: 'Gameplay is coming soon.',
                      details: 'Your game has started.',
                      icon: Icons.sports_esports_rounded,
                      accentColor: Color(0xFF8BCB2A),
                    ),
                  ),
                );
              });
            }
          },
          onError: (Object error) {
            if (mounted) {
              setState(
                () => _gameError = 'Could not refresh the game. Please retry.',
              );
            }
          },
        );
  }

  Future<void> _startGame() async {
    if (_starting ||
        _leaving ||
        _navigated ||
        game.status != GameStatus.lobby) {
      return;
    }
    setState(() => _starting = true);
    try {
      await widget.gameService.startGame(game.id);
    } catch (error) {
      if (!mounted || _navigated) return;
      setState(() => _starting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is GameServiceException
                ? error.message
                : 'Could not start the game. Please try again.',
          ),
        ),
      );
    }
  }

  Future<void> _leave() async {
    if (_leaving || _left) return;
    setState(() => _leaving = true);
    try {
      await widget.gameService.leaveGame(game.id);
      if (!mounted) return;
      setState(() => _left = true);
      await WidgetsBinding.instance.endOfFrame;
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _leaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is GameServiceException &&
                    error.code == GameServiceErrorCode.gameUnavailable
                ? error.message
                : 'Could not leave the game. Please try again.',
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    game = widget.game;
    _players = widget.gameService.watchPlayers(game.id);
    _watchGame();
  }

  @override
  void didUpdateWidget(covariant GameLobbyPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id ||
        oldWidget.gameService != widget.gameService) {
      game = widget.game;
      _players = widget.gameService.watchPlayers(game.id);
      _watchGame();
    }
  }

  @override
  void dispose() {
    _gameSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isHost =
        _gameError == null && widget.gameService.currentUserId == game.hostUid;
    return PopScope<void>(
      canPop: _left,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1F5235),
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
          toolbarHeight: 70,
          leadingWidth: 70,
          leading: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: 12),
              child: _MainMenuBackButton(onPressed: _leaving ? null : _leave),
            ),
          ),
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            LayoutBuilder(
              key: const Key('game-lobby-background'),
              builder: (context, constraints) {
                final isLandscape =
                    constraints.maxWidth > constraints.maxHeight;
                return JungleBackground(
                  assetPath: isLandscape
                      ? AppAssets.gameLobbyBackgroundLandscape
                      : AppAssets.gameLobbyBackground,
                  alignment: Alignment.center,
                );
              },
            ),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final codeSize = constraints.maxWidth < 400 ? 56.0 : 68.0;
                  final compact = constraints.maxHeight < 700;
                  final actionWidth = math.min(
                    constraints.maxWidth * 0.68,
                    300.0,
                  );
                  final actionHeight = compact ? 50.0 : 58.0;
                  return Align(
                    alignment: Alignment.topCenter,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(24, 34, 24, 24),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: 460,
                          minHeight: math.max(0, constraints.maxHeight - 58),
                        ),
                        child: IntrinsicHeight(
                          child: Column(
                            mainAxisSize: MainAxisSize.max,
                            children: [
                              const Text(
                                'GAME CODE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.center,
                                child: Semantics(
                                  label: 'Game code ${game.code}',
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0x8A123524),
                                          Color(0x66123524),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.34,
                                        ),
                                        width: 1.5,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x66000000),
                                          blurRadius: 14,
                                          offset: Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: SelectableText(
                                      game.code,
                                      key: const Key('game-code'),
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: codeSize,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 10,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${game.totalRounds} rounds · Waiting for players',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 36),
                              if (_leaving)
                                const Text(
                                  'Leaving game…',
                                  style: TextStyle(color: Colors.white),
                                ),
                              if (_gameError != null) ...[
                                Text(
                                  _gameError!,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                TextButton(
                                  onPressed: _watchGame,
                                  child: const Text('Retry game'),
                                ),
                              ],
                              StreamBuilder<List<GamePlayer>>(
                                stream: _players,
                                builder: (context, snapshot) {
                                  if (snapshot.hasError) {
                                    return Column(
                                      children: [
                                        const Text(
                                          'Could not load players. Please try again.',
                                          style: TextStyle(color: Colors.white),
                                        ),
                                        TextButton(
                                          onPressed: () => setState(() {
                                            _players = widget.gameService
                                                .watchPlayers(game.id);
                                          }),
                                          child: const Text('Retry'),
                                        ),
                                      ],
                                    );
                                  }
                                  if (!snapshot.hasData) {
                                    return const CircularProgressIndicator(
                                      color: Colors.white,
                                    );
                                  }
                                  final players = snapshot.data!;
                                  if (players.isEmpty) {
                                    return const Text(
                                      'Waiting for players',
                                      style: TextStyle(color: Colors.white),
                                    );
                                  }
                                  return Column(
                                    children: [
                                      for (final player in players)
                                        _PlayerCard(
                                          key: ValueKey('player-${player.id}'),
                                          player: player,
                                          isHost:
                                              player.ownerUid == game.hostUid,
                                        ),
                                    ],
                                  );
                                },
                              ),
                              const Spacer(),
                              SizedBox(height: compact ? 24 : 30),
                              if (isHost)
                                JungleActionButton(
                                  key: const Key('start-game-button'),
                                  label: 'START GAME',
                                  semanticsLabel: 'Start game',
                                  width: actionWidth,
                                  height: actionHeight,
                                  borderColor: const Color(0xFFB68A22),
                                  gradientColors: const [
                                    Color(0xFF8F6914),
                                    Color(0xFF6E4C0B),
                                    Color(0xFF493106),
                                  ],
                                  glowColor: const Color(0x66523B0B),
                                  loading: _starting,
                                  onPressed: _leaving || _starting
                                      ? null
                                      : _startGame,
                                ),
                              if (!isHost)
                                const Text(
                                  'Waiting for the host to start the game',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.white),
                                ),
                              const SizedBox(height: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MainMenuBackButton extends StatelessWidget {
  const _MainMenuBackButton({required this.onPressed});
  final VoidCallback? onPressed;

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
            key: const Key('game-lobby-back-button'),
            onTap: onPressed,
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

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.player, required this.isHost, super.key});

  final GamePlayer player;
  final bool isHost;

  @override
  Widget build(BuildContext context) {
    final avatarPath = AppAssets.avatars[player.avatarId];
    return Card(
      color: const Color(0xED123524),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0x995F8F63), width: 1.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFF426C49),
          backgroundImage: avatarPath == null ? null : AssetImage(avatarPath),
          child: avatarPath == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(
          player.nickname,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          isHost ? 'HOST' : 'PLAYER',
          style: const TextStyle(color: Color(0xFF8BCB2A)),
        ),
      ),
    );
  }
}
