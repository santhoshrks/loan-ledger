import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class TaxBenefitScreen extends StatefulWidget {
  final List<Loan> loans;

  const TaxBenefitScreen({super.key, required this.loans});

  @override
  State<TaxBenefitScreen> createState() => _TaxBenefitScreenState();
}

class _TaxBenefitScreenState extends State<TaxBenefitScreen> {
  final _incomeController = TextEditingController();
  final _taxRateController = TextEditingController();
  double? _annualIncome;
  double? _taxRatePercent;
  final Map<String, _LoanTaxData> _loanTaxData = {};

  @override
  void initState() {
    super.initState();
    for (final loan in widget.loans) {
      final monthlyInterest = (loan.loanAmount != null && loan.interestRate != null && loan.tenureMonths != null)
          ? loan.emiAmount - (loan.loanAmount! / loan.tenureMonths!)
          : loan.emiAmount * 0.4;
      _loanTaxData[loan.id] = _LoanTaxData(
        principalPaid: (loan.emiAmount - monthlyInterest.clamp(0, loan.emiAmount)) * 12,
        interestPaid: monthlyInterest.clamp(0, loan.emiAmount) * 12,
        loanType: loan.loanTypeName ?? 'Other',
      );
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _taxRateController.dispose();
    super.dispose();
  }

  _TaxSavingResult _calculate() {
    double totalInterestPaid = 0;
    double totalPrincipalPaid = 0;
    List<_LoanSummary> summaries = [];

    for (final loan in widget.loans) {
      final data = _loanTaxData[loan.id];
      if (data == null) continue;
      totalInterestPaid += data.interestPaid;
      totalPrincipalPaid += data.principalPaid;
      summaries.add(_LoanSummary(
        loanName: loan.name,
        loanType: loan.loanTypeName ?? 'Other',
        interestPaid: data.interestPaid,
        principalPaid: data.principalPaid,
        currencySymbol: loan.currencySymbol,
      ));
    }

    final taxRate = (_taxRatePercent ?? 20.0) / 100.0;
    final estimatedTaxSavingOnInterest = totalInterestPaid * taxRate;

    return _TaxSavingResult(
      totalInterestPaid: totalInterestPaid,
      totalPrincipalPaid: totalPrincipalPaid,
      estimatedTaxSaving: estimatedTaxSavingOnInterest,
      taxRate: _taxRatePercent ?? 20.0,
      summaries: summaries,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Loan Interest & Tax Summary'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoBanner(),
            const SizedBox(height: 20),
            if (widget.loans.isEmpty)
              _buildNoLoansCard()
            else ...[
              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Details',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (v) => setState(() => _annualIncome = double.tryParse(v)),
                      decoration: InputDecoration(
                        labelText: 'Annual Gross Income',
                        prefixIcon: const Icon(Icons.account_balance_wallet_rounded, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        helperText: _annualIncome != null ? IndianNumberFormat.formatWithFull(_annualIncome!) : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _taxRateController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (v) => setState(() => _taxRatePercent = double.tryParse(v)),
                      decoration: InputDecoration(
                        labelText: 'Your Marginal Tax Rate (%)',
                        prefixIcon: const Icon(Icons.percent_rounded, color: AppTheme.primaryColor),
                        filled: true,
                        fillColor: AppTheme.bgLight,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        helperText: 'e.g. 20, 30 — check your country\'s tax bracket',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...widget.loans.map((loan) => _buildLoanEntry(loan)),
              const SizedBox(height: 16),
              _buildResults(_calculate()),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanEntry(Loan loan) {
    final data = _loanTaxData[loan.id]!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.credit_card_rounded, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Expanded(child: Text(loan.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
              if (loan.loanTypeName != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(loan.loanTypeName!, style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniInput(
                  label: 'Principal Paid (Annual)',
                  value: data.principalPaid,
                  onChanged: (v) => setState(() {
                    _loanTaxData[loan.id] = data.copyWith(principalPaid: double.tryParse(v) ?? data.principalPaid);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniInput(
                  label: 'Interest Paid (Annual)',
                  value: data.interestPaid,
                  onChanged: (v) => setState(() {
                    _loanTaxData[loan.id] = data.copyWith(interestPaid: double.tryParse(v) ?? data.interestPaid);
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '💡 Interest paid on loans may be tax-deductible depending on your country\'s tax laws.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _miniInput({required String label, required double value, bool enabled = true, void Function(String)? onChanged}) {
    return TextField(
      enabled: enabled,
      controller: TextEditingController(text: enabled ? value.toStringAsFixed(0) : ''),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: enabled ? AppTheme.bgLight : Colors.grey.shade100,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        labelStyle: const TextStyle(fontSize: 12),
      ),
      style: const TextStyle(fontSize: 13),
    );
  }

  Widget _buildResults(_TaxSavingResult r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Annual Loan Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [AppTheme.primaryColor, AppTheme.primaryLight], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(Icons.summarize_rounded, color: Colors.white, size: 32),
              const SizedBox(height: 8),
              Text(IndianNumberFormat.formatCompact(r.totalInterestPaid), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const Text('Total Interest Paid This Year', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 12),
              Text('Principal Paid: ${IndianNumberFormat.formatCompact(r.totalPrincipalPaid)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              if (r.taxRate > 0) ...[
                const SizedBox(height: 4),
                Text('Potential Tax Saving (@ ${r.taxRate.toStringAsFixed(0)}%): ${IndianNumberFormat.formatCompact(r.estimatedTaxSaving)}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Loan-by-Loan Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...r.summaries.map((s) => _summaryRow(s)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: const Text(
            '⚠️ Tax deductibility of loan interest varies by country and loan type. Consult a local tax advisor or accountant for accurate advice specific to your jurisdiction.',
            style: TextStyle(fontSize: 11, color: Color(0xFF92400E)),
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(_LoanSummary s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(s.loanName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
              if (s.loanType != 'Other') Text(s.loanType, style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              _chip('Principal', IndianNumberFormat.formatCompact(s.principalPaid), AppTheme.primaryColor),
              const SizedBox(width: 8),
              _chip('Interest', IndianNumberFormat.formatCompact(s.interestPaid), AppTheme.accentBlue),
            ],
          ),
          const Divider(height: 16),
        ],
      ),
    );
  }

  Widget _chip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
      child: Text('$label: $value', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1E293B), Color(0xFF334155)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Loan Interest & Tax Summary', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Track how much interest you pay annually. Many countries allow tax deductions on home, education, and business loan interest.',
            style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          _infoRow(Icons.home_rounded, 'Home Loan Interest', 'Often tax-deductible (varies by country)', AppTheme.primaryLight),
          _infoRow(Icons.school_rounded, 'Education Loan Interest', 'May be deductible in many countries', AppTheme.accentBlue),
          _infoRow(Icons.business_rounded, 'Business Loan Interest', 'Usually deductible as a business expense', AppTheme.secondaryColor),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLoansCard() {
    return _buildCard(
      child: Column(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor, size: 40),
          const SizedBox(height: 12),
          const Text('No Loans Found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text(
            'Add loans to see your annual interest payment summary and estimate potential tax savings.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMedium, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: child,
    );
  }
}

class _LoanTaxData {
  final double principalPaid;
  final double interestPaid;
  final String loanType;

  _LoanTaxData({required this.principalPaid, required this.interestPaid, required this.loanType});

  _LoanTaxData copyWith({double? principalPaid, double? interestPaid}) {
    return _LoanTaxData(
      principalPaid: principalPaid ?? this.principalPaid,
      interestPaid: interestPaid ?? this.interestPaid,
      loanType: loanType,
    );
  }
}

class _TaxSavingResult {
  final double totalInterestPaid;
  final double totalPrincipalPaid;
  final double estimatedTaxSaving;
  final double taxRate;
  final List<_LoanSummary> summaries;

  _TaxSavingResult({
    required this.totalInterestPaid,
    required this.totalPrincipalPaid,
    required this.estimatedTaxSaving,
    required this.taxRate,
    required this.summaries,
  });
}

class _LoanSummary {
  final String loanName;
  final String loanType;
  final double interestPaid;
  final double principalPaid;
  final String currencySymbol;

  _LoanSummary({required this.loanName, required this.loanType, required this.interestPaid, required this.principalPaid, required this.currencySymbol});
}

