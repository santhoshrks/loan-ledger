import 'package:shared_preferences/shared_preferences.dart';

class RetentionStreakService {
  static const String _currentStreakKey = 'retention_current_streak';
  static const String _bestStreakKey = 'retention_best_streak';
  static const String _lastVisitDateKey = 'retention_last_visit_date';
  static const String _lastNudgeShownDateKey = 'retention_last_nudge_shown_date';
  static const String _lastNudgeDismissedDateKey =
      'retention_last_nudge_dismissed_date';

  static Future<int> recordDailyVisit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());
    final lastVisitDate = prefs.getString(_lastVisitDateKey);

    var currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

    if (lastVisitDate == today) {
      return currentStreak;
    }

    if (lastVisitDate == _dateOnly(DateTime.now().subtract(const Duration(days: 1)))) {
      currentStreak += 1;
    } else {
      currentStreak = 1;
    }

    final bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
    if (currentStreak > bestStreak) {
      await prefs.setInt(_bestStreakKey, currentStreak);
    }

    await prefs.setInt(_currentStreakKey, currentStreak);
    await prefs.setString(_lastVisitDateKey, today);

    return currentStreak;
  }

  static Future<bool> shouldShowMilestoneNudge(int streakCount) async {
    if (streakCount < 3 || streakCount % 3 != 0) {
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final today = _dateOnly(DateTime.now());

    if (prefs.getString(_lastNudgeShownDateKey) == today) {
      return false;
    }

    if (prefs.getString(_lastNudgeDismissedDateKey) == today) {
      return false;
    }

    return true;
  }

  static Future<void> markMilestoneNudgeShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNudgeShownDateKey, _dateOnly(DateTime.now()));
  }

  static Future<void> dismissMilestoneNudgeForToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastNudgeDismissedDateKey, _dateOnly(DateTime.now()));
  }

  static Future<Map<String, int>> getStreakStats() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'current': prefs.getInt(_currentStreakKey) ?? 0,
      'best': prefs.getInt(_bestStreakKey) ?? 0,
    };
  }

  static String _dateOnly(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.toIso8601String().split('T').first;
  }
}

