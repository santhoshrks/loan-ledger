import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:app_settings/app_settings.dart';
import 'package:provider/provider.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/loan.dart';
import '../services/loan_storage_service.dart';
import '../services/notification_service.dart';
import '../services/language_provider.dart';
import '../services/backup_service.dart';
import '../services/backup_reminder_service.dart';
import '../widgets/loan_card.dart';
import '../widgets/empty_loans_state.dart';
import '../widgets/loan_completion_celebration.dart';
import '../widgets/skeleton_loading.dart';
import '../services/pdf_export_service.dart';
import '../services/haptic_service.dart';
import '../services/share_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';
import '../utils/indian_number_format.dart';
import 'add_loan_screen.dart';
import 'calendar_screen.dart';
import 'emi_calculator_screen.dart';
import 'emi_progress_screen.dart';
import 'settings_screen.dart';
import 'debt_dashboard_screen.dart';
import 'amortization_screen.dart';
import 'prepayment_calculator_screen.dart';
import 'tax_benefit_screen.dart';
import 'floating_rate_screen.dart';
import 'balance_transfer_screen.dart';
import 'emi_vs_rent_screen.dart';
import 'financial_health_screen.dart';
import 'consolidation_planner_screen.dart';
import 'yearly_summary_screen.dart';
import 'ai_advisor_screen.dart';
import 'savings_goal_screen.dart';
import 'p2p_loan_screen.dart';
import 'expense_tracker_screen.dart';


class HomeScreen extends StatefulWidget {
  final LoanStorageService? storageService;
  final NotificationService? notificationService;

