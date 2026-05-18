import 'package:hive/hive.dart';

part 'expense.g.dart';

@HiveType(typeId: 3)
class Expense extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late double amount;

  @HiveField(3)
  late String type; // 'debit' | 'credit'

  @HiveField(4)
  late String category;

  @HiveField(5)
  late DateTime date;

  @HiveField(6)
  late String? note;

  @HiveField(7)
  late String currencyCode;

  @HiveField(8)
  late String? paymentMethod; // Cash, UPI, Card, Bank Transfer, etc.

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.note,
    this.currencyCode = 'INR',
    this.paymentMethod,
  });

  bool get isDebit => type == 'debit';
  bool get isCredit => type == 'credit';
}

