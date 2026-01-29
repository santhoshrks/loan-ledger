import 'package:flutter/material.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';

class DashboardCard extends StatelessWidget {
  final List<Loan> loans;

  const DashboardCard({
    Key? key,
    required this.loans,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final stats = _calculateStats();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${stats['totalLoans']} Loans',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Stats Grid
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  icon: Icons.credit_card,
                  label: 'Total EMIs',
                  value: stats['totalLoans'].toString(),
                ),
                _buildStatItem(
                  icon: Icons.payment,
                  label: 'Active',
                  value: stats['activeLoans'].toString(),
                ),
                _buildStatItem(
                  icon: Icons.check_circle,
                  label: 'Completed',
                  value: stats['paidLoans'].toString(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Amount Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildAmountRow(
                    'Total Monthly EMI',
                    '₹${stats['totalMonthlyEMI'].toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _buildAmountRow(
                    'Total Loan Amount',
                    '₹${stats['totalLoanAmount'].toStringAsFixed(0)}',
                  ),
                  const SizedBox(height: 8),
                  _buildAmountRow(
                    'Estimated Interest',
                    '₹${stats['estimatedInterest'].toStringAsFixed(0)}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Progress Bars
            _buildProgressSection(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountRow(String label, String amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(Map<String, dynamic> stats) {
    final paidLoans = stats['paidLoans'] as int;
    final totalLoans = stats['totalLoans'] as int;
    final progressPercent = totalLoans > 0 ? (paidLoans / totalLoans) * 100 : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Loan Completion Progress',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.9),
              ),
            ),
            Text(
              '${progressPercent.toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progressPercent / 100,
            minHeight: 8,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$paidLoans of $totalLoans loans completed',
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateStats() {
    int totalLoans = loans.length;
    int activeLoans = loans.where((l) => !l.isPaid).length;
    int paidLoans = loans.where((l) => l.isPaid).length;

    double totalMonthlyEMI = 0;
    double totalLoanAmount = 0;
    double estimatedInterest = 0;

    for (var loan in loans) {
      totalMonthlyEMI += loan.emiAmount;
      if (loan.loanAmount != null) {
        totalLoanAmount += loan.loanAmount!;
      }
      if (loan.interestRate != null && loan.loanAmount != null && loan.tenureMonths != null) {
        final monthlyRate = loan.interestRate! / 12 / 100;
        final numerator = loan.loanAmount! * monthlyRate * pow(1 + monthlyRate, loan.tenureMonths!);
        final denominator = pow(1 + monthlyRate, loan.tenureMonths!) - 1;
        final emi = numerator / denominator;
        final totalInterest = (emi * loan.tenureMonths!) - loan.loanAmount!;
        estimatedInterest += totalInterest;
      }
    }

    return {
      'totalLoans': totalLoans,
      'activeLoans': activeLoans,
      'paidLoans': paidLoans,
      'totalMonthlyEMI': totalMonthlyEMI,
      'totalLoanAmount': totalLoanAmount,
      'estimatedInterest': estimatedInterest,
    };
  }
}

/// Helper function for power calculation
double pow(double base, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}
