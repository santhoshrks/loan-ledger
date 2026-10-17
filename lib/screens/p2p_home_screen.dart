import 'package:flutter/material.dart';
import 'package:app_settings/app_settings.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/p2p_loan.dart';
import '../repositories/p2p_repository.dart';
import '../repositories/p2p_repository_factory.dart';
import '../services/auth_provider.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';
import 'login_screen.dart';
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
      backgroundColor: const Color(0xFFF4F7FB),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openP2PTracker,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Loan'),
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
          final net = lent - borrowed;

          return RefreshIndicator(
            onRefresh: () async => setState(() {}),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 176,
                  pinned: true,
                  elevation: 0,
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  actions: [
                    IconButton(
                      tooltip: 'Share Snapshot',
                      onPressed: _shareSummary,
                      icon: const Icon(Icons.share_rounded),
                    ),
                    IconButton(
                      tooltip: 'Settings',
                      onPressed: _showAccountSheet,
                      icon: const Icon(Icons.settings_rounded),
                    ),
                    IconButton(
                      tooltip: 'Logout',
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded),
                    ),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildHeroHeader(
                      activeCount: activeLoans.length,
                      lent: lent,
                      borrowed: borrowed,
                      net: net,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildBentoSummary(
                      activeCount: activeLoans.length,
                      lent: lent,
                      borrowed: borrowed,
                      net: net,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildActionGrid(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: _sectionHeader(
                      'Upcoming dues',
                      'What needs attention in the next 30 days',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FutureBuilder<List<P2PDueItem>>(
                      future: _repository.getUpcomingDues(withinDays: 30),
                      builder: (context, snapshot) {
                        final dues = snapshot.data ?? const <P2PDueItem>[];
                        return _buildDuesSection(dues);
                      },
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                    child: _sectionHeader(
                      'Recent repayments',
                      'Latest money coming in or going out',
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: FutureBuilder<List<P2PPaymentRecord>>(
                      future: _repository.getRepaymentHistory(limit: 15),
                      builder: (context, snapshot) {
                        final history = snapshot.data ?? const <P2PPaymentRecord>[];
                        return _buildHistorySection(history);
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeroHeader({
    required int activeCount,
    required double lent,
    required double borrowed,
    required double net,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF18181B), Color(0xFF312E81), Color(0xFF4F46E5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -35,
            left: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet_rounded,
                           color: Colors.white,
                           size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'LoanLedger',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -0.5,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Compact money tracker for personal loans.',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.white70, fontSize: 10.8),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _heroChip(
                        icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        label: 'Net ${IndianNumberFormat.formatCompact(net.abs())}',
                      ),
                      _heroChip(
                        icon: Icons.layers_rounded,
                        label: '$activeCount active',
                      ),
                      _heroChip(
                        icon: Icons.south_west_rounded,
                        label: 'Pay ${IndianNumberFormat.formatCompact(borrowed)}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _buildBentoSummary({
    required int activeCount,
    required double lent,
    required double borrowed,
    required double net,
  }) {
    final netColor = net >= 0 ? AppTheme.statusSuccess : AppTheme.accentOrange;
    return Column(
      children: [
        _overviewStrip(
          activeCount: activeCount,
          lent: lent,
          borrowed: borrowed,
          net: net,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _bentoCard(
                title: 'Net position',
                amount: IndianNumberFormat.formatCompact(net.abs()),
                subtitle: net >= 0 ? 'Positive cashflow' : 'More payable now',
                icon: net >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                accent: netColor,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _bentoCard(
                title: 'Status',
                amount: net >= 0 ? 'Healthy' : 'Watch',
                subtitle: net >= 0 ? 'Collection is higher' : 'Payments need focus',
                icon: Icons.auto_graph_rounded,
                accent: const Color(0xFF6366F1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bentoCard({
    required String title,
    required String amount,
    required Color accent,
    required String subtitle,
    required IconData icon,
    bool large = false,
  }) {
    return Container(
      padding: EdgeInsets.all(large ? 16 : 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: accent.withValues(alpha: 0.08), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accent, size: 18),
          ),
          SizedBox(height: large ? 14 : 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11.5,
              color: AppTheme.textLight,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: large ? 21 : 16,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Widget _overviewStrip({
    required int activeCount,
    required double lent,
    required double borrowed,
    required double net,
  }) {
    final accent = net >= 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  net >= 0 ? Icons.south_west_rounded : Icons.north_east_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Portfolio balance',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      IndianNumberFormat.formatCompact(net.abs()),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$activeCount active',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniMetric(
                  'Receive',
                  IndianNumberFormat.formatCompact(lent),
                  const Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniMetric(
                  'Pay',
                  IndianNumberFormat.formatCompact(borrowed),
                  const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniMetric(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.15,
      children: [
        _actionCard(
          icon: Icons.menu_book_rounded,
          title: 'Loan Book',
          subtitle: 'Open all P2P entries',
          color: const Color(0xFF4F46E5),
          onTap: _openP2PTracker,
        ),
        _actionCard(
          icon: Icons.ios_share_rounded,
          title: 'Share Snapshot',
          subtitle: 'Send summary text',
          color: const Color(0xFF10B981),
          onTap: _shareSummary,
        ),
        _actionCard(
          icon: Icons.settings_rounded,
          title: 'Settings',
          subtitle: 'Password, app and device',
          color: const Color(0xFFF59E0B),
          onTap: _showAccountSheet,
        ),
        _actionCard(
          icon: Icons.logout_rounded,
          title: 'Logout',
          subtitle: 'Sign out safely',
          color: AppTheme.statusError,
          onTap: _handleLogout,
        ),
      ],
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
            border: Border.all(color: color.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 19),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 10.5, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_outward_rounded, size: 16, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12.5, color: AppTheme.textLight),
        ),
      ],
    );
  }

  Widget _buildDuesSection(List<P2PDueItem> dues) {
    if (dues.isEmpty) {
      return _emptyCard(
        icon: Icons.event_available_rounded,
        title: 'Nothing due soon',
        subtitle: 'You are clear for the next 30 days.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: dues.take(5).map(_dueTile).toList(),
      ),
    );
  }

  Widget _dueTile(P2PDueItem due) {
    final isLoanIn = due.dueType == P2PDueType.interest;
    final accent = due.isOverdue ? AppTheme.statusError : AppTheme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: due.isOverdue ? AppTheme.statusError.withValues(alpha: 0.06) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isLoanIn ? Icons.percent_rounded : Icons.account_balance_wallet_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  due.personName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isLoanIn ? 'Interest due' : 'Principal due',
                  style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                DateFormat('d MMM').format(due.dueDate),
                style: const TextStyle(fontSize: 12, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 4),
              Text(
                IndianNumberFormat.formatCompact(due.amount),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(List<P2PPaymentRecord> history) {
    if (history.isEmpty) {
      return _emptyCard(
        icon: Icons.receipt_long_rounded,
        title: 'No repayments yet',
        subtitle: 'Your latest payments will appear here.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: history.take(6).map(_historyTile).toList(),
      ),
    );
  }

  Widget _historyTile(P2PPaymentRecord record) {
    final isInterest = record.type == P2PPaymentType.interest;
    final accent = isInterest ? AppTheme.statusSuccess : AppTheme.primaryColor;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.bgLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(isInterest ? Icons.payments_rounded : Icons.account_balance_rounded, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.personName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('d MMM yyyy').format(record.date),
                  style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                ),
              ],
            ),
          ),
          Text(
            IndianNumberFormat.formatCompact(record.amount),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: accent),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.textDark),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
          ),
        ],
      ),
    );
  }

  Future<void> _openP2PTracker() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => P2PLoanScreen(notificationService: widget.notificationService),
      ),
    );
    if (mounted) setState(() {});
  }

  Future<void> _shareSummary() async {
    final loans = await _repository.getLoans();
    final active = loans.where((l) => !l.isSettled).toList();
    final lent = active.where((l) => l.isLent).fold<double>(0, (sum, l) => sum + l.outstanding);
    final borrowed = active.where((l) => !l.isLent).fold<double>(0, (sum, l) => sum + l.outstanding);

    final buffer = StringBuffer()
      ..writeln('LoanLedger - Portfolio Snapshot')
      ..writeln('Date: ${DateFormat('d MMM yyyy').format(DateTime.now())}')
      ..writeln('Active loans: ${active.length}')
      ..writeln('Lent outstanding: ${IndianNumberFormat.formatCompact(lent)}')
      ..writeln('Borrowed outstanding: ${IndianNumberFormat.formatCompact(borrowed)}');

    await Share.share(buffer.toString(), subject: 'LoanLedger Snapshot');
  }

  Future<void> _showAccountSheet() async {
    if (!mounted) return;
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.textLight.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Settings & Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? user?.phoneNumber ?? 'Signed in account',
                  style: const TextStyle(color: AppTheme.textLight, fontSize: 12.5),
                ),
                const SizedBox(height: 16),
                _sheetAction(
                  icon: Icons.password_rounded,
                  title: 'Reset password',
                  subtitle: user?.email == null
                      ? 'No email linked to this account'
                      : 'Send a reset link to ${user!.email}',
                  onTap: user?.email == null
                      ? null
                      : () async {
                          Navigator.pop(sheetContext);
                          final success = await auth.sendPasswordReset(user!.email!);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                success
                                    ? 'Password reset link sent to ${user.email}'
                                    : auth.errorMessage ?? 'Unable to send reset link',
                              ),
                            ),
                          );
                        },
                ),
                const SizedBox(height: 10),
                _sheetAction(
                  icon: Icons.notifications_rounded,
                  title: 'Notification settings',
                  subtitle: 'Open Android notification settings',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AppSettings.openAppSettings(type: AppSettingsType.notification);
                  },
                ),
                const SizedBox(height: 10),
                _sheetAction(
                  icon: Icons.settings_applications_rounded,
                  title: 'App settings',
                  subtitle: 'Open system app settings',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    AppSettings.openAppSettings();
                  },
                ),
                const SizedBox(height: 10),
                _sheetAction(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out from this device',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _handleLogout();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetAction({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool destructive = false,
  }) {
    final color = destructive ? AppTheme.statusError : AppTheme.primaryColor;
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppTheme.textLight),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogout() async {
    final navigator = Navigator.of(context);
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Do you want to logout from LoanLedger on this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusError),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await auth.logout();
    if (!mounted) return;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }
}










