import 'package:flutter/material.dart';

import '../../features/create_game/presentation/pages/create_game_page.dart';
import '../../features/game_lobby/presentation/pages/game_lobby_page.dart';
import '../../features/join_game/presentation/pages/join_game_page.dart';
import '../../features/main_menu/domain/main_menu_identity.dart';
import '../../features/main_menu/presentation/pages/main_menu_page.dart';
import '../../services/game_service.dart';

class AppRouter {
  const AppRouter({
    required this.identityController,
    required this.gameService,
  });

  static const mainMenu = '/';
  static const createGame = '/create-game';
  static const joinGame = '/join-game';
  static const gameLobby = '/game-lobby';

  final MainMenuIdentityController identityController;
  final GameClient gameService;

  Route<void> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      mainMenu => MainMenuPage(identityController: identityController),
      createGame => CreateGamePage(
        identityController: identityController,
        gameService: gameService,
      ),
      joinGame => JoinGamePage(
        identityController: identityController,
        gameService: gameService,
      ),
      gameLobby when settings.arguments is Game => GameLobbyPage(
        game: settings.arguments! as Game,
        identityController: identityController,
      ),
      _ => null,
    };

    if (page == null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => MainMenuPage(identityController: identityController),
      );
    }

    return PageRouteBuilder<void>(
      settings: settings,
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, _, _) => page,
      transitionsBuilder: (_, animation, _, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
