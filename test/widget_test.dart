import 'package:flutter_test/flutter_test.dart';

import 'package:challenge_app/app.dart';

void main() {
  testWidgets('shows the main menu and navigates to placeholders', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('WILD DICE'), findsOneWidget);
    expect(find.text('CREATE GAME'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsOneWidget);

    await tester.tap(find.text('CREATE GAME'));
    await tester.pumpAndSettle();

    expect(
      find.text('This is where game setup will start in the next story.'),
      findsOneWidget,
    );

    await tester.pageBack();
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('JOIN GAME'));
    await tester.pumpAndSettle();

    expect(
      find.text('This is where players will enter a specific game.'),
      findsOneWidget,
    );
  });
}
