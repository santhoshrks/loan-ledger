import 'package:shared_preferences/shared_preferences.dart';

class BackupReminderService {
  static const String _lastBackupKey = 'last_backup_date';
  static const String _reminderDismissedKey = 'backup_reminder_dismissed';
  static const int _reminderIntervalDays = 7; // Remind every 7 days

  /// Save the current date as last backup date
  static Future<void> setLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, DateTime.now().toIso8601String());
    await prefs.remove(_reminderDismissedKey); // Reset dismissed state
  }

  /// Get the last backup date
  static Future<DateTime?> getLastBackupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_lastBackupKey);
    if (dateStr == null) return null;
    return DateTime.tryParse(dateStr);
  }

  /// Check if backup reminder should be shown
  static Future<bool> shouldShowReminder(int loanCount) async {
    // Don't show if no loans
    if (loanCount == 0) return false;

    final prefs = await SharedPreferences.getInstance();

    // Check if reminder was dismissed today
    final dismissedDate = prefs.getString(_reminderDismissedKey);
    if (dismissedDate != null) {
      final dismissed = DateTime.tryParse(dismissedDate);
      if (dismissed != null) {
        final now = DateTime.now();
        // If dismissed today, don't show again
        if (dismissed.year == now.year &&
            dismissed.month == now.month &&
            dismissed.day == now.day) {
          return false;
        }
      }
    }

    final lastBackup = await getLastBackupDate();

    // If never backed up and has loans, show reminder
    if (lastBackup == null) return true;

    // Show reminder if more than 7 days since last backup
    final daysSinceBackup = DateTime.now().difference(lastBackup).inDays;
    return daysSinceBackup >= _reminderIntervalDays;
  }

  /// Dismiss the reminder for today
  static Future<void> dismissReminder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_reminderDismissedKey, DateTime.now().toIso8601String());
  }

  /// Get days since last backup (for display)
  static Future<int?> getDaysSinceBackup() async {
    final lastBackup = await getLastBackupDate();
    if (lastBackup == null) return null;
    return DateTime.now().difference(lastBackup).inDays;
  }

  /// Check if user has ever backed up
  static Future<bool> hasEverBackedUp() async {
    final lastBackup = await getLastBackupDate();
    return lastBackup != null;
  }
}

