import 'dart:math';
import 'package:hive/hive.dart';
part 'p2p_loan.g.dart';

@HiveType(typeId: 2)
class P2PLoan extends HiveObject {
  @HiveField(0)  late String id;
  @HiveField(1)  late String personName;
  @HiveField(2)  late double amount;          // Principal
  @HiveField(3)  late bool isLent;
  @HiveField(4)  late DateTime date;
  @HiveField(5)  late String? notes;
  @HiveField(6)  late double repaidAmount;    // For EMI: total EMI paid. For Flat: total interest received.
  @HiveField(7)  late DateTime? dueDate;
  @HiveField(8)  late String? phoneNumber;
  @HiveField(9)  double? interestRate;        // Annual % for EMI; monthly % for Flat (see interestPeriod)
  @HiveField(10) int? tenureMonths;           // Only used for EMI loans
  @HiveField(11) bool isFlat;                 // true = flat interest (interest-only monthly, principal separate)
  @HiveField(12) String interestPeriod;       // 'monthly' or 'annual'
  @HiveField(13) double principalRepaid;      // For flat: how much principal has been returned
  @HiveField(14) List<String>? paymentLog;    // "YYYY-MM-DD|AMOUNT|I/P" (I=interest, P=principal)
  @HiveField(15) int? monthlyDueDay;           // Day of month (1-31) when interest is due each month

  P2PLoan({
    required this.id,
    required this.personName,
    required this.amount,
    required this.isLent,
    required this.date,
    this.notes,
    this.repaidAmount = 0,
    this.dueDate,
    this.phoneNumber,
    this.interestRate,
    this.tenureMonths,
    this.isFlat = false,
    this.interestPeriod = 'annual',
    this.principalRepaid = 0,
    this.paymentLog,
    this.monthlyDueDay,
  });

  // ── Flat interest helpers ──────────────────────────────────────────────────
  /// Monthly interest amount for flat loans
  double get monthlyInterestFlat {
    if (!isFlat || interestRate == null || interestRate! <= 0) return 0;
    return interestPeriod == 'monthly'
        ? amount * interestRate! / 100
        : amount * interestRate! / 1200;
  }

  /// How many months have elapsed since the loan start date (min 1)
  int get monthsElapsed {
    final now = DateTime.now();
    final months = (now.year - date.year) * 12 + (now.month - date.month);
    return months < 1 ? 1 : months;
  }

  /// Interest payments made so far (based on repaidAmount ÷ monthly interest)
  int get interestPaymentsMade {
    if (!isFlat || monthlyInterestFlat <= 0) return 0;
    return (repaidAmount / monthlyInterestFlat).floor();
  }

  /// Interest payments overdue (elapsed months − payments made)
  int get interestPaymentsOverdue {
    if (!isFlat) return 0;
    return (monthsElapsed - interestPaymentsMade).clamp(0, 9999);
  }

  /// Expected interest received by now
  double get expectedInterestToDate => monthlyInterestFlat * monthsElapsed;

  /// Next monthly interest due date (based on monthlyDueDay)
  DateTime? get nextInterestDueDate {
    if (monthlyDueDay == null) return null;
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final day = monthlyDueDay!.clamp(1, daysInMonth);
    DateTime candidate = DateTime(year, month, day);
    if (candidate.isBefore(now)) {
      month++;
      if (month > 12) { month = 1; year++; }
      final dim = DateTime(year, month + 1, 0).day;
      candidate = DateTime(year, month, monthlyDueDay!.clamp(1, dim));
    }
    return candidate;
  }

  int get daysUntilNextInterest {
    final d = nextInterestDueDate;
    if (d == null) return -1;
    final now = DateTime.now();
    return DateTime(d.year, d.month, d.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
  }

  /// Total interest that will accrue over full tenure (flat loans: indefinite until principal returned)
  double get totalInterestPaid => isFlat ? repaidAmount : 0;

  // ── Parsed payment log ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> get parsedPayments {
    if (paymentLog == null || paymentLog!.isEmpty) return [];
    return paymentLog!.map((e) {
      final parts = e.split('|');
      if (parts.length < 3) return <String, dynamic>{};
      return <String, dynamic>{
        'date': DateTime.tryParse(parts[0]) ?? date,
        'amount': double.tryParse(parts[1]) ?? 0.0,
        'type': parts[2], // 'I' or 'P'
      };
    }).where((m) => m.isNotEmpty).toList()
      ..sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
  }

