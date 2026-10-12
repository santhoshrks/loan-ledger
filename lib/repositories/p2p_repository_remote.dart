import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/p2p_loan.dart';
import 'p2p_repository.dart';

class P2PRepositoryRemote implements P2PRepository {
  static const String _notReady =
      'Remote repository is not configured yet. Switch to local mode for MVP.';

  @override
  Future<void> addLoan(P2PLoan loan) async {
    throw UnimplementedError(_notReady);
  }

  @override
  Future<void> deleteLoan(String loanId) async {
    throw UnimplementedError(_notReady);
  }

  @override
  Future<List<P2PLoan>> getLoans() async {
    throw UnimplementedError(_notReady);
  }

  @override
  Future<List<P2PDueItem>> getUpcomingDues({int withinDays = 30}) async {
    throw UnimplementedError(_notReady);
  }

  @override
  Future<void> updateLoan(P2PLoan loan) async {
    throw UnimplementedError(_notReady);
  }

  @override
  ValueListenable<Box<P2PLoan>> watchLoans() {
    throw UnimplementedError(_notReady);
  }

  @override
  Future<List<P2PPaymentRecord>> getRepaymentHistory({int limit = 50}) async {
    throw UnimplementedError(_notReady);
  }
}


