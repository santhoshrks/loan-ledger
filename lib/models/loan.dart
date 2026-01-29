import 'package:hive/hive.dart';

part 'loan.g.dart';

@HiveType(typeId: 0)
class Loan extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late double emiAmount;

  @HiveField(3)
  late int dueDay; // Day of month (1-31)

  @HiveField(4)
  late DateTime startDate;

  @HiveField(5)
  late String? notes;

  @HiveField(6)
  late double? loanAmount;

  @HiveField(7)
  late double? interestRate;

  @HiveField(8)
  late int? tenureMonths;

  @HiveField(9)
  late bool isPaid;

  @HiveField(10)
  late String currencyCode; // Currency code (INR, USD, EUR, etc.)

  @HiveField(11)
  late int emisPaidCount; // Number of EMIs already paid (for loans added with past start date)

  Loan({
    required this.id,
    required this.name,
    required this.emiAmount,
    required this.dueDay,
    required this.startDate,
    this.notes,
    this.loanAmount,
    this.interestRate,
    this.tenureMonths,
    this.isPaid = false,
    this.currencyCode = 'INR', // Default to INR for backward compatibility
    this.emisPaidCount = 0, // Default to 0 EMIs paid
  });

  /// Get currency symbol based on currency code
  String get currencySymbol => CurrencyHelper.getSymbol(currencyCode);

  /// Get formatted EMI amount with currency symbol
  String get formattedEmi => '$currencySymbol${emiAmount.toStringAsFixed(0)}';

  /// Calculate next due date from today
  /// If current month's EMI is unpaid and overdue, it still shows current month's due date
  /// Only moves to next month if current month's EMI is marked as paid
  DateTime getNextDueDate() {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;
    int day = dueDay;

    // Helper function to get valid day for a given month
    int getValidDay(int y, int m, int desiredDay) {
      final daysInMonth = DateTime(y, m + 1, 0).day;
      return desiredDay > daysInMonth ? daysInMonth : desiredDay;
    }

    // Get valid day for current month
    day = getValidDay(year, month, dueDay);
    DateTime dueDate = DateTime(year, month, day);

    // If current month's EMI is marked as paid, move to next month
    if (isPaid) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      day = getValidDay(year, month, dueDay);
      dueDate = DateTime(year, month, day);
    }
    // If due date has passed this month but NOT paid, still show current month (overdue)
    // Only if NOT paid and due date hasn't come yet, show current month
    // If NOT paid and due date has passed, show current month (it's overdue)

    return dueDate;
  }

  /// Get the due date that needs to be paid (current unpaid EMI)
  /// Returns the overdue date if EMI is unpaid and past due
  DateTime getCurrentDueDate() {
    final now = DateTime.now();
    int year = now.year;
    int month = now.month;

    // Helper function to get valid day for a given month
    int getValidDay(int y, int m, int desiredDay) {
      final daysInMonth = DateTime(y, m + 1, 0).day;
      return desiredDay > daysInMonth ? daysInMonth : desiredDay;
    }

    int day = getValidDay(year, month, dueDay);
    return DateTime(year, month, day);
  }

  /// Get days until due date (negative if overdue)
  int daysUntilDue() {
    final nextDue = getNextDueDate();
    final now = DateTime.now();

    // Normalize both dates to midnight for accurate day comparison
    final normalizedDue = DateTime(nextDue.year, nextDue.month, nextDue.day);
    final normalizedNow = DateTime(now.year, now.month, now.day);

    return normalizedDue.difference(normalizedNow).inDays;
  }

  /// Check if current month's EMI is overdue
  bool isOverdue() {
    if (isPaid) return false; // Already paid, not overdue
    final currentDue = getCurrentDueDate();
    final now = DateTime.now();
    final normalizedDue = DateTime(currentDue.year, currentDue.month, currentDue.day);
    final normalizedNow = DateTime(now.year, now.month, now.day);
    return normalizedNow.isAfter(normalizedDue);
  }

  /// Check if reminder should be sent
  bool shouldSendReminder() {
    final daysLeft = daysUntilDue();
    // Send reminder 3 days before, 1 day before, or on due date
    return daysLeft == 3 || daysLeft == 1 || daysLeft == 0;
  }

  /// Reset loan for next month after payment
  /// This marks the loan as not paid for the next cycle
  void resetForNextMonth() {
    isPaid = false; // Reset for next month
  }

  /// Get tenure remaining (if tracked)
  int getTenureRemaining() {
    if (tenureMonths == null) return 0;
    // Calculate months elapsed since start date
    final now = DateTime.now();
    final monthsElapsed = ((now.year - startDate.year) * 12) +
        (now.month - startDate.month);
    final remaining = tenureMonths! - monthsElapsed;
    return remaining > 0 ? remaining : 0;
  }
}