  void addPaymentEntry(DateTime dt, double amt, String type) {
    paymentLog ??= [];
    paymentLog!.add('${dt.toIso8601String().split('T')[0]}|$amt|$type');
  }

  /// Removes the payment entry at the given index (from parsedPayments order = newest first)
  /// and recalculates totals from the remaining log.
  void removePaymentAt(int parsedIndex) {
    if (paymentLog == null || paymentLog!.isEmpty) return;
    // parsedPayments is sorted newest-first; rebuild the raw index
    final parsed = parsedPayments; // sorted newest-first
    if (parsedIndex >= parsed.length) return;
    final target = parsed[parsedIndex];
    final targetStr = '${(target['date'] as DateTime).toIso8601String().split('T')[0]}|${target['amount']}|${target['type']}';
    paymentLog!.remove(targetStr);
    recalculateFromLog();
  }

  /// Updates a payment entry at the given parsed index with a new date/amount.
  void updatePaymentAt(int parsedIndex, DateTime newDate, double newAmt) {
    if (paymentLog == null || paymentLog!.isEmpty) return;
    final parsed = parsedPayments;
    if (parsedIndex >= parsed.length) return;
    final target = parsed[parsedIndex];
    final targetStr = '${(target['date'] as DateTime).toIso8601String().split('T')[0]}|${target['amount']}|${target['type']}';
    final idx = paymentLog!.indexOf(targetStr);
    if (idx >= 0) {
      paymentLog![idx] = '${newDate.toIso8601String().split('T')[0]}|$newAmt|${target['type']}';
    }
    recalculateFromLog();
  }

  /// Recalculates repaidAmount (sum of 'I' entries) and principalRepaid (sum of 'P' entries) from the log.
  void recalculateFromLog() {
    if (paymentLog == null) { repaidAmount = 0; principalRepaid = 0; return; }
    double iTotal = 0, pTotal = 0;
    for (final entry in paymentLog!) {
      final parts = entry.split('|');
      if (parts.length < 3) continue;
      final amt = double.tryParse(parts[1]) ?? 0;
      if (parts[2] == 'I') iTotal += amt;
      else if (parts[2] == 'P') pTotal += amt;
    }
    repaidAmount = iTotal;
    principalRepaid = pTotal.clamp(0, amount);
  }

  // ── Common computed properties (override for flat) ─────────────────────────
  double get outstanding {
    if (isFlat) return (amount - principalRepaid).clamp(0, double.infinity);
    return (amount - repaidAmount).clamp(0, double.infinity);
  }

  bool get isSettled {
    if (isFlat) return principalRepaid >= amount;
    return repaidAmount >= amount;
  }

  bool get isOverdue =>
      dueDate != null && DateTime.now().isAfter(dueDate!) && !isSettled;

  // ── EMI loan helpers (reducing balance) ───────────────────────────────────
  double get monthlyEmi {
    if (isFlat) return monthlyInterestFlat; // for display convenience
    if (tenureMonths == null || tenureMonths! <= 0) return 0;
    if (interestRate != null && interestRate! > 0) {
      final r = interestRate! / 1200;
      final n = tenureMonths!;
      final factor = pow(1 + r, n);
      return amount * r * factor / (factor - 1);
    }
    return amount / tenureMonths!;
  }

  int get monthsPaid {
    if (isFlat) return interestPaymentsMade;
    if (monthlyEmi <= 0) return 0;
    return (repaidAmount / monthlyEmi).floor().clamp(0, tenureMonths ?? 9999);
  }

  int get monthsRemaining =>
      tenureMonths != null ? (tenureMonths! - monthsPaid).clamp(0, tenureMonths!) : 0;

  double get totalInterest {
    if (isFlat || tenureMonths == null || tenureMonths! <= 0) return 0;
    return (monthlyEmi * tenureMonths!) - amount;
  }
}
