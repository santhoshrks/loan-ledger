import 'package:flutter/services.dart';

/// Centralized haptic feedback utility — call these on key interactions
class HapticService {
  /// Light tap — used for navigation, toggles, filter chips
  static void light() => HapticFeedback.lightImpact();

  /// Medium impact — used for mark paid, add loan, confirm actions
  static void medium() => HapticFeedback.mediumImpact();

  /// Heavy impact — used for delete, loan completion celebration
  static void heavy() => HapticFeedback.heavyImpact();

  /// Success pattern — double light tap, used for success confirmations
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.lightImpact();
  }

  /// Error pattern — heavy + medium, used for errors/overdue alerts
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.mediumImpact();
  }

  /// Celebration — triple tap, used for loan completion
  static Future<void> celebrate() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
  }

  /// Selection click — very subtle, used for dropdown/list selections
  static void selection() => HapticFeedback.selectionClick();
}

