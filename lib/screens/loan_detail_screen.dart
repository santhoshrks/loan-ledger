import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../utils/emi_calculator.dart';

class LoanDetailScreen extends StatelessWidget {
  final Loan loan;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LoanDetailScreen({
    Key? key,
    required this.loan,
    required this.onEdit,
    required this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final nextDue = loan.getNextDueDate();
    final daysUntilDue = loan.daysUntilDue();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Details'),
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
                      loan.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${loan.emiAmount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monthly EMI',
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
              title: 'Due Date',
              children: [
                _buildDetailRow(
                  icon: Icons.calendar_today,
                  label: 'Next Due',
                  value: DateFormat('MMM d, yyyy').format(nextDue),
                ),
                _buildDetailRow(
                  icon: Icons.schedule,
                  label: 'Days Until Due',
                  value: daysUntilDue == 0
                      ? 'Today'
                      : daysUntilDue < 0
                          ? 'Overdue by ${(-daysUntilDue)} days'
                          : '$daysUntilDue days',
                  valueColor: daysUntilDue < 0
                      ? Colors.red
                      : daysUntilDue <= 3
                          ? Colors.orange
                          : Colors.green,
                ),
                _buildDetailRow(
                  icon: Icons.calendar_month,
                  label: 'Due Day',
                  value: '${loan.dueDay}${_getDaySuffix(loan.dueDay)} of every month',
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Loan Details Section
            _buildSection(
              title: 'Loan Details',
              children: [
                _buildDetailRow(
                  icon: Icons.date_range,
                  label: 'Start Date',
                  value: DateFormat('MMM d, yyyy').format(loan.startDate),
                ),
                if (loan.loanAmount != null)
                  _buildDetailRow(
                    icon: Icons.money,
                    label: 'Loan Amount',
                    value: '₹${loan.loanAmount!.toStringAsFixed(2)}',
                  ),
                if (loan.interestRate != null)
                  _buildDetailRow(
                    icon: Icons.percent,
                    label: 'Interest Rate',
                    value: '${loan.interestRate!.toStringAsFixed(2)}% p.a.',
                  ),
                if (loan.tenureMonths != null)
                  _buildDetailRow(
                    icon: Icons.hourglass_bottom,
                    label: 'Tenure',
                    value: '${loan.tenureMonths} months',
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

            // Notes Section
            if (loan.notes != null && loan.notes!.isNotEmpty)
              _buildSection(
                title: 'Notes',
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
          value: '₹${breakdown['emi'].toStringAsFixed(2)}',
          valueColor: Colors.blue,
        ),
        _buildDetailRow(
          icon: Icons.trending_up,
          label: 'Total Interest',
          value: '₹${totalInterest.toStringAsFixed(2)}',
          valueColor: Colors.orange,
        ),
        _buildDetailRow(
          icon: Icons.money,
          label: 'Total Amount',
          value: '₹${totalAmount.toStringAsFixed(2)}',
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
}
