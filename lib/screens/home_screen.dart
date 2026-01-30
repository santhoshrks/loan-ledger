import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:app_settings/app_settings.dart';
import '../models/loan.dart';
import '../services/loan_storage_service.dart';
import '../services/notification_service.dart';
import '../services/backup_service.dart';
import '../widgets/loan_card.dart';
import '../theme/app_theme.dart';
import 'add_loan_screen.dart';
import 'calendar_screen.dart';
import 'emi_calculator_screen.dart';
import 'emi_progress_screen.dart';

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

  // Filter & Sort options
  String _sortBy = 'dueDate'; // dueDate, name, amount
  bool _showPaidOnly = false;
  bool _showUnpaidOnly = false;

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
        setState(() {
          _isInitialized = true;
        });
        _fabAnimationController.forward();
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
    _fabAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return _buildErrorScreen();
    }

    if (!_isInitialized) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Modern App Bar
            SliverToBoxAdapter(
              child: _buildHeader(),
            ),
            // Dashboard Summary
            SliverToBoxAdapter(
              child: _buildDashboard(),
            ),
            // Loans List Header
            SliverToBoxAdapter(
              child: _buildLoansHeader(),
            ),
            // Loans List
            _buildLoansList(),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimationController,
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToAddLoan(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Loan'),
          elevation: 4,
        ),
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                shape: BoxShape.circle,
                boxShadow: AppTheme.elevatedShadow,
              ),
              child: const Icon(
                Icons.account_balance_wallet_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Smart EMI',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Loading your loans...',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textMedium,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: Center(
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
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          // Left side - Menu button
          Container(
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.softShadow,
            ),
            child: PopupMenuButton<String>(
              icon: const Icon(Icons.menu_rounded, color: AppTheme.textDark, size: 22),
              padding: const EdgeInsets.all(10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              offset: const Offset(0, 50),
              onSelected: (value) {
                switch (value) {
                  case 'calendar':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarScreen(
                          storageService: _storageService,
                        ),
                      ),
                    );
                    break;
                  case 'calculator':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EMICalculatorScreen(),
                      ),
                    );
                    break;
                  case 'progress':
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EMIProgressScreen(
                          storageService: _storageService,
                        ),
                      ),
                    );
                    break;
                  case 'settings':
                    _showNotificationSettings();
                    break;
                  case 'backup':
                    _exportBackup();
                    break;
                  case 'restore':
                    _importBackup();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'calendar',
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Text('EMI Calendar'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'calculator',
                  child: Row(
                    children: [
                      Icon(Icons.calculate_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Text('EMI Calculator'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'progress',
                  child: Row(
                    children: [
                      Icon(Icons.trending_up_rounded, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      const Text('Loan Progress'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'backup',
                  child: Row(
                    children: [
                      Icon(Icons.backup_rounded, color: AppTheme.statusSuccess),
                      const SizedBox(width: 12),
                      const Text('Backup Data'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'restore',
                  child: Row(
                    children: [
                      Icon(Icons.restore_rounded, color: AppTheme.statusInfo),
                      const SizedBox(width: 12),
                      const Text('Restore Data'),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded, color: AppTheme.textMedium),
                      const SizedBox(width: 12),
                      const Text('Settings'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Center - App title and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textMedium,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Smart EMI',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                    letterSpacing: -0.5,
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: AppTheme.primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('EEE, MMM d, yyyy').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 11,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Right side - Notification button
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
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

  Widget _buildDashboard() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Loan>('loans').listenable(),
      builder: (context, Box<Loan> box, _) {
        final loans = box.values.toList();

        final totalEmi = loans.fold<double>(0, (sum, loan) => sum + loan.emiAmount);
        final dueSoon = loans.where((l) => !l.isPaid && l.daysUntilDue() <= 3).length;
        final paidThisMonth = loans.where((l) => l.isPaid).length;

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Monthly Overview',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          DateFormat('MMMM yyyy').format(DateTime.now()),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '₹${NumberFormat('#,##,###').format(totalEmi)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const Text(
                    'Total Monthly EMI',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildStatCard(
                        icon: Icons.receipt_long_rounded,
                        value: '${loans.length}',
                        label: 'Total Loans',
                        color: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.warning_rounded,
                        value: '$dueSoon',
                        label: 'Due Soon',
                        color: dueSoon > 0 ? AppTheme.accentOrange : Colors.white,
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        icon: Icons.check_circle_rounded,
                        value: '$paidThisMonth',
                        label: 'Paid',
                        color: AppTheme.statusSuccess,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoansHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Your Loans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          TextButton.icon(
            onPressed: () => _showFilterOptions(),
            icon: const Icon(Icons.filter_list_rounded, size: 20),
            label: const Text('Filter'),
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
        builder: (context, setModalState) => Container(
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
                  const Text(
                    'Sort & Filter',
                    style: TextStyle(
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
                    child: const Text('Reset'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Sort Options - Horizontal scroll chips
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'SORT BY',
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
                  _buildSortOption('Due Date', 'dueDate', Icons.event_rounded, setModalState),
                  const SizedBox(width: 10),
                  _buildSortOption('Name', 'name', Icons.sort_by_alpha_rounded, setModalState),
                  const SizedBox(width: 10),
                  _buildSortOption('Amount', 'amount', Icons.attach_money_rounded, setModalState),
                ],
              ),
              const SizedBox(height: 24),

              // Filter Options - Simple toggle buttons
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'FILTER BY STATUS',
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
                      'All',
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
                      'Unpaid',
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
                      'Paid',
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
                      label: const Text('Calendar'),
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
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildLoansList() {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Loan>('loans').listenable(),
      builder: (context, Box<Loan> box, _) {
        var loans = box.values.toList();

        if (loans.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          );
        }

        // Apply filters
        if (_showPaidOnly) {
          loans = loans.where((loan) => loan.isPaid).toList();
        } else if (_showUnpaidOnly) {
          loans = loans.where((loan) => !loan.isPaid).toList();
        }

        // Apply sorting
        switch (_sortBy) {
          case 'dueDate':
            loans.sort((a, b) => a.daysUntilDue().compareTo(b.daysUntilDue()));
            break;
          case 'name':
            loans.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            break;
          case 'amount':
            loans.sort((a, b) => b.emiAmount.compareTo(a.emiAmount)); // Highest first
            break;
        }

        // Show message if filters result in no loans
        if (loans.isEmpty) {
          return SliverFillRemaining(
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
                    'No loans match your filter',
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
                    child: const Text('Clear Filters'),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.only(bottom: 100),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final loan = loans[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: LoanCard(
                    loan: loan,
                    onTap: () => _showLoanOptions(context, loan),
                    onDelete: () => _deleteLoan(loan),
                    onMarkPaid: () => _markLoanPaid(loan),
                    onMarkUnpaid: () => _markLoanUnpaid(loan),
                  ),
                );
              },
              childCount: loans.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryColor.withValues(alpha: 0.1),
                  AppTheme.secondaryColor.withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.account_balance_wallet_outlined,
              size: 64,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'No loans yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add your first loan to start tracking\nyour EMI payments',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: AppTheme.textMedium,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _navigateToAddLoan(context),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Your First Loan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
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

    if (result != null && mounted) {
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
              title: 'Edit Loan',
              subtitle: 'Modify loan details',
              onTap: () {
                Navigator.pop(context);
                _editLoan(context, loan);
              },
            ),
            if (!loan.isPaid)
              _buildActionTile(
                icon: Icons.check_circle_rounded,
                title: 'Mark as Paid',
                subtitle: 'Record this month\'s payment',
                color: AppTheme.statusSuccess,
                onTap: () {
                  Navigator.pop(context);
                  _markLoanPaid(loan);
                },
              ),
            _buildActionTile(
              icon: Icons.notifications_rounded,
              title: 'Test Notification',
              subtitle: 'Send a test reminder',
              color: AppTheme.statusInfo,
              onTap: () async {
                Navigator.pop(context);
                await _notificationService.scheduleLoadReminders(loan, testMode: true);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Test notification sent!'),
                      duration: Duration(seconds: 3),
                    ),
                  );
                }
              },
            ),
            _buildActionTile(
              icon: Icons.delete_rounded,
              title: 'Delete Loan',
              subtitle: 'Remove this loan permanently',
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
    debugPrint('Before: isPaid = ${loan.isPaid}');

    // Mark as paid and save directly (Loan extends HiveObject)
    loan.isPaid = true;
    debugPrint('After setting: isPaid = ${loan.isPaid}');

    await loan.save();
    debugPrint('After save: isPaid = ${loan.isPaid}');
    debugPrint('loan.isInBox = ${loan.isInBox}');

    // Cancel current month's notifications
    await _notificationService.cancelLoanReminders(
      loan.id,
      tenureMonths: loan.tenureMonths ?? 60,
    );

    // Schedule notifications for next month's due date
    // The loan stays marked as paid, but notifications are scheduled for next month
    await _notificationService.scheduleLoadReminders(loan);

    _showSuccessSnackBar('${loan.name} marked as paid!');
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
                    const Text(
                      '🔔 Notification Settings',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ensure you receive EMI reminders even when app is closed',
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
                      'Settings → Apps → Smart EMI → Battery → Unrestricted',
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
}
