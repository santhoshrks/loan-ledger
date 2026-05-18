import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class BalanceTransferScreen extends StatefulWidget {
  const BalanceTransferScreen({super.key});
  @override
  State<BalanceTransferScreen> createState() => _BalanceTransferScreenState();
}

class _BalanceTransferScreenState extends State<BalanceTransferScreen> {
  final _balanceCtrl = TextEditingController();
  final _oldRateCtrl = TextEditingController();
  final _newRateCtrl = TextEditingController();
  final _tenureCtrl = TextEditingController();
  final _transferFeeCtrl = TextEditingController(text: '0');
  _BTResult? _result;

  double _calcEMI(double p, double r, int n) {
    if (r == 0) return p / n;
    final mr = r / 12 / 100;
    final f = math.pow(1 + mr, n).toDouble();
    return p * mr * f / (f - 1);
  }

  void _calculate() {
    final balance = double.tryParse(_balanceCtrl.text);
    final oldRate = double.tryParse(_oldRateCtrl.text);
    final newRate = double.tryParse(_newRateCtrl.text);
    final tenure = int.tryParse(_tenureCtrl.text);
    final fee = double.tryParse(_transferFeeCtrl.text) ?? 0;
    if (balance == null || oldRate == null || newRate == null || tenure == null) return;

    final oldEMI = _calcEMI(balance, oldRate, tenure);
    final newEMI = _calcEMI(balance, newRate, tenure);
    final oldTotal = oldEMI * tenure;
    final newTotal = newEMI * tenure + fee;
    final saving = oldTotal - newTotal;
    final breakEvenMonths = saving > 0 && (oldEMI - newEMI) > 0
        ? (fee / (oldEMI - newEMI)).ceil() : 0;

    setState(() {
      _result = _BTResult(
        oldEMI: oldEMI, newEMI: newEMI,
        oldTotal: oldTotal, newTotal: newTotal,
        saving: saving, transferFee: fee,
        breakEvenMonths: breakEvenMonths,
        worthIt: saving > fee,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Balance Transfer Calculator'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _infoBanner('💡 Compare your current loan rate with a new bank\'s offer to see exact savings.'),
          const SizedBox(height: 20),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('Current Loan'),
            const SizedBox(height: 12),
            _field(_balanceCtrl, 'Outstanding Balance', Icons.account_balance_wallet_rounded),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field(_oldRateCtrl, 'Current Rate (%)', Icons.percent_rounded, decimal: true)),
              const SizedBox(width: 12),
              Expanded(child: _field(_tenureCtrl, 'Remaining Months', Icons.schedule_rounded)),
            ]),
          ])),
          const SizedBox(height: 16),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _sectionLabel('New Bank Offer'),
            const SizedBox(height: 12),
            _field(_newRateCtrl, 'New Interest Rate (%)', Icons.trending_down_rounded, decimal: true),
            const SizedBox(height: 12),
            _field(_transferFeeCtrl, 'Transfer Fee / Processing Charge', Icons.receipt_rounded),
          ])),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.compare_arrows_rounded),
              label: const Text('Compare & Calculate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_result != null) ...[const SizedBox(height: 24), _buildResult(_result!)],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _buildResult(_BTResult r) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Verdict
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: r.worthIt
                ? [const Color(0xFF22C55E), const Color(0xFF4ADE80)]
                : [AppTheme.statusWarning, const Color(0xFFFBBF24)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(children: [
          Icon(r.worthIt ? Icons.thumb_up_rounded : Icons.info_rounded, color: Colors.white, size: 32),
          const SizedBox(height: 8),
          Text(r.worthIt ? 'Balance Transfer is WORTH IT! ✅' : 'Not Beneficial After Fees ⚠️',
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
            r.saving > 0
                ? 'You save ${IndianNumberFormat.formatCompact(r.saving)} over the loan tenure'
                : 'Transfer fee exceeds interest savings',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ]),
      ),
      const SizedBox(height: 16),
      _card(Column(children: [
        _compareRow('Monthly EMI', IndianNumberFormat.formatCompact(r.oldEMI), IndianNumberFormat.formatCompact(r.newEMI)),
        const Divider(),
        _compareRow('Total Payment', IndianNumberFormat.formatCompact(r.oldTotal), IndianNumberFormat.formatCompact(r.newTotal)),
        const Divider(),
        _compareRow('Interest Saved', '-', IndianNumberFormat.formatCompact(r.saving > 0 ? r.saving : 0)),
        if (r.transferFee > 0) ...[
          const Divider(),
          _compareRow('Transfer Fee', '-', '- ${IndianNumberFormat.formatCompact(r.transferFee)}'),
        ],
        if (r.breakEvenMonths > 0) ...[
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Break-Even', style: TextStyle(color: AppTheme.textMedium, fontSize: 13)),
              Text('${r.breakEvenMonths} months', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
            ]),
          ),
        ],
      ])),
    ]);
  }

  Widget _compareRow(String label, String before, String after) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: AppTheme.textMedium, fontSize: 13))),
      Text(before, style: const TextStyle(color: AppTheme.textDark, fontSize: 13)),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(Icons.arrow_forward_rounded, size: 14, color: AppTheme.primaryColor),
      ),
      Text(after, style: const TextStyle(color: AppTheme.statusSuccess, fontWeight: FontWeight.bold, fontSize: 13)),
    ]),
  );

  Widget _infoBanner(String msg) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      const Icon(Icons.lightbulb_rounded, color: AppTheme.primaryColor, size: 18),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: const TextStyle(fontSize: 12, color: AppTheme.textDark))),
    ]),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
    child: child,
  );

  Widget _sectionLabel(String t) => Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark));

  Widget _field(TextEditingController c, String label, IconData icon, {bool decimal = false}) => TextField(
    controller: c,
    keyboardType: decimal ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(decimal ? r'[\d.]' : r'\d'))],
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      filled: true, fillColor: AppTheme.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}

class _BTResult {
  final double oldEMI, newEMI, oldTotal, newTotal, saving, transferFee;
  final int breakEvenMonths;
  final bool worthIt;
  _BTResult({required this.oldEMI, required this.newEMI, required this.oldTotal, required this.newTotal, required this.saving, required this.transferFee, required this.breakEvenMonths, required this.worthIt});
}

