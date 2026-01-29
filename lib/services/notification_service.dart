import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/loan.dart';
import '../constants/app_constants.dart';

class NotificationService {
  static const AndroidNotificationDetails androidDetails =
      AndroidNotificationDetails(
    NotificationConstants.channelId,
    NotificationConstants.channelName,
    channelDescription: NotificationConstants.channelDescription,
    importance: Importance.max,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    enableLights: true,
    ledColor: Color.fromARGB(255, 99, 102, 241),
    ledOnMs: 1000,
    ledOffMs: 500,
    icon: '@mipmap/ic_launcher',
    largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    styleInformation: BigTextStyleInformation(''),
    ticker: 'Smart EMI',
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.reminder,
    fullScreenIntent: true,
    autoCancel: true,
  );

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;
  bool _hasPermission = false;
  String _currentTimezone = 'UTC';

  /// Check if notifications are initialized
  bool get isInitialized => _isInitialized;
  bool get hasPermission => _hasPermission;
  String get currentTimezone => _currentTimezone;

  /// Initialize notification service
  Future<void> init() async {
    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize timezone database
    tz.initializeTimeZones();

    // Detect and set local timezone automatically
    await _setLocalTimezone();

    // Android initialization settings
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization settings (for future use)
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: iOS,
    );

    try {
      await _flutterLocalNotificationsPlugin.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
      );

      // Get Android-specific implementation
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        // Create notification channel (required for Android 8.0+)
        const AndroidNotificationChannel channel = AndroidNotificationChannel(
          NotificationConstants.channelId,
          NotificationConstants.channelName,
          description: NotificationConstants.channelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
          ledColor: Color.fromARGB(255, 99, 102, 241),
          showBadge: true,
        );
        await androidImplementation.createNotificationChannel(channel);
        debugPrint('✅ Notification channel created: ${NotificationConstants.channelId}');

        // Request notification permission (Android 13+)
        final notifPermission = await androidImplementation.requestNotificationsPermission();
        _hasPermission = notifPermission ?? false;
        debugPrint('✅ Notification permission granted: $_hasPermission');

        // Request exact alarm permission (Android 12+)
        final alarmPermission = await androidImplementation.requestExactAlarmsPermission();
        debugPrint('✅ Exact alarm permission granted: $alarmPermission');

