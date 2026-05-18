import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../services/loan_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class FloatingRateScreen extends StatefulWidget {
  final Loan loan;
  final LoanStorageService storageService;

  const FloatingRateScreen({
    super.key,
    required this.loan,
    required this.storageService,
  });

  @override
  State<FloatingRateScreen> createState() => _FloatingRateScreenState();
}

class _FloatingRateScreenState extends State<FloatingRateScreen> {
  final _rateController = TextEditingController();
  late List<_RateEntry> _history;

  @override
  void initState() {
    super.initState();
    _history = _loadHistory();
  }

  List<_RateEntry> _loadHistory() {
    final rates = widget.loan.rateHistory ?? [];
    final dates = widget.loan.rateHistoryDates ?? [];
    List<_RateEntry> entries = [];
    for (int i = 0; i < rates.length && i < dates.length; i++) {
      entries.add(_RateEntry(rate: rates[i], date: DateTime.parse(dates[i])));
    }
    // If no history but has interest rate, seed it
    if (entries.isEmpty && widget.loan.interestRate != null) {
      entries.add(_RateEntry(rate: widget.loan.interestRate!, date: widget.loan.startDate));
    }
    return entries;
  }

  Future<void> _addRate() async {
    final rate = double.tryParse(_rateController.text);
    if (rate == null || rate <= 0 || rate > 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid interest rate (0-50%)')),
      );
      return;
    }

    setState(() {
      _history.add(_RateEntry(rate: rate, date: DateTime.now()));
      _history.sort((a, b) => a.date.compareTo(b.date));
    });

    // Persist to loan
    widget.loan.rateHistory = _history.map((e) => e.rate).toList();
    widget.loan.rateHistoryDates = _history.map((e) => e.date.toIso8601String()).toList();
    // Update current interest rate to latest
    widget.loan.interestRate = _history.last.rate;
    await widget.storageService.updateLoan(widget.loan.id, widget.loan);

    _rateController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rate updated successfully!'),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
    }
  }

  double _calcEMI(double p, double r, int n) {
    if (r == 0) return p / n;
    final monthlyRate = r / 12 / 100;
    final factor = math.pow(1 + monthlyRate, n).toDouble();
    return p * monthlyRate * factor / (factor - 1);
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loan = widget.loan;
    final symbol = loan.currencySymbol;
    final currentRate = _history.isNotEmpty ? _history.last.rate : loan.interestRate;
    final remainingTenure = loan.getTenureRemaining();

    double? newEMI;
    double? oldEMI;
    if (loan.loanAmount != null && loan.tenureMonths != null && currentRate != null) {
      newEMI = _calcEMI(loan.loanAmount!, currentRate, remainingTenure > 0 ? remainingTenure : loan.tenureMonths!);
      oldEMI = loan.emiAmount;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Floating Rate Tracker'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accentBlue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accentBlue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_rounded, color: AppTheme.accentBlue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Track floating interest rate changes on your loan. '
                      'When the central bank or lender changes the rate, add the new rate to see your revised EMI.',
                      style: const TextStyle(fontSize: 12, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Current rate card
            if (currentRate != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Rate', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('${currentRate.toStringAsFixed(2)}% p.a.',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    if (newEMI != null && oldEMI != null) ...[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Revised EMI', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(
                            IndianNumberFormat.formatCompact(newEMI, symbol: symbol),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          if ((newEMI - oldEMI).abs() > 1)
                            Text(
                              newEMI > oldEMI
                                  ? '▲ +${IndianNumberFormat.formatCompact(newEMI - oldEMI, symbol: symbol)}'
                                  : '▼ ${IndianNumberFormat.formatCompact(newEMI - oldEMI, symbol: symbol)}',
                              style: TextStyle(
                                  color: newEMI > oldEMI ? Colors.orangeAccent : Colors.greenAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Add new rate
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add New Interest Rate',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const SizedBox(height: 4),
                  const Text('Enter new rate after central bank / lender announcement',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMedium)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))],
                          decoration: InputDecoration(
                            labelText: 'New Rate (% p.a.)',
                            prefixIcon: const Icon(Icons.percent_rounded, color: AppTheme.primaryColor),
                            filled: true,
                            fillColor: AppTheme.bgLight,
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _addRate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rate history
            if (_history.isNotEmpty) ...[
              const Text('Rate History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
              const SizedBox(height: 12),
              _buildCard(
                child: Column(
                  children: _history.reversed.toList().asMap().entries.map((e) {
                    final i = e.key;
                    final entry = e.value;
                    final isLatest = i == 0;
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: i < _history.length - 1
                              ? const BorderSide(color: Color(0xFFF1F5F9))
                              : BorderSide.none,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isLatest ? AppTheme.primaryColor : AppTheme.textLight,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              DateFormat('d MMM yyyy').format(entry.date),
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isLatest ? AppTheme.textDark : AppTheme.textMedium),
                            ),
                          ),
                          Text(
                            '${entry.rate.toStringAsFixed(2)}% p.a.',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isLatest ? AppTheme.primaryColor : AppTheme.textMedium),
                          ),
                          if (isLatest) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('Current',
                                  style: TextStyle(fontSize: 10, color: AppTheme.primaryColor)),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],

            // Common rate types info
            const SizedBox(height: 20),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('📊 Common Loan Rate Types',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _rateTypeRow('Variable Rate', 'Rate linked to central bank policy rate', 'Home loans, mortgage loans'),
                  _rateTypeRow('Fixed Rate', 'Rate stays the same throughout tenure', 'Car loans, personal loans'),
                  _rateTypeRow('Tracker Rate', 'Tracks official benchmark rate', 'Common in UK, EU, AU'),
                  _rateTypeRow('Hybrid Rate', 'Fixed for initial years, then variable', 'ARM mortgages (USA)'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _rateTypeRow(String type, String desc, String example) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(type, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textDark)),
                Text(example, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: child,
    );
  }
}

class _RateEntry {
  final double rate;
  final DateTime date;

  _RateEntry({required this.rate, required this.date});
}

