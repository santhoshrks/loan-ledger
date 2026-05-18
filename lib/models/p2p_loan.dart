import 'package:hive/hive.dart';
part 'p2p_loan.g.dart';
@HiveType(typeId: 2)
class P2PLoan extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String personName;
  @HiveField(2) late double amount;
  @HiveField(3) late bool isLent;
  @HiveField(4) late DateTime date;
  @HiveField(5) late String? notes;
  @HiveField(6) late double repaidAmount;
  @HiveField(7) late DateTime? dueDate;
  @HiveField(8) late String? phoneNumber;
  P2PLoan({required this.id, required this.personName, required this.amount,
    required this.isLent, required this.date, this.notes,
    this.repaidAmount = 0, this.dueDate, this.phoneNumber});
  double get outstanding => (amount - repaidAmount).clamp(0, double.infinity);
  bool get isSettled => repaidAmount >= amount;
  bool get isOverdue => dueDate != null && DateTime.now().isAfter(dueDate!) && !isSettled;
}
