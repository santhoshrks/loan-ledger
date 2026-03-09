import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/loan.dart';
import '../services/loan_storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/emi_calculator.dart';
import '../localization/app_localizations.dart';

class EMIProgressScreen extends StatefulWidget {
  final LoanStorageService storageService;

  const EMIProgressScreen({
    super.key,
    required this.storageService,
  });

  @override
  State<EMIProgressScreen> createState() => _EMIProgressScreenState();
}

class _EMIProgressScreenState extends State<EMIProgressScreen> {
  List<Loan> _loans = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLoans();
  }

  Future<void> _loadLoans() async {
    setState(() => _isLoading = true);

    // Read fresh data from storage
    final loans = widget.storageService.getAllLoans();

    debugPrint('=== EMI Progress Screen ===');
    debugPrint('Loaded ${loans.length} loans');
    for (var loan in loans) {
      debugPrint('Loan: ${loan.name}, isPaid: ${loan.isPaid}');
    }

    setState(() {
      _loans = loans;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(l.emiProgress),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLoans,
            tooltip: l.refresh,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loans.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadLoans,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header Summary
                        _buildSummaryHeader(context, _loans),

                        // Individual Loan Progress
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.loanWiseProgress,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 16),
                              ..._loans.map((loan) => _buildLoanProgressCard(context, loan)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            l.noLoansToTrack,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l.addLoanToSeeProgress,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHeader(BuildContext context, List<Loan> loans) {
    final l = AppLocalizations.of(context);
    double totalPrincipal = 0;
    int totalEmisPaid = 0;
    int totalEmisRemaining = 0;

    // Aggregate paid/remaining/interest amounts per currency to avoid mixing currencies
    final Map<String, double> paidByCurrency = {};
    final Map<String, double> remainingByCurrency = {};
    final Map<String, double> interestByCurrency = {};

    debugPrint('=== Building Summary Header ===');
    debugPrint('Number of loans: ${loans.length}');

    for (var loan in loans) {
      final progress = _calculateLoanProgress(loan);

      final emisPaid = (progress['emisPaid'] as int?) ?? 0;
      final emisRemaining = (progress['emisRemaining'] as int?) ?? 0;

      debugPrint('Loan ${loan.name}: emisPaid=$emisPaid, emisRemaining=$emisRemaining');

      // Add to totals from progress calculation
      totalEmisPaid += emisPaid;
      totalEmisRemaining += emisRemaining;

      final currency = loan.currencyCode.isNotEmpty ? loan.currencyCode : 'INR';
      final amtPaid = (progress['amountPaid'] as double?) ?? 0;
      final amtRemaining = (progress['amountRemaining'] as double?) ?? 0;
      final totInterest = (progress['totalInterest'] as double?) ?? 0;

      paidByCurrency[currency] = (paidByCurrency[currency] ?? 0) + amtPaid;
      remainingByCurrency[currency] = (remainingByCurrency[currency] ?? 0) + amtRemaining;
      interestByCurrency[currency] = (interestByCurrency[currency] ?? 0) + totInterest;

      if (loan.loanAmount != null) {
        totalPrincipal += loan.loanAmount!;
      }
    }

    debugPrint('Total EMIs Paid: $totalEmisPaid');
    debugPrint('Total EMIs Remaining: $totalEmisRemaining');

    // Calculate overall progress based on EMIs (more intuitive for users)
    final totalEmis = totalEmisPaid + totalEmisRemaining;
    final overallProgress = totalEmis > 0
        ? (totalEmisPaid / totalEmis * 100)
        : 0.0;

    debugPrint('Overall Progress: $overallProgress%');

    return Container(
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
          Text(
            l.overallProgress,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          // Circular Progress
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: CircularProgressIndicator(
                    value: overallProgress / 100,
                    strokeWidth: 12,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${overallProgress.toStringAsFixed(1)}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l.completed,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Summary Stats
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  l.totalLoans,
                  '${loans.length}',
                  Icons.account_balance,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  l.emisPaid,
                  '$totalEmisPaid',
                  Icons.check_circle_outline,
                ),
              ),
              Expanded(
                child: _buildSummaryItem(
                  l.emisLeft,
                  '$totalEmisRemaining',
                  Icons.schedule,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Amount Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      _formatCurrencyMap(paidByCurrency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l.paid,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white24,
                ),
                Column(
                  children: [
                    Text(
                      _formatCurrencyMap(remainingByCurrency),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      l.remaining,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanProgressCard(BuildContext context, Loan loan) {
    final l = AppLocalizations.of(context);
    final progress = _calculateLoanProgress(loan);
    final progressPercent = (progress['progressPercent'] as double?) ?? 0.0;
    final emisPaid = (progress['emisPaid'] as int?) ?? 0;
    final emisRemaining = (progress['emisRemaining'] as int?) ?? 0;
    final amountPaid = (progress['amountPaid'] as double?) ?? 0.0;
    final amountRemaining = (progress['amountRemaining'] as double?) ?? 0.0;

    // Debug: print values
    debugPrint('=== Loan: ${loan.name} ===');
    debugPrint('isPaid: ${loan.isPaid}');
    debugPrint('tenureMonths: ${loan.tenureMonths}');
    debugPrint('loanAmount: ${loan.loanAmount}');
    debugPrint('emisPaid calculated: $emisPaid');
    debugPrint('progressPercent: $progressPercent');

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loan Name & EMI
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: loan.isPaid
                              ? AppTheme.statusSuccess.withValues(alpha: 0.1)
                              : AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          loan.isPaid ? Icons.check_circle : Icons.account_balance,
                          color: loan.isPaid ? AppTheme.statusSuccess : AppTheme.primaryColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _getTranslatedLoanName(loan, l),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                // Show paid status badge
                                if (loan.isPaid)
                                  Container(
                                    margin: const EdgeInsets.only(left: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppTheme.statusSuccess.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      l.paidStatus,
                                      style: TextStyle(
                                        color: AppTheme.statusSuccess,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              '${loan.formattedEmi}/month • Due: ${loan.dueDay}${_getDaySuffix(loan.dueDay)}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getProgressColor(progressPercent).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${progressPercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: _getProgressColor(progressPercent),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercent / 100,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progressPercent),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Stats Row - show even if tenureMonths is null
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    l.emisPaid,
                    loan.tenureMonths != null
                        ? '$emisPaid / ${loan.tenureMonths}'
                        : '$emisPaid',
                    Icons.check_circle,
                    AppTheme.statusSuccess,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    l.remaining,
                    '$emisRemaining',
                    Icons.schedule,
                    AppTheme.statusWarning,
                  ),
                ),
              ],
            ),

            if (loan.loanAmount != null) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.paid,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatCurrency(amountPaid),
                        style: TextStyle(
                          color: AppTheme.statusSuccess,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        l.remaining,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatCurrency(amountRemaining),
                        style: TextStyle(
                          color: AppTheme.statusWarning,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _calculateLoanProgress(Loan loan) {
    debugPrint('--- Calculating progress for: ${loan.name} ---');
    debugPrint('loan.isPaid = ${loan.isPaid}');
    debugPrint('loan.tenureMonths = ${loan.tenureMonths}');
    debugPrint('loan.loanAmount = ${loan.loanAmount}');
    debugPrint('loan.startDate = ${loan.startDate}');
    debugPrint('loan.emisPaidCount = ${loan.emisPaidCount}');

    // Use the stored emisPaidCount as the base (manually entered by user)
    int emisPaid = loan.emisPaidCount;

    // If current month's EMI is marked as paid, add 1
    if (loan.isPaid) {
      emisPaid = emisPaid + 1;
      debugPrint('Added 1 for isPaid, now emisPaid = $emisPaid');
    }

    // Get tenure (default to 60 if not set)
    final tenure = loan.tenureMonths ?? 60;

    // Clamp emisPaid to valid range (0 to tenure)
    if (emisPaid > tenure) {
      emisPaid = tenure;
    }
    if (emisPaid < 0) {
      emisPaid = 0;
    }

    final emisRemaining = tenure - emisPaid;
    debugPrint('Final emisPaid = $emisPaid, emisRemaining = $emisRemaining');

    // Calculate amounts
    double totalInterest = 0.0;
    double totalAmount = 0.0;
    double amountPaid = loan.emiAmount * emisPaid;
    double amountRemaining = 0.0;

    if (loan.loanAmount != null) {
      if (loan.interestRate != null && loan.interestRate! > 0) {
        totalInterest = EMICalculator.calculateTotalInterest(
          principal: loan.loanAmount!,
          annualRate: loan.interestRate!,
          tenureMonths: tenure,
        );
      }
      totalAmount = loan.loanAmount! + totalInterest;
      amountRemaining = totalAmount - amountPaid;
      if (amountRemaining < 0) {
        amountRemaining = 0;
      }
    } else {
      // No loan amount, estimate remaining based on EMI
      amountRemaining = loan.emiAmount * emisRemaining;
    }

    double progressPercent = 0.0;
    if (tenure > 0) {
      progressPercent = (emisPaid / tenure) * 100;
    }
    if (progressPercent > 100) {
      progressPercent = 100;
    }

    debugPrint('progressPercent = $progressPercent');

    return {
      'progressPercent': progressPercent,
      'emisPaid': emisPaid,
      'emisRemaining': emisRemaining,
      'amountPaid': amountPaid,
      'amountRemaining': amountRemaining,
      'totalInterest': totalInterest,
    };
  }

  Color _getProgressColor(double percent) {
    if (percent >= 75) return AppTheme.statusSuccess;
    if (percent >= 50) return AppTheme.primaryColor;
    if (percent >= 25) return AppTheme.statusWarning;
    return AppTheme.secondaryColor;
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000000) {
      return '₹${(amount / 10000000).toStringAsFixed(2)} Cr';
    } else if (amount >= 100000) {
      return '₹${(amount / 100000).toStringAsFixed(2)} L';
    } else if (amount >= 1000) {
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return '₹${amount.toStringAsFixed(0)}';
  }

  // Format a map of currency->amount into a compact readable string
  String _formatCurrencyMap(Map<String, double> map) {
    if (map.isEmpty) return '—';
    final parts = <String>[];
    map.forEach((currency, amount) {
      final symbol = CurrencyHelper.getSymbol(currency);
      String amtStr;
      if (amount >= 10000000) {
        amtStr = '${(amount / 10000000).toStringAsFixed(2)} Cr';
      } else if (amount >= 100000) {
        amtStr = '${(amount / 100000).toStringAsFixed(2)} L';
      } else if (amount >= 1000) {
        amtStr = '${(amount / 1000).toStringAsFixed(1)}K';
      } else {
        amtStr = amount.toStringAsFixed(0);
      }
      parts.add('$symbol$amtStr');
    });
    return parts.join(' • ');
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1: return 'st';
      case 2: return 'nd';
      case 3: return 'rd';
      default: return 'th';
    }
  }

  /// Translate standard loan type names to current language
  String _getTranslatedLoanName(Loan loan, AppLocalizations l) {
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
        name.contains('వ்యக்తిగత రుణం') || name.contains('व्यक्तिगत ऋण')) {
      return l.getLoanTypeName('Personal Loan');
    }
    if (name == 'education loan' || name.contains('கல்விக் கடன்') ||
        name.contains('విద்యா రుణం') || name.contains('शिक्षा ऋण')) {
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
