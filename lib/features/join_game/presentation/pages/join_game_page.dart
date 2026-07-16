import 'package:flutter/material.dart';

import '../../../../shared/widgets/future_feature_page.dart';

class JoinGamePage extends StatelessWidget {
  const JoinGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FutureFeaturePage(
      title: 'Join Game',
      message: 'Joining a game is coming soon.',
      details:
          'This is where you will enter an existing game in a future update.',
      icon: Icons.login_rounded,
      accentColor: Color(0xFFF2B129),
    );
  }
}
