import 'package:emi_reminder/services/retention_streak_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RetentionStreakService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('starts streak at 1 for first daily visit', () async {
      final streak = await RetentionStreakService.recordDailyVisit();
      final stats = await RetentionStreakService.getStreakStats();

      expect(streak, 1);
      expect(stats['current'], 1);
      expect(stats['best'], 1);
    });

    test('increments streak for consecutive day', () async {
      final yesterday = _dateOnly(DateTime.now().subtract(const Duration(days: 1)));
      SharedPreferences.setMockInitialValues({
        'retention_current_streak': 4,
        'retention_best_streak': 5,
        'retention_last_visit_date': yesterday,
      });

      final streak = await RetentionStreakService.recordDailyVisit();
      final stats = await RetentionStreakService.getStreakStats();

      expect(streak, 5);
      expect(stats['current'], 5);
      expect(stats['best'], 5);
    });

    test('resets streak when day gap is more than one day', () async {
      final oldDate = _dateOnly(DateTime.now().subtract(const Duration(days: 3)));
      SharedPreferences.setMockInitialValues({
        'retention_current_streak': 6,
        'retention_best_streak': 6,
        'retention_last_visit_date': oldDate,
      });

      final streak = await RetentionStreakService.recordDailyVisit();
      final stats = await RetentionStreakService.getStreakStats();

      expect(streak, 1);
      expect(stats['current'], 1);
      expect(stats['best'], 6);
    });

    test('shows nudge only for milestone streaks and once per day', () async {
      final today = _dateOnly(DateTime.now());

      expect(await RetentionStreakService.shouldShowMilestoneNudge(2), isFalse);
      expect(await RetentionStreakService.shouldShowMilestoneNudge(3), isTrue);

      await RetentionStreakService.markMilestoneNudgeShown();
      expect(await RetentionStreakService.shouldShowMilestoneNudge(3), isFalse);

      SharedPreferences.setMockInitialValues({
        'retention_last_nudge_dismissed_date': today,
      });
      expect(await RetentionStreakService.shouldShowMilestoneNudge(6), isFalse);
    });
  });
}

String _dateOnly(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  return normalized.toIso8601String().split('T').first;
}

