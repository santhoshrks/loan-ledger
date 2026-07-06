import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/p2p_loan.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class P2PLoanDetailScreen extends StatefulWidget {
  final P2PLoan loan;
  final NotificationService? notificationService;
  const P2PLoanDetailScreen({super.key, required this.loan, this.notificationService});

  @override
  State<P2PLoanDetailScreen> createState() => _P2PLoanDetailScreenState();
}

class _P2PLoanDetailScreenState extends State<P2PLoanDetailScreen> {
  P2PLoan get loan => widget.loan;

  @override
  Widget build(BuildContext context) {
    final color = loan.isLent ? AppTheme.statusSuccess : AppTheme.accentOrange;
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(loan.personName),
        backgroundColor: color, foregroundColor: Colors.white, elevation: 0,
        actions: [
          if (loan.phoneNumber != null)
            IconButton(icon: const Icon(Icons.chat_rounded), tooltip: 'WhatsApp Reminder', onPressed: _sendWhatsApp),
          IconButton(icon: const Icon(Icons.edit_rounded), tooltip: 'Edit', onPressed: () => _showEditSheet(context)),
          PopupMenuButton<String>(
            onSelected: (v) { if (v == 'delete') _confirmDelete(context); },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_rounded, color: Colors.red, size: 18),
                SizedBox(width: 8),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ])),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: loan.isFlat ? _buildFlatInterestBody(color) : _buildEmiBody(color),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // FLAT INTEREST LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildFlatInterestBody(Color color) {
    final monthlyInt = loan.monthlyInterestFlat;
    final made = loan.interestPaymentsMade;
    final overdue = loan.interestPaymentsOverdue;
    final elapsed = loan.monthsElapsed;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _flatHeroCard(color, monthlyInt, made, overdue),
      const SizedBox(height: 16),
      _flatInfoCard(color, monthlyInt),
      const SizedBox(height: 16),
      _statusBanner(overdue, monthlyInt),
      const SizedBox(height: 16),
      _monthlyTrackerCard(elapsed, made, monthlyInt),
      const SizedBox(height: 16),
      _paymentHistoryCard(),
      const SizedBox(height: 16),
      _flatSummaryCard(monthlyInt),
      const SizedBox(height: 20),
      if (!loan.isSettled) ...[
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: () => _recordInterestPayment(monthlyInt),
          icon: const Icon(Icons.payments_rounded),
          label: Text(
            loan.isLent
                ? (overdue > 1
                    ? 'Collect ₹${IndianNumberFormat.formatCompact(monthlyInt)} from ${loan.personName} ($overdue months overdue)'
                    : 'Collect ₹${IndianNumberFormat.formatCompact(monthlyInt)} Interest from ${loan.personName}')
                : (overdue > 1
                    ? 'Pay ₹${IndianNumberFormat.formatCompact(monthlyInt)} to ${loan.personName} ($overdue months overdue)'
                    : 'Pay ₹${IndianNumberFormat.formatCompact(monthlyInt)} Interest to ${loan.personName}'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
        const SizedBox(height: 10),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: _recordPrincipalRepayment,
          icon: const Icon(Icons.account_balance_rounded),
          label: Text(
            loan.isLent
                ? 'Record Principal Return (₹${IndianNumberFormat.formatCompact(loan.outstanding)})'
                : 'Record Principal Repayment (₹${IndianNumberFormat.formatCompact(loan.outstanding)})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor,
              side: const BorderSide(color: AppTheme.primaryColor),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        )),
      ] else
        _settledBanner(),
      const SizedBox(height: 32),
    ]);
  }

  Widget _flatHeroCard(Color color, double monthlyInt, int made, int overdue) {
    final principalProgress = loan.amount > 0 ? loan.principalRepaid / loan.amount : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(loan.personName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loan.personName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(loan.isLent ? '💸 You gave this loan' : '🏦 You took this loan',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Text(
                '💰 Flat Interest · ${loan.interestRate?.toStringAsFixed(1) ?? '?'}% ${loan.interestPeriod == 'monthly' ? '/month' : 'p.a.'}',
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(IndianNumberFormat.formatCompact(loan.amount),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Loan Amount', style: TextStyle(color: Colors.white60, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _heroStat(IndianNumberFormat.formatCompact(loan.repaidAmount), 'Interest\nReceived'),
          _heroStat(IndianNumberFormat.formatCompact(loan.outstanding), 'Principal\nDue'),
          _heroStat('$made paid\n${overdue > 0 ? '⚠️ $overdue due' : '✅ current'}', 'Monthly'),
        ]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: principalProgress.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 8)),
        const SizedBox(height: 6),
        Text('${(principalProgress * 100).toStringAsFixed(0)}% principal returned',
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }

  Widget _flatInfoCard(Color color, double monthlyInt) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Loan Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _detailTile(Icons.calendar_month_rounded, 'Start Date', DateFormat('d MMM yyyy').format(loan.date), color)),
          if (loan.dueDate != null)
            Expanded(child: _detailTile(Icons.event_rounded, 'End/Due Date',
                DateFormat('d MMM yyyy').format(loan.dueDate!),
                loan.isOverdue ? AppTheme.statusError : color)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (loan.interestRate != null)
            Expanded(child: _detailTile(Icons.percent_rounded, 'Interest Rate',
                '${loan.interestRate!.toStringAsFixed(1)}% ${loan.interestPeriod == 'monthly' ? 'per month' : 'per year'}',
                AppTheme.accentOrange)),
          Expanded(child: _detailTile(Icons.payments_rounded, 'Monthly Interest',
              IndianNumberFormat.formatCompact(monthlyInt), color)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _detailTile(Icons.account_balance_rounded, 'Principal', IndianNumberFormat.formatCompact(loan.amount), AppTheme.primaryColor)),
          Expanded(child: _detailTile(Icons.hourglass_top_rounded, 'Active Since', '${loan.monthsElapsed} months', AppTheme.textMedium)),
        ]),
        if (loan.notes != null && loan.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.notes_rounded, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Expanded(child: Text(loan.notes!, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium))),
            ]),
          ),
        ],
        // ── Next interest due date banner ──────────────────────
        if (loan.monthlyDueDay != null) ...[
          const SizedBox(height: 12),
          _nextDueBanner(color),
        ],
      ]),
    );
  }

  Widget _nextDueBanner(Color color) {
    final next = loan.nextInterestDueDate;
    final days = loan.daysUntilNextInterest;
    if (next == null) return const SizedBox.shrink();
    Color bc;
    String emoji;
    if (days == 0) { bc = AppTheme.statusError; emoji = '🔴'; }
    else if (days <= 3) { bc = AppTheme.statusWarning; emoji = '⚠️'; }
    else { bc = AppTheme.statusSuccess; emoji = '📅'; }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bc.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bc.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            days == 0 ? 'Interest due TODAY!'
                : days == 1 ? 'Interest due tomorrow'
                : 'Next interest due: ${DateFormat('d MMM yyyy').format(next)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: bc),
          ),
          Text(
            'Every ${_ordinal(loan.monthlyDueDay!)} of the month  •  ${IndianNumberFormat.formatCompact(loan.monthlyInterestFlat)}',
            style: TextStyle(fontSize: 11, color: bc),
          ),
        ])),
        if (widget.notificationService != null)
          GestureDetector(
            onTap: () async {
              await widget.notificationService!.showP2PTestNotification(
                  loan.personName, loan.monthlyInterestFlat);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('🔔 Test notification sent!')));
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: bc.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
              child: Text('Test 🔔', style: TextStyle(fontSize: 11, color: bc, fontWeight: FontWeight.bold)),
            ),
          ),
      ]),
    );
  }

  String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  Widget _statusBanner(int overdue, double monthlyInt) {
    if (loan.isSettled) return const SizedBox.shrink();
    if (overdue == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: AppTheme.statusSuccess.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.statusSuccess.withValues(alpha: 0.3))),
        child: Row(children: [
          const Icon(Icons.check_circle_rounded, color: AppTheme.statusSuccess, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(
              loan.isLent
                  ? 'All interest received from ${loan.personName} ✅'
                  : 'All interest payments to ${loan.personName} are up to date ✅',
              style: const TextStyle(color: AppTheme.statusSuccess, fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.statusError.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.statusError.withValues(alpha: 0.3))),
      child: Row(children: [
        const Icon(Icons.warning_rounded, color: AppTheme.statusError, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            loan.isLent
                ? '$overdue month${overdue > 1 ? 's' : ''} interest pending from ${loan.personName}!'
                : 'You owe $overdue month${overdue > 1 ? 's' : ''} interest to ${loan.personName}!',
            style: const TextStyle(color: AppTheme.statusError, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          Text(
            loan.isLent
                ? 'Collect: ${IndianNumberFormat.formatCompact(monthlyInt * overdue)}'
                : 'You need to pay: ${IndianNumberFormat.formatCompact(monthlyInt * overdue)}',
            style: const TextStyle(color: AppTheme.statusError, fontSize: 11),
          ),
        ])),
      ]),
    );
  }

  /// Returns true if any 'I' payment in paymentLog falls within the given month/year
  bool _isMonthPaid(DateTime monthDate) {
    return loan.parsedPayments.any((p) =>
        p['type'] == 'I' &&
        (p['date'] as DateTime).year == monthDate.year &&
        (p['date'] as DateTime).month == monthDate.month);
  }

  Widget _monthlyTrackerCard(int elapsed, int made, double monthlyInt) {
    final now = DateTime.now();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Monthly Interest Tracker',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          Text('$elapsed month${elapsed > 1 ? 's' : ''} elapsed',
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            SizedBox(width: 28, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
            Expanded(child: Text('Month', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
            SizedBox(width: 64, child: Text('Amount', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
            SizedBox(width: 72, child: Text('Status', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
          ]),
        ),
        const SizedBox(height: 4),
        ...List.generate(elapsed, (i) {
          final month = i + 1;
          final monthDate = DateTime(loan.date.year, loan.date.month + i, 1);
          // Date-based paid check: any 'I' payment recorded for this month/year
          final paid = _isMonthPaid(monthDate);
          final isCurrent = monthDate.year == now.year && monthDate.month == now.month;
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: paid ? AppTheme.statusSuccess.withValues(alpha: 0.06)
                  : isCurrent ? AppTheme.accentOrange.withValues(alpha: 0.06)
                  : AppTheme.statusError.withValues(alpha: 0.04),
              border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(children: [
              SizedBox(width: 28, child: Text('$month', style: TextStyle(fontSize: 11,
                  color: paid ? AppTheme.statusSuccess : AppTheme.statusError, fontWeight: FontWeight.w600))),
              Expanded(child: Text(DateFormat('MMM yyyy').format(monthDate),
                  style: TextStyle(fontSize: 11, color: paid ? AppTheme.statusSuccess : AppTheme.textMedium))),
              SizedBox(width: 64, child: Text(IndianNumberFormat.formatCompact(monthlyInt), textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: paid ? AppTheme.statusSuccess : AppTheme.textDark, fontWeight: FontWeight.w600))),
              SizedBox(width: 72, child: Text(
                paid ? '✅ Paid' : (isCurrent ? '⏳ Due now' : '❌ Overdue'),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                    color: paid ? AppTheme.statusSuccess : isCurrent ? AppTheme.accentOrange : AppTheme.statusError),
              )),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _paymentHistoryCard() {
    final payments = loan.parsedPayments;
    if (payments.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text('Payment History (${payments.length})',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          Text('Swipe or tap ✏️ 🗑️', style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
        ]),
        const SizedBox(height: 12),
        ...payments.asMap().entries.map((entry) {
          final i = entry.key;
          final p = entry.value;
          final isInterest = p['type'] == 'I';
          final c = isInterest ? AppTheme.statusSuccess : AppTheme.primaryColor;
          return Dismissible(
            key: ValueKey('payment_${i}_${(p['date'] as DateTime).millisecondsSinceEpoch}_${p['amount']}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppTheme.statusError.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.delete_outline_rounded, color: AppTheme.statusError, size: 20),
                SizedBox(width: 4),
                Text('Delete', style: TextStyle(color: AppTheme.statusError, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
            confirmDismiss: (_) => _confirmDeletePayment(i, p),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9)))),
              child: Row(children: [
                Container(padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                    child: Icon(isInterest ? Icons.payments_rounded : Icons.account_balance_rounded, size: 14, color: c)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isInterest ? 'Interest Payment' : 'Principal Repayment',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
                  Text(DateFormat('d MMM yyyy').format(p['date'] as DateTime),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                ])),
                Text(IndianNumberFormat.formatCompact(p['amount'] as double),
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c)),
                const SizedBox(width: 8),
                // Edit button
                GestureDetector(
                  onTap: () => _editPayment(i, p),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.edit_rounded, size: 13, color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(width: 6),
                // Delete button
                GestureDetector(
                  onTap: () async {
                    final confirmed = await _confirmDeletePayment(i, p);
                    if (confirmed == true) setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: AppTheme.statusError.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6)),
                    child: const Icon(Icons.delete_outline_rounded, size: 13, color: AppTheme.statusError),
                  ),
                ),
              ]),
            ),
          );
        }),
      ]),
    );
  }

  Future<bool?> _confirmDeletePayment(int index, Map<String, dynamic> p) async {
    final isInterest = p['type'] == 'I';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Payment?'),
        content: Text(
          'Remove ${isInterest ? 'interest' : 'principal'} payment of '
          '₹${IndianNumberFormat.formatCompact(p['amount'] as double)} '
          'on ${DateFormat('d MMM yyyy').format(p['date'] as DateTime)}?\n\n'
          'This will update the totals accordingly.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      loan.removePaymentAt(index);
      await loan.save();
      if (mounted) setState(() {});
    }
    return confirmed;
  }

  void _editPayment(int index, Map<String, dynamic> p) {
    final isInterest = p['type'] == 'I';
    final amtCtrl = TextEditingController(text: (p['amount'] as double).toStringAsFixed(0));
    DateTime paymentDate = p['date'] as DateTime;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(
                'Edit ${isInterest ? 'Interest' : 'Principal'} Payment',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              )),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 14),
            TextField(
              controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(
                labelText: isInterest ? 'Interest Amount' : 'Principal Amount',
                prefixIcon: Icon(
                    isInterest ? Icons.payments_rounded : Icons.account_balance_rounded,
                    color: AppTheme.primaryColor),
                filled: true, fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 12),
            // Date picker
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: paymentDate,
                  firstDate: loan.date,
                  lastDate: DateTime.now(),
                  helpText: isInterest ? 'Which month is this for?' : 'When was the payment made?',
                );
                if (picked != null) setInner(() => paymentDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(isInterest ? 'Payment Month' : 'Payment Date',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                    const SizedBox(height: 2),
                    Text(
                      isInterest
                          ? DateFormat('MMMM yyyy').format(paymentDate)
                          : DateFormat('d MMM yyyy').format(paymentDate),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600),
                    ),
                  ])),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textLight),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(amtCtrl.text) ?? 0;
                if (amt <= 0) return;
                loan.updatePaymentAt(index, paymentDate, amt);
                await loan.save();
                if (mounted) { Navigator.pop(context); setState(() {}); }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _flatSummaryCard(double monthlyInt) {
    final expected = loan.expectedInterestToDate;
    final received = loan.repaidAmount;
    final diff = received - expected;
    final onTrack = diff >= 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 14),
        _summaryRow('Principal', IndianNumberFormat.formatCompact(loan.amount), AppTheme.primaryColor),
        const SizedBox(height: 8),
        _summaryRow('Monthly Interest', IndianNumberFormat.formatCompact(monthlyInt), AppTheme.accentOrange),
        const SizedBox(height: 8),
        _summaryRow('Interest Received', IndianNumberFormat.formatCompact(received), AppTheme.statusSuccess),
        const SizedBox(height: 8),
        _summaryRow('Expected by Now', IndianNumberFormat.formatCompact(expected), AppTheme.textMedium),
        const Divider(height: 20),
        _summaryRow(onTrack ? '✅ Status' : '⚠️ Status',
            onTrack ? 'On Track' : 'Behind by ${IndianNumberFormat.formatCompact(diff.abs())}',
            onTrack ? AppTheme.statusSuccess : AppTheme.statusError),
        if (loan.principalRepaid > 0) ...[
          const SizedBox(height: 8),
          _summaryRow('Principal Returned', IndianNumberFormat.formatCompact(loan.principalRepaid), AppTheme.statusSuccess),
          const SizedBox(height: 8),
          _summaryRow('Principal Outstanding', IndianNumberFormat.formatCompact(loan.outstanding),
              loan.outstanding > 0 ? AppTheme.accentOrange : AppTheme.statusSuccess),
        ],
      ]),
    );
  }

  // ══════════════════════════════════════════════════════════════
  // EMI (REDUCING BALANCE) LAYOUT
  // ══════════════════════════════════════════════════════════════
  Widget _buildEmiBody(Color color) {
    final hasTenure = loan.tenureMonths != null && loan.tenureMonths! > 0;
    final emi = loan.monthlyEmi;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _emiHeroCard(color, hasTenure, emi),
      const SizedBox(height: 16),
      if (hasTenure) ...[_infoCard(color, emi), const SizedBox(height: 16)],
      if (hasTenure) ...[_scheduleCard(emi), const SizedBox(height: 16)],
      _repaymentCard(),
      const SizedBox(height: 24),
      if (!loan.isSettled)
        SizedBox(width: double.infinity, child: ElevatedButton.icon(
          onPressed: _showEmiRepaySheet,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Record Payment', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ))
      else _settledBanner(),
      const SizedBox(height: 32),
    ]);
  }

  Widget _emiHeroCard(Color color, bool hasTenure, double emi) {
    final progress = loan.amount > 0 ? loan.repaidAmount / loan.amount : 0.0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withValues(alpha: 0.75)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 24, backgroundColor: Colors.white.withValues(alpha: 0.25),
              child: Text(loan.personName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loan.personName, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            Text(loan.isLent ? '💸 You gave this loan' : '🏦 You took this loan',
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(IndianNumberFormat.formatCompact(loan.amount),
                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('Loan Amount', style: TextStyle(color: Colors.white60, fontSize: 10)),
          ]),
        ]),
        const SizedBox(height: 20),
        Row(children: [
          _heroStat(IndianNumberFormat.formatCompact(loan.repaidAmount), 'Paid'),
          _heroStat(IndianNumberFormat.formatCompact(loan.outstanding), 'Outstanding'),
          if (hasTenure) _heroStat('${loan.monthsPaid}/${loan.tenureMonths}', 'EMIs Done'),
        ]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), minHeight: 8)),
        const SizedBox(height: 6),
        Text('${(progress * 100).toStringAsFixed(0)}% repaid',
            style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ]),
    );
  }

  Widget _infoCard(Color color, double emi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Loan Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _detailTile(Icons.calendar_month_rounded, 'Start Date', DateFormat('d MMM yyyy').format(loan.date), color)),
          if (loan.dueDate != null)
            Expanded(child: _detailTile(Icons.event_rounded, 'Due Date',
                DateFormat('d MMM yyyy').format(loan.dueDate!),
                loan.isOverdue ? AppTheme.statusError : color)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          if (loan.interestRate != null)
            Expanded(child: _detailTile(Icons.percent_rounded, 'Interest Rate', '${loan.interestRate!.toStringAsFixed(1)}% p.a.', AppTheme.accentOrange)),
          if (loan.tenureMonths != null)
            Expanded(child: _detailTile(Icons.timelapse_rounded, 'Tenure', '${loan.tenureMonths} months', AppTheme.primaryColor)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _detailTile(Icons.payments_rounded, 'Monthly EMI', IndianNumberFormat.formatCompact(emi), color)),
          if (loan.totalInterest > 0)
            Expanded(child: _detailTile(Icons.trending_up_rounded, 'Total Interest', IndianNumberFormat.formatCompact(loan.totalInterest), AppTheme.statusError)),
        ]),
        if (loan.notes != null && loan.notes!.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(width: double.infinity, padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.notes_rounded, size: 16, color: AppTheme.textLight),
              const SizedBox(width: 8),
              Expanded(child: Text(loan.notes!, style: const TextStyle(fontSize: 12, color: AppTheme.textMedium))),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _scheduleCard(double emi) {
    final tenure = loan.tenureMonths!;
    final monthsPaid = loan.monthsPaid;
    final displayCount = tenure <= 12 ? tenure : 6;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text('Payment Schedule', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark))),
          Text('$tenure months', style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
        ]),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(8)),
          child: const Row(children: [
            SizedBox(width: 32, child: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
            Expanded(child: Text('Date', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
            SizedBox(width: 72, child: Text('EMI', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
            SizedBox(width: 72, child: Text('Remaining', textAlign: TextAlign.right, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textMedium))),
          ]),
        ),
        const SizedBox(height: 4),
        ...List.generate(displayCount, (i) {
          final month = i + 1;
          final d = DateTime(loan.date.year, loan.date.month + month, loan.date.day);
          final paid = month <= monthsPaid;
          final remaining = (loan.amount - (emi * month)).clamp(0.0, double.infinity);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
            decoration: BoxDecoration(
              color: paid ? AppTheme.statusSuccess.withValues(alpha: 0.06) : null,
              border: const Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(children: [
              SizedBox(width: 32, child: Text('$month', style: TextStyle(fontSize: 11,
                  color: paid ? AppTheme.statusSuccess : AppTheme.textLight,
                  fontWeight: paid ? FontWeight.bold : FontWeight.normal))),
              Expanded(child: Text(DateFormat('d MMM yy').format(d),
                  style: TextStyle(fontSize: 11, color: paid ? AppTheme.statusSuccess : AppTheme.textMedium))),
              SizedBox(width: 72, child: Text(IndianNumberFormat.formatCompact(emi), textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: paid ? AppTheme.statusSuccess : AppTheme.textDark, fontWeight: FontWeight.w600))),
              SizedBox(width: 72, child: Text(IndianNumberFormat.formatCompact(remaining), textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 11, color: paid ? AppTheme.statusSuccess : AppTheme.accentOrange))),
              if (paid) const SizedBox(width: 18, child: Icon(Icons.check_circle_rounded, size: 14, color: AppTheme.statusSuccess))
              else const SizedBox(width: 18),
            ]),
          );
        }),
        if (tenure > displayCount) ...[
          const SizedBox(height: 8),
          Center(child: Text('... and ${tenure - displayCount} more months',
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight))),
        ],
      ]),
    );
  }

  Widget _repaymentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Repayment Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 14),
        _summaryRow('Total Loan', IndianNumberFormat.formatCompact(loan.amount), AppTheme.primaryColor),
        const SizedBox(height: 8),
        _summaryRow('Amount Paid', IndianNumberFormat.formatCompact(loan.repaidAmount), AppTheme.statusSuccess),
        const SizedBox(height: 8),
        _summaryRow('Outstanding', IndianNumberFormat.formatCompact(loan.outstanding),
            loan.outstanding > 0 ? AppTheme.accentOrange : AppTheme.statusSuccess),
        if (loan.monthlyEmi > 0 && loan.tenureMonths != null) ...[
          const Divider(height: 20),
          _summaryRow('Monthly EMI', IndianNumberFormat.formatCompact(loan.monthlyEmi), AppTheme.primaryColor),
          const SizedBox(height: 8),
          _summaryRow('EMIs Paid', '${loan.monthsPaid} of ${loan.tenureMonths}', AppTheme.statusSuccess),
          const SizedBox(height: 8),
          _summaryRow('EMIs Left', '${loan.monthsRemaining}', AppTheme.accentOrange),
        ],
      ]),
    );
  }

  // ── Shared helpers ──────────────────────────────────────────────────────────
  Widget _heroStat(String value, String label) => Expanded(child: Column(children: [
    Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
    Text(label, style: const TextStyle(color: Colors.white60, fontSize: 9), textAlign: TextAlign.center),
  ]));

  Widget _detailTile(IconData icon, String label, String value, Color color) => Row(children: [
    Container(padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, size: 14, color: color)),
    const SizedBox(width: 8),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 10, color: AppTheme.textLight)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
    ])),
  ]);

  Widget _summaryRow(String label, String value, Color color) => Row(children: [
    Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMedium))),
    Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
  ]);

  Widget _settledBanner() => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(
      color: AppTheme.statusSuccess.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.statusSuccess.withValues(alpha: 0.3)),
    ),
    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.check_circle_rounded, color: AppTheme.statusSuccess),
      SizedBox(width: 8),
      Text('Fully Settled ✅', style: TextStyle(color: AppTheme.statusSuccess, fontWeight: FontWeight.bold, fontSize: 15)),
    ]),
  );

  // ── Action sheets ───────────────────────────────────────────────────────────
  void _recordInterestPayment(double monthlyInt) {
    final ctrl = TextEditingController(text: monthlyInt.toStringAsFixed(0));
    // Default to earliest unpaid month
    DateTime paymentDate = _defaultInterestPaymentDate();

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                loan.isLent
                    ? 'Record Interest Received — ${loan.personName}'
                    : 'Record Interest Payment to ${loan.personName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Monthly interest: ${IndianNumberFormat.formatCompact(monthlyInt)}  •  Paid so far: ${loan.interestPaymentsMade} months',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(labelText: 'Interest Amount',
                prefixIcon: const Icon(Icons.payments_rounded, color: AppTheme.primaryColor),
                filled: true, fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            // ── Payment date picker ──────────────────────────────────
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: paymentDate,
                  firstDate: loan.date,
                  lastDate: DateTime.now(),
                  helpText: 'Which month is this payment for?',
                );
                if (picked != null) setInner(() => paymentDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Payment Month', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                    const SizedBox(height: 2),
                    Text(DateFormat('MMMM yyyy').format(paymentDate),
                        style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                  ])),
                  Text(DateFormat('d MMM yyyy').format(paymentDate),
                      style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textLight),
                ]),
              ),
            ),
            // Warn if this month already has a payment
            if (_isMonthPaid(paymentDate)) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.accentOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                ),
                child: Row(children: [
                  const Icon(Icons.warning_amber_rounded, color: AppTheme.accentOrange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    '${DateFormat('MMM yyyy').format(paymentDate)} already has a payment recorded.',
                    style: const TextStyle(fontSize: 12, color: AppTheme.accentOrange),
                  )),
                ]),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt <= 0) return;
                loan.repaidAmount += amt;
                loan.addPaymentEntry(paymentDate, amt, 'I');
                await loan.save();
                if (mounted) { Navigator.pop(context); setState(() {}); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text('Save — ${DateFormat('MMM yyyy').format(paymentDate)}', style: const TextStyle(fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  /// Returns the first day of the earliest month that has no interest payment recorded yet
  DateTime _defaultInterestPaymentDate() {
    final now = DateTime.now();
    for (int i = 0; i < loan.monthsElapsed; i++) {
      final monthDate = DateTime(loan.date.year, loan.date.month + i, 1);
      if (!_isMonthPaid(monthDate)) return monthDate;
    }
    // All past months paid — default to current month
    return DateTime(now.year, now.month, 1);
  }

  void _recordPrincipalRepayment() {
    final ctrl = TextEditingController(text: loan.outstanding.toStringAsFixed(0));
    DateTime paymentDate = DateTime.now();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => SingleChildScrollView(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loan.isLent ? 'Record Principal Return — ${loan.personName}' : 'Record Principal Repayment — ${loan.personName}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Outstanding principal: ${IndianNumberFormat.formatCompact(loan.outstanding)}',
                style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
            const SizedBox(height: 16),
            TextField(controller: ctrl, autofocus: false,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
              decoration: InputDecoration(labelText: 'Amount',
                prefixIcon: const Icon(Icons.account_balance_rounded, color: AppTheme.primaryColor),
                filled: true, fillColor: AppTheme.bgLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: paymentDate,
                  firstDate: loan.date,
                  lastDate: DateTime.now(),
                );
                if (picked != null) setInner(() => paymentDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(
                  color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.edit_calendar_rounded, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(DateFormat('d MMM yyyy').format(paymentDate),
                      style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600))),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textLight),
                ]),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                if (amt <= 0) return;
                loan.principalRepaid = (loan.principalRepaid + amt).clamp(0, loan.amount);
                loan.addPaymentEntry(paymentDate, amt, 'P');
                await loan.save();
                if (mounted) { Navigator.pop(context); setState(() {}); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  void _showEmiRepaySheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Record Payment — ${loan.personName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Outstanding: ${IndianNumberFormat.formatCompact(loan.outstanding)}',
              style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
            decoration: InputDecoration(labelText: 'Amount Paid',
              hintText: loan.monthlyEmi > 0 ? loan.monthlyEmi.toStringAsFixed(0) : null,
              prefixIcon: const Icon(Icons.currency_rupee_rounded, color: AppTheme.primaryColor),
              filled: true, fillColor: AppTheme.bgLight,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
          ),
          const SizedBox(height: 14),
          SizedBox(width: double.infinity, child: ElevatedButton(
            onPressed: () async {
              final amt = double.tryParse(ctrl.text) ?? 0;
              if (amt <= 0) return;
              loan.repaidAmount = (loan.repaidAmount + amt).clamp(0, loan.amount);
              await loan.save();
              if (mounted) { Navigator.pop(context); setState(() {}); }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Save Payment', style: TextStyle(fontWeight: FontWeight.bold)),
          )),
        ]),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    final nameCtrl = TextEditingController(text: loan.personName);
    final rateCtrl = TextEditingController(text: loan.interestRate?.toString() ?? '');
    final tenureCtrl = TextEditingController(text: loan.tenureMonths?.toString() ?? '');
    final phoneCtrl = TextEditingController(
        text: loan.phoneNumber != null ? loan.phoneNumber!.replaceFirst('91', '') : '');
    final notesCtrl = TextEditingController(text: loan.notes ?? '');
    DateTime? dueDate = loan.dueDate;
    String interestPeriod = loan.interestPeriod;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => SingleChildScrollView(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Expanded(child: Text('Edit Loan Details',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold))),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
            ]),
            const SizedBox(height: 14),

            // Person name
            _editField(nameCtrl, 'Person Name', Icons.person_rounded),
            const SizedBox(height: 10),

            // Interest rate + period (flat) or tenure (emi)
            if (loan.isFlat) ...[
              Row(children: [
                Expanded(child: _editField(rateCtrl, 'Interest Rate', Icons.percent_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Column(children: [
                  const Text('Period', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                  const SizedBox(height: 4),
                  Row(children: [
                    _miniToggle('Monthly', interestPeriod == 'monthly', () => setInner(() => interestPeriod = 'monthly')),
                    const SizedBox(width: 6),
                    _miniToggle('Annual', interestPeriod == 'annual', () => setInner(() => interestPeriod = 'annual')),
                  ]),
                ]),
              ]),
            ] else ...[
              Row(children: [
                Expanded(child: _editField(rateCtrl, 'Interest % p.a.', Icons.percent_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true))),
                const SizedBox(width: 10),
                Expanded(child: _editField(tenureCtrl, 'Tenure (months)', Icons.timelapse_rounded,
                    keyboardType: TextInputType.number)),
              ]),
            ],
            const SizedBox(height: 10),

            // Phone
            _editField(phoneCtrl, 'WhatsApp Number', Icons.phone_rounded,
                keyboardType: TextInputType.phone, prefix: '+91 '),
            const SizedBox(height: 10),

            // Notes
            _editField(notesCtrl, 'Notes', Icons.notes_rounded, maxLines: 2),
            const SizedBox(height: 10),

            // Due date
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: ctx,
                  initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now().subtract(const Duration(days: 3650)),
                  lastDate: DateTime.now().add(const Duration(days: 3650)),
                );
                if (picked != null) setInner(() => dueDate = picked);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                decoration: BoxDecoration(color: AppTheme.bgLight, borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Icon(Icons.event_rounded, color: AppTheme.primaryColor, size: 18),
                  const SizedBox(width: 10),
                  Expanded(child: Text(
                    dueDate == null
                        ? (loan.isFlat ? 'Set Expected Return Date' : 'Set Due Date')
                        : DateFormat('d MMM yyyy').format(dueDate!),
                    style: TextStyle(fontSize: 13, color: dueDate == null ? AppTheme.textLight : AppTheme.textDark),
                  )),
                  if (dueDate != null)
                    GestureDetector(
                      onTap: () => setInner(() => dueDate = null),
                      child: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textLight),
                    ),
                ]),
              ),
            ),
            const SizedBox(height: 18),

            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                loan.personName = name;
                loan.interestRate = rateCtrl.text.isEmpty ? null : double.tryParse(rateCtrl.text);
                if (!loan.isFlat) {
                  loan.tenureMonths = tenureCtrl.text.isEmpty ? null : int.tryParse(tenureCtrl.text);
                }
                loan.phoneNumber = phoneCtrl.text.isEmpty ? null : '91${phoneCtrl.text.replaceAll(' ', '')}';
                loan.notes = notesCtrl.text.isEmpty ? null : notesCtrl.text.trim();
                loan.dueDate = dueDate;
                loan.interestPeriod = interestPeriod;
                await loan.save();
                if (mounted) { Navigator.pop(context); setState(() {}); }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            )),
          ]),
        ),
      ),
    );
  }

  Widget _editField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? keyboardType, String? prefix, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefix,
        prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 18),
        filled: true, fillColor: AppTheme.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _miniToggle(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? AppTheme.primaryColor : AppTheme.textLight),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppTheme.textMedium)),
    ),
  );

  void _sendWhatsApp() async {
    String msg;
    if (loan.isFlat) {
      final overdue = loan.interestPaymentsOverdue;
      final mi = loan.monthlyInterestFlat;
      msg = overdue > 0
          ? 'Hi ${loan.personName}, this is a reminder that $overdue month${overdue > 1 ? 's' : ''} of interest (${IndianNumberFormat.formatCompact(mi * overdue)}) is pending. Kindly pay at the earliest. Thank you!'
          : 'Hi ${loan.personName}, just a reminder about the monthly interest payment of ${IndianNumberFormat.formatCompact(mi)}. Thank you!';
    } else {
      msg = 'Hi ${loan.personName}, just a friendly reminder about the outstanding amount of ${IndianNumberFormat.formatCompact(loan.outstanding)}. Please let me know when it\'s convenient to settle. Thank you!';
    }
    final phone = loan.phoneNumber ?? '';
    final url = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(msg)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open WhatsApp. Please make sure it is installed.')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Remove loan entry for ${loan.personName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await loan.delete();
              if (mounted) Navigator.pop(context);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

