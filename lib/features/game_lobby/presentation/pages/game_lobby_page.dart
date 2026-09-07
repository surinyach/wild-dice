import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/assets/app_assets.dart';
import '../../../../services/game_service.dart';
import '../../../../shared/widgets/jungle_action_button.dart';
import '../../../../shared/widgets/jungle_background.dart';
import '../../../main_menu/domain/main_menu_identity.dart';

class GameLobbyPage extends StatelessWidget {
  const GameLobbyPage({
    required this.game,
    required this.identityController,
    super.key,
  });

  final Game game;
  final MainMenuIdentityController identityController;

  @override
  Widget build(BuildContext context) {
    final avatarPath = AppAssets.avatars[identityController.avatarId];
    return Scaffold(
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
        leading: const Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: EdgeInsets.only(left: 12, top: 12),
            child: _MainMenuBackButton(),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          LayoutBuilder(
            key: const Key('game-lobby-background'),
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
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
                            Card(
                              color: const Color(0xED123524),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(
                                  color: Color(0x995F8F63),
                                  width: 1.5,
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: const Color(0xFF426C49),
                                  backgroundImage: avatarPath == null
                                      ? null
                                      : AssetImage(avatarPath),
                                  child: avatarPath == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                title: Text(
                                  identityController.nickname,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: const Text(
                                  'HOST',
                                  style: TextStyle(color: Color(0xFF8BCB2A)),
                                ),
                              ),
                            ),
                            const Spacer(),
                            SizedBox(height: compact ? 24 : 30),
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
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Gameplay is coming soon.'),
                                  ),
                                );
                              },
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
            key: const Key('game-lobby-back-button'),
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
