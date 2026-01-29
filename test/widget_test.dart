import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emi_reminder/screens/home_screen.dart';

void main() {
  testWidgets('EMI Reminder app loads with empty state', (WidgetTester tester) async {
    // Build app with mocked services
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(),
      ),
    );

    // Verify that the app shows the empty state message.
    expect(find.text('No loans added yet'), findsOneWidget);

    // Verify that the FAB is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
