import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Aguántame El Cubata',
      theme: AppTheme.light,
      initialRoute: AppRouter.mainMenu,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
