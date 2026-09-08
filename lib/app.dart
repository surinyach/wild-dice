import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/main_menu/domain/main_menu_identity.dart';
import 'services/game_service.dart';

class App extends StatefulWidget {
  const App({this.gameService, this.identityController, super.key});

  final GameSession? gameService;
  final MainMenuIdentityController? identityController;

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final MainMenuIdentityController _identity =
      widget.identityController ?? MainMenuIdentityController();
  late final GameSession _gameService = widget.gameService ?? GameService();

  @override
  void dispose() {
    if (widget.identityController == null) _identity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = AppRouter(
      identityController: _identity,
      gameService: _gameService,
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aguántame El Cubata',
      theme: AppTheme.light,
      initialRoute: AppRouter.mainMenu,
      onGenerateRoute: router.onGenerateRoute,
    );
  }
}