/// Helper class for currency operations
class CurrencyHelper {
  static const Map<String, String> _currencySymbols = {
    'INR': '₹',    // Indian Rupee
    'USD': '\$',   // US Dollar
    'EUR': '€',    // Euro
    'GBP': '£',    // British Pound
    'JPY': '¥',    // Japanese Yen
    'CNY': '¥',    // Chinese Yuan
    'AUD': 'A\$',  // Australian Dollar
    'CAD': 'C\$',  // Canadian Dollar
    'SGD': 'S\$',  // Singapore Dollar
    'MYR': 'RM',   // Malaysian Ringgit
    'THB': '฿',    // Thai Baht
    'IDR': 'Rp',   // Indonesian Rupiah
    'PHP': '₱',    // Philippine Peso
    'VND': '₫',    // Vietnamese Dong
    'KRW': '₩',    // Korean Won
    'BDT': '৳',    // Bangladeshi Taka
    'PKR': 'Rs',   // Pakistani Rupee
    'LKR': 'Rs',   // Sri Lankan Rupee
    'NPR': 'रू',   // Nepalese Rupee
    'AED': 'د.إ',  // UAE Dirham
    'SAR': '﷼',   // Saudi Riyal
    'ZAR': 'R',    // South African Rand
    'BRL': 'R\$',  // Brazilian Real
    'MXN': '\$',   // Mexican Peso
    'RUB': '₽',    // Russian Ruble
    'TRY': '₺',    // Turkish Lira
    'CHF': 'Fr',   // Swiss Franc
    'SEK': 'kr',   // Swedish Krona
    'NOK': 'kr',   // Norwegian Krone
    'DKK': 'kr',   // Danish Krone
    'NZD': 'NZ\$', // New Zealand Dollar
    'HKD': 'HK\$', // Hong Kong Dollar
    'TWD': 'NT\$', // Taiwan Dollar
  };

  static const Map<String, String> _currencyNames = {
    'INR': 'Indian Rupee',
    'USD': 'US Dollar',
    'EUR': 'Euro',
    'GBP': 'British Pound',
    'JPY': 'Japanese Yen',
    'CNY': 'Chinese Yuan',
    'AUD': 'Australian Dollar',
    'CAD': 'Canadian Dollar',
    'SGD': 'Singapore Dollar',
    'MYR': 'Malaysian Ringgit',
    'THB': 'Thai Baht',
    'IDR': 'Indonesian Rupiah',
    'PHP': 'Philippine Peso',
    'VND': 'Vietnamese Dong',
    'KRW': 'Korean Won',
    'BDT': 'Bangladeshi Taka',
    'PKR': 'Pakistani Rupee',
    'LKR': 'Sri Lankan Rupee',
    'NPR': 'Nepalese Rupee',
    'AED': 'UAE Dirham',
    'SAR': 'Saudi Riyal',
    'ZAR': 'South African Rand',
    'BRL': 'Brazilian Real',
    'MXN': 'Mexican Peso',
    'RUB': 'Russian Ruble',
    'TRY': 'Turkish Lira',
    'CHF': 'Swiss Franc',
    'SEK': 'Swedish Krona',
    'NOK': 'Norwegian Krone',
    'DKK': 'Danish Krone',
    'NZD': 'New Zealand Dollar',
    'HKD': 'Hong Kong Dollar',
    'TWD': 'Taiwan Dollar',
  };

  /// Get currency symbol from code
  static String getSymbol(String code) {
    return _currencySymbols[code.toUpperCase()] ?? code;
  }

  /// Get currency name from code
  static String getName(String code) {
    return _currencyNames[code.toUpperCase()] ?? code;
  }

  /// Get all supported currencies
  static List<String> get supportedCurrencies => _currencySymbols.keys.toList();

  /// Get currency code from device locale
  static String getDefaultCurrency() {
    // This can be enhanced to detect from device locale
    return 'INR';
  }
}

