import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../services/loan_storage_service.dart';
import '../utils/emi_calculator.dart';
import '../localization/app_localizations.dart';
import '../theme/app_theme.dart';
import 'amortization_screen.dart';
import 'prepayment_calculator_screen.dart';
import 'floating_rate_screen.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final LoanStorageService? storageService;

  const LoanDetailScreen({
    super.key,
    required this.loan,
    required this.onEdit,
    required this.onDelete,
    this.storageService,
  });

  @override
  Widget build(BuildContext context) {
    final nextDue = loan.getNextDueDate();
    final daysUntilDue = loan.daysUntilDue();

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).loanDetails_title),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade700, Colors.green.shade400],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getTranslatedLoanName(context),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${loan.currencySymbol}${loan.emiAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppLocalizations.of(context).monthlyEmi,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Due Date Section
            _buildSection(
              title: AppLocalizations.of(context).dueDay_label,
              children: [
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: AppLocalizations.of(context).nextDue,
                  value: DateFormat('MMM d, yyyy').format(nextDue),
                ),
                _buildDetailRow(
                  icon: Icons.schedule,
                  label: AppLocalizations.of(context).daysUntilDue,
                  value: daysUntilDue == 0
                      ? AppLocalizations.of(context).today
                      : daysUntilDue < 0
                          ? '${AppLocalizations.of(context).overdue} ${(-daysUntilDue)} ${AppLocalizations.of(context).days}'
                          : '$daysUntilDue ${AppLocalizations.of(context).days}',
                  valueColor: daysUntilDue < 0
                      ? Colors.red
                      : daysUntilDue <= 3
                          ? Colors.orange
                          : Colors.green,
                ),
                _buildDetailRow(
                  icon: Icons.calendar_month,
                  label: AppLocalizations.of(context).dueDay,
                  value: '${loan.dueDay}${_getDaySuffix(loan.dueDay)} of ${AppLocalizations.of(context).everyMonth}',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Loan Details Section
            _buildSection(
              title: AppLocalizations.of(context).loanDetails_header,
              children: [
                _buildDetailRow(
                  icon: Icons.date_range,
                  label: AppLocalizations.of(context).startDate_label,
                  value: DateFormat('MMM d, yyyy').format(loan.startDate),
                ),
                if (loan.loanAmount != null)
                  _buildDetailRow(
                    icon: Icons.money,
                    label: AppLocalizations.of(context).loanAmount_label,
                    value: '${loan.currencySymbol}${loan.loanAmount!.toStringAsFixed(2)}',
                  ),
                if (loan.interestRate != null)
                  _buildDetailRow(
                    icon: Icons.percent,
                    label: AppLocalizations.of(context).interestRate_label,
                    value: '${loan.interestRate!.toStringAsFixed(2)}% ${AppLocalizations.of(context).perAnnum}',
                  ),
                if (loan.tenureMonths != null)
                  _buildDetailRow(
                    icon: Icons.hourglass_bottom,
                    label: AppLocalizations.of(context).tenure_label,
                    value: '${loan.tenureMonths} ${AppLocalizations.of(context).months}',
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // EMI Calculator Section (if loan details are available)
            if (loan.loanAmount != null &&
                loan.interestRate != null &&
                loan.tenureMonths != null)
              _buildCalculatorSection(),
            const SizedBox(height: 20),

            // Action Buttons — Amortization & Prepayment
            if (loan.loanAmount != null && loan.interestRate != null && loan.tenureMonths != null)
              _buildActionButtons(context),
            const SizedBox(height: 20),

            // Notes Section
            if (loan.notes != null && loan.notes!.isNotEmpty)
              _buildSection(
                title: AppLocalizations.of(context).notes_label,
                children: [
                  Text(
                    loan.notes!,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => AmortizationScreen(loan: loan))),
                icon: const Icon(Icons.table_chart_rounded, size: 18),
                label: const Text('Amortization', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  side: const BorderSide(color: AppTheme.primaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PrepaymentCalculatorScreen(loan: loan))),
                icon: const Icon(Icons.savings_rounded, size: 18),
                label: const Text('Prepayment', style: TextStyle(fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.secondaryColor,
                  side: const BorderSide(color: AppTheme.secondaryColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        if (storageService != null && loan.interestRate != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => FloatingRateScreen(
                      loan: loan, storageService: storageService!))),
              icon: const Icon(Icons.trending_up_rounded, size: 18),
              label: const Text('Floating Rate Tracker',
                  style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accentOrange,
                side: const BorderSide(color: AppTheme.accentOrange),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1) const Divider(height: 16),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildCalculatorSection() {
    final breakdown = EMICalculator.getLoanBreakdown(
      principal: loan.loanAmount!,
      annualRate: loan.interestRate!,
      tenureMonths: loan.tenureMonths!,
    );

    final totalInterest = breakdown['totalInterest'] as double;
    final totalAmount = breakdown['totalAmount'] as double;

    return _buildSection(
      title: 'EMI Breakdown',
      children: [
        _buildDetailRow(
          icon: Icons.calculate,
          label: 'Calculated EMI',
          value: '${loan.currencySymbol}${breakdown['emi'].toStringAsFixed(2)}',
          valueColor: Colors.blue,
        ),
        _buildDetailRow(
          icon: Icons.trending_up,
          label: 'Total Interest',
          value: '${loan.currencySymbol}${totalInterest.toStringAsFixed(2)}',
          valueColor: Colors.orange,
        ),
        _buildDetailRow(
          icon: Icons.money,
          label: 'Total Amount',
          value: '${loan.currencySymbol}${totalAmount.toStringAsFixed(2)}',
          valueColor: Colors.red,
        ),
      ],
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// Translate standard loan type names to current language
  String _getTranslatedLoanName(BuildContext context) {
    final l = AppLocalizations.of(context);
    final name = loan.name.toLowerCase();

    // Check if it's a standard loan type and translate it
    if (name == 'home loan' || name.contains('வீட்டுக் கடன்') ||
        name.contains('గృహ రుణం') || name.contains('गृह ऋण')) {
      return l.getLoanTypeName('Home Loan');
    }
    if (name == 'car loan' || name.contains('வாகனக் கடன்') ||
        name.contains('వాహన రుణం') || name.contains('कार ऋण')) {
      return l.getLoanTypeName('Car Loan');
    }
    if (name == 'personal loan' || name.contains('தனிநபர் கடன்') ||
        name.contains('వ్యక్తిగత రుణం') || name.contains('व्यक्तिगत ऋण')) {
      return l.getLoanTypeName('Personal Loan');
    }
    if (name == 'education loan' || name.contains('கல்விக் கடன்') ||
        name.contains('విద్యా రుణం') || name.contains('शिक्षा ऋण')) {
      return l.getLoanTypeName('Education Loan');
    }
    if (name == 'business loan' || name.contains('தொழில் கடன்') ||
        name.contains('వ్యాపార రుణం') || name.contains('व्यापार ऋण')) {
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

    // If not a standard type, return original name
    return loan.name;
  }
}
