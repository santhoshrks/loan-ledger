import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

import 'region_preferences_service.dart';

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

  static const Map<String, Map<String, List<int>>> _countryBucketHours = {
    // India default behavior remains unchanged.
    'IN': {
      'A': [9, 13, 17, 21],
      'B': [8, 12, 18, 21],
    },
    // Pakistan + Bangladesh: late afternoon tends to perform better.
    'PK': {
      'A': [9, 14, 18, 21],
      'B': [8, 13, 19, 21],
    },
    'BD': {
      'A': [9, 14, 18, 21],
      'B': [8, 12, 18, 21],
    },
    // Philippines + Malaysia: commute-evening patterns.
    'PH': {
      'A': [8, 12, 18, 21],
      'B': [9, 13, 19, 21],
    },
    'MY': {
      'A': [8, 12, 18, 21],
      'B': [9, 13, 19, 21],
    },
    // Gulf countries: later evening reminders are common.
    'AE': {
      'A': [9, 14, 19, 22],
      'B': [8, 13, 18, 21],
    },
    'QA': {
      'A': [9, 14, 19, 22],
      'B': [8, 13, 18, 21],
    },
    'MM': {
      'A': [8, 12, 17, 20],
      'B': [9, 13, 18, 21],
    },
    'US': {
      'A': [8, 12, 17, 20],
      'B': [9, 13, 18, 21],
    },
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

  static Future<List<int>> getHoursForResolvedRegion(String bucket) async {
    final countryCode = await RegionPreferencesService.resolveCountryCode();
    return getHoursForBucketAndCountry(
      bucket: bucket,
      countryCode: countryCode,
    );
  }

  static List<int> getHoursForBucketAndCountry({
    required String bucket,
    required String countryCode,
  }) {
    final upperCountry = countryCode.toUpperCase();
    final profile = _countryBucketHours[upperCountry];
    if (profile == null) {
      return getHoursForBucket(bucket);
    }

    return profile[bucket] ?? profile['A'] ?? getHoursForBucket(bucket);
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
