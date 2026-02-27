import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emi_reminder/screens/home_screen.dart';
import 'package:emi_reminder/services/loan_storage_service.dart';
import 'package:hive/hive.dart';
import 'package:emi_reminder/services/notification_service.dart';
import 'dart:io';
import 'package:emi_reminder/models/loan.dart';

/// A lightweight in-memory mock for LoanStorageService used in widget tests.
class LoanStorageServiceMock implements LoanStorageService {
  // Provide minimal implementations used by HomeScreen
  @override
  bool get isInitialized => true;

  @override
  Future<void> init() async {}

  @override
  List<Loan> getAllLoans() => <Loan>[];

  @override
  int getLoansCount() => 0;

  // Unused methods - provide stubs with correct signatures
  @override
  Future<void> addLoan(Loan loan) async {}

  @override
  Future<void> updateLoan(String id, Loan loan) async {}

  @override
  Future<void> deleteLoan(String id) async {}

  @override
  Future<void> clearAllLoans() async {}

  @override
  List<Loan> getLoansDueSoon({int withinDays = 3}) => <Loan>[];

  @override
  List<Loan> getOverdueLoans() => <Loan>[];

  @override
  double getTotalMonthlyEmi() => 0.0;

  @override
  Future<void> close() async {}

  @override
  Stream<BoxEvent> watchLoans() => const Stream<BoxEvent>.empty();

  @override
  Loan? getLoanById(String id) => null;
}

// Lightweight mock for NotificationService to avoid plugin initialization in tests
class NotificationServiceMock extends NotificationService {
  @override
  bool get isInitialized => true;

  @override
  Future<void> init() async {
    // no-op for tests
    return;
  }

  @override
  Future<void> scheduleLoadReminders(Loan loan, {bool testMode = false}) async {
    // no-op for tests
    return;
  }

  @override
  Future<void> cancelLoanReminders(String loanId, {int tenureMonths = 12}) async {
    // no-op for tests
    return;
  }

  // Add convenience stub to match possible usage
  Future<void> showTestNotification() async => Future.value();
}

void main() {
  // Initialize a pure-Dart Hive instance for widget tests so Hive.box('loans') exists
  late Directory _tmpDir;
  setUpAll(() async {
    _tmpDir = Directory.systemTemp.createTempSync('emi_reminder_test');
    Hive.init(_tmpDir.path);
    // Register adapter if generated
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(LoanAdapter());
    }
    await Hive.openBox<Loan>('loans');
  });

  tearDownAll(() async {
    if (Hive.isBoxOpen('loans')) {
      await Hive.box<Loan>('loans').clear();
      await Hive.box<Loan>('loans').close();
    }
    await Hive.close();
    try {
      _tmpDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('EMI Reminder app loads with empty state', (WidgetTester tester) async {
    // Build app
    // Ensure the test's Hive box is ready before building the widget
    expect(Hive.isBoxOpen('loans'), true);
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          storageService: LoanStorageServiceMock(),
          notificationService: NotificationServiceMock(),
        ),
      ),
    );

    // Wait for async initialization in HomeScreen to complete and UI to settle.
    await tester.pumpAndSettle();

    // Verify that the app shows the empty state message (current UI text).
    expect(find.text('No loans yet'), findsOneWidget);

    // Verify that the FloatingActionButton with the add icon is present.
    expect(find.widgetWithIcon(FloatingActionButton, Icons.add_rounded), findsOneWidget);
  });
}
