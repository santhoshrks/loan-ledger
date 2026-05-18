import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/expense.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class ExpenseTrackerScreen extends StatefulWidget {
  const ExpenseTrackerScreen({super.key});

  @override
  State<ExpenseTrackerScreen> createState() => _ExpenseTrackerScreenState();
}

class _ExpenseTrackerScreenState extends State<ExpenseTrackerScreen>
    with SingleTickerProviderStateMixin {
  late Box<Expense> _box;
  late TabController _tabController;
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  String _filterType = 'all'; // all, debit, credit

  static const List<Map<String, dynamic>> categories = [
    {'name': 'Food & Dining',    'icon': Icons.restaurant_rounded,     'color': Color(0xFFEF4444)},
    {'name': 'Transport',        'icon': Icons.directions_car_rounded,  'color': Color(0xFF3B82F6)},
    {'name': 'Shopping',         'icon': Icons.shopping_bag_rounded,    'color': Color(0xFFF59E0B)},
    {'name': 'Bills & Utilities','icon': Icons.receipt_long_rounded,    'color': Color(0xFF8B5CF6)},
    {'name': 'Entertainment',    'icon': Icons.movie_rounded,           'color': Color(0xFFEC4899)},
    {'name': 'Health',           'icon': Icons.local_hospital_rounded,  'color': Color(0xFF10B981)},
    {'name': 'Education',        'icon': Icons.school_rounded,          'color': Color(0xFF0EA5E9)},
    {'name': 'Groceries',        'icon': Icons.local_grocery_store_rounded,'color': Color(0xFF84CC16)},
    {'name': 'Rent',             'icon': Icons.home_rounded,            'color': Color(0xFF6366F1)},
    {'name': 'Salary',           'icon': Icons.account_balance_wallet_rounded,'color': Color(0xFF14B8A6)},
    {'name': 'Investment',       'icon': Icons.trending_up_rounded,     'color': Color(0xFF22C55E)},
    {'name': 'EMI / Loan',       'icon': Icons.account_balance_rounded, 'color': Color(0xFFF97316)},
    {'name': 'Personal',         'icon': Icons.person_rounded,          'color': Color(0xFFA78BFA)},
    {'name': 'Gift',             'icon': Icons.card_giftcard_rounded,   'color': Color(0xFFFB7185)},
    {'name': 'Other',            'icon': Icons.more_horiz_rounded,      'color': Color(0xFF94A3B8)},
  ];

  static const List<String> paymentMethods = [
    'Cash', 'UPI', 'Credit Card', 'Debit Card',
    'Bank Transfer', 'Net Banking', 'Cheque', 'Other',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _box = Hive.box<Expense>('expenses');
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Expense> get _allExpenses => _box.values.toList()
    ..sort((a, b) => b.date.compareTo(a.date));

  List<Expense> get _monthExpenses {
    return _allExpenses.where((e) =>
      e.date.year == _selectedMonth.year &&
      e.date.month == _selectedMonth.month &&
      (_filterType == 'all' || e.type == _filterType),
    ).toList();
  }

  double get _totalDebit => _monthExpenses
      .where((e) => e.isDebit)
      .fold(0.0, (s, e) => s + e.amount);

  double get _totalCredit => _monthExpenses
      .where((e) => e.isCredit)
      .fold(0.0, (s, e) => s + e.amount);

  double get _balance => _totalCredit - _totalDebit;

  // Group expenses by date
  Map<String, List<Expense>> get _groupedExpenses {
    final map = <String, List<Expense>>{};
    for (final e in _monthExpenses) {
      final key = DateFormat('yyyy-MM-dd').format(e.date);
      map.putIfAbsent(key, () => []).add(e);
    }
    return map;
  }

  IconData _catIcon(String cat) =>
      (categories.firstWhere((c) => c['name'] == cat,
          orElse: () => categories.last)['icon'] as IconData);

  Color _catColor(String cat) =>
      (categories.firstWhere((c) => c['name'] == cat,
          orElse: () => categories.last)['color'] as Color);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Daily Expense Tracker'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded),
            tooltip: 'Analytics',
            onPressed: () => _tabController.animateTo(1),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.list_rounded), text: 'Transactions'),
            Tab(icon: Icon(Icons.pie_chart_rounded), text: 'Analytics'),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, _, __) {
          return TabBarView(
            controller: _tabController,
            children: [
              _buildTransactionsTab(),
              _buildAnalyticsTab(),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddExpenseDialog(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add'),
        backgroundColor: AppTheme.primaryColor,
      ),
    );
  }

  // ─── Transactions Tab ─────────────────────────────────────────────────────

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        _buildSummaryHeader(),
        _buildMonthSelector(),
        _buildFilterChips(),
        Expanded(
          child: _monthExpenses.isEmpty
              ? _buildEmptyState()
              : _buildTransactionList(),
        ),
      ],
    );
  }

  Widget _buildSummaryHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          _summaryTile('Income', _totalCredit, Icons.arrow_downward_rounded, Colors.greenAccent),
          const SizedBox(width: 12),
          _summaryTile('Expense', _totalDebit, Icons.arrow_upward_rounded, Colors.redAccent),
          const SizedBox(width: 12),
          _summaryTile('Balance', _balance, Icons.account_balance_wallet_rounded,
              _balance >= 0 ? Colors.greenAccent : Colors.redAccent),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, double amount, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              IndianNumberFormat.formatCompact(amount.abs()),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded),
            onPressed: () => setState(() {
              _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
            }),
          ),
          GestureDetector(
            onTap: _pickMonth,
            child: Text(
              DateFormat('MMMM yyyy').format(_selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded),
            onPressed: _selectedMonth.year == DateTime.now().year &&
                    _selectedMonth.month == DateTime.now().month
                ? null
                : () => setState(() {
                      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                    }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _filterChip('All', 'all', AppTheme.primaryColor),
          const SizedBox(width: 8),
          _filterChip('Expense', 'debit', AppTheme.statusError),
          const SizedBox(width: 8),
          _filterChip('Income', 'credit', AppTheme.statusSuccess),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, Color color) {
    final selected = _filterType == value;
    return GestureDetector(
      onTap: () => setState(() => _filterType = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? Colors.white : color,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  Widget _buildTransactionList() {
    final grouped = _groupedExpenses;
    final dates = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: dates.length,
      itemBuilder: (context, i) {
        final dateKey = dates[i];
        final items = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);
        final dayTotal = items.fold(0.0, (s, e) => e.isDebit ? s - e.amount : s + e.amount);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateHeader(date),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                        color: AppTheme.textMedium),
                  ),
                  Text(
                    (dayTotal >= 0 ? '+' : '') + IndianNumberFormat.formatCompact(dayTotal.abs()),
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: dayTotal >= 0 ? AppTheme.statusSuccess : AppTheme.statusError),
                  ),
                ],
              ),
            ),
            ...items.map((e) => _buildExpenseTile(e)),
          ],
        );
      },
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Today  •  ${DateFormat('MMM d').format(date)}';
    if (d == yesterday) return 'Yesterday  •  ${DateFormat('MMM d').format(date)}';
    return DateFormat('EEEE  •  MMM d').format(date);
  }

  Widget _buildExpenseTile(Expense e) {
    final symbol = CurrencyHelper.getSymbol(e.currencyCode);
    return Dismissible(
      key: Key(e.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.statusError,
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) => _confirmDelete(e),
      onDismissed: (_) => e.delete(),
      child: ListTile(
        onTap: () => _showAddExpenseDialog(existing: e),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _catColor(e.category).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(_catIcon(e.category), color: _catColor(e.category), size: 20),
        ),
        title: Text(e.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                color: AppTheme.textDark)),
        subtitle: Row(
          children: [
            Text(e.category,
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
            if (e.paymentMethod != null) ...[
              const Text('  •  ', style: TextStyle(color: AppTheme.textLight, fontSize: 11)),
              Text(e.paymentMethod!,
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ],
          ],
        ),
        trailing: Text(
          '${e.isDebit ? '-' : '+'}$symbol${IndianNumberFormat.format(e.amount)}',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: e.isDebit ? AppTheme.statusError : AppTheme.statusSuccess,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                size: 48, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 16),
          const Text('No transactions yet',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold,
                  color: AppTheme.textDark)),
          const SizedBox(height: 8),
          const Text('Tap + to add your first expense or income',
              style: TextStyle(fontSize: 13, color: AppTheme.textMedium)),
        ],
      ),
    );
  }

  // ─── Analytics Tab ────────────────────────────────────────────────────────

  Widget _buildAnalyticsTab() {
    final expenses = _monthExpenses;
    if (expenses.isEmpty) {
      return const Center(
        child: Text('No data for this month', style: TextStyle(color: AppTheme.textMedium)),
      );
    }

    // Group by category
    final catTotals = <String, double>{};
    for (final e in expenses.where((e) => e.isDebit)) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final sortedCats = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final totalDebitForPercent = sortedCats.fold(0.0, (s, e) => s + e.value);

    // Daily spending for the month
    final dailyMap = <int, double>{};
    for (final e in expenses.where((e) => e.isDebit)) {
      dailyMap[e.date.day] = (dailyMap[e.date.day] ?? 0) + e.amount;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildMonthSelector(),
          // Summary cards
          Row(
            children: [
              _analyticsCard('Total Spent', _totalDebit, AppTheme.statusError, Icons.arrow_upward_rounded),
              const SizedBox(width: 12),
              _analyticsCard('Total Income', _totalCredit, AppTheme.statusSuccess, Icons.arrow_downward_rounded),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _analyticsCard('Net Balance', _balance, _balance >= 0 ? AppTheme.statusSuccess : AppTheme.statusError, Icons.account_balance_wallet_rounded),
              const SizedBox(width: 12),
              _analyticsCard('Transactions', expenses.length.toDouble(), AppTheme.accentBlue, Icons.swap_horiz_rounded, isCount: true),
            ],
          ),
          const SizedBox(height: 20),

          if (sortedCats.isNotEmpty) ...[
            const Text('Spending by Category',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            ...sortedCats.map((entry) => _buildCategoryBar(
                entry.key, entry.value, totalDebitForPercent)),
            const SizedBox(height: 20),
          ],

          // Top expenses
          const Text('Top Expenses',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
          const SizedBox(height: 8),
          ...expenses
              .where((e) => e.isDebit)
              .toList()
              .take(5)
              .map((e) => _buildTopExpenseTile(e)),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _analyticsCard(String label, double value, Color color, IconData icon,
      {bool isCount = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              isCount ? value.toInt().toString() : IndianNumberFormat.formatCompact(value.abs()),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(label,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBar(String cat, double amount, double total) {
    final pct = total > 0 ? (amount / total) : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_catIcon(cat), color: _catColor(cat), size: 14),
              const SizedBox(width: 6),
              Expanded(child: Text(cat,
                  style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
              Text(IndianNumberFormat.formatCompact(amount),
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold,
                      color: _catColor(cat))),
              const SizedBox(width: 8),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: _catColor(cat).withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(_catColor(cat)),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpenseTile(Expense e) {
    final symbol = CurrencyHelper.getSymbol(e.currencyCode);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: _catColor(e.category).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(_catIcon(e.category), color: _catColor(e.category), size: 18),
      ),
      title: Text(e.title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      subtitle: Text(DateFormat('MMM d').format(e.date),
          style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
      trailing: Text('-$symbol${IndianNumberFormat.format(e.amount)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold,
              color: AppTheme.statusError)),
    );
  }

  // ─── Add / Edit Dialog ────────────────────────────────────────────────────

  void _showAddExpenseDialog({Expense? existing}) {
    final isEdit = existing != null;
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final amountCtrl = TextEditingController(
        text: existing?.amount.toStringAsFixed(0) ?? '');
    final noteCtrl = TextEditingController(text: existing?.note ?? '');

    String type = existing?.type ?? 'debit';
    String category = existing?.category ?? 'Food & Dining';
    String paymentMethod = existing?.paymentMethod ?? 'Cash';
    DateTime selectedDate = existing?.date ?? DateTime.now();
    String currency = existing?.currencyCode ?? 'INR';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(isEdit ? 'Edit Transaction' : 'Add Transaction',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold,
                            color: AppTheme.textDark)),
                    const Spacer(),
                    if (isEdit)
                      IconButton(
                        icon: const Icon(Icons.delete_rounded, color: AppTheme.statusError),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _confirmDelete(existing).then((confirmed) {
                            if (confirmed == true) existing.delete();
                          });
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.only(
                    left: 20, right: 20, bottom:
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type toggle
                      Container(
                        decoration: BoxDecoration(
                          color: AppTheme.bgLight,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            _typeToggle(ctx, setModalState, 'debit', 'Expense',
                                Icons.arrow_upward_rounded, AppTheme.statusError, type,
                                (v) => setModalState(() => type = v)),
                            _typeToggle(ctx, setModalState, 'credit', 'Income',
                                Icons.arrow_downward_rounded, AppTheme.statusSuccess, type,
                                (v) => setModalState(() => type = v)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Amount
                      TextField(
                        controller: amountCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: '${CurrencyHelper.getSymbol(currency)}  ',
                          prefixStyle: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold,
                              color: AppTheme.textMedium),
                          hintText: '0',
                          hintStyle: const TextStyle(fontSize: 28, color: AppTheme.textLight),
                          filled: true,
                          fillColor: AppTheme.bgLight,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        autofocus: !isEdit,
                      ),
                      const SizedBox(height: 12),

                      // Title
                      TextField(
                        controller: titleCtrl,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Title / Description',
                          prefixIcon: const Icon(Icons.edit_rounded, color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: AppTheme.bgLight,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Category
                      const Text('Category',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                              color: AppTheme.textDark)),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 80,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: categories.length,
                          itemBuilder: (_, i) {
                            final cat = categories[i];
                            final sel = category == cat['name'];
                            return GestureDetector(
                              onTap: () => setModalState(() => category = cat['name']),
                              child: Container(
                                width: 64,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? (cat['color'] as Color).withValues(alpha: 0.15)
                                      : AppTheme.bgLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? (cat['color'] as Color)
                                        : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(cat['icon'] as IconData,
                                        color: cat['color'] as Color, size: 22),
                                    const SizedBox(height: 4),
                                    Text(
                                      (cat['name'] as String).split(' ').first,
                                      style: TextStyle(
                                          fontSize: 9,
                                          color: sel ? cat['color'] as Color : AppTheme.textMedium,
                                          fontWeight: sel ? FontWeight.bold : FontWeight.normal),
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
                      const SizedBox(height: 12),

                      // Date & Payment Method row
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now(),
                                );
                                if (picked != null) {
                                  setModalState(() => selectedDate = picked);
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppTheme.bgLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        size: 16, color: AppTheme.primaryColor),
                                    const SizedBox(width: 8),
                                    Text(
                                      DateFormat('MMM d, yyyy').format(selectedDate),
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: paymentMethod,
                              isDense: true,
                              decoration: InputDecoration(
                                labelText: 'Payment',
                                filled: true,
                                fillColor: AppTheme.bgLight,
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                              items: paymentMethods
                                  .map((m) => DropdownMenuItem(
                                      value: m, child: Text(m, style: const TextStyle(fontSize: 13))))
                                  .toList(),
                              onChanged: (v) => setModalState(() => paymentMethod = v!),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Note
                      TextField(
                        controller: noteCtrl,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Note (optional)',
                          prefixIcon: const Icon(Icons.notes_rounded,
                              color: AppTheme.primaryColor),
                          filled: true,
                          fillColor: AppTheme.bgLight,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            final amount = double.tryParse(amountCtrl.text);
                            final title = titleCtrl.text.trim();
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a valid amount')),
                              );
                              return;
                            }
                            if (title.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please enter a title')),
                              );
                              return;
                            }

                            if (isEdit) {
                              existing.title = title;
                              existing.amount = amount;
                              existing.type = type;
                              existing.category = category;
                              existing.date = selectedDate;
                              existing.note = noteCtrl.text.trim().isEmpty
                                  ? null
                                  : noteCtrl.text.trim();
                              existing.paymentMethod = paymentMethod;
                              existing.currencyCode = currency;
                              existing.save();
                            } else {
                              final expense = Expense(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: title,
                                amount: amount,
                                type: type,
                                category: category,
                                date: selectedDate,
                                note: noteCtrl.text.trim().isEmpty
                                    ? null
                                    : noteCtrl.text.trim(),
                                currencyCode: currency,
                                paymentMethod: paymentMethod,
                              );
                              _box.add(expense);
                            }
                            Navigator.pop(ctx);
                          },
                          icon: Icon(isEdit ? Icons.save_rounded : Icons.add_rounded),
                          label: Text(isEdit ? 'Save Changes' : 'Add Transaction',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: type == 'debit'
                                ? AppTheme.statusError
                                : AppTheme.statusSuccess,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeToggle(
    BuildContext ctx,
    StateSetter setModalState,
    String value,
    String label,
    IconData icon,
    Color color,
    String currentType,
    void Function(String) onChanged,
  ) {
    final sel = currentType == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? color : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: sel ? Colors.white : color, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: sel ? Colors.white : color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(Expense e) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Transaction?'),
        content: Text('Delete "${e.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.statusError),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    int selectedYear = _selectedMonth.year;
    int selectedMonthNum = _selectedMonth.month;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left_rounded),
                  onPressed: () => setD(() => selectedYear--)),
              Text('$selectedYear',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                  icon: const Icon(Icons.chevron_right_rounded),
                  onPressed: selectedYear < now.year
                      ? () => setD(() => selectedYear++)
                      : null),
            ],
          ),
          content: SizedBox(
            width: 280,
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 2,
              children: List.generate(12, (i) {
                final m = i + 1;
                final isFuture = selectedYear == now.year && m > now.month;
                final isSel = m == selectedMonthNum && selectedYear == _selectedMonth.year;
                return GestureDetector(
                  onTap: isFuture ? null : () {
                    setD(() => selectedMonthNum = m);
                    setState(() {
                      _selectedMonth = DateTime(selectedYear, m);
                    });
                    Navigator.pop(ctx);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSel ? AppTheme.primaryColor
                          : isFuture ? Colors.grey.shade100 : AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      DateFormat('MMM').format(DateTime(2000, m)),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                        color: isSel ? Colors.white
                            : isFuture ? Colors.grey : AppTheme.textDark,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}


