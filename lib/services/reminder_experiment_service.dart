import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class ReminderExperimentService {
  static const String _bucketKey = 'reminder_timing_bucket';
  static const String _seedKey = 'reminder_experiment_seed';
  static const String _referralCodeKey = 'referral_code';

  static const List<String> _buckets = ['A', 'B'];
  static const Map<String, List<int>> _bucketHours = {
    // Existing/default schedule.
    'A': [9, 13, 17, 21],
    // Variant schedule to test morning vs evening engagement.
    'B': [8, 12, 18, 21],
  };

  static Future<String> getOrAssignBucket() async {
    final prefs = await SharedPreferences.getInstance();

    final existing = prefs.getString(_bucketKey);
    if (existing != null && _bucketHours.containsKey(existing)) {
      return existing;
    }

    var seed = prefs.getString(_referralCodeKey) ?? prefs.getString(_seedKey);
    if (seed == null || seed.isEmpty) {
      seed = await _createAndPersistSeed(prefs);
    }

    final bucket = _buckets[_stableHash(seed) % _buckets.length];
    await prefs.setString(_bucketKey, bucket);
    return bucket;
  }

  static List<int> getHoursForBucket(String bucket) {
    return _bucketHours[bucket] ?? _bucketHours['A']!;
  }

  static int stableHashForTesting(String seed) => _stableHash(seed);

  static Future<String> _createAndPersistSeed(SharedPreferences prefs) async {
    final now = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final rand = Random().nextInt(1 << 20).toRadixString(36).padLeft(4, '0');
    final seed = 'exp_${now}_$rand';
    await prefs.setString(_seedKey, seed);
    return seed;
  }

  static int _stableHash(String input) {
    var hash = 17;
    for (final unit in input.codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return hash;
  }
}
