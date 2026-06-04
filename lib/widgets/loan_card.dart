import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onMarkUnpaid;
  final VoidCallback? onShare;

  const LoanCard({
    super.key,
    required this.loan,
    required this.onTap,
    this.onDelete,
    this.onMarkPaid,
    this.onMarkUnpaid,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = loan.daysUntilDue();
    // For a paid loan, show the current month's due date (the one just paid).
    // For an unpaid loan, show the upcoming due date.
    final nextDueDate = loan.isPaid ? loan.getCurrentDueDate() : loan.getNextDueDate();
    final isOverdue = loan.isOverdue();
    final statusColor = _getStatusColor(daysUntilDue, isOverdue);
    final l = AppLocalizations.of(context);
    final progress = (loan.tenureMonths != null && loan.tenureMonths! > 0)
        ? (_getEmiPaidCount() / loan.tenureMonths!).clamp(0.0, 1.0)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Top gradient tint banner
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withValues(alpha: 0.4)],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    // Row 1: Icon + Name + Amount
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Icon with gradient bg
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                statusColor.withValues(alpha: 0.18),
                                statusColor.withValues(alpha: 0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(_getLoanIcon(), color: statusColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        // Name + Due date
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getTranslatedLoanName(l),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF111827),
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                                  Row(
                                 children: [
                                   Icon(
                                     loan.isPaid
                                         ? Icons.check_circle_outline_rounded
                                         : Icons.schedule_rounded,
                                     size: 12,
                                     color: loan.isPaid
                                         ? const Color(0xFF10B981)
                                         : Colors.grey[400]),
                                   const SizedBox(width: 4),
                                   Text(
                                     loan.isPaid
                                         ? 'Paid • ${DateFormat('MMM d').format(nextDueDate)}'
                                         : 'Due ${DateFormat('MMM d').format(nextDueDate)}',
                                     style: TextStyle(
                                       fontSize: 12,
                                       color: loan.isPaid
                                           ? const Color(0xFF10B981)
                                           : Colors.grey[500],
                                       fontWeight: FontWeight.w500,
                                     ),
                                   ),
                                 ],
                               ),
                            ],
                          ),
                        ),
                        // Amount + badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${loan.currencySymbol}${NumberFormat('#,##,###').format(loan.emiAmount)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: Color(0xFF111827),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 5),
                            _buildStatusBadge(context, daysUntilDue, isOverdue, statusColor),
                          ],
                        ),
                      ],
                    ),

                    // Progress row (if tenure)
                    if (progress != null) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_getEmiPaidCount()} of ${loan.tenureMonths} EMIs paid',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: statusColor,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    backgroundColor: Colors.grey[100],
                                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          _buildActionBtn(context, statusColor),
                          if (onShare != null) ...[
                            const SizedBox(width: 6),
                            _shareBtn(),
                          ],
                        ],
                      ),
                    ] else ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _buildActionBtn(context, statusColor),
                          if (onShare != null) ...[
                            const SizedBox(width: 6),
                            _shareBtn(),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shareBtn() {
    return GestureDetector(
      onTap: onShare,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: const Color(0xFF6366F1).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Icon(Icons.share_rounded, size: 14, color: Color(0xFF6366F1)),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, int daysUntilDue,
      bool isOverdue, Color statusColor) {
    final text = _getStatusText(context, daysUntilDue, isOverdue);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: statusColor,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildActionBtn(BuildContext context, Color statusColor) {
    if (!loan.isPaid && onMarkPaid != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onMarkPaid!();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.green.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_rounded, color: Colors.white, size: 13),
              SizedBox(width: 4),
              Text(
                'Mark Paid',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (loan.isPaid && onMarkUnpaid != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onMarkUnpaid!();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.undo_rounded, color: Colors.orange, size: 13),
              SizedBox(width: 4),
              Text(
                'Undo',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  String _getStatusText(BuildContext context, int daysUntilDue, bool isOverdue) {
    final l = AppLocalizations.of(context);
    if (loan.isPaid) return l.paidStatus;
    if (isOverdue) return l.overdueStatus;
    if (daysUntilDue == 0) return l.dueTodayStatus;
    if (daysUntilDue == 1) return l.dueTomorrowStatus;
    if (daysUntilDue <= 3) return l.dueSoonStatus;
    return l.upcomingStatus;
  }

  IconData _getLoanIcon() {
    final name = loan.name.toLowerCase();
    if (name.contains('home') || name.contains('house') ||
        name.contains('வீட்டு') || name.contains('வீடு') ||
        name.contains('గృహ') || name.contains('गृह')) return Icons.home_rounded;
    if (name.contains('car') || name.contains('vehicle') ||
        name.contains('வாகன') ||
        name.contains('వాహన') || name.contains('कार')) return Icons.directions_car_rounded;
    if (name.contains('personal') ||
        name.contains('தனிநபர்') ||
        name.contains('వ్యక్తిగత') || name.contains('व्यक्तिगत')) return Icons.person_rounded;
    if (name.contains('education') || name.contains('study') ||
        name.contains('கல்வி') ||
        name.contains('విద్య') || name.contains('शिक्षा')) return Icons.school_rounded;
    if (name.contains('business') ||
        name.contains('தொழில்') ||
        name.contains('వ్యాపార') || name.contains('व्यापार')) return Icons.business_center_rounded;
    if (name.contains('gold') ||
        name.contains('நகை') ||
        name.contains('బంగారు') || name.contains('स्वर्ण')) return Icons.diamond_rounded;
    if (name.contains('credit') ||
        name.contains('கிரெடிட்') ||
        name.contains('క్రెడిట్') || name.contains('क्रेडिट')) return Icons.credit_card_rounded;
    return Icons.account_balance_rounded;
  }

  String _getTranslatedLoanName(AppLocalizations l) {
    final name = loan.name.toLowerCase();
    if (name == 'home loan' || name.contains('வீட்டுக் கடன்') ||
        name.contains('గృహ రుణం') || name.contains('गृह ऋण')) return l.getLoanTypeName('Home Loan');
    if (name == 'car loan' || name.contains('வாகனக் கடன்') ||
        name.contains('వాహన రుణం') || name.contains('कार ऋण')) return l.getLoanTypeName('Car Loan');
    if (name == 'personal loan' || name.contains('தனிநபர் கடன்') ||
        name.contains('వ్యక్తిగత రుణం') || name.contains('व्यक्तिगत ऋण')) return l.getLoanTypeName('Personal Loan');
    if (name == 'education loan' || name.contains('கல்விக் கடன்') ||
        name.contains('విద్యా రుణం') || name.contains('शिक्षा ऋण')) return l.getLoanTypeName('Education Loan');
    if (name == 'business loan' || name.contains('தொழில் கடன்') ||
        name.contains('వ్యాపార రుణం') || name.contains('व्यापार ऋण')) return l.getLoanTypeName('Business Loan');
    if (name == 'gold loan' || name.contains('நகைக்கடன்') ||
        name.contains('బంగారు రుణం') || name.contains('स्वर्ण ऋण')) return l.getLoanTypeName('Gold Loan');
    if (name == 'credit card' || name.contains('கிரெடிட் கார்டு') ||
        name.contains('క్రెడిట్ కార్డ్') || name.contains('क्रेडिट कार्ड')) return l.getLoanTypeName('Credit Card');
    return loan.name;
  }

  Color _getStatusColor(int daysUntilDue, bool isOverdue) {
    if (loan.isPaid) return const Color(0xFF10B981);
    if (isOverdue) return const Color(0xFFEF4444);
    if (daysUntilDue <= 3) return const Color(0xFFF59E0B);
    return AppTheme.primaryColor;
  }

  int _getEmiPaidCount() {
    if (loan.tenureMonths == null) return 0;
    return loan.emisPaidCount.clamp(0, loan.tenureMonths!);
  }
}
