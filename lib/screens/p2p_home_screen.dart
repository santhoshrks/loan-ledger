import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/p2p_loan.dart';
import '../repositories/p2p_repository.dart';
import '../repositories/p2p_repository_factory.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';
import 'p2p_loan_screen.dart';

class P2PHomeScreen extends StatefulWidget {
  final NotificationService? notificationService;
  final P2PRepository? repository;

  const P2PHomeScreen({super.key, this.notificationService, this.repository});

  @override
  State<P2PHomeScreen> createState() => _P2PHomeScreenState();
}

class _P2PHomeScreenState extends State<P2PHomeScreen> {
  late final P2PRepository _repository;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        P2PRepositoryFactory.create(source: P2PDataSource.local);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('LoanLedger'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Share Report',
            onPressed: _shareSummary,
            icon: const Icon(Icons.share_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openP2PTracker,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add P2P Loan'),
      ),
      body: ValueListenableBuilder<Box<P2PLoan>>(
        valueListenable: _repository.watchLoans(),
        builder: (context, box, _) {
          final loans = box.values.toList();
          final activeLoans = loans.where((l) => !l.isSettled).toList();
          final lent = activeLoans
              .where((l) => l.isLent)
              .fold<double>(0, (sum, l) => sum + l.outstanding);
          final borrowed = activeLoans
              .where((l) => !l.isLent)
              .fold<double>(0, (sum, l) => sum + l.outstanding);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(
                lent: lent,
                borrowed: borrowed,
                active: activeLoans.length,
              ),
              const SizedBox(height: 12),
              _buildActionRow(),
              const SizedBox(height: 12),
              FutureBuilder<List<P2PDueItem>>(
                future: _repository.getUpcomingDues(withinDays: 30),
                builder: (context, snapshot) {
                  final dues = snapshot.data ?? const <P2PDueItem>[];
                  return _duesCard(dues);
                },
              ),
              const SizedBox(height: 12),
              FutureBuilder<List<P2PPaymentRecord>>(
                future: _repository.getRepaymentHistory(limit: 15),
                builder: (context, snapshot) {
                  final history = snapshot.data ?? const <P2PPaymentRecord>[];
                  return _historyCard(history);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard({
    required double lent,
    required double borrowed,
    required int active,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lent / Borrowed Summary',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _metricTile('Lent', lent, const Color(0xFF166534)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _metricTile(
                  'Borrowed',
                  borrowed,
                  const Color(0xFF92400E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$active active loans',
            style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            IndianNumberFormat.formatCompact(amount),
            style: TextStyle(
              fontSize: 20,
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _openP2PTracker,
            icon: const Icon(Icons.list_alt_rounded),
            label: const Text('Loan Book'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _shareSummary,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Simple Report'),
          ),
        ),
      ],
    );
  }

  Widget _duesCard(List<P2PDueItem> dues) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Interest / Principal Dues',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (dues.isEmpty)
            const Text(
              'No dues in the next 30 days.',
              style: TextStyle(color: AppTheme.textMedium),
            )
          else
            ...dues
                .take(6)
                .map(
                  (due) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          due.dueType == P2PDueType.interest
                              ? Icons.percent_rounded
                              : Icons.account_balance_wallet_rounded,
                          size: 16,
                          color: due.isOverdue
                              ? AppTheme.statusError
                              : AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${due.personName} • ${due.dueType == P2PDueType.interest ? 'Interest' : 'Principal'}',
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          DateFormat('d MMM').format(due.dueDate),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          IndianNumberFormat.formatCompact(due.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _historyCard(List<P2PPaymentRecord> history) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Repayment History',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (history.isEmpty)
            const Text(
              'No payments logged yet.',
              style: TextStyle(color: AppTheme.textMedium),
            )
          else
            ...history
                .take(8)
                .map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          record.type == P2PPaymentType.interest
                              ? Icons.payments_rounded
                              : Icons.account_balance_rounded,
                          size: 16,
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.personName,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(
                          DateFormat('d MMM').format(record.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textMedium,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          IndianNumberFormat.formatCompact(record.amount),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _openP2PTracker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            P2PLoanScreen(notificationService: widget.notificationService),
      ),
    );
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _shareSummary() async {
    final loans = await _repository.getLoans();
    final active = loans.where((l) => !l.isSettled).toList();
    final lent = active
        .where((l) => l.isLent)
        .fold<double>(0, (sum, l) => sum + l.outstanding);
    final borrowed = active
        .where((l) => !l.isLent)
        .fold<double>(0, (sum, l) => sum + l.outstanding);

    final buffer = StringBuffer()
      ..writeln('LoanLedger - Snapshot')
      ..writeln('Date: ${DateFormat('d MMM yyyy').format(DateTime.now())}')
      ..writeln('Active loans: ${active.length}')
      ..writeln('Lent outstanding: ${IndianNumberFormat.formatCompact(lent)}')
      ..writeln(
        'Borrowed outstanding: ${IndianNumberFormat.formatCompact(borrowed)}',
      );

    await Share.share(buffer.toString(), subject: 'LoanLedger Report');
  }
}



