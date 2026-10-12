import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_reminder/models/loan.dart';

void main() {
  test('Loan with future startDate should not have reminders before start', () {
    final now = DateTime.now();
    final futureStart = DateTime(now.year, now.month + 1, 10);

    final loan = Loan(
      id: '1',
      name: 'Future Loan',
      emiAmount: 1000,
      dueDay: 5,
      startDate: futureStart,
    );

    final nextDue = loan.getNextDueDate();
    final currentDue = loan.getCurrentDueDate();

    // nextDue and currentDue should be on or after the loan's startDate month
    expect(!nextDue.isBefore(loan.startDate), true,
        reason: 'Next due should not be before startDate');
    expect(!currentDue.isBefore(loan.startDate), true,
        reason: 'Current due should not be before startDate');

    // daysUntilDue should be positive (since start is in future)
    expect(loan.daysUntilDue() > 0, true,
        reason: 'daysUntilDue should be > 0 for future-start loans');

    // shouldSendReminder should be false for future loans (not within 3/1/0 days)
    expect(loan.shouldSendReminder(), false,
        reason: 'shouldSendReminder should be false for future-start loans');
  });

  test('Loan with past startDate keeps existing behavior', () {
    final now = DateTime.now();
    final pastStart = DateTime(now.year, now.month - 2, 1);

    final loan = Loan(
      id: '2',
      name: 'Past Loan',
      emiAmount: 500,
      dueDay: now.day, // due today
      startDate: pastStart,
    );

    // If dueDay is today and loan not paid, daysUntilDue should be 0
    final days = loan.daysUntilDue();
    expect(days <= 3, true);

    // shouldSendReminder may be true if daysUntilDue is 3/1/0
    final should = loan.shouldSendReminder();
    expect(should == (days == 3 || days == 1 || days == 0), true);
  });
}
