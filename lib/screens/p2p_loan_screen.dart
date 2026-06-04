import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/p2p_loan.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';
import 'p2p_loan_detail_screen.dart';

class P2PLoanScreen extends StatefulWidget {
  final NotificationService? notificationService;
  const P2PLoanScreen({super.key, this.notificationService});
  @override
  State<P2PLoanScreen> createState() => _P2PLoanScreenState();
}

class _P2PLoanScreenState extends State<P2PLoanScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  late Box<P2PLoan> _box;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _box = Hive.box<P2PLoan>('p2p_loans');
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('P2P Loan Tracker'),
        backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, elevation: 0,
        bottom: TabBar(
          controller: _tab, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.arrow_upward_rounded), text: 'Given Loans'),
            Tab(icon: Icon(Icons.arrow_downward_rounded), text: 'Taken Loans'),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box<P2PLoan> box, _) {
          final lent = box.values.where((l) => l.isLent).toList();
          final borrowed = box.values.where((l) => !l.isLent).toList();
          return Column(children: [
            _buildSummaryBar(lent, borrowed),
            Expanded(child: TabBarView(controller: _tab, children: [
              _buildList(lent, true),
              _buildList(borrowed, false),
            ])),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add_rounded), label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildSummaryBar(List<P2PLoan> lent, List<P2PLoan> borrowed) {
    final totalLent = lent.where((l) => !l.isSettled).fold(0.0, (s, l) => s + l.outstanding);
    final totalBorrowed = borrowed.where((l) => !l.isSettled).fold(0.0, (s, l) => s + l.outstanding);
    final lentEmi = lent.where((l) => !l.isSettled && l.monthlyEmi > 0).fold(0.0, (s, l) => s + l.monthlyEmi);
    final borrowedEmi = borrowed.where((l) => !l.isSettled && l.monthlyEmi > 0).fold(0.0, (s, l) => s + l.monthlyEmi);
    final overdueCount = lent.where((l) => !l.isSettled && l.isFlat && l.interestPaymentsOverdue > 0).length
        + borrowed.where((l) => !l.isSettled && l.isFlat && l.interestPaymentsOverdue > 0).length;

    return Container(
      color: AppTheme.primaryColor,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(children: [
        // ── Two big stat cards ──────────────────────────────────
        Row(children: [
          Expanded(child: _summaryCard(
            icon: Icons.arrow_circle_up_rounded,
            iconColor: const Color(0xFF4ADE80),
            title: "You'll Receive",
            amount: totalLent,
            sub: lentEmi > 0 ? '${IndianNumberFormat.formatCompact(lentEmi)}/mo interest' : '${lent.where((l) => !l.isSettled).length} active',
          )),
          const SizedBox(width: 12),
          Expanded(child: _summaryCard(
            icon: Icons.arrow_circle_down_rounded,
            iconColor: const Color(0xFFFBBF24),
            title: 'You Owe',
            amount: totalBorrowed,
            sub: borrowedEmi > 0 ? '${IndianNumberFormat.formatCompact(borrowedEmi)}/mo interest' : '${borrowed.where((l) => !l.isSettled).length} active',
            amountColor: const Color(0xFFFBBF24),
          )),
        ]),
        // ── Overdue alert bar ───────────────────────────────────
        if (overdueCount > 0) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.statusError.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppTheme.statusError.withValues(alpha: 0.4)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                '$overdueCount loan${overdueCount > 1 ? 's have' : ' has'} overdue interest payments!',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required double amount,
    required String sub,
    Color amountColor = Colors.white,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.2), shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          const SizedBox(height: 2),
          Text(IndianNumberFormat.formatCompact(amount),
              style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 18)),
          Text(sub, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        ])),
      ]),
    );
  }

  Widget _buildList(List<P2PLoan> items, bool isLent) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isLent ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded, size: 64, color: AppTheme.textLight),
        const SizedBox(height: 12),
        Text(isLent ? 'No loans given yet' : 'No loans taken', style: const TextStyle(color: AppTheme.textMedium, fontSize: 15)),
        const SizedBox(height: 6),
        const Text('Tap + to add an entry', style: TextStyle(color: AppTheme.textLight, fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(P2PLoan loan) {
    final color = loan.isLent ? AppTheme.statusSuccess : AppTheme.accentOrange;
    final hasTenure = loan.tenureMonths != null && loan.tenureMonths! > 0;
    final progress = loan.amount > 0 ? (loan.isFlat ? loan.principalRepaid / loan.amount : loan.repaidAmount / loan.amount) : 0.0;

    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => P2PLoanDetailScreen(
              loan: loan, notificationService: widget.notificationService))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppTheme.softShadow,
          border: loan.isOverdue ? Border.all(color: AppTheme.statusError, width: 1.5) : null,
        ),
        child: Column(children: [
          // ── Top accent bar ────────────────────────────────────────
          Container(
            height: 3,
            decoration: BoxDecoration(
              color: loan.isSettled ? AppTheme.statusSuccess : color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(children: [
              // ── Row 1: Avatar + Name + Amount ────────────────────
              Row(children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withValues(alpha: 0.15),
                  child: Text(loan.personName[0].toUpperCase(),
                      style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(loan.personName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textDark)),
                  const SizedBox(height: 2),
                  // Sub-info row
                  Row(children: [
                    if (loan.isFlat)
                      _infoTag('💰 Flat', AppTheme.accentOrange)
                    else if (hasTenure)
                      _infoTag('📊 EMI', AppTheme.primaryColor),
                    if (loan.interestRate != null) ...[
                      const SizedBox(width: 4),
                      _infoTag(
                        '${loan.interestRate!.toStringAsFixed(0)}%${loan.isFlat && loan.interestPeriod == 'monthly' ? '/mo' : ' p.a.'}',
                        AppTheme.textMedium,
                      ),
                    ],
                    if (loan.isFlat && loan.monthlyInterestFlat > 0) ...[
                      const SizedBox(width: 4),
                      _infoTag('₹${IndianNumberFormat.formatCompact(loan.monthlyInterestFlat)}/mo interest', color),
                    ] else if (!loan.isFlat && loan.monthlyEmi > 0 && hasTenure) ...[
                      const SizedBox(width: 4),
                      _infoTag('EMI ${IndianNumberFormat.formatCompact(loan.monthlyEmi)}', color),
                    ],
                  ]),
                ])),
                // Amount + Status
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(
                    IndianNumberFormat.formatCompact(loan.isFlat ? loan.outstanding : loan.outstanding),
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15,
                        color: loan.isSettled ? AppTheme.statusSuccess : AppTheme.textDark),
                  ),
                  Text(
                    loan.isSettled ? 'Settled ✅' : (loan.isFlat ? 'Principal Due' : 'Outstanding'),
                    style: TextStyle(
                        fontSize: 10,
                        color: loan.isSettled ? AppTheme.statusSuccess : AppTheme.textLight),
                  ),
                ]),
              ]),

              // ── Progress bar (if has progress) ───────────────────
              if (!loan.isSettled) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    backgroundColor: AppTheme.bgLight,
                    minHeight: 4,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                const SizedBox(height: 6),
                // ── Row 2: Progress info + actions ───────────────
                Row(children: [
                  // Progress text
                  Expanded(child: Text(
                    _progressLabel(loan, hasTenure),
                    style: const TextStyle(fontSize: 10, color: AppTheme.textLight),
                  )),
                  // Overdue badge
                  if (loan.isFlat && loan.interestPaymentsOverdue > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppTheme.statusError.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text('${loan.interestPaymentsOverdue} mo overdue',
                          style: const TextStyle(fontSize: 9, color: AppTheme.statusError, fontWeight: FontWeight.bold)),
                    ),
                  // WhatsApp remind
                  if (loan.phoneNumber != null)
                    GestureDetector(
                      onTap: () => _sendWhatsApp(loan),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: const Color(0xFF25D366).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Row(children: [
                          Icon(Icons.chat_rounded, size: 12, color: Color(0xFF25D366)),
                          SizedBox(width: 3),
                          Text('Remind', style: TextStyle(fontSize: 10, color: Color(0xFF25D366), fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textLight),
                ]),
              ] else ...[
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerRight,
                  child: const Icon(Icons.chevron_right_rounded, size: 16, color: AppTheme.textLight),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  String _progressLabel(P2PLoan loan, bool hasTenure) {
    if (loan.isFlat) {
      return '${loan.interestPaymentsMade} interest payments · Principal ₹${IndianNumberFormat.formatCompact(loan.amount)} due';
    }
    if (hasTenure) {
      return '${loan.monthsPaid}/${loan.tenureMonths} EMIs · ${loan.dueDate != null ? DateFormat('d MMM').format(loan.dueDate!) : ''}';
    }
    return DateFormat('d MMM yyyy').format(loan.date);
  }

  Widget _infoTag(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _chip(String label, Color color) => Container(
    margin: const EdgeInsets.only(right: 4, top: 2),
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  void _sendWhatsApp(P2PLoan loan) async {
    final amount = IndianNumberFormat.formatCompact(loan.outstanding);
    final msg = loan.isFlat && loan.interestPaymentsOverdue > 0
        ? 'Hi ${loan.personName}, this is a reminder that ${loan.interestPaymentsOverdue} month${loan.interestPaymentsOverdue > 1 ? 's' : ''} of interest (${IndianNumberFormat.formatCompact(loan.monthlyInterestFlat * loan.interestPaymentsOverdue)}) is pending. Please settle at the earliest. Thank you!'
        : 'Hi ${loan.personName}, just a friendly reminder about the outstanding amount of $amount. Please let me know when it\'s convenient to settle. Thank you!';
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

  void _showAddSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final rateCtrl = TextEditingController();
    final tenureCtrl = TextEditingController();
    bool isLent = true;
    bool isFlat = false;
    String interestPeriod = 'monthly';
    DateTime loanDate = DateTime.now();   // actual loan start date
    DateTime? dueDate;
    int? monthlyDueDay;   // day of month interest is due
    bool showDayPicker = false; // inline day picker expanded state
    int tempDay = DateTime.now().day; // temp selection inside inline picker

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) {
          // Live preview calculation
          final amt = double.tryParse(amtCtrl.text) ?? 0;
          final rate = double.tryParse(rateCtrl.text) ?? 0;
          final tenure = int.tryParse(tenureCtrl.text) ?? 0;
          double previewMonthly = 0;
          double previewInterest = 0;
          if (amt > 0 && rate > 0) {
            if (isFlat) {
              previewMonthly = interestPeriod == 'monthly' ? amt * rate / 100 : amt * rate / 1200;
            } else if (tenure > 0) {
              final r = rate / 1200;
              final factor = pow(1 + r, tenure);
              previewMonthly = amt * r * factor / (factor - 1);
              previewInterest = (previewMonthly * tenure) - amt;
            }
          }

          return SingleChildScrollView(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 24, left: 20, right: 20, top: 24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Add P2P Loan Entry', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              const Text('Track person-to-person loans', style: TextStyle(fontSize: 12, color: AppTheme.textLight)),
              const SizedBox(height: 16),

              // ── Lent / Borrowed toggle ──────────────────────────────
              Row(children: [
                Expanded(child: _choiceBtn('💸 I Gave Loan', isLent, () => setInner(() => isLent = true))),
                const SizedBox(width: 12),
                Expanded(child: _choiceBtn('🏦 I Took Loan', !isLent, () => setInner(() => isLent = false))),
              ]),
              const SizedBox(height: 12),

              // ── Loan type toggle ───────────────────────────────────
              Row(children: [
                Expanded(child: _choiceBtn('📊 EMI / Reducing', !isFlat, () => setInner(() => isFlat = false),
                    subtitle: 'Fixed monthly EMI')),
                const SizedBox(width: 12),
                Expanded(child: _choiceBtn('💰 Flat Interest', isFlat, () => setInner(() => isFlat = true),
                    subtitle: 'Interest only each month')),
              ]),
              const SizedBox(height: 14),

              // ── Flat interest info banner ──────────────────────────
              if (isFlat)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.accentOrange.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.3))),
                  child: const Text(
                    '💡 Flat Interest: Your friend pays only interest every month (e.g. ₹300/month on ₹10,000 @ 3%). '
                    'Principal (₹10,000) is tracked separately and due at end.',
                    style: TextStyle(fontSize: 11, color: AppTheme.accentOrange),
                  ),
                ),

              // ── Name + Amount ──────────────────────────────────────
              TextField(controller: nameCtrl, decoration: _inputDeco('Person Name', Icons.person_rounded)),
              const SizedBox(height: 10),
              TextField(controller: amtCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setInner(() {}),
                  decoration: _inputDeco('Loan Amount (₹)', Icons.currency_rupee_rounded)),
              const SizedBox(height: 10),

              // ── Interest Rate ──────────────────────────────────────
              if (isFlat) ...[
                Row(children: [
                  Expanded(child: TextField(controller: rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (_) => setInner(() {}),
                      decoration: _inputDeco('Interest Rate', Icons.percent_rounded))),
                  const SizedBox(width: 10),
                  // Period selector
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
                  Expanded(child: TextField(controller: rateCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                      onChanged: (_) => setInner(() {}),
                      decoration: _inputDeco('Interest % p.a.', Icons.percent_rounded))),
                  const SizedBox(width: 10),
                  Expanded(child: TextField(controller: tenureCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setInner(() {}),
                      decoration: _inputDeco('Tenure (months)', Icons.timelapse_rounded))),
                ]),
              ],
              const SizedBox(height: 10),

              // ── Phone + Notes ──────────────────────────────────────
              TextField(controller: phoneCtrl, keyboardType: TextInputType.phone,
                  decoration: _inputDeco('WhatsApp Number (optional)', Icons.phone_rounded, prefix: '+91 ')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: _inputDeco('Notes (optional)', Icons.notes_rounded)),
              const SizedBox(height: 10),

              // ── Monthly due day (flat only) ────────────────────────
              if (isFlat) ...[
                GestureDetector(
                  onTap: () => setInner(() {
                    if (monthlyDueDay != null) {
                      // already set — toggle picker to edit
                      tempDay = monthlyDueDay!;
                      showDayPicker = !showDayPicker;
                    } else {
                      showDayPicker = !showDayPicker;
                    }
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    decoration: BoxDecoration(
                        color: monthlyDueDay != null
                            ? AppTheme.primaryColor.withValues(alpha: 0.07)
                            : AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: monthlyDueDay != null
                                ? AppTheme.primaryColor.withValues(alpha: 0.4)
                                : Colors.transparent)),
                    child: Row(children: [
                      Icon(Icons.notifications_active_rounded,
                          color: monthlyDueDay != null ? AppTheme.primaryColor : AppTheme.textLight, size: 18),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          monthlyDueDay != null
                              ? 'Interest due on ${_ordinal(monthlyDueDay!)} of every month'
                              : 'Set Monthly Interest Due Day + Reminder',
                          style: TextStyle(
                              fontSize: 13,
                              color: monthlyDueDay != null ? AppTheme.textDark : AppTheme.textLight,
                              fontWeight: monthlyDueDay != null ? FontWeight.w600 : FontWeight.normal),
                        ),
                        if (monthlyDueDay != null)
                          const Text('Tap to change • Reminder: 3 days, 1 day & on due day',
                              style: TextStyle(fontSize: 10, color: AppTheme.textLight)),
                      ])),
                      if (monthlyDueDay != null)
                        GestureDetector(
                          onTap: () => setInner(() { monthlyDueDay = null; showDayPicker = false; }),
                          child: const Icon(Icons.clear_rounded, size: 16, color: AppTheme.textLight),
                        )
                      else
                        Icon(showDayPicker ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 18, color: AppTheme.textLight),
                    ]),
                  ),
                ),
                // ── Inline day grid ──────────────────────────────────
                if (showDayPicker) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Pick the day of month when interest is due',
                          style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7, childAspectRatio: 1.0,
                            crossAxisSpacing: 4, mainAxisSpacing: 4),
                        itemCount: 31,
                        itemBuilder: (_, i) {
                          final day = i + 1;
                          final isSel = day == tempDay;
                          return GestureDetector(
                            onTap: () => setInner(() => tempDay = day),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSel ? AppTheme.primaryColor : Colors.white,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: isSel ? AppTheme.primaryColor : AppTheme.bgLight),
                              ),
                              child: Center(child: Text('$day',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                      color: isSel ? Colors.white : AppTheme.textDark))),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                        TextButton(
                          onPressed: () => setInner(() => showDayPicker = false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => setInner(() {
                            monthlyDueDay = tempDay;
                            showDayPicker = false;
                          }),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
                          child: Text('Set ${_ordinal(tempDay)}'),
                        ),
                      ]),
                    ]),
                  ),
                ],
                const SizedBox(height: 10),
              ],

              // ── Loan Start Date picker ──────────────────────────────
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: loanDate,
                    firstDate: DateTime(2000),
                    lastDate: DateTime.now(),
                    helpText: 'When was the loan given/taken?',
                  );
                  if (picked != null) setInner(() => loanDate = picked);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(
                    color: AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: loanDate.day != DateTime.now().day || loanDate.month != DateTime.now().month || loanDate.year != DateTime.now().year
                          ? AppTheme.primaryColor.withValues(alpha: 0.4)
                          : Colors.transparent,
                    ),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor, size: 18),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Loan Start Date', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
                      const SizedBox(height: 2),
                      Text(DateFormat('d MMM yyyy').format(loanDate),
                          style: const TextStyle(fontSize: 13, color: AppTheme.textDark, fontWeight: FontWeight.w600)),
                    ])),
                    Text(
                      loanDate.day == DateTime.now().day && loanDate.month == DateTime.now().month && loanDate.year == DateTime.now().year
                          ? 'Today' : _daysAgoLabel(loanDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: loanDate.isBefore(DateTime.now()) && !(loanDate.day == DateTime.now().day && loanDate.month == DateTime.now().month && loanDate.year == DateTime.now().year)
                            ? AppTheme.accentOrange : AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.edit_calendar_rounded, size: 15, color: AppTheme.textLight),
                  ]),
                ),
              ),
              const SizedBox(height: 10),

              // ── Due date picker ────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: dueDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2000),
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
                    Text(dueDate == null ? (isFlat ? 'Set Expected Return Date (optional)' : 'Set Due Date (optional)')
                        : (isFlat ? 'Expected return: ' : 'Due: ') + DateFormat('d MMM yyyy').format(dueDate!),
                        style: TextStyle(fontSize: 13, color: dueDate == null ? AppTheme.textLight : AppTheme.textDark)),
                  ]),
                ),
              ),
              const SizedBox(height: 16),

              // ── Live preview ───────────────────────────────────────
              if (previewMonthly > 0)
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.07),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      const Icon(Icons.calculate_rounded, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        isFlat
                            ? 'Monthly Interest: ${IndianNumberFormat.formatCompact(previewMonthly)}'
                            : 'Monthly EMI: ${IndianNumberFormat.formatCompact(previewMonthly)}',
                        style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ]),
                    if (isFlat) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Principal stays as ₹${IndianNumberFormat.formatCompact(amt)} until returned. '
                        'Borrower pays ${IndianNumberFormat.formatCompact(previewMonthly)}/month as interest.',
                        style: const TextStyle(fontSize: 11, color: AppTheme.textMedium),
                      ),
                    ] else if (previewInterest > 0) ...[
                      const SizedBox(height: 4),
                      Text('Total Interest: ${IndianNumberFormat.formatCompact(previewInterest)}',
                          style: const TextStyle(color: AppTheme.accentOrange, fontSize: 11)),
                    ],
                  ]),
                ),

              // ── Save button ────────────────────────────────────────
              SizedBox(width: double.infinity, child: ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final amtVal = double.tryParse(amtCtrl.text) ?? 0;
                  if (name.isEmpty || amtVal <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter name and amount')));
                    return;
                  }
                  final p2p = P2PLoan(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    personName: name,
                    amount: amtVal,
                    isLent: isLent,
                    date: loanDate,
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text.trim(),
                    phoneNumber: phoneCtrl.text.isEmpty ? null : '91${phoneCtrl.text.replaceAll(' ', '')}',
                    dueDate: dueDate,
                    interestRate: rateCtrl.text.isEmpty ? null : double.tryParse(rateCtrl.text),
                    tenureMonths: (!isFlat && tenureCtrl.text.isNotEmpty) ? int.tryParse(tenureCtrl.text) : null,
                    isFlat: isFlat,
                    interestPeriod: interestPeriod,
                    monthlyDueDay: monthlyDueDay,
                  );
                  await _box.add(p2p);
                  // Schedule P2P interest reminder if due day set
                  if (isFlat && monthlyDueDay != null && widget.notificationService != null) {
                    final rate = double.tryParse(rateCtrl.text) ?? 0;
                    final amt = double.tryParse(amtCtrl.text) ?? 0;
                    final mi = interestPeriod == 'monthly' ? amt * rate / 100 : amt * rate / 1200;
                    if (mi > 0) {
                      await widget.notificationService!.scheduleP2PInterestReminder(
                        loanId: p2p.id,
                        personName: name,
                        monthlyInterest: mi,
                        dueDay: monthlyDueDay!,
                        isLent: isLent,
                      );
                    }
                  }
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
            ]),
          );
        },
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

  String _daysAgoLabel(DateTime date) {
    final diff = DateTime.now().difference(date).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 30) return '$diff days ago';
    final months = (diff / 30).round();
    if (months < 12) return '$months month${months > 1 ? 's' : ''} ago';
    final years = (diff / 365).round();
    return '$years year${years > 1 ? 's' : ''} ago';
  }

  String _ordinal(int n) {    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  InputDecoration _inputDeco(String label, IconData icon, {String? prefix}) => InputDecoration(
    labelText: label,
    prefixText: prefix,
    prefixIcon: Icon(icon, color: AppTheme.primaryColor, size: 18),
    filled: true, fillColor: AppTheme.bgLight,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
  );

  Widget _choiceBtn(String label, bool active, VoidCallback onTap, {String? subtitle}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: active ? AppTheme.primaryColor : AppTheme.textLight),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: active ? AppTheme.primaryColor : AppTheme.textMedium, fontSize: 13), textAlign: TextAlign.center),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10, color: active ? AppTheme.primaryColor : AppTheme.textLight), textAlign: TextAlign.center),
        ],
      ]),
    ),
  );
}


