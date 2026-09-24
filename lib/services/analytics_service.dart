import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsService {
  static const String _eventPrefix = 'analytics_event_';
  static const String _dailyPrefix = 'analytics_daily_';
  static const String _lastEventPrefix = 'analytics_last_';

  static Future<void> track(
    String eventName, {
    Map<String, String>? attributes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = _normalize(eventName);
    final totalKey = '$_eventPrefix$normalized';
    final total = (prefs.getInt(totalKey) ?? 0) + 1;
    await prefs.setInt(totalKey, total);

    final dayKey =
        '$_dailyPrefix${DateTime.now().toIso8601String().substring(0, 10)}_$normalized';
    final dayTotal = (prefs.getInt(dayKey) ?? 0) + 1;
    await prefs.setInt(dayKey, dayTotal);

    await prefs.setInt(
      '$_lastEventPrefix${normalized}_at',
      DateTime.now().millisecondsSinceEpoch,
    );

    if (attributes != null && attributes.isNotEmpty) {
      for (final entry in attributes.entries) {
        await prefs.setString(
          '$_lastEventPrefix${normalized}_${_normalize(entry.key)}',
          entry.value,
        );
      }
    }
  }

  static Future<void> trackOnboardingCompleted({required String goal}) {
    return track('onboarding_completed', attributes: {'goal': goal});
  }

  static Future<void> trackLoanCreated({
    required String loanType,
    required bool fromTemplate,
  }) {
    return track(
      'loan_created',
      attributes: {
        'loan_type': loanType,
        'from_template': fromTemplate ? 'yes' : 'no',
      },
    );
  }

  static Future<void> trackInviteShared({required String source}) {
    return track('invite_shared', attributes: {'source': source});
  }

  static Future<int> getEventCount(String eventName) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_eventPrefix${_normalize(eventName)}') ?? 0;
  }

  static String _normalize(String value) {
    return value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  }
}
