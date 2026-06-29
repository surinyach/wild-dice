import 'package:flutter_test/flutter_test.dart';

import 'package:challenge_app/app.dart';

void main() {
  testWidgets('shows the boilerplate home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const App());

    expect(find.text('Flutter App Boilerplate'), findsOneWidget);
  });
}
