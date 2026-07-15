import 'package:flutter/material.dart';

import '../../features/create_game/presentation/pages/create_game_page.dart';
import '../../features/join_game/presentation/pages/join_game_page.dart';
import '../../features/main_menu/presentation/pages/main_menu_page.dart';

class AppRouter {
  static const mainMenu = '/';
  static const createGame = '/create-game';
  static const joinGame = '/join-game';

  static Route<void> onGenerateRoute(RouteSettings settings) {
    final page = switch (settings.name) {
      mainMenu => const MainMenuPage(),
      createGame => const CreateGamePage(),
      joinGame => const JoinGamePage(),
      _ => null,
    };

    if (page == null) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const MainMenuPage(),
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
