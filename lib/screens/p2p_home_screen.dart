import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/p2p_loan.dart';
import '../repositories/p2p_repository.dart';
import '../repositories/p2p_repository_factory.dart';
import '../services/auth_provider.dart';
import '../services/notification_service.dart';
import '../services/loan_storage_service.dart';
import '../services/backup_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';
import 'login_screen.dart';
import 'p2p_loan_screen.dart';
import 'p2p_loan_detail_screen.dart';
import 'emi_calculator_screen.dart';
import 'expense_tracker_screen.dart';
import 'ai_advisor_screen.dart';
import 'settings_screen.dart';

class P2PHomeScreen extends StatefulWidget {
  final NotificationService? notificationService;
  final P2PRepository? repository;

  const P2PHomeScreen({super.key, this.notificationService, this.repository});

  @override
  State<P2PHomeScreen> createState() => _P2PHomeScreenState();
}

class _P2PHomeScreenState extends State<P2PHomeScreen> {
  late final P2PRepository _repository;
  bool _showWelcomeGuide = false;
  bool _isBoxReady = false;
  StreamSubscription? _boxSubscription;

  @override
  void initState() {
    super.initState();
    _repository =
        widget.repository ??
        P2PRepositoryFactory.create(source: P2PDataSource.local);
    _checkWelcomeGuide();
    _initBox();
  }

  @override
  void dispose() {
    _boxSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initBox() async {
    try {
      if (!Hive.isBoxOpen('p2p_loans')) {
        await Hive.openBox<P2PLoan>('p2p_loans');
      }
      final box = Hive.box<P2PLoan>('p2p_loans');
      _boxSubscription?.cancel();
      _boxSubscription = box.watch().listen((_) {
        if (mounted) {
          setState(() {});
        }
      });
    } catch (e) {
      debugPrint('❌ Error initializing p2p_loans box: $e');
    }
    if (mounted) {
      setState(() {
        _isBoxReady = true;
      });
    }
  }

  Future<void> _checkWelcomeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissed = prefs.getBool('welcome_guide_dismissed') ?? false;
    if (mounted) {
      setState(() {
        _showWelcomeGuide = !dismissed;
      });
    }
  }

  Future<void> _dismissWelcomeGuide() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('welcome_guide_dismissed', true);
    if (mounted) {
      setState(() {
        _showWelcomeGuide = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isBoxReady || !Hive.isBoxOpen('p2p_loans')) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F7FB),
        body: Center(
          child: CircularProgressIndicator(
            color: AppTheme.primaryColor,
          ),
        ),
      );
    }

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
                  expandedHeight: 100,
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
                      onPressed: _openSettings,
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
                if (_showWelcomeGuide)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: _buildWelcomeGuideCard(),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: _buildFeaturedLoanBookCard(),
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
          colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFF4F46E5)],
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'LoanLedger',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Smart Personal Loan & Debt Manager',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                title: 'Active Loans',
                amount: '$activeCount Accounts',
                subtitle: activeCount == 0 ? 'No active dues' : 'Currently being tracked',
                icon: Icons.account_balance_rounded,
                accent: const Color(0xFF0EA5E9),
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
          title: 'LoanBook',
          subtitle: 'Open all LoanBook entries',
          color: const Color(0xFF4F46E5),
          onTap: _openP2PTracker,
        ),
        _actionCard(
          icon: Icons.calculate_rounded,
          title: 'EMI Calculator',
          subtitle: 'Calculate EMI & interest',
          color: const Color(0xFF0EA5E9),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const EMICalculatorScreen()),
            );
          },
        ),
        _actionCard(
          icon: Icons.account_balance_wallet_rounded,
          title: 'Expense Tracker',
          subtitle: 'Track daily expenses',
          color: const Color(0xFF8B5CF6),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExpenseTrackerScreen()),
            );
          },
        ),
        _actionCard(
          icon: Icons.psychology_rounded,
          title: 'AI Advisor',
          subtitle: 'Smart debt payoff plan',
          color: const Color(0xFF10B981),
          onTap: () {
            final storageService = LoanStorageService();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => AiAdvisorScreen(
                  loans: storageService.getAllLoans(),
                ),
              ),
            );
          },
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLoanDetailById(due.loanId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
        ),
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

  Future<void> _openLoanDetailById(String loanId) async {
    if (!Hive.isBoxOpen('p2p_loans')) return;
    final box = Hive.box<P2PLoan>('p2p_loans');
    final loan = box.values.firstWhere(
      (l) => l.id == loanId,
      orElse: () => P2PLoan(
        id: '',
        personName: '',
        amount: 0,
        isLent: true,
        date: DateTime.now(),
      ),
    );

    if (loan.id.isNotEmpty) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => P2PLoanDetailScreen(
            loan: loan,
            notificationService: widget.notificationService,
          ),
        ),
      );
      if (mounted) setState(() {});
    }
  }

  Widget _historyTile(P2PPaymentRecord record) {
    final isInterest = record.type == P2PPaymentType.interest;
    final accent = isInterest ? AppTheme.statusSuccess : AppTheme.primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openLoanDetailById(record.loanId),
        borderRadius: BorderRadius.circular(16),
        child: Container(
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
        ),
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

  void _openSettings() {
    final storageService = LoanStorageService();
    final backupService = BackupService(storageService);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          storageService: storageService,
          backupService: backupService,
          notificationService: widget.notificationService,
          onDataChanged: () => setState(() {}),
        ),
      ),
    );
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

  Widget _buildWelcomeGuideCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to LoanLedger 👋',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E1B4B),
                      ),
                    ),
                    Text(
                      'Smart loan tracking & payment reminders',
                      style: TextStyle(fontSize: 12, color: Color(0xFF4338CA)),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF6366F1)),
                onPressed: _dismissWelcomeGuide,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'LoanLedger is your personal digital loan notebook. Track money lent to or borrowed from friends & family, compute interest, and send instant WhatsApp payment reminders.',
            style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF312E81)),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {
                  _dismissWelcomeGuide();
                  _openP2PTracker();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4F46E5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.menu_book_rounded, size: 18),
                label: const Text(
                  'Explore LoanBook',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 10),
              TextButton(
                onPressed: _dismissWelcomeGuide,
                child: const Text('Dismiss', style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedLoanBookCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: _openP2PTracker,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_book_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Digital LoanBook',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: AppTheme.textDark,
                                ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEEF2FF),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'CORE',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Track personal loans, interest & WhatsApp reminders',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.25,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Open',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ],
            ),
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










