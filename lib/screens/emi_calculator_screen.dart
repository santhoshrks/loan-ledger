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

  // Additional controllers for Compound and SIP calculators
  final _yearsController = TextEditingController();
  final _compoundsPerYearController = TextEditingController(text: '12');
  final _monthlyInvestmentController = TextEditingController();
  final _sipMonthsController = TextEditingController();
  final _missedMonthsController = TextEditingController(); // comma-separated months
  final _missedCountController = TextEditingController(); // optional: number of missed months
  bool _sipContributionAtStart = false;

  double? _emi;
  double? _totalInterest;
  double? _totalAmount;
  double? _totalInvested;
  double? _principalAmount;
  double? _monthlyInvestment;
  bool _showResults = false;

  String _calcType = 'EMI'; // 'EMI', 'Compound', 'SIP'

  @override
  void dispose() {
    _principalController.dispose();
    _rateController.dispose();
    _tenureController.dispose();
    // Dispose additional controllers
    _yearsController.dispose();
    _compoundsPerYearController.dispose();
    _monthlyInvestmentController.dispose();
    _sipMonthsController.dispose();
    _missedMonthsController.dispose();
    _missedCountController.dispose();
    super.dispose();
  }

  void _calculateEMI() {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _showResults = false;
      if (_calcType == 'EMI') {
        final principal = double.parse(_principalController.text.replaceAll(',', ''));
        final rate = double.parse(_rateController.text);
        final tenure = int.parse(_tenureController.text);

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
        _totalInvested = principal;
        _principalAmount = principal;
      } else if (_calcType == 'Compound') {
        final principal = double.parse(_principalController.text.replaceAll(',', ''));
        final rate = double.parse(_rateController.text);
        final years = int.parse(_yearsController.text);
        final compounds = int.tryParse(_compoundsPerYearController.text) ?? 12;

        final fv = EMICalculator.calculateCompoundFutureValue(
          principal: principal,
          annualRate: rate,
          years: years,
          compoundingPerYear: compounds,
        );
        _emi = null;
        _totalInterest = fv - principal;
        _totalAmount = fv;
        _totalInvested = principal;
        _principalAmount = principal;
      } else if (_calcType == 'SIP') {
        final monthly = double.parse(_monthlyInvestmentController.text.replaceAll(',', ''));
        final rate = double.parse(_rateController.text);
        final months = int.parse(_sipMonthsController.text);
        // parse missed months
        List<int>? missed;
        final missedInput = _missedMonthsController.text.trim();
        if (missedInput.isNotEmpty) {
          // support comma-separated, ranges (e.g., 3-5), or a single number meaning count
          final parts = missedInput.split(',');
          final tmp = <int>{};
          for (var p in parts) {
            p = p.trim();
            if (p.contains('-')) {
              final range = p.split('-').map((s) => int.tryParse(s.trim())).toList();
              if (range.length == 2 && range[0] != null && range[1] != null) {
                final a = range[0]!, b = range[1]!;
                if (a <= b) {
                  for (var i = a; i <= b; i++) {
                    if (i >= 1 && i <= months) tmp.add(i);
                  }
                } else {
                  for (var i = b; i <= a; i++) {
                    if (i >= 1 && i <= months) tmp.add(i);
                  }
                }
              }
            } else {
              final v = int.tryParse(p);
              if (v != null) {
                tmp.add(v);
              }
            }
          }

          if (tmp.isNotEmpty) {
            // If user supplied a single number only (no commas/ranges) and it looks like a count
            if (tmp.length == 1 && !missedInput.contains(',') && !missedInput.contains('-')) {
              final cnt = tmp.first;
              if (cnt > 0 && cnt <= months) {
                missed = List<int>.generate(cnt, (i) => months - cnt + 1 + i);
              }
            } else {
              // treat parsed numbers as explicit indices
              missed = tmp.toList()..sort();
            }
          }
        }
        // If no explicit indices provided but a missed count is given in the separate field, interpret as last N months missed
        if ((missed == null || missed.isEmpty) && _missedCountController.text.trim().isNotEmpty) {
          final cnt = int.tryParse(_missedCountController.text.trim()) ?? 0;
          if (cnt > 0) {
            missed = List<int>.generate(cnt, (i) => months - cnt + 1 + i);
          }
        }
        final result = EMICalculator.calculateSIP(
          monthlyInvestment: monthly,
          annualRate: rate,
          months: months,
          missedMonths: missed,
          contributionAtStart: _sipContributionAtStart,
        );
        _emi = null;
        _totalInterest = result['futureValue']! - result['totalInvested']!;
        _totalAmount = result['futureValue'];
        _totalInvested = result['totalInvested'];
        _monthlyInvestment = monthly;
      }

      _showResults = true;
    });
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
      // Reset additional controllers
      _yearsController.clear();
      _compoundsPerYearController.text = '12';
      _monthlyInvestmentController.clear();
      _sipMonthsController.clear();
      _missedMonthsController.clear();
      _missedCountController.clear();
      _sipContributionAtStart = false;
      _calcType = 'EMI';
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

                        // Calculator Type Selector
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ChoiceChip(
                              label: const Text('EMI'),
                              selected: _calcType == 'EMI',
                              onSelected: (v) => setState(() => _calcType = 'EMI'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('Compound'),
                              selected: _calcType == 'Compound',
                              onSelected: (v) => setState(() => _calcType = 'Compound'),
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('SIP'),
                              selected: _calcType == 'SIP',
                              onSelected: (v) => setState(() => _calcType = 'SIP'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Common: Interest Rate field remains used for all calculators
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

                        // Principal/Initial Amount or Monthly investment depending on calculator
                        if (_calcType != 'SIP')
                          TextFormField(
                            controller: _principalController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                            ],
                            decoration: InputDecoration(
                              labelText: _calcType == 'Compound' ? 'Initial Amount' : 'Loan Amount',
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
                                return 'Please enter amount';
                              }
                              final parsed = double.tryParse(value.replaceAll(',', ''));
                              if (parsed == null || parsed <= 0) {
                                return 'Enter a valid amount';
                              }
                              return null;
                            },
                          ),
                        if (_calcType == 'SIP')
                          TextFormField(
                            controller: _monthlyInvestmentController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(RegExp(r'[\d,]')),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Monthly Investment',
                              hintText: 'e.g., 5000',
                              prefixIcon: Icon(Icons.savings, color: AppTheme.primaryColor),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter monthly amount';
                              final p = double.tryParse(value.replaceAll(',', ''));
                              if (p == null || p <= 0) return 'Enter valid amount';
                              return null;
                            },
                          ),
                        const SizedBox(height: 16),

                        // Tenure or Years depending on calculator
                        if (_calcType == 'EMI')
                          TextFormField(
                            controller: _tenureController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                              if (value == null || value.isEmpty) return 'Please enter tenure';
                              final parsed = int.tryParse(value);
                              if (parsed == null || parsed <= 0 || parsed > 360) return 'Enter valid tenure (1-360 months)';
                              return null;
                            },
                          )
                        else if (_calcType == 'Compound')
                          Column(
                            children: [
                              TextFormField(
                                controller: _yearsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Years',
                                  hintText: 'e.g., 5',
                                  prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter years';
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed <= 0) return 'Enter valid years';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _compoundsPerYearController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Compounds per year',
                                  hintText: '12',
                                  prefixIcon: Icon(Icons.repeat, color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter compounding frequency';
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed <= 0) return 'Enter valid number';
                                  return null;
                                },
                              ),
                            ],
                          )
                        else if (_calcType == 'SIP')
                          Column(
                            children: [
                              TextFormField(
                                controller: _sipMonthsController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Months',
                                  hintText: 'e.g., 60',
                                  prefixIcon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Please enter months';
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed <= 0) return 'Enter valid months';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              // Missed months: either supply explicit indices (e.g., 3,6) OR supply a missed count below
                              TextFormField(
                                controller: _missedMonthsController,
                                keyboardType: TextInputType.text,
                                decoration: InputDecoration(
                                  labelText: 'Missed Months (indices or range)',
                                  hintText: 'e.g., 3,5 or 3-5; single number treated as count (last N months)',
                                  prefixIcon: Icon(Icons.block, color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _missedCountController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                decoration: InputDecoration(
                                  labelText: 'Missed count (optional)',
                                  hintText: 'e.g., 3 (marks last N months as missed)',
                                  prefixIcon: Icon(Icons.remove_circle_outline, color: AppTheme.primaryColor),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return null;
                                  final parsed = int.tryParse(value);
                                  if (parsed == null || parsed < 0) return 'Enter a valid number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Checkbox(
                                    value: _sipContributionAtStart,
                                    onChanged: (v) => setState(() => _sipContributionAtStart = v ?? false),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('Contribution at start of month'),
                                ],
                              ),
                            ],
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

            // Results (show for any calculator when results available)
            if (_showResults && (_emi != null || _totalAmount != null))
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
                        // Title and main value depend on calculator type
                        if (_calcType == 'EMI') ...[
                          const Text(
                            'Your EMI',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textMedium,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_formatNumber(_emi ?? 0)}',
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
                        ] else if (_calcType == 'Compound') ...[
                          const Text(
                            'Future Value',
                            style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_formatNumber(_totalAmount ?? 0)}',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          Text(
                            'at end of period',
                            style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                          ),
                        ] else if (_calcType == 'SIP') ...[
                          const Text(
                            'SIP Future Value',
                            style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '₹${_formatNumber(_totalAmount ?? 0)}',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          Text(
                            'Total Invested: ₹${_formatNumber(_totalInvested ?? 0)}',
                            style: TextStyle(fontSize: 14, color: AppTheme.textMedium),
                          ),
                        ],

                        const SizedBox(height: 24),
                        const Divider(),
                        const SizedBox(height: 16),

                        // Breakdown rows
                        if (_calcType == 'EMI') ...[
                          _buildResultRow(
                            'Principal Amount',
                            '₹${_formatNumber(_getPrincipalForDisplay())}',
                            Icons.account_balance,
                            AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            'Total Interest',
                            '₹${_formatNumber(_totalInterest ?? 0)}',
                            Icons.trending_up,
                            AppTheme.statusWarning,
                          ),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            'Total Amount',
                            '₹${_formatNumber(_totalAmount ?? 0)}',
                            Icons.payments,
                            AppTheme.statusSuccess,
                          ),
                          const SizedBox(height: 24),
                          // Visual breakdown with principal and interest (use safe getter)
                          _buildBreakdownFor(
                            _getPrincipalForDisplay(),
                            _totalInterest ?? 0,
                          ),
                        ] else if (_calcType == 'Compound') ...[
                          _buildResultRow(
                            'Initial Amount',
                            '₹${_formatNumber(_getPrincipalForDisplay())}',
                            Icons.account_balance,
                            AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            'Total Interest',
                            '₹${_formatNumber(_totalInterest ?? 0)}',
                            Icons.trending_up,
                            AppTheme.statusWarning,
                          ),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            'Future Value',
                            '₹${_formatNumber(_totalAmount ?? 0)}',
                            Icons.payments,
                            AppTheme.statusSuccess,
                          ),
                          const SizedBox(height: 24),
                          // Visual breakdown with principal and interest
                          _buildBreakdownFor(
                            _getPrincipalForDisplay(),
                            _totalInterest ?? 0,
                          ),
                        ] else if (_calcType == 'SIP') ...[
                          _buildResultRow(
                            'Monthly Investment',
                            '₹${_formatNumber(_getMonthlyInvestmentForDisplay())}',
                            Icons.savings,
                            AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            'Total Invested',
                            '₹${_formatNumber(_totalInvested ?? 0)}',
                            Icons.account_balance_wallet_rounded,
                            AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          _buildResultRow(
                            'Gains',
                            '₹${_formatNumber((_totalAmount ?? 0) - (_totalInvested ?? 0))}',
                            Icons.trending_up,
                            AppTheme.statusWarning,
                          ),
                          const SizedBox(height: 24),
                          _buildBreakdownFor(_totalInvested ?? 0, (_totalAmount ?? 0) - (_totalInvested ?? 0)),
                        ],
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
    final principal = _getPrincipalForDisplay();
    final interest = _totalInterest ?? 0;
    final total = principal + interest;

    final int principalPercent;
    final int interestPercent;
    if (total <= 0) {
      principalPercent = 50;
      interestPercent = 50;
    } else {
      principalPercent = (principal / total * 100).round();
      interestPercent = 100 - principalPercent;
    }

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

  Widget _buildBreakdownFor(double principal, double interest) {
    final total = principal + interest;

    final principalPercent = (principal / total * 100).round();
    final interestPercent = 100 - principalPercent;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Breakdown',
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

  // Safe getters to read parsed values for UI display (avoid parsing empty controllers)
  double _getPrincipalForDisplay() {
    if (_principalAmount != null) return _principalAmount!;
    final text = _principalController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(text);
    return parsed ?? 0.0;
  }

  double _getMonthlyInvestmentForDisplay() {
    if (_monthlyInvestment != null) return _monthlyInvestment!;
    final text = _monthlyInvestmentController.text.replaceAll(',', '').trim();
    final parsed = double.tryParse(text);
    return parsed ?? 0.0;
  }
}
