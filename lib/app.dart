import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter App',
      theme: AppTheme.light,
      home: const Scaffold(
        body: Center(child: Text('Flutter App Boilerplate')),
      ),
    );
  }
}
