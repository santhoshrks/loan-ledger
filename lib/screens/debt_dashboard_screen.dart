import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';
import 'amortization_screen.dart';
import 'prepayment_calculator_screen.dart';
import 'tax_benefit_screen.dart';

class DebtDashboardScreen extends StatefulWidget {
  final List<Loan> loans;

  const DebtDashboardScreen({super.key, required this.loans});

  @override
  State<DebtDashboardScreen> createState() => _DebtDashboardScreenState();
}

class _DebtDashboardScreenState extends State<DebtDashboardScreen> {
  int _touchedIndex = -1;

  // Loan type colors
  static const Map<String, Color> _typeColors = {
    'Home Loan': Color(0xFF6366F1),
    'Car Loan': Color(0xFF14B8A6),
    'Two-Wheeler Loan': Color(0xFF8B5CF6),
    'Personal Loan': Color(0xFFF59E0B),
    'Education Loan': Color(0xFF3B82F6),
    'Business Loan': Color(0xFF10B981),
    'Gold Loan': Color(0xFFD97706),
    'Chit Fund': Color(0xFFEC4899),
    'Agricultural Loan': Color(0xFF84CC16),
    'Microfinance': Color(0xFF06B6D4),
    'Credit Card': Color(0xFFEF4444),
    'Other': Color(0xFF94A3B8),
  };

  Color _colorForType(String? type) =>
      _typeColors[type ?? 'Other'] ?? const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    final loans = widget.loans;

    if (loans.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgLight,
        appBar: AppBar(
          title: const Text('Debt Dashboard'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: Text('No loans added yet.')),
      );
    }

    final totalMonthlyEMI = loans.fold(0.0, (s, l) => s + l.emiAmount);
    final totalLoanAmount = loans.fold(0.0, (s, l) => s + (l.loanAmount ?? 0));
    final totalInterest = loans.fold(0.0, (s, l) {
      if (l.loanAmount != null && l.interestRate != null && l.tenureMonths != null) {
        final emi = l.emiAmount;
        final n = l.tenureMonths!;
        return s + ((emi * n) - l.loanAmount!);
      }
      return s;
    });
    final overdueCount = loans.where((l) => l.isOverdue()).length;
    final paidCount = loans.where((l) => l.isPaid).length;

    // Group by type
    final Map<String, double> byType = {};
    for (final loan in loans) {
      final type = loan.loanTypeName ?? 'Other';
      byType[type] = (byType[type] ?? 0) + loan.emiAmount;
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Debt Dashboard'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_rounded),
            tooltip: 'Tax Benefits',
            onPressed: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => TaxBenefitScreen(loans: loans))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header gradient
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Total Monthly Outflow',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    IndianNumberFormat.formatCompact(totalMonthlyEMI),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    IndianNumberFormat.formatWithFull(totalMonthlyEMI),
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _headerStat('${loans.length}', 'Total Loans'),
                      _headerStat(overdueCount > 0 ? '$overdueCount ⚠️' : '$overdueCount', 'Overdue',
                          color: overdueCount > 0 ? AppTheme.accentOrange : Colors.white),
                      _headerStat('$paidCount', 'Paid This Month', color: AppTheme.statusSuccess),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // DTI Ratio Card
            _buildDTICard(totalMonthlyEMI),

            const SizedBox(height: 16),

            // Total Interest Burden
            if (totalLoanAmount > 0)
              _buildInterestBurdenCard(totalLoanAmount, totalInterest),

            const SizedBox(height: 16),

            // Pie Chart — EMI by Loan Type
            if (byType.isNotEmpty)
              _buildPieChartCard(byType, totalMonthlyEMI),

            const SizedBox(height: 16),

            // Loan-wise breakdown
            _buildLoanBreakdownCard(loans),

            const SizedBox(height: 16),

