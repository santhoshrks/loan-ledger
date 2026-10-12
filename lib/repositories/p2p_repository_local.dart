import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/p2p_loan.dart';
import 'p2p_repository.dart';

class P2PRepositoryLocal implements P2PRepository {
  static const String _boxName = 'p2p_loans';

  Box<P2PLoan> get _box => Hive.box<P2PLoan>(_boxName);

  @override
  ValueListenable<Box<P2PLoan>> watchLoans() => _box.listenable();

  @override
  Future<List<P2PLoan>> getLoans() async {
    return _box.values.toList();
  }

  @override
  Future<void> addLoan(P2PLoan loan) async {
    await _box.add(loan);
  }

  @override
  Future<void> updateLoan(P2PLoan loan) async {
    await loan.save();
  }

  @override
  Future<void> deleteLoan(String loanId) async {
    for (final loan in _box.values) {
      if (loan.id == loanId) {
        await loan.delete();
        return;
      }
    }
  }

  @override
  Future<List<P2PDueItem>> getUpcomingDues({int withinDays = 30}) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(Duration(days: withinDays));
    final dues = <P2PDueItem>[];

    for (final loan in _box.values) {
      if (loan.isSettled) {
        continue;
      }

      if (loan.isFlat) {
        if (loan.monthlyDueDay != null && loan.monthlyInterestFlat > 0) {
          final next = loan.nextInterestDueDate;
          if (next != null && !next.isAfter(end)) {
            dues.add(
              P2PDueItem(
                loanId: loan.id,
                personName: loan.personName,
                isLent: loan.isLent,
                dueType: P2PDueType.interest,
                dueDate: next,
                amount: loan.monthlyInterestFlat,
                isOverdue: next.isBefore(start),
              ),
            );
          }
        }

        if (loan.dueDate != null && !loan.isSettled) {
          final dueDate = loan.dueDate!;
          final isOverdue = dueDate.isBefore(start);
          if (isOverdue || !dueDate.isAfter(end)) {
            dues.add(
              P2PDueItem(
                loanId: loan.id,
                personName: loan.personName,
                isLent: loan.isLent,
                dueType: P2PDueType.principal,
                dueDate: dueDate,
                amount: loan.outstanding,
                isOverdue: isOverdue,
              ),
            );
          }
        }
      } else if (loan.dueDate != null) {
        final dueDate = loan.dueDate!;
        final isOverdue = dueDate.isBefore(start);
        if (isOverdue || !dueDate.isAfter(end)) {
          dues.add(
            P2PDueItem(
              loanId: loan.id,
              personName: loan.personName,
              isLent: loan.isLent,
              dueType: P2PDueType.principal,
              dueDate: dueDate,
              amount: loan.outstanding,
              isOverdue: isOverdue,
            ),
          );
        }
      }
    }

    dues.sort((a, b) {
      if (a.isOverdue != b.isOverdue) {
        return a.isOverdue ? -1 : 1;
      }
      return a.dueDate.compareTo(b.dueDate);
    });

    return dues;
  }

  @override
  Future<List<P2PPaymentRecord>> getRepaymentHistory({int limit = 50}) async {
    final payments = <P2PPaymentRecord>[];

    for (final loan in _box.values) {
      for (final entry in loan.parsedPayments) {
        final type = entry['type'] == 'P'
            ? P2PPaymentType.principal
            : P2PPaymentType.interest;
        final date = entry['date'] as DateTime;
        final amount = entry['amount'] as double;

        payments.add(
          P2PPaymentRecord(
            loanId: loan.id,
            personName: loan.personName,
            type: type,
            date: date,
            amount: amount,
          ),
        );
      }
    }

    payments.sort((a, b) => b.date.compareTo(a.date));

    if (payments.length <= limit) {
      return payments;
    }
    return payments.sublist(0, limit);
  }
}
