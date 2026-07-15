import 'package:flutter/material.dart';

import '../../../../shared/widgets/future_feature_page.dart';

class CreateGamePage extends StatelessWidget {
  const CreateGamePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const FutureFeaturePage(
      title: 'Create Game',
      message: 'Game creation is coming soon.',
      details: 'This is where you will set up a new game in a future update.',
      icon: Icons.add_circle_outline_rounded,
      accentColor: Color(0xFF8BCB2A),
    );
  }
}
