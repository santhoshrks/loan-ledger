import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 4)
class Subscription extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late int billingDay; // 1-31

  @HiveField(4)
  late DateTime createdAt;

  @HiveField(5)
  late String category;

  @HiveField(6)
  late bool isActive;

  @HiveField(7)
  late String currencyCode;

  @HiveField(8)
  DateTime? lastPaidAt;

  @HiveField(9)
  String? notes;

  Subscription({
    required this.id,
    required this.name,
    required this.amount,
    required this.billingDay,
    required this.createdAt,
    this.category = 'General',
    this.isActive = true,
    this.currencyCode = 'INR',
    this.lastPaidAt,
    this.notes,
  });

  int _clampDay(int year, int month) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return billingDay.clamp(1, lastDay);
  }

  DateTime getCurrentCycleDueDate({DateTime? now}) {
    final reference = now ?? DateTime.now();

    int year = reference.year;
    int month = reference.month;
    DateTime due = DateTime(year, month, _clampDay(year, month));

    // If the subscription starts after the due day, move first cycle to next month.
    if (due.isBefore(createdAt)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      due = DateTime(year, month, _clampDay(year, month));
    }

    return due;
  }

  bool isPaidForCycle(DateTime cycleDueDate) {
    if (lastPaidAt == null) return false;
    return lastPaidAt!.year == cycleDueDate.year &&
        lastPaidAt!.month == cycleDueDate.month;
  }

  DateTime getNextDueDate({DateTime? now}) {
    final currentDue = getCurrentCycleDueDate(now: now);
    if (!isPaidForCycle(currentDue)) {
      return currentDue;
    }

    int year = currentDue.year;
    int month = currentDue.month + 1;
    if (month > 12) {
      month = 1;
      year++;
    }

    return DateTime(year, month, _clampDay(year, month));
  }

  int daysUntilDue({DateTime? now}) {
    final today = now ?? DateTime.now();
    final due = getNextDueDate(now: today);
    final normalizedToday = DateTime(today.year, today.month, today.day);
    final normalizedDue = DateTime(due.year, due.month, due.day);
    return normalizedDue.difference(normalizedToday).inDays;
  }

  void markPaid({DateTime? paidAt}) {
    lastPaidAt = paidAt ?? DateTime.now();
  }

  void markUnpaid() {
    lastPaidAt = null;
  }
}