            // Quick Actions
            _buildQuickActions(loans),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildDTICard(double totalMonthlyEMI) {
    final controller = TextEditingController();

    return StatefulBuilder(
      builder: (context, setInner) {
        double? income;
        double dti = 0;
        String dtiStatus = '';
        Color dtiColor = AppTheme.statusSuccess;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.balance_rounded, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Text('Debt-to-Income Ratio (DTI)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                  const Spacer(),
                  const Tooltip(
                    message: 'DTI = Monthly EMIs / Monthly Income × 100\n'
                        'Below 30%: Healthy\n30–40%: Manageable\nAbove 40%: High risk',
                    child: Icon(Icons.info_outline_rounded, size: 16, color: AppTheme.textLight),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  setInner(() {
                    income = double.tryParse(v);
                    if (income != null && income! > 0) {
                      dti = (totalMonthlyEMI / income!) * 100;
                      if (dti < 30) {
                        dtiStatus = '✅ Healthy DTI';
                        dtiColor = AppTheme.statusSuccess;
                      } else if (dti < 40) {
                        dtiStatus = '⚠️ Manageable';
                        dtiColor = AppTheme.statusWarning;
                      } else {
                        dtiStatus = '🚨 High Risk';
                        dtiColor = AppTheme.statusError;
                      }
                    }
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Your Monthly Income',
                  prefixIcon: const Icon(Icons.payments_rounded, color: AppTheme.primaryColor),
                  filled: true,
                  fillColor: AppTheme.bgLight,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              if (income != null && income! > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${dti.toStringAsFixed(1)}%',
                      style: TextStyle(
                          fontSize: 28, fontWeight: FontWeight.bold, color: dtiColor),
                    ),
                    const SizedBox(width: 12),
                    Text(dtiStatus,
                        style: TextStyle(fontSize: 14, color: dtiColor, fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: (dti / 60).clamp(0, 1),
                  backgroundColor: AppTheme.bgLight,
                  valueColor: AlwaysStoppedAnimation<Color>(dtiColor),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('0%', style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
                    Text('30% Healthy', style: TextStyle(fontSize: 10, color: AppTheme.statusSuccess)),
                    Text('40% Caution', style: TextStyle(fontSize: 10, color: AppTheme.statusWarning)),
                    Text('60%+', style: TextStyle(fontSize: 10, color: AppTheme.statusError)),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInterestBurdenCard(double principal, double totalInterest) {
    final totalPayment = principal + totalInterest;
    final interestPct = totalPayment > 0 ? (totalInterest / totalPayment * 100) : 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Total Interest Burden',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _interestStat('Principal', principal, AppTheme.primaryColor),
                    const SizedBox(height: 8),
                    _interestStat('Total Interest', totalInterest, AppTheme.accentOrange),
                    const SizedBox(height: 8),
                    _interestStat('Total Payment', totalPayment, AppTheme.textDark),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Interest percentage circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${interestPct.toStringAsFixed(0)}%',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.accentOrange),
                      ),
                      const Text('Interest', style: TextStyle(fontSize: 9, color: AppTheme.textLight)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPieChartCard(Map<String, double> byType, double total) {
    final entries = byType.entries.toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('EMI Breakdown by Loan Type',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                // Pie chart
                Expanded(
                  child: PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions ||
                                pieTouchResponse == null ||
                                pieTouchResponse.touchedSection == null) {
                              _touchedIndex = -1;
                              return;
                            }
                            _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      sections: entries.asMap().entries.map((e) {
                        final i = e.key;
                        final entry = e.value;
                        final isTouched = i == _touchedIndex;
                        final pct = total > 0 ? entry.value / total * 100 : 0;
                        return PieChartSectionData(
                          color: _colorForType(entry.key),
                          value: entry.value,
                          title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
                          radius: isTouched ? 70 : 55,
                          titleStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 35,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Legend
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: entries.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: _colorForType(entry.key),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            entry.key.length > 12 ? '${entry.key.substring(0, 12)}…' : entry.key,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textDark),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            IndianNumberFormat.formatCompact(entry.value),
                            style: const TextStyle(
                                fontSize: 11, color: AppTheme.textMedium, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoanBreakdownCard(List<Loan> loans) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Text('Loan-wise Details',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          ),
          ...loans.map((loan) => _buildLoanRow(loan)),
        ],
      ),
    );
  }

  Widget _buildLoanRow(Loan loan) {
    final symbol = loan.currencySymbol;
    final isOverdue = loan.isOverdue();
    final daysLeft = loan.daysUntilDue();
    final progress = loan.tenureMonths != null && loan.tenureMonths! > 0
        ? loan.emisPaidCount / loan.tenureMonths!
        : 0.0;

    return InkWell(
      onTap: () => _showLoanActions(loan),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _colorForType(loan.loanTypeName).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconForType(loan.loanTypeName),
                    color: _colorForType(loan.loanTypeName),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loan.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
                      if (loan.bankName != null)
                        Text(loan.bankName!,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      IndianNumberFormat.formatCompact(loan.emiAmount, symbol: symbol),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                    Text('per month',
                        style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
                  ],
                ),
              ],
            ),
            if (loan.tenureMonths != null && loan.tenureMonths! > 0) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: AppTheme.bgLight,
                valueColor: AlwaysStoppedAnimation<Color>(_colorForType(loan.loanTypeName)),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${loan.emisPaidCount}/${loan.tenureMonths} EMIs paid',
                      style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
                  if (isOverdue)
                    const Text('OVERDUE',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.statusError, fontWeight: FontWeight.bold))
                  else
                    Text('Due in $daysLeft days',
                        style: TextStyle(
                            fontSize: 10,
                            color: daysLeft <= 3 ? AppTheme.statusWarning : AppTheme.textLight)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showLoanActions(Loan loan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loan.name,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _actionTile(Icons.table_chart_rounded, 'View Amortization Schedule', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => AmortizationScreen(loan: loan)));
            }),
            _actionTile(Icons.payments_rounded, 'Prepayment Calculator', () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(
                  builder: (_) => PrepaymentCalculatorScreen(loan: loan)));
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildQuickActions(List<Loan> loans) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Tools',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _quickActionCard(
                  icon: Icons.payments_rounded,
                  label: 'Prepayment\nCalculator',
                  color: AppTheme.secondaryColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const PrepaymentCalculatorScreen())),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _quickActionCard(
                  icon: Icons.account_balance_rounded,
                  label: 'Tax Benefit\nCalculator',
                  color: AppTheme.primaryColor,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => TaxBenefitScreen(loans: loans))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickActionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _headerStat(String value, String label, {Color color = Colors.white}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _interestStat(String label, double value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium)),
        Text(
          IndianNumberFormat.formatCompact(value),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  IconData _iconForType(String? type) {
    switch (type) {
      case 'Home Loan': return Icons.home_rounded;
      case 'Car Loan': return Icons.directions_car_rounded;
      case 'Two-Wheeler Loan': return Icons.two_wheeler_rounded;
      case 'Personal Loan': return Icons.person_rounded;
      case 'Education Loan': return Icons.school_rounded;
      case 'Business Loan': return Icons.business_center_rounded;
      case 'Gold Loan': return Icons.diamond_rounded;
      case 'Chit Fund': return Icons.groups_rounded;
      case 'Agricultural Loan': return Icons.agriculture_rounded;
      case 'Microfinance': return Icons.handshake_rounded;
      case 'Credit Card': return Icons.credit_card_rounded;
      default: return Icons.account_balance_rounded;
    }
  }
}



