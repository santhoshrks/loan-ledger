import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class PrepaymentCalculatorScreen extends StatefulWidget {
  final Loan? loan;

  const PrepaymentCalculatorScreen({super.key, this.loan});

  @override
  State<PrepaymentCalculatorScreen> createState() => _PrepaymentCalculatorScreenState();
}

class _PrepaymentCalculatorScreenState extends State<PrepaymentCalculatorScreen> {
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();
  final _emisPaidController = TextEditingController(text: '0');
  final _prepaymentController = TextEditingController();

  _PrepaymentResult? _result;
  bool _reduceEMI = false; // false = reduce tenure, true = reduce EMI

  @override
  void initState() {
    super.initState();
    if (widget.loan != null) {
      final l = widget.loan!;
      _principalController.text = l.loanAmount?.toStringAsFixed(0) ?? '';
      _rateController.text = l.interestRate?.toString() ?? '';
      _tenureController.text = l.tenureMonths?.toString() ?? '';
      _emisPaidController.text = l.emisPaidCount.toString();
    }
  }

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    _emisPaidController.dispose();
    _prepaymentController.dispose();
    super.dispose();
  }

  void _calculate() {
    final principal = double.tryParse(_principalController.text);
    final rate = double.tryParse(_rateController.text);
    final tenure = int.tryParse(_tenureController.text);
    final emisPaid = int.tryParse(_emisPaidController.text) ?? 0;
    final prepayment = double.tryParse(_prepaymentController.text);

    if (principal == null || rate == null || tenure == null || prepayment == null) return;

    final monthlyRate = rate / 12 / 100;
    final originalEMI = _calcEMI(principal, monthlyRate, tenure);

    // Current outstanding balance after emisPaid
    double balance = principal;
    for (int i = 0; i < emisPaid; i++) {
      final interest = balance * monthlyRate;
      final principalPaid = originalEMI - interest;
      balance = math.max(0, balance - principalPaid);
    }

    final outstandingBefore = balance;
    final outstandingAfter = math.max(0.0, balance - prepayment);
    final remainingTenure = tenure - emisPaid;

    double newEMI = originalEMI;
    int newTenure = remainingTenure;
    double interestSaved = 0;
    int monthsSaved = 0;

    if (outstandingAfter <= 0) {
      // Fully paid off
      interestSaved = originalEMI * remainingTenure - outstandingBefore;
      monthsSaved = remainingTenure;
      newTenure = 0;
      newEMI = 0;
    } else if (_reduceEMI) {
      // Same tenure, reduce EMI
      newEMI = _calcEMI(outstandingAfter, monthlyRate, remainingTenure);
      final interestWithoutPrepay = originalEMI * remainingTenure - outstandingBefore;
      final interestWithPrepay = newEMI * remainingTenure - outstandingAfter;
      interestSaved = math.max(0, interestWithoutPrepay - interestWithPrepay);
      monthsSaved = 0;
    } else {
      // Same EMI, reduce tenure
      newTenure = _calcTenure(outstandingAfter, monthlyRate, originalEMI);
      monthsSaved = remainingTenure - newTenure;
      interestSaved = originalEMI * monthsSaved;
      newEMI = originalEMI;
    }

    setState(() {
      _result = _PrepaymentResult(
        originalEMI: originalEMI,
        newEMI: newEMI,
        outstandingBefore: outstandingBefore,
        outstandingAfter: outstandingAfter,
        remainingTenure: remainingTenure,
        newTenure: newTenure,
        monthsSaved: monthsSaved,
        interestSaved: interestSaved,
        reduceEMI: _reduceEMI,
      );
    });
  }

  double _calcEMI(double p, double r, int n) {
    if (r == 0) return p / n;
    final factor = math.pow(1 + r, n).toDouble();
    return p * r * factor / (factor - 1);
  }

  int _calcTenure(double p, double r, double emi) {
    if (r == 0) return (p / emi).ceil();
    if (emi <= p * r) return 9999; // will never pay off
    final n = math.log(emi / (emi - p * r)) / math.log(1 + r);
    return n.ceil();
  }

  String get _symbol => widget.loan?.currencySymbol ?? '\$';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Prepayment Calculator'),
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
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_rounded, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'See how much interest you save by paying extra towards your loan today.',
                      style: TextStyle(fontSize: 13, color: AppTheme.textDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Input fields
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Loan Details'),
                  const SizedBox(height: 12),
                  _inputField(_principalController, 'Original Loan Amount', Icons.account_balance_wallet_rounded),
                  const SizedBox(height: 12),
                  _inputField(_rateController, 'Interest Rate (% per annum)', Icons.percent_rounded, decimal: true),
                  const SizedBox(height: 12),
                  _inputField(_tenureController, 'Original Tenure (months)', Icons.schedule_rounded),
                  const SizedBox(height: 12),
                  _inputField(_emisPaidController, 'EMIs Already Paid', Icons.check_circle_outline_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _label('Prepayment'),
                  const SizedBox(height: 12),
                  _inputField(_prepaymentController, 'Prepayment Amount ($_symbol)', Icons.payments_rounded),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _reduceEMI = false),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: !_reduceEMI ? AppTheme.primaryColor : AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primaryColor),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.timer_rounded,
                                    color: !_reduceEMI ? Colors.white : AppTheme.primaryColor, size: 20),
                                const SizedBox(height: 4),
                                Text('Reduce Tenure',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: !_reduceEMI ? Colors.white : AppTheme.primaryColor)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _reduceEMI = true),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _reduceEMI ? AppTheme.primaryColor : AppTheme.bgLight,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primaryColor),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.trending_down_rounded,
                                    color: _reduceEMI ? Colors.white : AppTheme.primaryColor, size: 20),
                                const SizedBox(height: 4),
                                Text('Reduce EMI',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _reduceEMI ? Colors.white : AppTheme.primaryColor)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calculate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _calculate,
                icon: const Icon(Icons.calculate_rounded),
                label: const Text('Calculate Savings',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
              ),
            ),

            // Results
            if (_result != null) ...[
              const SizedBox(height: 24),
              _buildResults(_result!),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(_PrepaymentResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Savings Summary',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 12),

        // Interest saved — highlight card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF22C55E), Color(0xFF4ADE80)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.savings_rounded, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(
                IndianNumberFormat.formatCompact(r.interestSaved, symbol: _symbol),
                style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const Text('Interest Saved', style: TextStyle(color: Colors.white70, fontSize: 14)),
              if (r.monthsSaved > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${r.monthsSaved} months saved (${(r.monthsSaved / 12).toStringAsFixed(1)} years)',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Comparison table
        _buildCard(
          child: Column(
            children: [
              _comparisonRow('Outstanding Balance',
                  IndianNumberFormat.formatCompact(r.outstandingBefore, symbol: _symbol),
                  IndianNumberFormat.formatCompact(r.outstandingAfter, symbol: _symbol)),
              const Divider(),
              if (!r.reduceEMI)
                _comparisonRow('Remaining Tenure',
                    '${r.remainingTenure} months',
                    r.newTenure == 0 ? 'Loan Closed! 🎉' : '${r.newTenure} months'),
              if (r.reduceEMI)
                _comparisonRow('Monthly EMI',
                    IndianNumberFormat.formatCompact(r.originalEMI, symbol: _symbol),
                    IndianNumberFormat.formatCompact(r.newEMI, symbol: _symbol)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _comparisonRow(String label, String before, String after) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textMedium, fontSize: 13))),
          Text(before, style: const TextStyle(color: AppTheme.textDark, fontSize: 13)),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primaryColor),
          ),
          Text(after,
              style: const TextStyle(color: AppTheme.statusSuccess, fontSize: 13, fontWeight: FontWeight.bold)),
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

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark));
  }

  Widget _inputField(TextEditingController controller, String label, IconData icon,
      {bool decimal = false}) {
    return TextField(
      controller: controller,
      keyboardType: decimal
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number,
      inputFormatters: decimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor),
        filled: true,
        fillColor: AppTheme.bgLight,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

class _PrepaymentResult {
  final double originalEMI;
  final double newEMI;
  final double outstandingBefore;
  final double outstandingAfter;
  final int remainingTenure;
  final int newTenure;
  final int monthsSaved;
  final double interestSaved;
  final bool reduceEMI;

  _PrepaymentResult({
    required this.originalEMI,
    required this.newEMI,
    required this.outstandingBefore,
    required this.outstandingAfter,
    required this.remainingTenure,
    required this.newTenure,
    required this.monthsSaved,
    required this.interestSaved,
    required this.reduceEMI,
  });
}

