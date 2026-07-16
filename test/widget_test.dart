import 'package:flutter_test/flutter_test.dart';

import 'package:challenge_app/app.dart';

void main() {
  testWidgets('opens on the main menu', (WidgetTester tester) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 1));

    expect(find.bySemanticsLabel('WILD DICE'), findsOneWidget);
    expect(find.text('CREATE GAME'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsOneWidget);
  });

  testWidgets('navigates to Create Game and back to the main menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('CREATE GAME'));
    await tester.pumpAndSettle();

    expect(find.text('Game creation is coming soon.'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('MAIN MENU'), findsNothing);

    await tester.tap(find.byTooltip('Back to main menu'));
    await tester.pumpAndSettle();

    expect(find.text('CREATE GAME'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsOneWidget);
  });

  testWidgets('navigates to Join Game and back to the main menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('JOIN GAME'));
    await tester.pumpAndSettle();

    expect(find.text('Joining a game is coming soon.'), findsOneWidget);
    expect(find.text('COMING SOON'), findsOneWidget);
    expect(find.text('MAIN MENU'), findsNothing);

    await tester.tap(find.byTooltip('Back to main menu'));
    await tester.pumpAndSettle();

    expect(find.text('CREATE GAME'), findsOneWidget);
    expect(find.text('JOIN GAME'), findsOneWidget);
  });
}
