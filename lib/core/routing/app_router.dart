import 'package:flutter/material.dart';

import '../../features/main_menu/presentation/pages/action_placeholder_page.dart';
import '../../features/main_menu/presentation/pages/main_menu_page.dart';

class AppRouter {
  static const mainMenu = '/';
  static const createGame = '/create-game';
  static const joinGame = '/join-game';

  static Map<String, WidgetBuilder> get routes => {
    mainMenu: (_) => const MainMenuPage(),
    createGame: (_) => const ActionPlaceholderPage(
      title: 'Create Game',
      message: 'This is where game setup will start in the next story.',
      icon: Icons.add_circle_outline,
    ),
    joinGame: (_) => const ActionPlaceholderPage(
      title: 'Join Game',
      message: 'This is where players will enter a specific game.',
      icon: Icons.login_rounded,
    ),
  };
}
