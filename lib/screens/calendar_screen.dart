import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/loan.dart';
import '../services/loan_storage_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class CalendarScreen extends StatefulWidget {
  final LoanStorageService storageService;

  const CalendarScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focusedDay;
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
    _selectedDay = DateTime.now();
  }

  // Get loans that have due date on a specific day
  List<Loan> _getLoansForDay(DateTime day) {
    final loans = widget.storageService.getAllLoans();
    final daysInMonth = DateTime(day.year, day.month + 1, 0).day;

    return loans.where((loan) {
      // If loan's due day is greater than days in this month,
      // it should fall on the last day of the month
      int effectiveDueDay = loan.dueDay;
      if (loan.dueDay > daysInMonth) {
        effectiveDueDay = daysInMonth;
      }
      return effectiveDueDay == day.day;
    }).toList();
  }

  // Get all EMI due dates for the calendar markers
  Map<DateTime, List<Loan>> _getEmiEvents() {
    final events = <DateTime, List<Loan>>{};
    final loans = widget.storageService.getAllLoans();

    // Generate events for 12 months ahead
    final now = DateTime.now();
    for (int monthOffset = 0; monthOffset < 12; monthOffset++) {
      final month = DateTime(now.year, now.month + monthOffset, 1);

      for (var loan in loans) {
        int dueDay = loan.dueDay;
        // Handle months with fewer days
        final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
        if (dueDay > daysInMonth) {
          dueDay = daysInMonth;
        }

        final dueDate = DateTime(month.year, month.month, dueDay);

        if (events[dueDate] == null) {
          events[dueDate] = [];
        }
        events[dueDate]!.add(loan);
      }
    }

    return events;
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEmiEvents();
    final l = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(l.emiCalendar),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Calendar Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                Text(
                  l.trackYourEmiDueDates,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Calendar Widget
          Card(
            margin: const EdgeInsets.all(16),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: TableCalendar<Loan>(
                firstDay: DateTime.now().subtract(const Duration(days: 365)),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                calendarFormat: _calendarFormat,
                eventLoader: (day) {
                  final normalizedDay = DateTime(day.year, day.month, day.day);
                  return events[normalizedDay] ?? [];
                },
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: BoxDecoration(
                    color: AppTheme.statusWarning,
                    shape: BoxShape.circle,
                  ),
                  markersMaxCount: 3,
                  outsideDaysVisible: false,
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  titleCentered: true,
                  formatButtonDecoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  formatButtonTextStyle: TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                  titleTextStyle: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  markerBuilder: (context, date, events) {
                    if (events.isEmpty) return null;

                    return Positioned(
                      bottom: 1,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: events.length > 1
                              ? AppTheme.statusError
                              : AppTheme.statusWarning,
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Selected Day's EMIs
          Expanded(
            child: _buildSelectedDayLoans(),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedDayLoans() {
    final loans = _getLoansForDay(_selectedDay ?? DateTime.now());
    final selectedDate = _selectedDay ?? DateTime.now();
    final l = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${l.loansOnThisDay} - ${DateFormat('MMMM d').format(selectedDate)}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Expanded(
            child: loans.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_available,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          l.noEmiDueOnThisDay,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: loans.length,
                    itemBuilder: (context, index) {
                      final loan = loans[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.account_balance,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          title: Text(
                            _getTranslatedLoanName(loan, l),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Text(
                            '${l.dueDay}: ${loan.dueDay}${_getDaySuffix(loan.dueDay)} ${l.everyMonth}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                loan.formattedEmi,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                              const Text(
                                'EMI',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  /// Translate standard loan type names to current language
  String _getTranslatedLoanName(Loan loan, AppLocalizations l) {
    final name = loan.name.toLowerCase();

    if (name == 'home loan' || name.contains('வீட்டுக் கடன்') ||
        name.contains('గృహ రుణం') || name.contains('गृह ऋण')) {
      return l.getLoanTypeName('Home Loan');
    }
    if (name == 'car loan' || name.contains('வாகனக் கடன்') ||
        name.contains('వాహన రుణం') || name.contains('कार ऋण')) {
      return l.getLoanTypeName('Car Loan');
    }
    if (name == 'personal loan' || name.contains('தனிநபர் கடன்') ||
        name.contains('వ్యக்తిగత రుణం') || name.contains('व्यक्तिगत ऋण')) {
      return l.getLoanTypeName('Personal Loan');
    }
    if (name == 'education loan' || name.contains('கல்விக் கடன்') ||
        name.contains('విద்యా రుణం') || name.contains('शिक्षा ऋण')) {
      return l.getLoanTypeName('Education Loan');
    }
    if (name == 'business loan' || name.contains('தொழில் கடன்') ||
        name.contains('வ్యాபార రుణం') || name.contains('व्यापार ऋण')) {
      return l.getLoanTypeName('Business Loan');
    }
    if (name == 'gold loan' || name.contains('நகைக்கடன்') ||
        name.contains('బంగారు రుణం') || name.contains('स्वर्ण ऋण')) {
      return l.getLoanTypeName('Gold Loan');
    }
    if (name == 'credit card' || name.contains('கிரெடிட் கார்டு') ||
        name.contains('క్రెడిట్ కార్డ్') || name.contains('क्रेडिट कार्ड')) {
      return l.getLoanTypeName('Credit Card');
    }

    return loan.name;
  }
}
