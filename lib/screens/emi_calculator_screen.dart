import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/emi_calculator.dart';

class EMICalculatorScreen extends StatefulWidget {
  const EMICalculatorScreen({super.key});

  @override
  State<EMICalculatorScreen> createState() => _EMICalculatorScreenState();
}

class _EMICalculatorScreenState extends State<EMICalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _principalController = TextEditingController();
  final _rateController = TextEditingController();
  final _tenureController = TextEditingController();

  double? _emi;
  double? _totalInterest;
  double? _totalAmount;
  bool _showResults = false;

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    super.dispose();
  }

  void _calculateEMI() {
    if (_formKey.currentState!.validate()) {
      final principal = double.parse(_principalController.text.replaceAll(',', ''));
      final rate = double.parse(_rateController.text);
      final tenure = int.parse(_tenureController.text);

      setState(() {
        _emi = EMICalculator.calculateEMI(
          principal: principal,
          annualRate: rate,
          tenureMonths: tenure,
        );
        _totalInterest = EMICalculator.calculateTotalInterest(
          principal: principal,
          annualRate: rate,
          tenureMonths: tenure,
        );
        _totalAmount = EMICalculator.calculateTotalAmount(
          principal: principal,
          annualRate: rate,
          tenureMonths: tenure,
        );
        _showResults = true;
      });
    }
  }

  void _reset() {
    setState(() {
      _principalController.clear();
      _rateController.clear();
      _tenureController.clear();
      _emi = null;
      _totalInterest = null;
      _totalAmount = null;
      _showResults = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('EMI Calculator'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _reset,
            tooltip: 'Reset',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.calculate_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Calculate your loan EMI',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            // Input Form
            Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text(
                          'Enter Loan Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Principal Amount
                        TextFormField(
                          controller: _principalController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Loan Amount',
                            hintText: 'e.g., 500000',
                            prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter loan amount';
                            }
                            final parsed = double.tryParse(value.replaceAll(',', ''));
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid amount';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Interest Rate
                        TextFormField(
                          controller: _rateController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
                          ],
                          decoration: InputDecoration(
                            labelText: 'Interest Rate (% per annum)',
                            hintText: 'e.g., 8.5',
                            prefixIcon: Icon(Icons.percent, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter interest rate';
                            }
                            final parsed = double.tryParse(value);
                            if (parsed == null || parsed < 0 || parsed > 50) {
                              return 'Enter a valid rate (0-50%)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Tenure
                        TextFormField(
                          controller: _tenureController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            labelText: 'Loan Tenure (months)',
                            hintText: 'e.g., 60',
                            prefixIcon: Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter tenure';
                            }
                            final parsed = int.tryParse(value);
                            if (parsed == null || parsed <= 0 || parsed > 360) {
                              return 'Enter valid tenure (1-360 months)';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Calculate Button
                        ElevatedButton(
                          onPressed: _calculateEMI,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calculate),
                              SizedBox(width: 8),
                              Text(
                                'Calculate EMI',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Results
            if (_showResults && _emi != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryColor.withValues(alpha: 0.05),
                          AppTheme.secondaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Your EMI',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '₹${_formatNumber(_emi!)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        Text(
                          'per month',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Breakdown
                        _buildResultRow(
                          'Principal Amount',
                          '₹${_formatNumber(double.parse(_principalController.text.replaceAll(',', '')))}',
                          Icons.account_balance,
                          AppTheme.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        _buildResultRow(
                          'Total Interest',
                          '₹${_formatNumber(_totalInterest!)}',
                          Icons.trending_up,
                          AppTheme.statusWarning,
                        ),
                        const SizedBox(height: 12),
                        _buildResultRow(
                          'Total Amount',
                          '₹${_formatNumber(_totalAmount!)}',
                          Icons.payments,
                          AppTheme.statusSuccess,
                        ),

                        const SizedBox(height: 24),

                        // Visual Breakdown
                        _buildVisualBreakdown(),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.textMedium,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildVisualBreakdown() {
    final principal = double.parse(_principalController.text.replaceAll(',', ''));
    final interest = _totalInterest ?? 0;
    final total = principal + interest;

    final principalPercent = (principal / total * 100).round();
    final interestPercent = 100 - principalPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Row(
            children: [
              Expanded(
                flex: principalPercent,
                child: Container(
                  height: 24,
                  color: AppTheme.primaryColor,
                  alignment: Alignment.center,
                  child: principalPercent > 15
                      ? Text(
                          '$principalPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
              ),
              Expanded(
                flex: interestPercent,
                child: Container(
                  height: 24,
                  color: AppTheme.statusWarning,
                  alignment: Alignment.center,
                  child: interestPercent > 15
                      ? Text(
                          '$interestPercent%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Principal',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.statusWarning,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Interest',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 10000000) {
      return '${(number / 10000000).toStringAsFixed(2)} Cr';
    } else if (number >= 100000) {
      return '${(number / 100000).toStringAsFixed(2)} L';
    } else {
      return number.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    }
  }
}
