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
    final isOverdue = loan.isOverdue();
    final statusColor = _getStatusColor(daysUntilDue, isOverdue);
    final statusGradient = _getStatusGradient(daysUntilDue, isOverdue);
    final statusText = _getStatusText(daysUntilDue, isOverdue);
    final statusIcon = _getStatusIcon(daysUntilDue, isOverdue);

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
                              Icons.event_rounded,
                              size: 14,
                              color: isOverdue
                                  ? AppTheme.statusError
                                  : (loan.isPaid ? AppTheme.primaryColor : AppTheme.textLight),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _getDueDateText(nextDueDate, isOverdue),
                              style: TextStyle(
                                color: isOverdue
                                    ? AppTheme.statusError
                                    : (loan.isPaid ? AppTheme.primaryColor : AppTheme.textMedium),
                                fontSize: 13,
                                fontWeight: isOverdue || loan.isPaid ? FontWeight.w500 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                        // EMI Progress (if tenure is set)
                        Builder(
                          builder: (context) {
                            debugPrint('Loan ${loan.name}: tenureMonths = ${loan.tenureMonths}');
                            if (loan.tenureMonths != null && loan.tenureMonths! > 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.pie_chart_rounded,
                                      size: 14,
                                      color: AppTheme.secondaryColor,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'EMI: ${_getEmiPaidCount()}/${loan.tenureMonths} paid',
                                      style: TextStyle(
                                        color: AppTheme.secondaryColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
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
                  // Status indicator
                  if (loan.isPaid)
                    Row(
                      children: [
                        _buildInfoChip(
                          icon: Icons.check_circle_outline,
                          text: 'Paid',
                          color: AppTheme.statusSuccess,
                        ),
                        const SizedBox(width: 8),
                        _buildInfoChip(
                          icon: Icons.schedule_rounded,
                          text: 'Next in ${daysUntilDue}d',
                          color: AppTheme.primaryColor,
                        ),
                      ],
                    )
                  else if (isOverdue)
                    _buildInfoChip(
                      icon: Icons.warning_rounded,
                      text: '${daysUntilDue.abs()} days overdue',
                      color: AppTheme.statusError,
                    )
                  else
                    _buildInfoChip(
                      icon: Icons.timer_outlined,
                      text: _getDaysText(daysUntilDue),
                      color: statusColor,
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
  Color _getStatusColor(int daysUntilDue, bool isOverdue) {
    if (loan.isPaid) return AppTheme.statusSuccess;
    if (isOverdue) return AppTheme.statusError; // Overdue (unpaid and past due date)
    if (daysUntilDue == 0) return AppTheme.statusWarning; // Due today
    if (daysUntilDue <= 3) return AppTheme.statusWarning; // Due soon
    if (daysUntilDue <= 7) return AppTheme.statusInfo; // Coming up
    return AppTheme.secondaryColor; // Upcoming
  }

  LinearGradient _getStatusGradient(int daysUntilDue, bool isOverdue) {
    if (loan.isPaid) return AppTheme.successGradient;
    if (isOverdue) return AppTheme.errorGradient;
    if (daysUntilDue == 0) return AppTheme.warningGradient;
    if (daysUntilDue <= 3) return AppTheme.warningGradient;
    return AppTheme.primaryGradient;
  }

  IconData _getStatusIcon(int daysUntilDue, bool isOverdue) {
    if (loan.isPaid) return Icons.check_circle_rounded;
    if (isOverdue) return Icons.error_rounded;
    if (daysUntilDue == 0) return Icons.warning_rounded;
    if (daysUntilDue <= 3) return Icons.schedule_rounded;
    return Icons.event_rounded;
  }

  /// Get status text
  String _getStatusText(int daysUntilDue, bool isOverdue) {
    if (loan.isPaid) return 'PAID';
    if (isOverdue) return 'OVERDUE';
    if (daysUntilDue == 0) return 'DUE TODAY';
    if (daysUntilDue == 1) return 'DUE TOMORROW';
    if (daysUntilDue <= 3) return 'DUE SOON';
    if (daysUntilDue <= 7) return 'THIS WEEK';
    return 'UPCOMING';
  }

  /// Get due date text based on status
  String _getDueDateText(DateTime dueDate, bool isOverdue) {
    if (loan.isPaid) {
      return 'Next Due: ${DateFormat('MMM d, yyyy').format(dueDate)}';
    } else if (isOverdue) {
      return 'Overdue: ${DateFormat('MMM d, yyyy').format(dueDate)}';
    } else {
      return 'Due: ${DateFormat('MMM d, yyyy').format(dueDate)}';
    }
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

  /// Calculate number of EMIs paid
  int _getEmiPaidCount() {
    if (loan.tenureMonths == null) return 0;

    // Use the stored emisPaidCount as the base (manually entered by user)
    int emisPaid = loan.emisPaidCount;

    // If current month's EMI is marked as paid, add 1 to the stored count
    if (loan.isPaid) {
      emisPaid = emisPaid + 1;
    }

    // Clamp to valid range
    if (emisPaid > loan.tenureMonths!) {
      emisPaid = loan.tenureMonths!;
    }
    if (emisPaid < 0) {
      emisPaid = 0;
    }

    return emisPaid;
  }
}
