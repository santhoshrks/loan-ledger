import 'package:flutter_test/flutter_test.dart';
import 'package:p2p_reminder/models/subscription.dart';

void main() {
  group('Subscription model', () {
    test('returns current month due date when unpaid', () {
      final subscription = Subscription(
        id: 'sub_1',
        name: 'Netflix',
        amount: 649,
        billingDay: 10,
        createdAt: DateTime(2026, 1, 1),
      );

      final nextDue = subscription.getNextDueDate(now: DateTime(2026, 8, 5));
      expect(nextDue, DateTime(2026, 8, 10));
      expect(subscription.daysUntilDue(now: DateTime(2026, 8, 5)), 5);
    });

    test('moves to next month when current cycle is paid', () {
      final subscription = Subscription(
        id: 'sub_2',
        name: 'Spotify',
        amount: 119,
        billingDay: 15,
        createdAt: DateTime(2026, 1, 1),
        lastPaidAt: DateTime(2026, 8, 2),
      );

      final nextDue = subscription.getNextDueDate(now: DateTime(2026, 8, 10));
      expect(nextDue, DateTime(2026, 9, 15));
    });

    test('clamps billing day for shorter month', () {
      final subscription = Subscription(
        id: 'sub_3',
        name: 'YouTube Premium',
        amount: 129,
        billingDay: 31,
        createdAt: DateTime(2026, 1, 1),
      );

      final due = subscription.getNextDueDate(now: DateTime(2026, 2, 10));
      expect(due, DateTime(2026, 2, 28));
    });
  });
}

