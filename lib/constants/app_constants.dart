/// Application-wide constants for EMI Reminder
library app_constants;

/// App identity constants
class AppConstants {
  static const String appName = 'EMI Reminder';
  static const String appFullName = 'EMI Reminder & Loan Tracker';
  static const String appTagline = 'Loan Tracker';
  static const String appDescription = 'Never miss your loan payments! Get timely reminders for all your EMIs.';
}

/// Notification related constants
class NotificationConstants {
  static const String channelId = 'emi_reminder_channel';
  static const String channelName = 'EMI Reminders';
  static const String channelDescription = 'Notifications for EMI due dates';

  static const int daysBeforeReminder = 3;
  static const int dayBeforeReminder = 1;
  static const int reminderHourOfDay = 9;
  static const int reminderMinute = 0;

  static const Duration notificationDuration = Duration(seconds: 3);
}

/// Loan-related constants
class LoanConstants {
  static const int defaultTenureMonths = 60;
  static const int maxDueDay = 31;
  static const int minDueDay = 1;
  static const int defaultInterestRate = 7;

  static const double defaultEMIAmount = 15000.0;
}

/// Storage/Database constants
class StorageConstants {
  static const String loanBoxName = 'loans';
}

/// Duration constants
class DurationConstants {
  static const Duration delayBeforeNotification = Duration(milliseconds: 500);
  static const Duration animationDuration = Duration(milliseconds: 300);
}

/// Validation constants
class ValidationConstants {
  static const int minLoanNameLength = 2;
  static const int maxLoanNameLength = 50;
  static const double minEMIAmount = 100.0;
  static const double maxEMIAmount = 10000000.0; // 1 crore
}

/// UI/UX constants
class UIConstants {
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const double cardBorderRadius = 12.0;
  static const double headerBorderRadius = 16.0;
}
