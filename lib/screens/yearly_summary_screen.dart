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

  @override
  Widget build(BuildContext context) {
    final loans = widget.loans;
    final totalEMI = loans.fold(0.0, (s, l) => s + l.emiAmount);
    final totalPaidYear = totalEMI * 12;
    final totalInterestYear = loans.fold(0.0, (s, l) {
      if (l.loanAmount != null && l.interestRate != null && l.tenureMonths != null) {
        final emi = l.emiAmount;
        final interestFrac = l.interestRate! > 0
            ? (l.interestRate! / 12 / 100) * (l.loanAmount ?? 0) / emi
            : 0.0;
        return s + (emi * 12 * interestFrac.clamp(0.0, 1.0));
      }
      return s;
    });
    final totalPrincipalYear = (totalPaidYear - totalInterestYear).clamp(0.0, double.infinity);
    final topLoan = loans.isEmpty ? null : loans.reduce((a, b) => a.emiAmount > b.emiAmount ? a : b);

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
                final tempFile = XFile.fromData(image, mimeType: 'image/png', name: 'emi_summary_$_selectedYear.png');
                await Share.shareXFiles([tempFile], text: 'My EMI Summary $_selectedYear — EMI Reminder App');
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
              Text('$_selectedYear', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              IconButton(
                icon: const Icon(Icons.chevron_right_rounded),
                onPressed: _selectedYear < DateTime.now().year ? () => setState(() => _selectedYear++) : null,
              ),
            ]),

            // Hero card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                Text('Total EMI Paid in $_selectedYear', style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 4),
                Text(IndianNumberFormat.formatCompact(totalPaidYear), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  _statChip('Principal', IndianNumberFormat.formatCompact(totalPrincipalYear), AppTheme.statusSuccess),
                  const SizedBox(width: 8),
                  _statChip('Interest', IndianNumberFormat.formatCompact(totalInterestYear), AppTheme.accentOrange),
                  const SizedBox(width: 8),
                  _statChip('Loans', '${loans.length}', Colors.white),
                ]),
              ]),
            ),
            const SizedBox(height: 20),

            // Month-wise chart
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Monthly EMI Outflow', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 16),
              SizedBox(
                height: 100,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(12, (i) {
                    final month = i + 1;
                    final isCurrentMonth = _selectedYear == DateTime.now().year && month == DateTime.now().month;
                    final isFuture = _selectedYear == DateTime.now().year && month > DateTime.now().month;
                    final barH = isFuture ? 20.0 : 80.0;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                          Container(
                            height: barH,
                            decoration: BoxDecoration(
                              color: isCurrentMonth
                                  ? AppTheme.primaryColor
                                  : isFuture
                                      ? AppTheme.textLight.withValues(alpha: 0.3)
                                      : AppTheme.primaryColor.withValues(alpha: 0.5),
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
              const Text('Loan-wise Annual Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              ...loans.map((l) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(l.loanTypeName ?? 'Other', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                  ])),
                  Text(IndianNumberFormat.formatCompact(l.emiAmount * 12, symbol: l.currencySymbol),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                ]),
              )),
            ])),
            const SizedBox(height: 16),

            if (topLoan != null)
              _card(Row(children: [
                const Icon(Icons.emoji_events_rounded, color: AppTheme.accentOrange, size: 32),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Largest EMI', style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                  Text(topLoan.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(IndianNumberFormat.formatCompact(topLoan.emiAmount * 12, symbol: topLoan.currencySymbol) + '/year',
                      style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                ])),
              ])),
            const SizedBox(height: 40),
          ]),
        ),
      ),
    );
  }

  Widget _statChip(String l, String v, Color c) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(v, style: TextStyle(color: c, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(l, style: const TextStyle(color: Colors.white70, fontSize: 10)),
      ]),
    ),
  );

  Widget _card(Widget c) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
    child: c,
  );
}


