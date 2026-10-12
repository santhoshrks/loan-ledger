import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'dart:io';
import 'package:p2p_reminder/models/p2p_loan.dart';
import 'package:p2p_reminder/screens/p2p_home_screen.dart';

void main() {
  // Initialize a pure-Dart Hive instance for widget tests so Hive.box('p2p_loans') exists.
  late Directory _tmpDir;
  setUpAll(() async {
    _tmpDir = Directory.systemTemp.createTempSync('p2p_reminder_test');
    Hive.init(_tmpDir.path);
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(P2PLoanAdapter());
    }
    await Hive.openBox<P2PLoan>('p2p_loans');
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('p2p_loans')) {
      await Hive.box<P2PLoan>('p2p_loans').clear();
      await Hive.box<P2PLoan>('p2p_loans').close();
    }
    await Hive.close();
    try {
      _tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('P2P home loads with empty state', (WidgetTester tester) async {
    expect(Hive.isBoxOpen('p2p_loans'), true);
    await tester.pumpWidget(
      MaterialApp(
        home: const P2PHomeScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('P2P Reminder'), findsOneWidget);
    expect(find.text('No dues in the next 30 days.'), findsOneWidget);
    expect(find.text('Add P2P Loan'), findsOneWidget);
  });
}
