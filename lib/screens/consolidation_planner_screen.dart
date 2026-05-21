import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class ConsolidationPlannerScreen extends StatefulWidget {
  final List<Loan> loans;
  const ConsolidationPlannerScreen({super.key, required this.loans});
  @override
  State<ConsolidationPlannerScreen> createState() => _ConsolidationPlannerScreenState();
}

class _ConsolidationPlannerScreenState extends State<ConsolidationPlannerScreen> {
  final _extraCtrl = TextEditingController(text: '0');
  String _method = 'avalanche';
  List<_PayoffPlan> _avalanchePlan = [];
  List<_PayoffPlan> _snowballPlan = [];
  bool _calculated = false;

  double _calcEMI(double p, double r, int n) {
    if (r == 0) return p / n;
    final f = math.pow(1 + r, n).toDouble();
    return p * r * f / (f - 1);
  }

  void _calculate() {
    final extra = double.tryParse(_extraCtrl.text) ?? 0;
    final loans = widget.loans;
    if (loans.isEmpty) return;

    _avalanchePlan = _buildPlan(loans, extra, avalanche: true);
    _snowballPlan  = _buildPlan(loans, extra, avalanche: false);
    setState(() => _calculated = true);
  }

  List<_PayoffPlan> _buildPlan(List<Loan> loans, double extra, {required bool avalanche}) {
    final now = DateTime.now();

    // Build items — works with full data (loanAmount+rate+tenure) OR simplified (emi+tenure)
    var items = loans.map((l) {
      final hasFullData = l.loanAmount != null && l.interestRate != null && l.tenureMonths != null;

      if (hasFullData) {
        final r = l.interestRate! / 12 / 100;
        final n = l.tenureMonths!;
        final emi = _calcEMI(l.loanAmount!, r, n);
        // Recompute current outstanding balance
        final monthsElapsed = ((now.year - l.startDate.year) * 12 +
            (now.month - l.startDate.month)).clamp(0, n);
        double bal = l.loanAmount!;
        for (int i = 0; i < monthsElapsed; i++) {
          final interest = bal * r;
          bal = math.max(0, bal - (emi - interest));
        }
        return _LoanItem(loan: l, balance: bal, rate: l.interestRate!, emi: emi, hasFullData: true);
      } else {
        // Simplified: use EMI × remaining months as proxy balance
        final remaining = math.max(0, (l.tenureMonths ?? 0) - l.emisPaidCount);
        final proxyBalance = l.emiAmount * remaining;
        return _LoanItem(loan: l, balance: proxyBalance, rate: 0, emi: l.emiAmount, hasFullData: false);
      }
    }).toList();

    // Sort strategy
    if (avalanche) {
      // Highest rate first; for zero-rate (simplified) loans, sort by balance desc
      items.sort((a, b) {
        if (a.rate != b.rate) return b.rate.compareTo(a.rate);
        return b.balance.compareTo(a.balance);
      });
    } else {
      // Smallest balance first
      items.sort((a, b) => a.balance.compareTo(b.balance));
    }

    final plans = <_PayoffPlan>[];
    double availableExtra = extra;
    int order = 1;

    for (final item in items) {
      double balance = item.balance;
      final r = item.rate / 12 / 100;
      final monthlyPayment = item.emi + availableExtra;
      int months = 0;
      double totalInterest = 0;

      if (item.hasFullData && r > 0) {
        // Standard amortization payoff simulation
        while (balance > 0.01 && months < 600) {
          final interest = balance * r;
          totalInterest += interest;
          balance = math.max(0, balance - (monthlyPayment - interest));
          months++;
        }
      } else {
        // Simplified: months = balance / monthlyPayment
        months = monthlyPayment > 0
            ? (balance / monthlyPayment).ceil().clamp(0, 600)
            : (l: item.loan.tenureMonths ?? 0, s: 0).l;
        totalInterest = 0; // unknown
      }

      int rawMonth = now.month + months - 1;
      final debtFreeDate = DateTime(
        now.year + rawMonth ~/ 12,
        rawMonth % 12 + 1,
      );
      plans.add(_PayoffPlan(
        loan: item.loan,
        order: order++,
        months: months,
        totalInterest: totalInterest,
        debtFreeDate: debtFreeDate,
        balance: item.balance,
        hasFullData: item.hasFullData,
      ));
      availableExtra += item.emi; // freed EMI rolls to next loan
    }
    return plans;
  }

  List<_PayoffPlan> get _activePlan => _method == 'avalanche' ? _avalanchePlan : _snowballPlan;

