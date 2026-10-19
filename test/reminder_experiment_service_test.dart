import 'package:loan_ledger/services/reminder_experiment_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReminderExperimentService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('reuses existing assigned bucket', () async {
      SharedPreferences.setMockInitialValues({'reminder_timing_bucket': 'B'});

      final bucket = await ReminderExperimentService.getOrAssignBucket();
      expect(bucket, 'B');
      expect(ReminderExperimentService.getHoursForBucket(bucket), [
        8,
        12,
        18,
        21,
      ]);
    });

    test('assigns deterministic bucket from referral code', () async {
      SharedPreferences.setMockInitialValues({'referral_code': 'EMITEST1234'});

      final bucket = await ReminderExperimentService.getOrAssignBucket();
      final expectedIndex =
          ReminderExperimentService.stableHashForTesting('EMITEST1234') % 2;
      final expectedBucket = expectedIndex == 0 ? 'A' : 'B';

      expect(bucket, expectedBucket);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('reminder_timing_bucket'), expectedBucket);
    });

    test('falls back to default hours for unknown bucket', () {
      expect(ReminderExperimentService.getHoursForBucket('Z'), [9, 13, 17, 21]);
    });

    test('returns country-specific hours when profile exists', () {
      final hours = ReminderExperimentService.getHoursForBucketAndCountry(
        bucket: 'A',
        countryCode: 'AE',
      );
      expect(hours, [9, 14, 19, 22]);
    });

    test('falls back to bucket defaults for unknown country profile', () {
      final hours = ReminderExperimentService.getHoursForBucketAndCountry(
        bucket: 'B',
        countryCode: 'ZZ',
      );
      expect(hours, [8, 12, 18, 21]);
    });
  });
}
