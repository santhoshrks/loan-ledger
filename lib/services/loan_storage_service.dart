import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/loan.dart';
import '../models/savings_goal.dart';
import '../models/p2p_loan.dart';
import '../models/expense.dart';
import '../models/subscription.dart';

class LoanStorageService {
  static const String _boxName = 'loans';
  Box<Loan>? _loansBox;
  bool _isInitialized = false;

  /// Check if service is initialized
  bool get isInitialized => _isInitialized;

  /// Initialize Hive and open loans box
  Future<void> init() async {
    try {
      // Initialize Hive Flutter
      await Hive.initFlutter();

      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(LoanAdapter());
        debugPrint('✅ LoanAdapter registered');
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(SavingsGoalAdapter());
        debugPrint('✅ SavingsGoalAdapter registered');
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(P2PLoanAdapter());
        debugPrint('✅ P2PLoanAdapter registered');
      }
      if (!Hive.isAdapterRegistered(3)) {
        Hive.registerAdapter(ExpenseAdapter());
        debugPrint('✅ ExpenseAdapter registered');
      }
      if (!Hive.isAdapterRegistered(4)) {
        Hive.registerAdapter(SubscriptionAdapter());
        debugPrint('✅ SubscriptionAdapter registered');
      }

      // Open the loans box
      _loansBox = await Hive.openBox<Loan>(_boxName);
      // Open auxiliary boxes
      if (!Hive.isBoxOpen('savings_goals')) await Hive.openBox<SavingsGoal>('savings_goals');
      if (!Hive.isBoxOpen('p2p_loans')) await Hive.openBox<P2PLoan>('p2p_loans');
      if (!Hive.isBoxOpen('expenses')) await Hive.openBox<Expense>('expenses');
      if (!Hive.isBoxOpen('subscriptions')) await Hive.openBox<Subscription>('subscriptions');
      _isInitialized = true;
      debugPrint('✅ Loans box opened with ${_loansBox?.length ?? 0} loans');
    } catch (e) {
      debugPrint('❌ Error initializing loan storage: $e');
      _isInitialized = false;

      // Try to recover by deleting and recreating the box
      try {
        await Hive.deleteBoxFromDisk(_boxName);
        _loansBox = await Hive.openBox<Loan>(_boxName);
        _isInitialized = true;
        debugPrint('✅ Loans box recreated successfully');
      } catch (recoveryError) {
        debugPrint('❌ Recovery failed: $recoveryError');
        rethrow;
      }
    }
  }

  /// Get the loans box (with safety check)
  Box<Loan> get _box {
    if (_loansBox == null || !_loansBox!.isOpen) {
      throw Exception('Loans box is not initialized. Call init() first.');
    }
    return _loansBox!;
  }

  /// Get all loans
  List<Loan> getAllLoans() {
    try {
      return _box.values.toList();
    } catch (e) {
      debugPrint('❌ Error getting all loans: $e');
      return [];
    }
  }

  /// Get loan by ID
  Loan? getLoanById(String id) {
    try {
      return _box.values.firstWhere((loan) => loan.id == id);
    } catch (e) {
      debugPrint('❌ Error getting loan by ID: $e');
      return null;
    }
  }

  /// Add a new loan
  Future<void> addLoan(Loan loan) async {
    try {
      await _box.put(loan.id, loan);
      debugPrint('✅ Loan added: ${loan.name}');
    } catch (e) {
      debugPrint('❌ Error adding loan: $e');
      rethrow;
    }
  }

  /// Update an existing loan
  Future<void> updateLoan(String id, Loan loan) async {
    try {
      // Find the loan by ID and update it
      final existingLoan = getLoanById(id);
      if (existingLoan != null) {
        await _box.put(id, loan);
        debugPrint('✅ Loan updated: ${loan.name}');
      } else {
        // If loan doesn't exist, add it
        await addLoan(loan);
      }
    } catch (e) {
      debugPrint('❌ Error updating loan: $e');
      rethrow;
    }
  }

  /// Delete a loan
  Future<void> deleteLoan(String id) async {
    try {
      await _box.delete(id);
      debugPrint('✅ Loan deleted: $id');
    } catch (e) {
      debugPrint('❌ Error deleting loan: $e');
      rethrow;
    }
  }

  /// Get loans due soon (within specified days)
  List<Loan> getLoansDueSoon({int withinDays = 3}) {
    try {
      return _box.values
          .where((loan) => !loan.isPaid && loan.daysUntilDue() <= withinDays)
          .toList()
        ..sort((a, b) => a.daysUntilDue().compareTo(b.daysUntilDue()));
    } catch (e) {
      debugPrint('❌ Error getting loans due soon: $e');
      return [];
    }
  }

  /// Get overdue loans
  List<Loan> getOverdueLoans() {
    try {
      return _box.values
          .where((loan) => !loan.isPaid && loan.daysUntilDue() < 0)
          .toList();
    } catch (e) {
      debugPrint('❌ Error getting overdue loans: $e');
      return [];
    }
  }

  /// Get total monthly EMI
  double getTotalMonthlyEmi() {
    try {
      return _box.values.fold<double>(0, (sum, loan) => sum + loan.emiAmount);
    } catch (e) {
      debugPrint('❌ Error calculating total EMI: $e');
      return 0;
    }
  }

  /// Get loans count
  int getLoansCount() {
    try {
      return _box.length;
    } catch (e) {
      debugPrint('❌ Error getting loans count: $e');
      return 0;
    }
  }

  /// Clear all loans (for testing/reset)
  Future<void> clearAllLoans() async {
    try {
      await _box.clear();
      debugPrint('✅ All loans cleared');
    } catch (e) {
      debugPrint('❌ Error clearing loans: $e');
      rethrow;
    }
  }

  /// Watch for changes in loans box
  Stream<BoxEvent> watchLoans() {
    return _box.watch();
  }

  /// Close the box
  Future<void> close() async {
    try {
      if (_loansBox != null && _loansBox!.isOpen) {
        await _loansBox!.close();
        _isInitialized = false;
        debugPrint('✅ Loans box closed');
      }
    } catch (e) {
      debugPrint('❌ Error closing loans box: $e');
    }
  }
}
