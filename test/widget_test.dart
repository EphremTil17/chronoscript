import 'package:flutter_test/flutter_test.dart';
import 'package:chronoscript/main.dart';

void main() {
  testWidgets('App Setup verification', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ChronoScriptApp());

    // Verify that the setup complete text is shown.
    expect(find.text('ChronoScript Setup Complete'), findsOneWidget);
  });
}
