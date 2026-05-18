import 'package:hive/hive.dart';
part 'savings_goal.g.dart';

@HiveType(typeId: 1)
class SavingsGoal extends HiveObject {
  @HiveField(0) late String id;
  @HiveField(1) late String name;
  @HiveField(2) late double targetAmount;
  @HiveField(3) late double savedAmount;
  @HiveField(4) late DateTime targetDate;
  @HiveField(5) late String emoji;
  @HiveField(6) late double monthlyContribution;
  @HiveField(7) late DateTime createdAt;

  SavingsGoal({
    required this.id, required this.name,
    required this.targetAmount, this.savedAmount = 0,
    required this.targetDate, this.emoji = '🎯',
    this.monthlyContribution = 0,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get progressPercent => targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
  double get remaining => (targetAmount - savedAmount).clamp(0, double.infinity);
  bool get isCompleted => savedAmount >= targetAmount;

  int get monthsRemaining {
    final now = DateTime.now();
    return ((targetDate.year - now.year) * 12 + (targetDate.month - now.month)).clamp(0, 9999);
  }
}

