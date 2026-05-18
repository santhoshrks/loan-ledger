import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/p2p_loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class P2PLoanScreen extends StatefulWidget {
  const P2PLoanScreen({super.key});
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
        title: const Text('Peer-to-Peer Loans'),
        backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, elevation: 0,
        bottom: TabBar(
          controller: _tab, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white60,
          tabs: const [Tab(icon: Icon(Icons.arrow_upward_rounded), text: 'I Lent'), Tab(icon: Icon(Icons.arrow_downward_rounded), text: 'I Borrowed')],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box<P2PLoan> box, _) {
          final lent = box.values.where((l) => l.isLent).toList();
          final borrowed = box.values.where((l) => !l.isLent).toList();
          return Column(children: [
            _buildSummaryBar(lent, borrowed),
            Expanded(child: TabBarView(controller: _tab, children: [_buildList(lent, true), _buildList(borrowed, false)])),
          ]);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add_rounded), label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildSummaryBar(List<P2PLoan> lent, List<P2PLoan> borrowed) {
    final totalLent = lent.where((l) => !l.isSettled).fold(0.0, (s, l) => s + l.outstanding);
    final totalBorrowed = borrowed.where((l) => !l.isSettled).fold(0.0, (s, l) => s + l.outstanding);
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppTheme.primaryColor,
      child: Row(children: [
        Expanded(child: Column(children: [
          const Text('You\'ll Receive', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(IndianNumberFormat.formatCompact(totalLent), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
        ])),
        Container(width: 1, height: 40, color: Colors.white24),
        Expanded(child: Column(children: [
          const Text('You Owe', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(IndianNumberFormat.formatCompact(totalBorrowed), style: const TextStyle(color: AppTheme.accentOrange, fontWeight: FontWeight.bold, fontSize: 20)),
        ])),
      ]),
    );
  }

  Widget _buildList(List<P2PLoan> items, bool isLent) {
    if (items.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(isLent ? Icons.arrow_circle_up_rounded : Icons.arrow_circle_down_rounded, size: 64, color: AppTheme.textLight),
        const SizedBox(height: 12),
        Text(isLent ? 'No money lent yet' : 'No money borrowed', style: const TextStyle(color: AppTheme.textMedium, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, i) => _buildCard(items[i]),
    );
  }

  Widget _buildCard(P2PLoan loan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.softShadow,
        border: loan.isOverdue ? Border.all(color: AppTheme.statusError, width: 1.5) : null,
      ),
      child: Column(children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: loan.isLent ? AppTheme.statusSuccess.withValues(alpha: 0.15) : AppTheme.accentOrange.withValues(alpha: 0.15),
            child: Text(loan.personName[0].toUpperCase(), style: TextStyle(color: loan.isLent ? AppTheme.statusSuccess : AppTheme.accentOrange, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(loan.personName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (loan.notes != null) Text(loan.notes!, style: const TextStyle(fontSize: 12, color: AppTheme.textLight)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(IndianNumberFormat.formatCompact(loan.outstanding), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: loan.isSettled ? AppTheme.statusSuccess : AppTheme.textDark)),
            Text(loan.isSettled ? 'Settled ✅' : 'Outstanding', style: TextStyle(fontSize: 10, color: loan.isSettled ? AppTheme.statusSuccess : AppTheme.textMedium)),
          ]),
        ]),
        if (!loan.isSettled) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: loan.amount > 0 ? loan.repaidAmount / loan.amount : 0,
            backgroundColor: AppTheme.bgLight, minHeight: 4, borderRadius: BorderRadius.circular(2),
            valueColor: AlwaysStoppedAnimation<Color>(loan.isLent ? AppTheme.statusSuccess : AppTheme.accentOrange),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Text('${DateFormat('d MMM yyyy').format(loan.date)}', style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
            if (loan.dueDate != null) ...[
              const Text(' • Due: ', style: TextStyle(fontSize: 11, color: AppTheme.textLight)),
              Text(DateFormat('d MMM').format(loan.dueDate!), style: TextStyle(fontSize: 11, color: loan.isOverdue ? AppTheme.statusError : AppTheme.textLight, fontWeight: FontWeight.w600)),
            ],
            const Spacer(),
            if (loan.phoneNumber != null)
              GestureDetector(
                onTap: () => _sendWhatsApp(loan),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: const Color(0xFF25D366).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Row(children: [Icon(Icons.chat_rounded, size: 14, color: Color(0xFF25D366)), SizedBox(width: 4), Text('Remind', style: TextStyle(fontSize: 11, color: Color(0xFF25D366), fontWeight: FontWeight.w600))]),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showRepaySheet(loan),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: const Text('Update', style: TextStyle(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
              ),
            ),
          ]),
        ],
      ]),
    );
  }

  void _sendWhatsApp(P2PLoan loan) async {
    final amount = IndianNumberFormat.formatCompact(loan.outstanding);
    final msg = Uri.encodeComponent('Hi ${loan.personName}, just a friendly reminder about the outstanding amount of $amount. Please let me know when it\'s convenient to settle. Thank you!');
    final url = Uri.parse('https://wa.me/${loan.phoneNumber}?text=$msg');
    if (await canLaunchUrl(url)) await launchUrl(url);
  }

  void _showRepaySheet(P2PLoan loan) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Record Repayment — ${loan.personName}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(controller: ctrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Amount Repaid')),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                loan.repaidAmount = (loan.repaidAmount + amt).clamp(0, loan.amount);
                await loan.save();
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
              child: const Text('Save'),
            ),
          ),
        ]),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    bool isLent = true;
    DateTime? dueDate;

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Add P2P Loan Entry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _choiceBtn('I Lent', isLent, () => setInner(() => isLent = true))),
              const SizedBox(width: 12),
              Expanded(child: _choiceBtn('I Borrowed', !isLent, () => setInner(() => isLent = false))),
            ]),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Person Name')),
            const SizedBox(height: 8),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Amount')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone/WhatsApp (optional)', prefixText: '+91 ')),
            const SizedBox(height: 8),
            TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Notes (optional)')),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final p2p = P2PLoan(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    personName: nameCtrl.text.trim(),
                    amount: double.tryParse(amtCtrl.text) ?? 0,
                    isLent: isLent, date: DateTime.now(),
                    notes: notesCtrl.text.isEmpty ? null : notesCtrl.text,
                    phoneNumber: phoneCtrl.text.isEmpty ? null : '91${phoneCtrl.text.replaceAll(' ', '')}',
                    dueDate: dueDate,
                  );
                  await _box.add(p2p);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Add Entry', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _choiceBtn(String label, bool active, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.bgLight,
        borderRadius: BorderRadius.circular(10), border: Border.all(color: active ? AppTheme.primaryColor : AppTheme.textLight),
      ),
      child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: active ? AppTheme.primaryColor : AppTheme.textMedium))),
    ),
  );
}


