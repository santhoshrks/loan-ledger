import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class YearlySummaryScreen extends StatefulWidget {
  final List<Loan> loans;
  const YearlySummaryScreen({super.key, required this.loans});
  @override
  State<YearlySummaryScreen> createState() => _YearlySummaryScreenState();
}

class _YearlySummaryScreenState extends State<YearlySummaryScreen> {
  final _shotController = ScreenshotController();
  int _selectedYear = DateTime.now().year;

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Returns the DateTime of the first EMI payment for a loan
  DateTime _firstPayDate(Loan loan) {
    final s = loan.startDate;
    int m = s.month + 1, y = s.year;
    if (m > 12) { m = 1; y++; }
    return DateTime(y, m);
  }

  /// Returns the DateTime of the last EMI payment for a loan (null if no tenure)
  DateTime? _lastPayDate(Loan loan) {
    if (loan.tenureMonths == null) return null;
    final first = _firstPayDate(loan);
    int m = first.month + loan.tenureMonths! - 1;
    int y = first.year + (m - 1) ~/ 12;
    m = ((m - 1) % 12) + 1;
    return DateTime(y, m);
  }

  /// EMI this loan contributes in a given [year],[month] (0 if inactive)
  double _emiInMonth(Loan loan, int year, int month) {
    final now = DateTime.now();
    final monthDate = DateTime(year, month);
    if (monthDate.isAfter(DateTime(now.year, now.month))) return 0; // future
    final first = _firstPayDate(loan);
    if (monthDate.isBefore(first)) return 0; // loan not started yet
    final last = _lastPayDate(loan);
    if (last != null && monthDate.isAfter(last)) return 0; // loan ended
    return loan.emiAmount;
  }

  /// Monthly EMI totals for the selected year (12 values)
  List<double> _monthlyTotals(int year) {
    return List.generate(12, (i) {
      final m = i + 1;
      return widget.loans.fold(0.0, (s, l) => s + _emiInMonth(l, year, m));
    });
  }

  double _calcEMI(double p, double r, int n) {
    if (r == 0) return p / n;
    final f = math.pow(1 + r, n).toDouble();
    return p * r * f / (f - 1);
  }

  /// Interest paid by a loan across the entire selected year (needs full data)
  double _yearlyInterest(Loan loan, int year) {
    if (loan.loanAmount == null || loan.interestRate == null || loan.tenureMonths == null) return 0;
    final r = loan.interestRate! / 12 / 100;
    final n = loan.tenureMonths!;
    final emi = _calcEMI(loan.loanAmount!, r, n);
    double balance = loan.loanAmount!;
    double yearInterest = 0;
    final first = _firstPayDate(loan);

    for (int i = 0; i < n; i++) {
      // Payment month index
      int pm = first.month + i - 1;
      int py = first.year + pm ~/ 12;
      pm = pm % 12 + 1;
      final interest = balance * r;
      balance = math.max(0, balance - (emi - interest));
      if (py == year) yearInterest += interest;
      if (py > year) break;
    }
    return yearInterest;
  }

  // ────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final loans = widget.loans;
    final now = DateTime.now();

    final monthly = _monthlyTotals(_selectedYear);
    final totalPaidYear = monthly.fold(0.0, (s, v) => s + v);

    final hasFullData = loans.any(
        (l) => l.loanAmount != null && l.interestRate != null && l.tenureMonths != null);
    final totalInterestYear = hasFullData
        ? loans.fold(0.0, (s, l) => s + _yearlyInterest(l, _selectedYear))
        : null;
    final totalPrincipalYear = totalInterestYear != null
        ? (totalPaidYear - totalInterestYear).clamp(0.0, double.infinity)
        : null;

    final topLoan = loans.isEmpty ? null
        : loans.reduce((a, b) => a.emiAmount > b.emiAmount ? a : b);

    final maxBar = monthly.fold(0.0, (s, v) => v > s ? v : s);

