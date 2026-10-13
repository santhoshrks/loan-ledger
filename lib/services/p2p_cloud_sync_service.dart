import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/p2p_loan.dart';

class P2PCloudSyncService {
  static const String _users = 'users';
  static const String _p2pLoans = 'p2p_loans';

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  bool _syncDisabledForSession = false;

  P2PCloudSyncService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>>? _collection() {
    if (_syncDisabledForSession) return null;
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    return _firestore.collection(_users).doc(uid).collection(_p2pLoans);
  }

  bool get isSyncAvailable => !_syncDisabledForSession;

  bool _shouldDisableSync(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
          error.code == 'failed-precondition' ||
          error.code == 'unimplemented';
    }
    final msg = error.toString().toLowerCase();
    return msg.contains('permission_denied') ||
        msg.contains('permission-denied') ||
        msg.contains('firestore api has not been used') ||
        msg.contains('cloud firestore api') ||
        msg.contains('service_disabled');
  }

  Future<T?> _runGuarded<T>(String op, Future<T> Function() action) async {
    if (_syncDisabledForSession) return null;
    try {
      return await action();
    } catch (e) {
      if (_shouldDisableSync(e)) {
        _syncDisabledForSession = true;
        debugPrint('☁️ Cloud sync disabled for this session: $e');
      } else {
        debugPrint('☁️ Cloud sync "$op" failed: $e');
      }
      return null;
    }
  }

  Future<void> pullFromCloudIfLocalEmpty(Box<P2PLoan> box) async {
    final coll = _collection();
    if (coll == null) return;
    if (box.isNotEmpty) return;

    final snapshot = await _runGuarded('pullFromCloudIfLocalEmpty', () => coll.get());
    if (snapshot == null) return;
    for (final doc in snapshot.docs) {
      final loan = _fromMap(doc.id, doc.data());
      await box.put(loan.id, loan);
    }
    debugPrint('☁️ Pulled ${snapshot.docs.length} loans from cloud');
  }

  Future<void> pushAllToCloud(Box<P2PLoan> box) async {
    final coll = _collection();
    if (coll == null) return;

    for (final loan in box.values) {
      await _runGuarded<void>(
        'pushAllToCloud',
        () => coll.doc(loan.id).set(_toMap(loan), SetOptions(merge: true)),
      );
      if (_syncDisabledForSession) return;
    }
    debugPrint('☁️ Pushed ${box.length} loans to cloud');
  }

  Future<void> upsertLoan(P2PLoan loan) async {
    final coll = _collection();
    if (coll == null) return;
    await _runGuarded(
      'upsertLoan',
      () => coll.doc(loan.id).set(_toMap(loan), SetOptions(merge: true)),
    );
  }

  Future<void> deleteLoanById(String id) async {
    final coll = _collection();
    if (coll == null) return;
    await _runGuarded('deleteLoanById', () => coll.doc(id).delete());
  }

  Map<String, dynamic> _toMap(P2PLoan loan) {
    return {
      'id': loan.id,
      'personName': loan.personName,
      'amount': loan.amount,
      'isLent': loan.isLent,
      'date': loan.date.toIso8601String(),
      'notes': loan.notes,
      'repaidAmount': loan.repaidAmount,
      'dueDate': loan.dueDate?.toIso8601String(),
      'phoneNumber': loan.phoneNumber,
      'interestRate': loan.interestRate,
      'tenureMonths': loan.tenureMonths,
      'isFlat': loan.isFlat,
      'interestPeriod': loan.interestPeriod,
      'principalRepaid': loan.principalRepaid,
      'paymentLog': loan.paymentLog,
      'monthlyDueDay': loan.monthlyDueDay,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  P2PLoan _fromMap(String id, Map<String, dynamic> m) {
    return P2PLoan(
      id: (m['id'] as String?) ?? id,
      personName: (m['personName'] as String?) ?? 'Unknown',
      amount: (m['amount'] as num?)?.toDouble() ?? 0,
      isLent: (m['isLent'] as bool?) ?? true,
      date: DateTime.tryParse((m['date'] as String?) ?? '') ?? DateTime.now(),
      notes: m['notes'] as String?,
      repaidAmount: (m['repaidAmount'] as num?)?.toDouble() ?? 0,
      dueDate: DateTime.tryParse((m['dueDate'] as String?) ?? ''),
      phoneNumber: m['phoneNumber'] as String?,
      interestRate: (m['interestRate'] as num?)?.toDouble(),
      tenureMonths: m['tenureMonths'] as int?,
      isFlat: (m['isFlat'] as bool?) ?? false,
      interestPeriod: (m['interestPeriod'] as String?) ?? 'annual',
      principalRepaid: (m['principalRepaid'] as num?)?.toDouble() ?? 0,
      paymentLog: (m['paymentLog'] as List?)?.map((e) => e.toString()).toList(),
      monthlyDueDay: m['monthlyDueDay'] as int?,
    );
  }
}



