import 'package:intl/intl.dart';

/// Utility class for compact number formatting (global K/M/B notation)
class IndianNumberFormat {
  static final NumberFormat _standardFormat = NumberFormat('#,###');

  /// Format number with standard comma separator
  static String format(double amount) {
    return _standardFormat.format(amount.round());
  }

  /// Format with currency symbol
  static String formatCurrency(double amount, {String symbol = ''}) {
    return '$symbol${format(amount)}';
  }

  /// Format as compact: K / M / B notation (universal)
  /// e.g. 250000 → 250K, 10000000 → 10M
  static String formatCompact(double amount, {String symbol = ''}) {
    if (amount >= 1000000000) {
      final b = amount / 1000000000;
      return '$symbol${_removeTrailingZeros(b.toStringAsFixed(2))}B';
    } else if (amount >= 1000000) {
      final m = amount / 1000000;
      return '$symbol${_removeTrailingZeros(m.toStringAsFixed(2))}M';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '$symbol${_removeTrailingZeros(k.toStringAsFixed(1))}K';
    }
    return '$symbol${amount.toStringAsFixed(0)}';
  }

  /// Format with both compact and full value
  /// e.g. 250K (250,000)
  static String formatWithFull(double amount, {String symbol = ''}) {
    if (amount >= 1000) {
      return '${formatCompact(amount, symbol: symbol)} (${formatCurrency(amount, symbol: symbol)})';
    }
    return formatCurrency(amount, symbol: symbol);
  }

  /// Convert amount to words (universal)
  static String toWords(double amount) {
    if (amount >= 1000000000) {
      final b = amount / 1000000000;
      return '${_removeTrailingZeros(b.toStringAsFixed(2))} Billion';
    } else if (amount >= 1000000) {
      final m = amount / 1000000;
      return '${_removeTrailingZeros(m.toStringAsFixed(2))} Million';
    } else if (amount >= 1000) {
      final k = amount / 1000;
      return '${_removeTrailingZeros(k.toStringAsFixed(1))} Thousand';
    }
    return amount.toStringAsFixed(0);
  }

  static String _removeTrailingZeros(String value) {
    if (!value.contains('.')) return value;
    value = value.replaceAll(RegExp(r'0+$'), '');
    if (value.endsWith('.')) value = value.substring(0, value.length - 1);
    return value;
  }
}
