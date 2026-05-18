import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class AmortizationScreen extends StatefulWidget {
  final Loan loan;

  const AmortizationScreen({super.key, required this.loan});

  @override
  State<AmortizationScreen> createState() => _AmortizationScreenState();
}

class _AmortizationScreenState extends State<AmortizationScreen> {
  List<_AmortizationRow> _schedule = [];
  bool _showFullTable = false;

  @override
  void initState() {
    super.initState();
    _generateSchedule();
  }

  void _generateSchedule() {
    final loan = widget.loan;
    if (loan.loanAmount == null || loan.interestRate == null || loan.tenureMonths == null) {
      return;
    }

    double balance = loan.loanAmount!;
    final monthlyRate = loan.interestRate! / 12 / 100;
    final tenure = loan.tenureMonths!;
    final emi = _calculateEMI(balance, monthlyRate, tenure);

    DateTime date = loan.startDate;
    _schedule.clear();

    for (int i = 1; i <= tenure; i++) {
      final interest = balance * monthlyRate;
      final principal = emi - interest;
      balance = math.max(0, balance - principal);

      _schedule.add(_AmortizationRow(
        month: i,
        date: date,
        emi: emi,
        principal: principal,
        interest: interest,
        balance: balance,
        isPaid: i <= loan.emisPaidCount,
      ));

      // Move to next month
      int nextMonth = date.month + 1;
      int nextYear = date.year;
      if (nextMonth > 12) {
        nextMonth = 1;
        nextYear++;
      }
      date = DateTime(nextYear, nextMonth, date.day);
    }
  }

  double _calculateEMI(double principal, double monthlyRate, int tenure) {
    if (monthlyRate == 0) return principal / tenure;
    final factor = math.pow(1 + monthlyRate, tenure).toDouble();
    return principal * monthlyRate * factor / (factor - 1);
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final symbol = loan.currencySymbol;
    final hasData = loan.loanAmount != null && loan.interestRate != null && loan.tenureMonths != null;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Amortization Schedule'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: hasData ? _buildContent(symbol) : _buildNoDataView(),
    );
  }

  Widget _buildNoDataView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.table_chart_outlined, size: 64, color: AppTheme.textLight),
            const SizedBox(height: 16),
            const Text(
              'No Amortization Data',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
            const SizedBox(height: 8),
            Text(
              'Please add Loan Amount, Interest Rate, and Tenure to view the amortization schedule.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String symbol) {
    if (_schedule.isEmpty) return _buildNoDataView();

    final totalInterest = _schedule.fold(0.0, (s, r) => s + r.interest);
    final totalPrincipal = widget.loan.loanAmount ?? 0;
    final totalAmount = totalPrincipal + totalInterest;
    final paidRows = _schedule.where((r) => r.isPaid).toList();
    final paidPrincipal = paidRows.fold(0.0, (s, r) => s + r.principal);
    final paidInterest = paidRows.fold(0.0, (s, r) => s + r.interest);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Summary Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppTheme.primaryGradient,
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.loan.name,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  IndianNumberFormat.formatCompact(totalAmount, symbol: symbol),
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                ),
                Text(
                  'Total Payment (Principal + Interest)',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _summaryChip(
                      label: 'Principal',
                      value: IndianNumberFormat.formatCompact(totalPrincipal, symbol: symbol),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    _summaryChip(
                      label: 'Total Interest',
                      value: IndianNumberFormat.formatCompact(totalInterest, symbol: symbol),
                      color: AppTheme.accentOrange,
                    ),
                    const SizedBox(width: 12),
                    _summaryChip(
                      label: 'EMI',
                      value: IndianNumberFormat.formatCompact(_schedule.first.emi, symbol: symbol),
                      color: Colors.greenAccent,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Progress Summary
          if (widget.loan.emisPaidCount > 0)
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Progress',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: widget.loan.emisPaidCount / (widget.loan.tenureMonths ?? 1),
                    backgroundColor: AppTheme.bgLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.statusSuccess),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${widget.loan.emisPaidCount} EMIs paid',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                      Text('${(widget.loan.tenureMonths ?? 0) - widget.loan.emisPaidCount} remaining',
                          style: const TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _progressStat('Principal Paid',
                            IndianNumberFormat.formatCompact(paidPrincipal, symbol: symbol),
                            AppTheme.statusSuccess),
                      ),
                      Expanded(
                        child: _progressStat('Interest Paid',
                            IndianNumberFormat.formatCompact(paidInterest, symbol: symbol),
                            AppTheme.accentOrange),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Table Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Monthly Breakdown',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                TextButton(
                  onPressed: () => setState(() => _showFullTable = !_showFullTable),
                  child: Text(_showFullTable ? 'Show Summary' : 'Show All'),
                ),
              ],
            ),
          ),

          // Table
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              children: [
                // Table header row
                _buildTableHeader(),
                const Divider(height: 1),
                // Table rows
                ..._getDisplayedRows(symbol),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  List<Widget> _getDisplayedRows(String symbol) {
    final rows = _showFullTable ? _schedule : _schedule.take(12).toList();
    final widgets = rows.map((row) => _buildTableRow(row, symbol)).toList();
    if (!_showFullTable && _schedule.length > 12) {
      widgets.add(
        InkWell(
          onTap: () => setState(() => _showFullTable = true),
          child: Container(
            padding: const EdgeInsets.all(16),
            alignment: Alignment.center,
            child: Text(
              'View all ${_schedule.length} months →',
              style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    }
    return widgets;
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 32, child: Text('#', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const Expanded(child: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          const Expanded(child: Text('Principal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
          const Expanded(child: Text('Interest', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
          const Expanded(child: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _buildTableRow(_AmortizationRow row, String symbol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: row.isPaid
            ? AppTheme.statusSuccess.withValues(alpha: 0.05)
            : null,
        border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: Row(
              children: [
                if (row.isPaid)
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.statusSuccess)
                else
                  Text('${row.month}',
                      style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              ],
            ),
          ),
          Expanded(
            child: Text(
              DateFormat('MMM yy').format(row.date),
              style: TextStyle(
                fontSize: 12,
                color: row.isPaid ? AppTheme.statusSuccess : AppTheme.textDark,
                fontWeight: row.isPaid ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          Expanded(
            child: Text(
              IndianNumberFormat.formatCompact(row.principal, symbol: symbol),
              style: const TextStyle(fontSize: 11, color: AppTheme.statusSuccess),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              IndianNumberFormat.formatCompact(row.interest, symbol: symbol),
              style: const TextStyle(fontSize: 11, color: AppTheme.accentOrange),
              textAlign: TextAlign.right,
            ),
          ),
          Expanded(
            child: Text(
              IndianNumberFormat.formatCompact(row.balance, symbol: symbol),
              style: const TextStyle(fontSize: 11, color: AppTheme.textDark, fontWeight: FontWeight.w500),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryChip({required String label, required String value, required Color color}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _progressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
      ],
    );
  }
}

class _AmortizationRow {
  final int month;
  final DateTime date;
  final double emi;
  final double principal;
  final double interest;
  final double balance;
  final bool isPaid;

  _AmortizationRow({
    required this.month,
    required this.date,
    required this.emi,
    required this.principal,
    required this.interest,
    required this.balance,
    required this.isPaid,
  });
}