  const HomeScreen({
    super.key,
    this.storageService,
    this.notificationService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late LoanStorageService _storageService;
  late NotificationService _notificationService;
  late BackupService _backupService;
  late AnimationController _fabAnimationController;
  bool _isInitialized = false;
  String? _initError;

  // Loan data
  List<Loan> _loans = [];

  // Filter & Sort options
  String _sortBy = 'dueDate'; // dueDate, name, amount
  bool _showPaidOnly = false;
  bool _showUnpaidOnly = false;

  void _onLoansChanged() {
    if (mounted) {
      setState(() {
        _loans = Hive.box<Loan>('loans').values.toList();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      if (widget.storageService != null) {
        _storageService = widget.storageService!;
      } else {
        _storageService = LoanStorageService();
        await _storageService.init();
      }

      if (widget.notificationService != null) {
        _notificationService = widget.notificationService!;
      } else {
        _notificationService = NotificationService();
        await _notificationService.init();
      }

      // Initialize backup service
      _backupService = BackupService(_storageService);

      if (mounted) {
        // Load initial loans and start listening for changes
        final box = Hive.box<Loan>('loans');
        _loans = box.values.toList();
        box.listenable().addListener(_onLoansChanged);

        setState(() {
          _isInitialized = true;
        });
        _fabAnimationController.forward();

        // Schedule monthly summary notification
        if (_loans.isNotEmpty) {
          _notificationService.scheduleMonthSummaryNotification(_loans);
        }

        // Check if backup reminder should be shown
        _checkBackupReminder();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _initError = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    if (_isInitialized) {
      Hive.box<Loan>('loans').listenable().removeListener(_onLoansChanged);
    }
    _fabAnimationController.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    if (_initError != null) {
      return _buildErrorBody();
    }
    if (!_isInitialized) {
      return _buildLoadingBody();
    }
    return CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: const SizedBox(height: 16)),
          SliverToBoxAdapter(child: _buildDashboard(_loans)),
          SliverToBoxAdapter(child: _buildQuickActions()),
          SliverToBoxAdapter(child: _buildLoansHeader()),
          ..._buildLoansList(_loans),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: _buildBody(),
      floatingActionButton: (_isInitialized && _initError == null)
          ? ScaleTransition(
              scale: _fabAnimationController,
              child: FloatingActionButton.extended(
                onPressed: () {
                  HapticService.medium();
                  _navigateToAddLoan(context);
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(AppLocalizations.of(context).addLoan),
                elevation: 4,
              ),
            )
          : null,
    );
  }

  Widget _buildLoadingBody() {
    return const SkeletonHomeScreen();
  }

  Widget _buildErrorBody() {
    return Center(
      child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.statusError.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 48,
                  color: AppTheme.statusError,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Oops! Something went wrong',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _initError ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textMedium,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _initError = null;
                    _isInitialized = false;
                  });
                  _initializeServices();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: Text(AppLocalizations.of(context).ok),
              ),
            ],
          ),
        ),
      );
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withBlue(220),
          ],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 52, 20, 20),
      child: Row(
        children: [
          // Left side - Menu button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
              padding: const EdgeInsets.all(10),
              onPressed: () {
                HapticService.light();
                _showAppMenu();
              },
            ),
          ),
          const SizedBox(width: 14),
          // Center - App title and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getGreeting(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'EMI Reminder',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, size: 11, color: Colors.white60),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, MMM d').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white60,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Right side - Notification button
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.notifications_rounded, color: Colors.white, size: 22),
              onPressed: () => _testNotification(),
              padding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 👋';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }

  Widget _buildDashboard(List<Loan> loans) {
    final totalEmi = loans.fold<double>(0, (sum, loan) => sum + loan.emiAmount);
    final dueSoon = loans.where((l) => !l.isPaid && l.daysUntilDue() <= 3).length;
    final paidThisMonth = loans.where((l) => l.isPaid).length;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).monthlyOverview,
                style: TextStyle(
                  color: AppTheme.textMedium,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  DateFormat('MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            IndianNumberFormat.formatCompact(totalEmi),
            style: const TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -1,
            ),
          ),
          Text(
            AppLocalizations.of(context).totalMonthlyEmi,
            style: TextStyle(color: AppTheme.textMedium, fontSize: 12),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatPill(
                icon: Icons.receipt_long_rounded,
                value: '${loans.length}',
                label: AppLocalizations.of(context).totalLoans,
                color: AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              _buildStatPill(
                icon: Icons.warning_amber_rounded,
                value: '$dueSoon',
                label: AppLocalizations.of(context).dueSoon,
                color: dueSoon > 0 ? const Color(0xFFF59E0B) : AppTheme.primaryColor,
              ),
              const SizedBox(width: 10),
              _buildStatPill(
                icon: Icons.check_circle_rounded,
                value: '$paidThisMonth',
                label: AppLocalizations.of(context).paid,
                color: const Color(0xFF10B981),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 7),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(color: AppTheme.textMedium, fontSize: 9.5),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showAppMenu() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF4F6FA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    child: Row(
                      children: [
                        const Text(
                          'All Features',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 18, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      children: [
                        _menuSection(ctx, 'Tools', [
                          _MenuItem(Icons.calculate_rounded, AppLocalizations.of(context).emiCalculator, const Color(0xFF0EA5E9),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EMICalculatorScreen()))),
                          _MenuItem(Icons.trending_up_rounded, AppLocalizations.of(context).progress, const Color(0xFF10B981),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => EMIProgressScreen(storageService: _storageService)))),
                        ]),
                        const SizedBox(height: 20),
                        _menuSection(ctx, 'Analytics', [
                          _MenuItem(Icons.dashboard_rounded, 'Debt Dashboard', const Color(0xFF3B82F6),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => DebtDashboardScreen(loans: _storageService.getAllLoans())))),
                          _MenuItem(Icons.bar_chart_rounded, 'Yearly Summary', const Color(0xFFF59E0B),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => YearlySummaryScreen(loans: _storageService.getAllLoans())))),
                          _MenuItem(Icons.psychology_rounded, 'AI Advisor', const Color(0xFF8B5CF6),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => AiAdvisorScreen(loans: _storageService.getAllLoans())))),
                        ]),
                        const SizedBox(height: 20),
                        _menuSection(ctx, 'Calculators', [
                          _MenuItem(Icons.payments_rounded, 'Prepayment', const Color(0xFFEF4444),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrepaymentCalculatorScreen()))),
                          _MenuItem(Icons.compare_arrows_rounded, 'Balance Transfer', const Color(0xFFF97316),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BalanceTransferScreen()))),
                          _MenuItem(Icons.home_work_rounded, 'EMI vs Rent', const Color(0xFF0EA5E9),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EmiVsRentScreen()))),
                          _MenuItem(Icons.account_balance_rounded, 'Debt Payoff', const Color(0xFF6366F1),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => ConsolidationPlannerScreen(loans: _storageService.getAllLoans())))),
                          _MenuItem(Icons.receipt_long_rounded, 'Tax Summary', const Color(0xFF8B5CF6),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => TaxBenefitScreen(loans: _storageService.getAllLoans())))),
                        ]),
                        const SizedBox(height: 20),
                        _menuSection(ctx, 'Trackers', [
                          _MenuItem(Icons.account_balance_wallet_rounded, 'Expenses', const Color(0xFFF97316),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseTrackerScreen()))),
                          _MenuItem(Icons.savings_rounded, 'Savings Goals', const Color(0xFF10B981),
                              () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavingsGoalScreen(loans: _storageService.getAllLoans())))),
                        ]),
                        const SizedBox(height: 20),
                        // Settings row
                        Row(
                          children: [
                            Expanded(child: _menuTileWide(ctx, Icons.backup_rounded, 'Backup', const Color(0xFF10B981), _exportBackup)),
                            const SizedBox(width: 10),
                            Expanded(child: _menuTileWide(ctx, Icons.restore_rounded, 'Restore', const Color(0xFF3B82F6), _importBackup)),
                            const SizedBox(width: 10),
                            Expanded(child: _menuTileWide(ctx, Icons.settings_rounded, 'Settings', const Color(0xFF6B7280), _showSettingsMenu)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        // Share row
                        Row(
                          children: [
                            Expanded(child: _menuTileWide(ctx, Icons.share_rounded, 'Share App', const Color(0xFF6366F1), () {
                              HapticService.light();
                              ShareService.shareApp();
                            })),
                            const SizedBox(width: 10),
                            Expanded(child: _menuTileWide(ctx, Icons.summarize_rounded, 'Share Summary', const Color(0xFF10B981), () {
                              HapticService.light();
                              ShareService.shareMonthlyOverview(_storageService.getAllLoans());
                            })),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _menuSection(BuildContext ctx, String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF9CA3AF),
              letterSpacing: 1.2,
            ),
          ),
        ),
        GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.05,
          children: items.map((item) => _menuGridTile(ctx, item)).toList(),
        ),
      ],
    );
  }

  Widget _menuGridTile(BuildContext ctx, _MenuItem item) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        Navigator.pop(ctx);
        item.onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: item.color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    item.color.withValues(alpha: 0.18),
                    item.color.withValues(alpha: 0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(item.icon, color: item.color, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuTileWide(BuildContext ctx, IconData icon, String label, Color color, VoidCallback action) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(ctx);
        action();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(Icons.calculate_rounded, 'Calculator', const Color(0xFF6366F1),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EMICalculatorScreen()))),
      _QuickAction(Icons.trending_up_rounded, 'Progress', const Color(0xFF10B981),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => EMIProgressScreen(storageService: _storageService)))),
      _QuickAction(Icons.dashboard_rounded, 'Dashboard', const Color(0xFFF59E0B),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => DebtDashboardScreen(loans: _storageService.getAllLoans())))),
      _QuickAction(Icons.payments_rounded, 'Prepay', const Color(0xFFEF4444),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrepaymentCalculatorScreen()))),
      _QuickAction(Icons.account_balance_wallet_rounded, 'Expenses', const Color(0xFFF97316),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseTrackerScreen()))),
      _QuickAction(Icons.people_rounded, 'P2P', const Color(0xFF3B82F6),
          () => Navigator.push(context, MaterialPageRoute(builder: (_) => const P2PLoanScreen()))),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: SizedBox(
        height: 86,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: actions.length,
          itemBuilder: (context, i) {
            final a = actions[i];
            return GestureDetector(
              onTap: a.onTap,
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 70,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: a.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: a.color.withValues(alpha: 0.2), width: 1),
                      ),
                      child: Icon(a.icon, color: a.color, size: 24),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoansHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context).yourLoans,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          Row(
            children: [
              if (_loans.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    HapticService.light();
                    PdfExportService.exportLoansSummary(
                      context: context,
                      loans: _loans,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.picture_as_pdf_rounded, size: 14, color: Color(0xFFEF4444)),
                        SizedBox(width: 4),
                        Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                ),
              TextButton.icon(
                onPressed: () {
                  HapticService.light();
                  _showFilterOptions();
                },
                icon: const Icon(Icons.tune_rounded, size: 16),
                label: Text(AppLocalizations.of(context).filter,
                    style: const TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.07),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final l = AppLocalizations.of(context);
          return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Title Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l.sortAndFilter,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setModalState(() {
                        _sortBy = 'dueDate';
                        _showPaidOnly = false;
                        _showUnpaidOnly = false;
                      });
                      setState(() {});
                    },
                    child: Text(l.reset),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sort Options - Horizontal scroll chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.sortBy,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSortOption(l.dueDate, 'dueDate', Icons.event_rounded, setModalState),
                  const SizedBox(width: 10),
                  _buildSortOption(l.name, 'name', Icons.sort_by_alpha_rounded, setModalState),
                  const SizedBox(width: 10),
                  _buildSortOption(l.amount, 'amount', Icons.attach_money_rounded, setModalState),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Options - Simple toggle buttons
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l.filterByStatus,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textMedium,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildFilterOption(
                      l.all,
                      !_showPaidOnly && !_showUnpaidOnly,
                      Icons.list_rounded,
                      () {
                        setModalState(() {
                          _showPaidOnly = false;
                          _showUnpaidOnly = false;
                        });
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterOption(
                      l.unpaid,
                      _showUnpaidOnly,
                      Icons.schedule_rounded,
                      () {
                        setModalState(() {
                          _showUnpaidOnly = true;
                          _showPaidOnly = false;
                        });
                        setState(() {});
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildFilterOption(
                      l.paid,
                      _showPaidOnly,
                      Icons.check_circle_rounded,
                      () {
                        setModalState(() {
                          _showPaidOnly = true;
                          _showUnpaidOnly = false;
                        });
                        setState(() {});
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CalendarScreen(
                              storageService: _storageService,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(l.calendar),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(l.done),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
        },
      ),
    );
  }

  Widget _buildSortOption(String label, String value, IconData icon, StateSetter setModalState) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setModalState(() => _sortBy = value);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textMedium,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, bool isSelected, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.bgLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textMedium,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryColor : AppTheme.textDark,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildLoansList(List<Loan> loans) {
        if (loans.isEmpty) {
          return [SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )];
        }

        // Apply filters
        var filtered = loans.toList();
        if (_showPaidOnly) {
          filtered = filtered.where((loan) => loan.isPaid).toList();
        } else if (_showUnpaidOnly) {
          filtered = filtered.where((loan) => !loan.isPaid).toList();
        }

        // Apply sorting
        switch (_sortBy) {
          case 'dueDate':
            filtered.sort((a, b) => a.daysUntilDue().compareTo(b.daysUntilDue()));
            break;
          case 'name':
            filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            break;
          case 'amount':
            filtered.sort((a, b) => b.emiAmount.compareTo(a.emiAmount));
            break;
        }

        // Show message if filters result in no loans
        if (filtered.isEmpty) {
          return [SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_list_off_rounded,
                    size: 64,
                    color: AppTheme.textLight,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).noLoansMatchFilter,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _showPaidOnly = false;
                        _showUnpaidOnly = false;
                      });
                    },
                    child: Text(AppLocalizations.of(context).clearFilters),
                  ),
                ],
              ),
            ),
          )];
        }

        return [SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final loan = filtered[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: LoanCard(
                    loan: loan,
                    onTap: () => _showLoanOptions(context, loan),
                    onDelete: () => _deleteLoan(loan),
                    onMarkPaid: () => _markLoanPaid(loan),
                    onMarkUnpaid: () => _markLoanUnpaid(loan),
                    onShare: () {
                      HapticService.light();
                      ShareService.shareLoanSummary(loan);
                    },
                  ),
                );
              },
              childCount: filtered.length,
            ),
          ),
        )];
  }

  Widget _buildEmptyState() {
    return EmptyLoansState(onAddLoan: () => _navigateToAddLoan(context));
  }

  Future<void> _navigateToAddLoan(BuildContext context) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AddLoanScreen(
          storageService: _storageService,
          notificationService: _notificationService,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    );

    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Loan added successfully!'),
            ],
          ),
          backgroundColor: AppTheme.statusSuccess,
        ),
      );
    }
  }

  void _showLoanOptions(BuildContext context, Loan loan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          loan.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${loan.currencySymbol}${NumberFormat('#,##,###').format(loan.emiAmount)} / month',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildActionTile(
              icon: Icons.edit_rounded,
              title: AppLocalizations.of(context).editLoan,
              subtitle: AppLocalizations.of(context).modifyLoanDetails,
              onTap: () {
                Navigator.pop(context);
                _editLoan(context, loan);
              },
            ),
            if (loan.loanAmount != null && loan.interestRate != null && loan.tenureMonths != null) ...[
              _buildActionTile(
                icon: Icons.table_chart_rounded,
                title: 'Amortization Schedule',
                subtitle: 'Month-by-month principal vs interest',
                color: AppTheme.primaryColor,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => AmortizationScreen(loan: loan)));
                },
              ),
              _buildActionTile(
                icon: Icons.savings_rounded,
                title: 'Prepayment Calculator',
                subtitle: 'See how much interest you save',
                color: AppTheme.secondaryColor,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => PrepaymentCalculatorScreen(loan: loan)));
                },
              ),
              _buildActionTile(
                icon: Icons.trending_up_rounded,
                title: 'Floating Rate Tracker',
                subtitle: 'Track variable / floating rate changes',
                color: AppTheme.accentOrange,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(
                      builder: (_) => FloatingRateScreen(
                          loan: loan, storageService: _storageService)));
                },
              ),
            ],
            if (!loan.isPaid)
              _buildActionTile(
                icon: Icons.check_circle_rounded,
                title: AppLocalizations.of(context).markPaid,
                subtitle: AppLocalizations.of(context).recordThisMonthsPayment,
                color: AppTheme.statusSuccess,
                onTap: () {
                  Navigator.pop(context);
                  _markLoanPaid(loan);
                },
              ),
            _buildActionTile(
              icon: Icons.notifications_rounded,
              title: AppLocalizations.of(context).testNotification,
              subtitle: AppLocalizations.of(context).sendTestReminder,
              color: AppTheme.statusInfo,
              onTap: () async {
                Navigator.pop(context);
                await _notificationService.scheduleLoadReminders(loan, testMode: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(AppLocalizations.of(context).testNotificationSent),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            _buildActionTile(
              icon: Icons.delete_rounded,
              title: AppLocalizations.of(context).deleteLoan,
              subtitle: AppLocalizations.of(context).removeThisLoanPermanently,
              color: AppTheme.statusError,
              onTap: () {
                Navigator.pop(context);
                _deleteLoan(loan);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, Color color) {
    return Row(children: [
      Icon(icon, color: color, size: 20),
      const SizedBox(width: 12),
      Text(label, style: const TextStyle(fontSize: 14)),
    ]);
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.primaryColor).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color ?? AppTheme.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: color ?? AppTheme.textDark,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 16,
        color: AppTheme.textLight,
      ),
    );
  }

  Future<void> _editLoan(BuildContext context, Loan loan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLoanScreen(
          storageService: _storageService,
          notificationService: _notificationService,
          existingLoan: loan,
        ),
      ),
    );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Loan updated successfully!'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _markLoanPaid(Loan loan) async {
    debugPrint('=== MARKING LOAN AS PAID ===');
    debugPrint('Loan: ${loan.name}');
    debugPrint('Before: isPaid = ${loan.isPaid}, emisPaidCount = ${loan.emisPaidCount}');

    // Mark as paid AND increment the paid count
    loan.isPaid = true;
    loan.emisPaidCount = loan.emisPaidCount + 1;

    // Clamp to tenure if known
    if (loan.tenureMonths != null && loan.emisPaidCount > loan.tenureMonths!) {
      loan.emisPaidCount = loan.tenureMonths!;
    }

    debugPrint('After setting: isPaid = ${loan.isPaid}, emisPaidCount = ${loan.emisPaidCount}');

    await loan.save();
    debugPrint('After save: isPaid = ${loan.isPaid}, emisPaidCount = ${loan.emisPaidCount}');

    // Cancel current month's notifications
    await _notificationService.cancelLoanReminders(
      loan.id,
      tenureMonths: loan.tenureMonths ?? 60,
    );

    // Schedule notifications for next month's due date
    // The loan stays marked as paid, but notifications are scheduled for next month
    await _notificationService.scheduleLoadReminders(loan);

    // Check if this was the FINAL EMI — trigger celebration 🎉
    final isFullyComplete = loan.tenureMonths != null &&
        loan.emisPaidCount >= loan.tenureMonths!;

    if (isFullyComplete && mounted) {
      await HapticService.celebrate();
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) {
        showLoanCompletionCelebration(
          context: context,
          loanName: loan.name,
          totalPaid: loan.emiAmount * loan.tenureMonths!,
          currencySymbol: loan.currencySymbol,
          tenureMonths: loan.tenureMonths!,
        );
      }
    } else {
      await HapticService.success();
      _showSuccessSnackBar('${loan.name} marked as paid!');
    }
    _maybeRequestReview();
  }

  Future<void> _maybeRequestReview() async {
    try {
      final prefs = await _getPrefs();
      final paidCount = (prefs.getInt('loans_paid_count') ?? 0) + 1;
      await prefs.setInt('loans_paid_count', paidCount);

      // Ask for review after 3rd payment marked — feels natural, not too early
      if (paidCount == 3 || paidCount == 10) {
        final inAppReview = InAppReview.instance;
        if (await inAppReview.isAvailable()) {
          await Future.delayed(const Duration(milliseconds: 800));
          await inAppReview.requestReview();
        }
      }
    } catch (_) {}
  }

  Future<dynamic> _getPrefs() async {
    return await SharedPreferences.getInstance();
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.statusSuccess,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

  Future<void> _markLoanUnpaid(Loan loan) async {
    // Revert: decrement emisPaidCount only if it was incremented (isPaid was true)
    if (loan.isPaid && loan.emisPaidCount > 0) {
      loan.emisPaidCount = loan.emisPaidCount - 1;
    }
    loan.isPaid = false;
    await loan.save();
    await _notificationService.scheduleLoadReminders(loan);

    _showSuccessSnackBar('${loan.name} marked as unpaid.');
  }

  Future<void> _deleteLoan(Loan loan) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Delete Loan?'),
        content: Text(
          'Are you sure you want to delete "${loan.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.statusError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      // Store loan data for potential undo
      final deletedLoan = Loan(
        id: loan.id,
        name: loan.name,
        emiAmount: loan.emiAmount,
        dueDay: loan.dueDay,
        startDate: loan.startDate,
        notes: loan.notes,
        loanAmount: loan.loanAmount,
        interestRate: loan.interestRate,
        tenureMonths: loan.tenureMonths,
        isPaid: loan.isPaid,
        currencyCode: loan.currencyCode,
        emisPaidCount: loan.emisPaidCount,
      );

      await _storageService.deleteLoan(loan.id);
      await _notificationService.cancelLoanReminders(
        loan.id,
        tenureMonths: loan.tenureMonths ?? 60,
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text('${deletedLoan.name} deleted!')),
              ],
            ),
            backgroundColor: AppTheme.textDark,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: AppTheme.accentOrange,
              onPressed: () async {
                await _storageService.addLoan(deletedLoan);
                await _notificationService.scheduleLoadReminders(deletedLoan);
                if (mounted) {
                  setState(() {});
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _testNotification() async {
    await _notificationService.showTestNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test notification sent! Check your notification panel.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _showNotificationSettings() async {
    final permissions = await _notificationService.checkAllPermissions();
    final pendingCount = await _notificationService.getPendingNotificationsCount();

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.textLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).padding.bottom + 24,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🔔 ${AppLocalizations.of(context).notificationSettings}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context).ensureYouReceiveReminders,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textMedium,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Loan Count Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded, color: AppTheme.primaryColor),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have ${_storageService.getLoansCount()} loans. '
                              'Today is ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Permission Status
                    _buildSettingItem(
                      icon: Icons.notifications_active_rounded,
                      title: 'Notifications',
                      subtitle: permissions['notificationsEnabled'] == true
                          ? 'Enabled'
                          : 'Disabled - Tap to enable',
                      isEnabled: permissions['notificationsEnabled'] == true,
                      onTap: () => _openAppSettings(),
                    ),
                    _buildSettingItem(
                      icon: Icons.alarm_rounded,
                      title: 'Exact Alarms',
                      subtitle: permissions['exactAlarms'] == true
                          ? 'Enabled'
                          : 'Disabled - Required for precise reminders',
                      isEnabled: permissions['exactAlarms'] == true,
                      onTap: () => _openAppSettings(),
                    ),
                    _buildSettingItem(
                      icon: Icons.schedule_rounded,
                      title: 'Pending Reminders',
                      subtitle: '$pendingCount notifications scheduled',
                      isEnabled: pendingCount > 0,
                      onTap: () => _showPendingReminders(),
                    ),

                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Important Instructions
                    const Text(
                      '⚠️ Important for Background Notifications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInstructionItem(
                      '1',
                      'Disable Battery Optimization',
                      'Settings → Apps → EMI Reminder → Battery → Unrestricted',
                    ),
                    _buildInstructionItem(
                      '2',
                      'Allow Auto-start (Chinese phones)',
                      'For Xiaomi/Redmi/OPPO/Vivo/Realme: Enable auto-start',
                    ),
                    _buildInstructionItem(
                      '3',
                      'Lock App in Recent Apps',
                      'Swipe down on EMI Reminder to lock it',
                    ),

                    const SizedBox(height: 24),

                    // Reschedule All Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _rescheduleAllNotifications();
                        },
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Reschedule All Reminders'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: AppTheme.statusSuccess,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Open Settings Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _openAppSettings();
                        },
                        icon: const Icon(Icons.settings_rounded),
                        label: const Text('Open App Settings'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Test Notification Button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _testNotification();
                        },
                        icon: const Icon(Icons.notifications_rounded),
                        label: const Text('Send Test Notification'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isEnabled
              ? AppTheme.statusSuccess.withValues(alpha: 0.1)
              : AppTheme.statusWarning.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isEnabled ? AppTheme.statusSuccess : AppTheme.statusWarning,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        isEnabled ? Icons.check_circle_rounded : Icons.warning_rounded,
        color: isEnabled ? AppTheme.statusSuccess : AppTheme.statusWarning,
      ),
    );
  }

  Widget _buildInstructionItem(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAppSettings() async {
    // Open the app settings page on Android
    await AppSettings.openAppSettings(type: AppSettingsType.notification);
  }

  Future<void> _rescheduleAllNotifications() async {
    // Show loading indicator
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 16),
            Text('Rescheduling all reminders...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      // Cancel all existing notifications first
      await _notificationService.cancelAllNotifications();

      // Get all loans and reschedule
      final loans = _storageService.getAllLoans();
      int scheduledLoans = 0;

      for (final loan in loans) {
        debugPrint('Scheduling for loan: ${loan.name}, Due day: ${loan.dueDay}');
        debugPrint('  Next due date: ${loan.getNextDueDate()}');
        await _notificationService.scheduleLoadReminders(loan);
        scheduledLoans++;
      }

      // Get updated pending count
      final pendingCount = await _notificationService.getPendingNotificationsCount();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Rescheduled reminders for $scheduledLoans loans. '
              '$pendingCount notifications pending.',
            ),
            backgroundColor: AppTheme.statusSuccess,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: AppTheme.statusError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showPendingReminders() async {
    final pendingNotifications = await _notificationService.getPendingNotifications();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.schedule_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 8),
            const Text('Scheduled Reminders'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: pendingNotifications.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No reminders scheduled',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add a loan to get EMI reminders',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: pendingNotifications.length > 20
                      ? 21
                      : pendingNotifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (index == 20) {
                      return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '+ ${pendingNotifications.length - 20} more reminders',
                          style: TextStyle(
                            color: AppTheme.textMedium,
                            fontStyle: FontStyle.italic,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }
                    final notification = pendingNotifications[index];
                    return ListTile(
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_active_rounded,
                          size: 18,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      title: Text(
                        notification.title ?? 'EMI Reminder',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        notification.body ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  /// Export backup of all loans
  Future<void> _exportBackup() async {
    try {
      final loans = _storageService.getAllLoans();

      if (loans.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No loans to backup'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Show options dialog
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.backup_rounded, color: Colors.green),
              SizedBox(width: 12),
              Text('Backup Data'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${loans.length} loan(s) will be backed up.'),
              const SizedBox(height: 16),
              const Text(
                'Choose how to save your backup:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context, 'save'),
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Save to Device'),
            ),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, 'share'),
              icon: const Icon(Icons.share_rounded),
              label: const Text('Share'),
            ),
          ],
        ),
      );

      if (choice == null) return;

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 16),
                Text('Creating backup...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      String? savedPath;
      if (choice == 'save') {
        savedPath = await _backupService.saveBackupToLocation();
      } else {
        savedPath = await _backupService.exportLoans();
      }

      // Record backup date
      await BackupReminderService.setLastBackupDate();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(savedPath != null
                ? '✅ Backup saved with ${loans.length} loans'
                : '✅ Backup created with ${loans.length} loans'),
            backgroundColor: AppTheme.statusSuccess,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Backup failed: $e'),
            backgroundColor: AppTheme.statusError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  /// Check if backup reminder should be shown
  Future<void> _checkBackupReminder() async {
    // Wait a bit for the UI to settle
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final loans = _storageService.getAllLoans();
    final shouldShow = await BackupReminderService.shouldShowReminder(loans.length);

    if (!shouldShow || !mounted) return;

    final l = AppLocalizations.of(context);
    final daysSinceBackup = await BackupReminderService.getDaysSinceBackup();
    final hasBackedUp = await BackupReminderService.hasEverBackedUp();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.backup_rounded, color: Colors.orange, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l.backupReminder,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l.backupReminderMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    hasBackedUp ? Icons.history : Icons.warning_rounded,
                    color: Colors.orange,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      hasBackedUp
                        ? '$daysSinceBackup ${l.lastBackupDaysAgo}'
                        : l.neverBackedUp,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${loans.length} ${l.loansStored}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              BackupReminderService.dismissReminder();
              Navigator.pop(context);
            },
            child: Text(l.later, style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _exportBackup();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(l.backupNow),
          ),
        ],
      ),
    );
  }

  /// Import backup from file
  Future<void> _importBackup() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.restore_rounded, color: Colors.blue),
            SizedBox(width: 8),
            Text('Restore Backup'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will import loans from a backup file.'),
            SizedBox(height: 12),
            Text(
              'Note: Imported loans will be added to your existing loans.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Select File'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 16),
              Text('Restoring backup...'),
            ],
          ),
          duration: Duration(seconds: 30),
        ),
      );

      final importedCount = await _backupService.importLoans();

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();

        if (importedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Restored $importedCount loans successfully'),
              backgroundColor: AppTheme.statusSuccess,
              duration: const Duration(seconds: 3),
            ),
          );
          setState(() {}); // Refresh the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No loans imported. Please select a valid backup file.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Restore failed: $e'),
            backgroundColor: AppTheme.statusError,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _showSettingsMenu() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          storageService: _storageService,
          backupService: _backupService,
          notificationService: _notificationService,
          onDataChanged: () => setState(() {}),
        ),
      ),
    );
  }

  Future<void> _showLanguageDialogDirect() async {
    showDialog(
      context: context,
      builder: (context) => Consumer<LanguageProvider>(
        builder: (context, languageProvider, _) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context).language),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildLanguageOption('en', 'English'),
                _buildLanguageOption('ta', 'தமிழ் (Tamil)'),
                _buildLanguageOption('te', 'తెలుగు (Telugu)'),
                _buildLanguageOption('hi', 'हिन्दी (Hindi)'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).cancel),
              ),
            ],
          );
        },
      ),
    );
  }


  Widget _buildLanguageOption(String code, String name) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final isSelected = languageProvider.currentLocale.languageCode == code;
        return ListTile(
          title: Text(name),
          trailing: isSelected
              ? const Icon(Icons.check_circle_rounded, color: Colors.green)
              : null,
          selected: isSelected,
          onTap: () {
            languageProvider.setLanguage(code);
            // Close the dialog after 500ms to allow the change to propagate
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                Navigator.pop(context);
              }
            });
          },
        );
      },
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickAction(this.icon, this.label, this.color, this.onTap);
}

class _MenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.color, this.onTap);
}

