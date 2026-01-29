import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';

class LoanCard extends StatelessWidget {
  final Loan loan;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onMarkPaid;
  final VoidCallback? onMarkUnpaid;

  const LoanCard({
    Key? key,
    required this.loan,
    required this.onTap,
    this.onDelete,
    this.onMarkPaid,
    this.onMarkUnpaid,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final daysUntilDue = loan.daysUntilDue();
    final nextDueDate = loan.getNextDueDate();
    final statusColor = _getStatusColor(daysUntilDue);
    final statusGradient = _getStatusGradient(daysUntilDue);
    final statusText = _getStatusText(daysUntilDue);
    final statusIcon = _getStatusIcon(daysUntilDue);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          children: [
            // Main Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Loan Icon with Status
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: statusGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _getLoanIcon(),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Loan Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: AppTheme.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppTheme.textLight,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              DateFormat('MMM d, yyyy').format(nextDueDate),
                              style: TextStyle(
                                color: AppTheme.textMedium,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Amount and Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${loan.currencySymbol}${NumberFormat('#,##,###').format(loan.emiAmount)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              statusIcon,
                              size: 12,
                              color: statusColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.bgLight.withValues(alpha: 0.5),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Days remaining indicator
                  if (!loan.isPaid)
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      text: _getDaysText(daysUntilDue),
                      color: statusColor,
                    )
                  else
                    _buildInfoChip(
                      icon: Icons.check_circle_outline,
                      text: 'Paid this month',
                      color: AppTheme.statusSuccess,
                    ),
                  const Spacer(),
                  // Quick Actions
                  if (!loan.isPaid && onMarkPaid != null)
                    _buildActionButton(
                      icon: Icons.check_rounded,
                      color: AppTheme.statusSuccess,
                      onTap: onMarkPaid!,
                      tooltip: 'Mark Paid',
                    )
                  else if (loan.isPaid && onMarkUnpaid != null)
                    _buildActionButton(
                      icon: Icons.undo_rounded,
                      color: AppTheme.statusWarning,
                      onTap: onMarkUnpaid!,
                      tooltip: 'Mark Unpaid',
                    ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    icon: Icons.arrow_forward_rounded,
                    color: AppTheme.primaryColor,
                    onTap: onTap,
                    tooltip: 'View Details',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            size: 18,
            color: color,
          ),
        ),
      ),
    );
  }

  IconData _getLoanIcon() {
    final name = loan.name.toLowerCase();
    if (name.contains('home') || name.contains('house') || name.contains('flat')) {
      return Icons.home_rounded;
    } else if (name.contains('car') || name.contains('vehicle') || name.contains('bike')) {
      return Icons.directions_car_rounded;
    } else if (name.contains('personal')) {
      return Icons.person_rounded;
    } else if (name.contains('education') || name.contains('study')) {
      return Icons.school_rounded;
    } else if (name.contains('business')) {
      return Icons.business_center_rounded;
    } else if (name.contains('gold')) {
      return Icons.diamond_rounded;
    } else if (name.contains('credit')) {
      return Icons.credit_card_rounded;
    }
    return Icons.account_balance_rounded;
  }

  /// Get color based on due date status
  Color _getStatusColor(int daysUntilDue) {
    if (loan.isPaid) return AppTheme.statusSuccess;
    if (daysUntilDue < 0) return AppTheme.statusError; // Overdue
    if (daysUntilDue == 0) return AppTheme.statusError; // Due today
    if (daysUntilDue <= 3) return AppTheme.statusWarning; // Due soon
    if (daysUntilDue <= 7) return AppTheme.statusInfo; // Coming up
    return AppTheme.secondaryColor; // Upcoming
  }

  LinearGradient _getStatusGradient(int daysUntilDue) {
    if (loan.isPaid) return AppTheme.successGradient;
    if (daysUntilDue < 0) return AppTheme.errorGradient;
    if (daysUntilDue == 0) return AppTheme.errorGradient;
    if (daysUntilDue <= 3) return AppTheme.warningGradient;
    return AppTheme.primaryGradient;
  }

  IconData _getStatusIcon(int daysUntilDue) {
    if (loan.isPaid) return Icons.check_circle_rounded;
    if (daysUntilDue < 0) return Icons.error_rounded;
    if (daysUntilDue == 0) return Icons.warning_rounded;
    if (daysUntilDue <= 3) return Icons.schedule_rounded;
    return Icons.event_rounded;
  }

  /// Get status text
  String _getStatusText(int daysUntilDue) {
    if (loan.isPaid) return 'PAID';
    if (daysUntilDue < 0) return 'OVERDUE';
    if (daysUntilDue == 0) return 'DUE TODAY';
    if (daysUntilDue <= 3) return 'DUE SOON';
    if (daysUntilDue <= 7) return 'THIS WEEK';
    return 'UPCOMING';
  }

  String _getDaysText(int daysUntilDue) {
    if (daysUntilDue < 0) {
      return '${daysUntilDue.abs()} days overdue';
    } else if (daysUntilDue == 0) {
      return 'Due today';
    } else if (daysUntilDue == 1) {
      return 'Due tomorrow';
    } else {
      return '$daysUntilDue days left';
    }
  }
}