    // Count loans active in selected year
    final activeLoans = loans.where((l) {
      final first = _firstPayDate(l);
      final last = _lastPayDate(l);
      final yearStart = DateTime(_selectedYear, 1);
      final yearEnd = DateTime(_selectedYear, 12);
      if (first.isAfter(yearEnd)) return false;
      if (last != null && last.isBefore(yearStart)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text('$_selectedYear Summary'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            onPressed: () async {
              final image = await _shotController.capture();
              if (image != null) {
                final tempFile = XFile.fromData(image, mimeType: 'image/png',
                    name: 'emi_summary_$_selectedYear.png');
                await Share.shareXFiles([tempFile],
                    text: 'My EMI Summary $_selectedYear — EMI Reminder App');
              }
            },
          ),
        ],
      ),
      body: Screenshot(
        controller: _shotController,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Year selector
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                icon: const Icon(Icons.chevron_left_rounded),
                onPressed: () => setState(() => _selectedYear--),
              ),
              Text('$_selectedYear',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _selectedYear < now.year ? () => setState(() => _selectedYear++) : null,
              ),
            ]),

            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Text(
                  _selectedYear == now.year
                      ? 'EMI Paid Jan–${DateFormat('MMM').format(DateTime(now.year, now.month))} $_selectedYear'
                      : 'Total EMI Paid in $_selectedYear',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(IndianNumberFormat.formatCompact(totalPaidYear),
                    style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                Text(IndianNumberFormat.formatWithFull(totalPaidYear),
                    style: const TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 16),
                Row(children: [
                  if (totalPrincipalYear != null)
                    _statChip('Principal', IndianNumberFormat.formatCompact(totalPrincipalYear), AppTheme.statusSuccess)
                  else
                    _statChip('EMI/mo', IndianNumberFormat.formatCompact(
                        loans.fold(0.0, (s, l) => s + l.emiAmount)), AppTheme.statusSuccess),
                  const SizedBox(width: 8),
                  if (totalInterestYear != null)
                    _statChip('Interest', IndianNumberFormat.formatCompact(totalInterestYear), AppTheme.accentOrange)
                  else
                    _statChip('Active', '${activeLoans.length}', Colors.white70),
                  const SizedBox(width: 8),
                  _statChip('Loans', '${activeLoans.length}', Colors.white),
                ]),
              ]),
            ),
            const SizedBox(height: 12),

            // Partial data notice
            if (!hasFullData)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.2)),
                ),
                child: const Row(children: [
                  Icon(Icons.info_outline_rounded, color: AppTheme.accentOrange, size: 15),
                  SizedBox(width: 8),
                  Expanded(child: Text(
                    'Add Loan Amount & Interest Rate to see principal/interest split.',
                    style: TextStyle(fontSize: 11, color: AppTheme.accentOrange),
                  )),
                ]),
              ),

            // Month-wise bar chart
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Monthly EMI Outflow',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              SizedBox(
                height: 110,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (i) {
                    final month = i + 1;
                    final val = monthly[i];
                    final isCurrentMonth = _selectedYear == now.year && month == now.month;
                    final isFuture = val == 0 &&
                        (_selectedYear > now.year || (_selectedYear == now.year && month > now.month));
                    final isInactive = val == 0 && !isFuture; // loan hadn't started / ended
                    final barH = maxBar > 0
                        ? (val / maxBar * 80).clamp(4.0, 80.0)
                        : (isFuture ? 4.0 : 4.0);
                    final barColor = isFuture || isInactive
                        ? AppTheme.textLight.withValues(alpha: 0.25)
                        : isCurrentMonth
                            ? AppTheme.primaryColor
                            : AppTheme.primaryColor.withValues(alpha: 0.55);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          if (!isFuture && !isInactive && val > 0)
                            Text(
                              IndianNumberFormat.formatCompact(val),
                              style: TextStyle(
                                  fontSize: 7,
                                  color: isCurrentMonth ? AppTheme.primaryColor : AppTheme.textLight),
                            ),
                          Container(
                            height: barH,
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(DateFormat('MMM').format(DateTime(_selectedYear, month)),
                              style: const TextStyle(fontSize: 8, color: AppTheme.textLight)),
                        ]),
                      ),
                    );
                  }),
                ),
              ),
            ])),
            const SizedBox(height: 16),

            // Loan-wise breakdown
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Loan-wise Annual Breakdown',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              if (activeLoans.isEmpty)
                const Center(child: Text('No active loans in this year.',
                    style: TextStyle(color: AppTheme.textLight, fontSize: 13)))
              else
                ...activeLoans.map((l) {
                  final lMonthly = List.generate(12, (i) => _emiInMonth(l, _selectedYear, i + 1));
                  final lTotal = lMonthly.fold(0.0, (s, v) => s + v);
                  final lInterest = _yearlyInterest(l, _selectedYear);
                  final activeMs = lMonthly.where((v) => v > 0).length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        Text(
                          l.loanTypeName != null ? '${l.loanTypeName} • $activeMs months' : '$activeMs months active',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textLight),
                        ),
                        if (lInterest > 0)
                          Text('Interest: ${IndianNumberFormat.formatCompact(lInterest)}',
                              style: const TextStyle(fontSize: 11, color: AppTheme.accentOrange)),
                      ])),
                      Text(IndianNumberFormat.formatCompact(lTotal, symbol: l.currencySymbol),
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                    ]),
                  );
                }),
            ])),
            const SizedBox(height: 16),

            if (topLoan != null) ...[
              _card(Row(children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.accentOrange, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Largest EMI', style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                  Text(topLoan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(
                    '${IndianNumberFormat.formatCompact(topLoan.emiAmount * 12, symbol: topLoan.currencySymbol)}/year',
                    style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                ])),
              ])),
            ],
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _statChip(String l, String v, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(v, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]),
    ),
  );

  Widget _card(Widget c) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow),
    child: c,
  );
}