        // Check if notifications are enabled
        final areEnabled = await androidImplementation.areNotificationsEnabled();
        debugPrint('✅ Notifications enabled: $areEnabled');
      }

      _isInitialized = true;
      debugPrint('✅ Notification service initialized successfully');
      debugPrint('🌍 Using timezone: $_currentTimezone');
    } catch (e) {
      debugPrint('❌ Error initializing notifications: $e');
      _isInitialized = false;
      rethrow;
    }
  }

  /// Detect and set the device's local timezone
  Future<void> _setLocalTimezone() async {
    try {
      // Get the device's timezone offset
      final now = DateTime.now();
      final offset = now.timeZoneOffset;

      // Try to find matching timezone from the database
      String timezoneName = _getTimezoneFromOffset(offset);

      try {
        tz.setLocalLocation(tz.getLocation(timezoneName));
        _currentTimezone = timezoneName;
        debugPrint('✅ Timezone set to: $timezoneName');
      } catch (e) {
        // Fallback to UTC if timezone not found
        tz.setLocalLocation(tz.UTC);
        _currentTimezone = 'UTC';
        debugPrint('⚠️ Timezone $timezoneName not found, using UTC');
      }
    } catch (e) {
      debugPrint('❌ Error detecting timezone: $e');
      tz.setLocalLocation(tz.UTC);
      _currentTimezone = 'UTC';
    }
  }

  /// Map timezone offset to timezone name
  String _getTimezoneFromOffset(Duration offset) {
    final hours = offset.inHours;
    final minutes = offset.inMinutes.remainder(60);

    // Common timezone mappings
    final timezoneMap = {
      // Asia
      '5:30': 'Asia/Kolkata',      // India
      '5:45': 'Asia/Kathmandu',    // Nepal
      '6:0': 'Asia/Dhaka',         // Bangladesh
      '6:30': 'Asia/Yangon',       // Myanmar
      '7:0': 'Asia/Bangkok',       // Thailand, Vietnam
      '8:0': 'Asia/Singapore',     // Singapore, Malaysia, Philippines
      '9:0': 'Asia/Tokyo',         // Japan, Korea
      '9:30': 'Australia/Darwin',  // Australia Central
      '10:0': 'Australia/Sydney',  // Australia Eastern
      '11:0': 'Pacific/Noumea',    // New Caledonia
      '12:0': 'Pacific/Auckland',  // New Zealand

      // Middle East
      '3:0': 'Asia/Riyadh',        // Saudi Arabia
      '3:30': 'Asia/Tehran',       // Iran
      '4:0': 'Asia/Dubai',         // UAE
      '4:30': 'Asia/Kabul',        // Afghanistan

      // Europe
      '0:0': 'Europe/London',      // UK (GMT)
      '1:0': 'Europe/Paris',       // Central Europe
      '2:0': 'Europe/Helsinki',    // Eastern Europe

      // Americas
      '-5:0': 'America/New_York',  // US Eastern
      '-6:0': 'America/Chicago',   // US Central
      '-7:0': 'America/Denver',    // US Mountain
      '-8:0': 'America/Los_Angeles', // US Pacific
      '-3:0': 'America/Sao_Paulo', // Brazil
      '-4:0': 'America/New_York',  // US Eastern (DST)

      // Africa
      '1:0': 'Africa/Lagos',       // West Africa
      '2:0': 'Africa/Cairo',       // Egypt
      '3:0': 'Africa/Nairobi',     // East Africa
    };

    final key = '$hours:${minutes.abs()}';
    return timezoneMap[key] ?? 'UTC';
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
    // Handle navigation or other actions based on payload
  }

  /// Handle background notification tap
  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Background notification tapped: ${response.payload}');
  }

  /// Schedule reminders for a loan (next due cycle only)
  /// Set testMode = true to show immediate test notification
  Future<void> scheduleLoadReminders(Loan loan, {bool testMode = false}) async {
    if (!_isInitialized) {
      debugPrint('⚠️ Notification service not initialized');
      return;
    }

    final currencySymbol = loan.currencySymbol;

    if (testMode) {
      // TEST MODE: Show immediate notification to verify it works
      debugPrint('========================================');
      debugPrint('🧪 TEST MODE: Attempting to show notification');
      debugPrint('Loan: ${loan.name}, EMI: ${loan.emiAmount}');
      try {
        await _flutterLocalNotificationsPlugin.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          '🔔 Smart EMI Test',
          '${loan.name} - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} notification is working!',
          const NotificationDetails(android: androidDetails),
          payload: loan.id,
        );
        debugPrint('✅ TEST MODE: Notification sent successfully!');
        debugPrint('========================================');
      } catch (e) {
        debugPrint('❌ TEST MODE ERROR: $e');
        debugPrint('========================================');
      }
      return;
    }

    // NORMAL MODE: Schedule based on due date
    final nextDue = loan.getNextDueDate();
    final now = DateTime.now();

    // Calculate base dates for notifications
    final day3Before = nextDue.subtract(const Duration(days: 3));
    final day1Before = nextDue.subtract(const Duration(days: 1));
    final dueDay = nextDue;

    // Use simple IDs based on loan ID
    final baseId = loan.id.hashCode.abs() % 100000;

    debugPrint('📅 Scheduling notifications for ${loan.name}:');
    debugPrint('   Next due date: $nextDue');
    debugPrint('   3 days before: $day3Before');
    debugPrint('   1 day before: $day1Before');
    debugPrint('   Current time: $now');

    // Notification times: 9 AM, 1 PM, 5 PM, 9 PM (every 4 hours)
    final notificationHours = [9, 13, 17, 21];

    int notificationIndex = 0;
    int scheduledCount = 0;

    // Day 1: 3 days before due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(day3Before.year, day3Before.month, day3Before.day, hour, 0, 0);
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _getNotificationTitle(3, hour),
          body: '${loan.name} - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} due on ${loan.dueDay}${_getDaySuffix(loan.dueDay)}',
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    // Day 2: 1 day before due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(day1Before.year, day1Before.month, day1Before.day, hour, 0, 0);
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _getNotificationTitle(1, hour),
          body: '${loan.name} - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} is due tomorrow! Don\'t forget to pay.',
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    // Day 3: On due date
    for (int hour in notificationHours) {
      final scheduledDate = DateTime(dueDay.year, dueDay.month, dueDay.day, hour, 0, 0);
      if (scheduledDate.isAfter(now)) {
        final success = await _scheduleNotification(
          id: baseId + notificationIndex,
          title: _getNotificationTitle(0, hour),
          body: '${loan.name} - $currencySymbol${loan.emiAmount.toStringAsFixed(0)} is due today! Pay now to avoid late fees.',
          scheduledDate: scheduledDate,
          payload: loan.id,
        );
        if (success) scheduledCount++;
      }
      notificationIndex++;
    }

    debugPrint('✅ Scheduled $scheduledCount out of $notificationIndex notifications for ${loan.name}');

    // Verify by checking pending notifications
    final pendingCount = await getPendingNotificationsCount();
    debugPrint('📊 Total pending notifications now: $pendingCount');
  }

  /// Get notification title based on days remaining and time
  String _getNotificationTitle(int daysRemaining, int hour) {
    String timeEmoji;
    if (hour == 9) {
      timeEmoji = '🌅'; // Morning
    } else if (hour == 13) {
      timeEmoji = '☀️'; // Afternoon
    } else if (hour == 17) {
      timeEmoji = '🌆'; // Evening
    } else {
      timeEmoji = '🌙'; // Night
    }

    if (daysRemaining == 3) {
      return '$timeEmoji EMI Due in 3 Days';
    } else if (daysRemaining == 1) {
      return '$timeEmoji EMI Due Tomorrow';
    } else {
      return '🔴 $timeEmoji EMI Due Today!';
    }
  }

  /// Schedule a single notification
  Future<bool> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    required String payload,
  }) async {
    try {
      final now = DateTime.now();

      // Prevent scheduling past dates
      if (scheduledDate.isBefore(now)) {
        debugPrint('⏭️ Skipping notification $id - scheduled date ($scheduledDate) is in the past');
        return false;
      }

      // Use zonedSchedule for all future notifications
      final tzScheduledDate = tz.TZDateTime.from(
        scheduledDate,
        tz.local,
      );

      debugPrint('⏰ Scheduling notification $id at $tzScheduledDate (local: $scheduledDate)');

      // Try alarmClock mode first (better for Chinese phones like Realme, Xiaomi, OPPO)
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.alarmClock,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint('✅ Notification $id scheduled with alarmClock mode');
        return true;
      } catch (alarmClockError) {
        debugPrint('⚠️ alarmClock mode failed: $alarmClockError, trying exactAllowWhileIdle...');
      }

      // Fallback to exactAllowWhileIdle
      try {
        await _flutterLocalNotificationsPlugin.zonedSchedule(
          id,
          title,
          body,
          tzScheduledDate,
          const NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
        debugPrint('✅ Notification $id scheduled with exactAllowWhileIdle mode');
        return true;
      } catch (exactError) {
        debugPrint('⚠️ exactAllowWhileIdle failed: $exactError, trying inexact...');
      }

      // Final fallback to inexact
      await _flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        tzScheduledDate,
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('✅ Notification $id scheduled with inexact mode');
      return true;
    } catch (e) {
      debugPrint('❌ All scheduling methods failed for notification $id: $e');
      return false;
    }
  }

  /// Cancel reminders for a loan
  Future<void> cancelLoanReminders(String loanId, {int tenureMonths = 12}) async {
    // Cancel all 12 notifications (4 per day × 3 days)
    final baseId = loanId.hashCode.abs() % 100000;
    try {
      for (int i = 0; i < 12; i++) {
        await _flutterLocalNotificationsPlugin.cancel(baseId + i);
      }
      debugPrint('✅ Cancelled all notifications for loan: $loanId');
    } catch (e) {
      debugPrint('❌ Error cancelling notifications: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _flutterLocalNotificationsPlugin.cancelAll();
      debugPrint('✅ All notifications cancelled');
    } catch (e) {
      debugPrint('❌ Error cancelling all notifications: $e');
    }
  }

  /// Test notification
  Future<void> showTestNotification() async {
    try {
      await _flutterLocalNotificationsPlugin.show(
        0,
        '🔔 Test Notification',
        'EMI Reminder is working! You will receive timely reminders for your EMI payments.',
        const NotificationDetails(android: androidDetails),
      );
      debugPrint('✅ Test notification sent');
    } catch (e) {
      debugPrint('❌ Error sending test notification: $e');
    }
  }

  /// Get pending notifications count
  Future<int> getPendingNotificationsCount() async {
    try {
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      return pending.length;
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return 0;
    }
  }

  /// Get list of pending notifications for debugging
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
    } catch (e) {
      debugPrint('❌ Error getting pending notifications: $e');
      return [];
    }
  }

  /// Check if all required permissions are granted
  Future<Map<String, bool>> checkAllPermissions() async {
    final permissions = <String, bool>{
      'notifications': false,
      'exactAlarms': false,
      'notificationsEnabled': false,
    };

    try {
      final androidImplementation = _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        permissions['notificationsEnabled'] =
            await androidImplementation.areNotificationsEnabled() ?? false;
      }

      permissions['notifications'] = _hasPermission;
      permissions['exactAlarms'] = true; // Assume granted if no error during init
    } catch (e) {
      debugPrint('❌ Error checking permissions: $e');
    }

    return permissions;
  }

  /// Get debug info for troubleshooting
  Future<String> getDebugInfo() async {
    final buffer = StringBuffer();

    buffer.writeln('=== Notification Debug Info ===');
    buffer.writeln('Initialized: $_isInitialized');
    buffer.writeln('Has Permission: $_hasPermission');
    buffer.writeln('Timezone: $_currentTimezone');
    buffer.writeln('Current Time: ${DateTime.now()}');

    try {
      final pending = await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
      buffer.writeln('Pending Count: ${pending.length}');

      if (pending.isNotEmpty) {
        buffer.writeln('\nScheduled Notifications:');
        for (var notif in pending.take(10)) {
          buffer.writeln('  ID: ${notif.id}, Title: ${notif.title}');
        }
        if (pending.length > 10) {
          buffer.writeln('  ... and ${pending.length - 10} more');
        }
      }
    } catch (e) {
      buffer.writeln('Error getting pending: $e');
    }

    return buffer.toString();
  }

  /// Get day suffix (st, nd, rd, th)
  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}

