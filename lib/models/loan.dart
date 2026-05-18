import 'package:hive/hive.dart';
import 'package:intl/intl.dart';

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

  @HiveField(12)
  String? bankName; // Bank or lender name (Chase, HSBC, HDFC, etc.)

  @HiveField(13)
  String? loanTypeName; // Loan type (Home Loan, Car Loan, Gold Loan, etc.)

  @HiveField(14)
  List<double>? rateHistory; // Historical interest rates for floating rate tracking

  @HiveField(15)
  List<String>? rateHistoryDates; // Dates of rate changes (ISO string)

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
    this.currencyCode = 'INR',
    this.emisPaidCount = 0,
    this.bankName,
    this.loanTypeName,
    this.rateHistory,
    this.rateHistoryDates,
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

    // Helper function to get valid day for a given month
    int getValidDay(int y, int m, int desiredDay) {
      final daysInMonth = DateTime(y, m + 1, 0).day;
      return desiredDay > daysInMonth ? daysInMonth : desiredDay;
    }

    // Start from the later of today or the loan's startDate month
    DateTime reference = now;
    if (startDate.isAfter(now)) {
      // Use startDate as reference so we don't schedule before the loan starts
      reference = DateTime(startDate.year, startDate.month, startDate.day);
    }

    int year = reference.year;
    int month = reference.month;
    int day = getValidDay(year, month, dueDay);
    DateTime dueDate = DateTime(year, month, day);

    // If the reference is the startDate and the computed dueDate is before the actual startDate
    // advance to next month so the first due is on/after startDate
    if (dueDate.isBefore(startDate)) {
      month++;
      if (month > 12) {
        month = 1;
        year++;
      }
      day = getValidDay(year, month, dueDay);
      dueDate = DateTime(year, month, day);
    }

    // If current/first due month is already marked as paid, move to next month
    if (isPaid) {
      month = dueDate.month + 1;
      year = dueDate.year;
      if (month > 12) {
        month = 1;
        year++;
      }
      day = getValidDay(year, month, dueDay);
      dueDate = DateTime(year, month, day);
    }

    return dueDate;
  }

  /// Get the due date that needs to be paid (current unpaid EMI)
  /// Returns the overdue date if EMI is unpaid and past due
  DateTime getCurrentDueDate() {
    final now = DateTime.now();

    // Helper function to get valid day for a given month
    int getValidDay(int y, int m, int desiredDay) {
      final daysInMonth = DateTime(y, m + 1, 0).day;
      return desiredDay > daysInMonth ? daysInMonth : desiredDay;
    }

    // If loan hasn't started yet, the current due date should be its first due date
    if (startDate.isAfter(now)) {
      int year = startDate.year;
      int month = startDate.month;
      int day = getValidDay(year, month, dueDay);
      DateTime dueDate = DateTime(year, month, day);
      if (dueDate.isBefore(startDate)) {
        month++;
        if (month > 12) {
          month = 1;
          year++;
        }
        day = getValidDay(year, month, dueDay);
        dueDate = DateTime(year, month, day);
      }
      return dueDate;
    }

    int year = now.year;
    int month = now.month;
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
    // Primary markets
    'INR': '₹',    // Indian Rupee
    'PKR': '₨',    // Pakistani Rupee (distinct symbol)
    'PHP': '₱',    // Philippine Peso
    'BDT': '৳',    // Bangladeshi Taka
    // Spanish-speaking markets
    'MXN': 'MX\$', // Mexican Peso
    'COP': 'COL\$',// Colombian Peso
    'ARS': 'AR\$', // Argentine Peso
    'PEN': 'S/',   // Peruvian Sol
    'CLP': 'CL\$', // Chilean Peso
    // Global
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
    'VND': '₫',    // Vietnamese Dong
    'KRW': '₩',    // Korean Won
    'LKR': 'Rs',   // Sri Lankan Rupee
    'NPR': 'रू',   // Nepalese Rupee
    'AED': 'د.إ',  // UAE Dirham
    'SAR': '﷼',   // Saudi Riyal
    'ZAR': 'R',    // South African Rand
    'BRL': 'R\$',  // Brazilian Real
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
    'INR': 'Indian Rupee (₹)',
    'PKR': 'Pakistani Rupee (₨)',
    'PHP': 'Philippine Peso (₱)',
    'BDT': 'Bangladeshi Taka (৳)',
    'MXN': 'Mexican Peso (MX\$)',
    'COP': 'Colombian Peso (COL\$)',
    'ARS': 'Argentine Peso (AR\$)',
    'PEN': 'Peruvian Sol (S/)',
    'CLP': 'Chilean Peso (CL\$)',
    'USD': 'US Dollar (\$)',
    'EUR': 'Euro (€)',
    'GBP': 'British Pound (£)',
    'JPY': 'Japanese Yen (¥)',
    'CNY': 'Chinese Yuan (¥)',
    'AUD': 'Australian Dollar (A\$)',
    'CAD': 'Canadian Dollar (C\$)',
    'SGD': 'Singapore Dollar (S\$)',
    'MYR': 'Malaysian Ringgit (RM)',
    'THB': 'Thai Baht (฿)',
    'IDR': 'Indonesian Rupiah (Rp)',
    'VND': 'Vietnamese Dong (₫)',
    'KRW': 'Korean Won (₩)',
    'LKR': 'Sri Lankan Rupee (Rs)',
    'NPR': 'Nepalese Rupee (रू)',
    'AED': 'UAE Dirham (د.إ)',
    'SAR': 'Saudi Riyal (﷼)',
    'ZAR': 'South African Rand (R)',
    'BRL': 'Brazilian Real (R\$)',
    'RUB': 'Russian Ruble (₽)',
    'TRY': 'Turkish Lira (₺)',
    'CHF': 'Swiss Franc (Fr)',
    'SEK': 'Swedish Krona (kr)',
    'NOK': 'Norwegian Krone (kr)',
    'DKK': 'Danish Krone (kr)',
    'NZD': 'New Zealand Dollar (NZ\$)',
    'HKD': 'Hong Kong Dollar (HK\$)',
    'TWD': 'Taiwan Dollar (NT\$)',
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
    try {
      final locale = Intl.getCurrentLocale();
      final localeLower = locale.toLowerCase();

      // India (primary market) — INR
      if (localeLower.startsWith('hi') || localeLower.startsWith('ta') ||
          localeLower.startsWith('te') || localeLower.startsWith('kn') ||
          localeLower.startsWith('ml') || localeLower.startsWith('mr') ||
          localeLower.startsWith('gu') || localeLower.startsWith('pa') ||
          localeLower.contains('en_in') || localeLower == 'en_in') return 'INR';

      // Pakistan — PKR
      if (localeLower.startsWith('ur') || localeLower.contains('en_pk') ||
          localeLower.contains('ur_pk')) return 'PKR';

      // Philippines — PHP
      if (localeLower.startsWith('fil') || localeLower.startsWith('tl') ||
          localeLower.contains('en_ph')) return 'PHP';

      // Bangladesh — BDT
      if (localeLower.startsWith('bn') || localeLower.contains('en_bd')) return 'BDT';

      // Spanish-speaking countries
      if (localeLower.contains('es_mx')) return 'MXN'; // Mexico
      if (localeLower.contains('es_co')) return 'COP'; // Colombia
      if (localeLower.contains('es_ar')) return 'ARS'; // Argentina
      if (localeLower.contains('es_pe')) return 'PEN'; // Peru
      if (localeLower.contains('es_cl')) return 'CLP'; // Chile
      if (localeLower.contains('es_es')) return 'EUR'; // Spain
      if (localeLower.startsWith('es')) return 'USD';  // Other Spanish (many use USD)

      // Other regions
      if (localeLower.contains('en_us') || localeLower.startsWith('en_us')) return 'USD';
      if (localeLower.contains('en_gb')) return 'GBP';
      if (localeLower.startsWith('de') || localeLower.startsWith('fr') ||
          localeLower.startsWith('it')) return 'EUR';
      if (localeLower.startsWith('ja')) return 'JPY';
      if (localeLower.startsWith('zh')) return 'CNY';
      if (localeLower.contains('en_au')) return 'AUD';
      if (localeLower.contains('en_ca')) return 'CAD';
      if (localeLower.contains('en_sg') || localeLower.contains('zh_sg')) return 'SGD';
      if (localeLower.startsWith('ms') || localeLower.contains('en_my')) return 'MYR';
      if (localeLower.startsWith('id')) return 'IDR';
      if (localeLower.startsWith('th')) return 'THB';
      if (localeLower.startsWith('ko')) return 'KRW';
      if (localeLower.contains('ar_ae') || localeLower.contains('en_ae')) return 'AED';
      if (localeLower.contains('ar_sa')) return 'SAR';
      if (localeLower.contains('pt_br')) return 'BRL';
      if (localeLower.startsWith('tr')) return 'TRY';
      if (localeLower.startsWith('ru')) return 'RUB';
    } catch (_) {}
    return 'INR'; // Default to INR (primary market)
  }
}

