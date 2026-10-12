import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/p2p_loan.dart';

enum P2PDueType { interest, principal }

enum P2PPaymentType { interest, principal }

class P2PDueItem {
  final String loanId;
  final String personName;
  final bool isLent;
  final P2PDueType dueType;
  final DateTime dueDate;
  final double amount;
  final bool isOverdue;

  const P2PDueItem({
    required this.loanId,
    required this.personName,
    required this.isLent,
    required this.dueType,
    required this.dueDate,
    required this.amount,
    required this.isOverdue,
  });
}

class P2PPaymentRecord {
  final String loanId;
  final String personName;
  final P2PPaymentType type;
  final DateTime date;
  final double amount;

  const P2PPaymentRecord({
    required this.loanId,
    required this.personName,
    required this.type,
    required this.date,
    required this.amount,
  });
}

abstract class P2PRepository {
  ValueListenable<Box<P2PLoan>> watchLoans();

  Future<List<P2PLoan>> getLoans();

  Future<void> addLoan(P2PLoan loan);

  Future<void> updateLoan(P2PLoan loan);

  Future<void> deleteLoan(String loanId);

  Future<List<P2PDueItem>> getUpcomingDues({int withinDays = 30});

  Future<List<P2PPaymentRecord>> getRepaymentHistory({int limit = 50});
}