  @override
  Widget build(BuildContext context) {
    final hasAnyLoan = widget.loans.isNotEmpty;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Debt Payoff Planner'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (!hasAnyLoan)
            _infoBanner('⚠️ Add at least one loan to use the Debt Payoff Planner.')
          else ...[
            // Strategy selector
            _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Choose Strategy',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              Row(children: [
                _methodBtn('avalanche', '🏔️ Avalanche', 'Highest interest first\n(Saves most money)'),
                const SizedBox(width: 12),
                _methodBtn('snowball', '⛄ Snowball', 'Smallest balance first\n(Quick wins, motivation)'),
              ]),
              const SizedBox(height: 12),
              TextField(
                controller: _extraCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Extra Monthly Payment (optional)',
                  helperText: 'Amount you can add on top of regular EMIs',
                  prefixIcon: const Icon(Icons.add_circle_rounded, color: AppTheme.primaryColor),
                  filled: true, fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ])),
            const SizedBox(height: 16),

            // Loans that lack full data — info
            if (widget.loans.any((l) => l.loanAmount == null || l.interestRate == null))
              _infoBanner('ℹ️ Some loans are missing Loan Amount or Interest Rate. '
                  'Payoff dates are estimated from EMI × remaining tenure. '
                  'Edit loans to add full details for exact interest savings.'),

            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Generate Payoff Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            if (_calculated) ...[
              const SizedBox(height: 24),
              _buildComparisonBanner(),
              const SizedBox(height: 16),
              ..._activePlan.map(_buildPlanCard),
            ],
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildComparisonBanner() {
    if (_avalanchePlan.isEmpty || _snowballPlan.isEmpty) return const SizedBox.shrink();
    final avInterest = _avalanchePlan.fold(0.0, (s, p) => s + p.totalInterest);
    final snowInterest = _snowballPlan.fold(0.0, (s, p) => s + p.totalInterest);
    final avMonths = _avalanchePlan.map((p) => p.months).reduce(math.max);
    final snowMonths = _snowballPlan.map((p) => p.months).reduce(math.max);
    final hasInterestData = avInterest > 0 || snowInterest > 0;
    final saved = (snowInterest - avInterest).abs();

    return _card(Column(children: [
      const Text('Strategy Comparison',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
      const SizedBox(height: 12),
      Row(children: [
        _compStat('🏔️ Avalanche', '${avMonths}m',
            hasInterestData ? IndianNumberFormat.formatCompact(avInterest) : 'N/A',
            _method == 'avalanche'),
        const SizedBox(width: 12),
        _compStat('⛄ Snowball', '${snowMonths}m',
            hasInterestData ? IndianNumberFormat.formatCompact(snowInterest) : 'N/A',
            _method == 'snowball'),
      ]),
      const SizedBox(height: 8),
      Text(
        hasInterestData
            ? (avInterest < snowInterest
                ? '💡 Avalanche saves ${IndianNumberFormat.formatCompact(saved)} more in interest'
                : '💡 Both strategies are similar in this case')
            : '💡 Add Loan Amount & Interest Rate for interest savings comparison.',
        style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
        textAlign: TextAlign.center,
      ),
    ]));
  }

  Widget _compStat(String name, String months, String interest, bool active) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? AppTheme.primaryColor : Colors.transparent),
      ),
      child: Column(children: [
        Text(name, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
            color: active ? AppTheme.primaryColor : AppTheme.textMedium)),
        Text(months, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        Text(interest, style: const TextStyle(fontSize: 11, color: AppTheme.accentOrange)),
        const Text('interest', style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
      ]),
    ),
  );

  Widget _buildPlanCard(_PayoffPlan p) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppTheme.bgCard,
      borderRadius: BorderRadius.circular(14),
      boxShadow: AppTheme.softShadow,
      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
    ),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
        child: Center(child: Text('${p.order}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      ),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(p.loan.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
        Text(
          p.hasFullData
              ? 'Balance: ${IndianNumberFormat.formatCompact(p.balance)} • ${p.loan.interestRate?.toStringAsFixed(1)}% p.a.'
              : 'Balance: ${IndianNumberFormat.formatCompact(p.balance)} (estimated)',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
        ),
        Text(
          p.hasFullData
              ? 'Interest: ${IndianNumberFormat.formatCompact(p.totalInterest)}'
              : 'Interest: N/A (add rate for details)',
          style: TextStyle(
              fontSize: 11,
              color: p.hasFullData ? AppTheme.accentOrange : AppTheme.textLight),
        ),
      ])),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text('${p.months}m',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
        Text(DateFormat('MMM yyyy').format(p.debtFreeDate),
            style: const TextStyle(fontSize: 11, color: AppTheme.statusSuccess, fontWeight: FontWeight.w600)),
        const Text('Debt Free', style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
      ]),
    ]),
  );

  Widget _methodBtn(String val, String title, String sub) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _method = val),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _method == val ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _method == val ? AppTheme.primaryColor : AppTheme.textLight),
        ),
        child: Column(children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13,
              color: _method == val ? AppTheme.primaryColor : AppTheme.textDark)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 10, color: AppTheme.textMedium), textAlign: TextAlign.center),
        ]),
      ),
    ),
  );

  Widget _infoBanner(String msg) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
        color: AppTheme.statusWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      const Icon(Icons.warning_rounded, color: AppTheme.statusWarning, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
    ]),
  );

  Widget _card(Widget c) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow),
    child: c,
  );
}

class _LoanItem {
  final Loan loan;
  final double balance, rate, emi;
  final bool hasFullData;
  _LoanItem({required this.loan, required this.balance, required this.rate,
      required this.emi, required this.hasFullData});
}

class _PayoffPlan {
  final Loan loan;
  final int order, months;
  final double totalInterest, balance;
  final DateTime debtFreeDate;
  final bool hasFullData;
  _PayoffPlan({required this.loan, required this.order, required this.months,
      required this.totalInterest, required this.debtFreeDate,
      required this.balance, required this.hasFullData});
}
