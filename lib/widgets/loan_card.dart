import 'package:flutter/material.dart';
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

  const LoanCard({
    super.key,
    required this.loan,
    required this.onTap,
    this.onDelete,
    this.onMarkPaid,
    this.onMarkUnpaid,
  });

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = loan.daysUntilDue();
    final nextDueDate = loan.getNextDueDate();
    final isOverdue = loan.isOverdue();
    final statusColor = _getStatusColor(daysUntilDue, isOverdue);
    final l = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Icon, Name, Amount
              Row(
                children: [
                  // Icon
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_getLoanIcon(), color: statusColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  // Name
                  Expanded(
                    child: Text(
                      _getTranslatedLoanName(l),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF1F2937),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Amount
                  Text(
                    '${loan.currencySymbol}${NumberFormat('#,##,###').format(loan.emiAmount)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Row 2: Due Date and Status Badge
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[500]),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM d, yyyy').format(nextDueDate),
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const Spacer(),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getStatusText(context, daysUntilDue, isOverdue),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              // Row 3: Progress bar (if tenure exists)
              if (loan.tenureMonths != null && loan.tenureMonths! > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _getEmiPaidCount() / loan.tenureMonths!,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_getEmiPaidCount()}/${loan.tenureMonths}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 14),

              // Divider
              Divider(height: 1, color: Colors.grey[200]),

              const SizedBox(height: 12),

              // Row 4: Days left + Actions
              Row(
                children: [
                  Icon(
                    loan.isPaid ? Icons.check_circle_rounded : Icons.schedule_rounded,
                    size: 16,
                    color: statusColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _getDaysText(context, l, daysUntilDue, isOverdue),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Action Buttons
                  if (!loan.isPaid && onMarkPaid != null)
                    _actionBtn(Icons.check_rounded, Colors.green, onMarkPaid!),
                  if (loan.isPaid && onMarkUnpaid != null)
                    _actionBtn(Icons.undo_rounded, Colors.orange, onMarkUnpaid!),
                  const SizedBox(width: 8),
                  _actionBtn(Icons.arrow_forward_ios_rounded, AppTheme.primaryColor, onTap),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
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

  String _getDaysText(BuildContext context, AppLocalizations l, int daysUntilDue, bool isOverdue) {
    if (loan.isPaid) return l.paid;
    if (isOverdue) return '${daysUntilDue.abs()} ${l.daysOverdue}';
    if (daysUntilDue == 0) return l.dueTodayLabel;
    if (daysUntilDue == 1) return l.dueTomorrowLabel;
    return '$daysUntilDue ${l.daysLeft}';
  }

  IconData _getLoanIcon() {
    final name = loan.name.toLowerCase();

    // Home Loan
    if (name.contains('home') || name.contains('house') ||
        name.contains('வீட்டு') || name.contains('வீடு') ||
        name.contains('గృహ') || name.contains('गृह')) {
      return Icons.home_rounded;
    }
    // Car Loan
    if (name.contains('car') || name.contains('vehicle') ||
        name.contains('வாகன') ||
        name.contains('వాహన') || name.contains('कार')) {
      return Icons.directions_car_rounded;
    }
    // Personal Loan
    if (name.contains('personal') ||
        name.contains('தனிநபர்') ||
        name.contains('వ్యక్తిగత') || name.contains('व्यक्तिगत')) {
      return Icons.person_rounded;
    }
    // Education Loan
    if (name.contains('education') || name.contains('study') ||
        name.contains('கல்வி') ||
        name.contains('విద్య') || name.contains('शिक्षा')) {
      return Icons.school_rounded;
    }
    // Business Loan
    if (name.contains('business') ||
        name.contains('தொழில்') ||
        name.contains('వ్యాపార') || name.contains('व्यापार')) {
      return Icons.business_center_rounded;
    }
    // Gold Loan
    if (name.contains('gold') ||
        name.contains('நகை') ||
        name.contains('బంగారు') || name.contains('स्वर्ण')) {
      return Icons.diamond_rounded;
    }
    // Credit Card
    if (name.contains('credit') ||
        name.contains('கிரெடிட்') ||
        name.contains('క్రెడిట్') || name.contains('क्रेडिट')) {
      return Icons.credit_card_rounded;
    }

    return Icons.account_balance_rounded;
  }

  /// Translate standard loan type names to current language
  String _getTranslatedLoanName(AppLocalizations l) {
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
