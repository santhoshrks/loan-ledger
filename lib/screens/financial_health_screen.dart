import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';

class FinancialHealthScreen extends StatefulWidget {
  final List<Loan> loans;
  const FinancialHealthScreen({super.key, required this.loans});
  @override
  State<FinancialHealthScreen> createState() => _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends State<FinancialHealthScreen> with SingleTickerProviderStateMixin {
  final _incomeCtrl = TextEditingController();
  final _savingsCtrl = TextEditingController();
  _HealthResult? _result;
  late AnimationController _animCtrl;
  late Animation<double> _scoreAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _scoreAnim = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() { _animCtrl.dispose(); super.dispose(); }

  void _calculate() {
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    final savings = double.tryParse(_savingsCtrl.text) ?? 0;
    if (income <= 0) return;
    final loans = widget.loans;
    final totalEMI = loans.fold(0.0, (s, l) => s + l.emiAmount);
    final overdueCount = loans.where((l) => l.isOverdue()).length;
    final paidCount = loans.where((l) => l.isPaid).length;

    // DTI Score (0-25 pts)
    final dti = (totalEMI / income) * 100;
    final dtiScore = dti < 20 ? 25 : dti < 30 ? 20 : dti < 40 ? 12 : dti < 50 ? 5 : 0;

    // Payment streak score (0-25 pts)
    final streakScore = loans.isEmpty ? 25 : overdueCount == 0 ? 25 : overdueCount == 1 ? 15 : 5;

    // Savings rate score (0-25 pts)
    final savingsRate = (savings / income) * 100;
    final savingsScore = savingsRate > 20 ? 25 : savingsRate > 10 ? 18 : savingsRate > 5 ? 10 : 3;

    // Loan diversity score (0-25 pts)
    final types = loans.map((l) => l.loanTypeName ?? 'Other').toSet();
    final hasHomeOrEdu = types.any((t) => t == 'Home Loan' || t == 'Education Loan');
    final diversityScore = loans.isEmpty ? 20 : hasHomeOrEdu && loans.length <= 3 ? 22 : loans.length <= 2 ? 20 : loans.length <= 4 ? 15 : 8;

    final total = dtiScore + streakScore + savingsScore + diversityScore;
    final grade = total >= 85 ? 'Excellent' : total >= 70 ? 'Good' : total >= 50 ? 'Fair' : 'Needs Improvement';
    final gradeColor = total >= 85 ? AppTheme.statusSuccess : total >= 70 ? AppTheme.accentBlue : total >= 50 ? AppTheme.statusWarning : AppTheme.statusError;

    final tips = <String>[];
    if (dti > 40) tips.add('Your EMI burden (${dti.toStringAsFixed(0)}%) is high. Try to close one loan early.');
    if (savingsRate < 10) tips.add('Save at least 10% of income. Currently saving ${savingsRate.toStringAsFixed(0)}%.');
    if (overdueCount > 0) tips.add('$overdueCount EMI(s) overdue! Pay immediately to protect your credit score.');
    if (loans.length > 4) tips.add('Too many active loans. Consider debt consolidation.');
    if (tips.isEmpty) tips.add('Great job! Keep maintaining your payment discipline. 🎉');

    setState(() {
      _result = _HealthResult(
        score: total, grade: grade, gradeColor: gradeColor,
        dtiScore: dtiScore, streakScore: streakScore,
        savingsScore: savingsScore, diversityScore: diversityScore,
        dti: dti, savingsRate: savingsRate, tips: tips,
        totalEMI: totalEMI, overdueCount: overdueCount,
      );
    });
    _animCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('Financial Health Score'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Enter Your Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            _field(_incomeCtrl, 'Monthly Income', Icons.account_balance_wallet_rounded),
            const SizedBox(height: 12),
            _field(_savingsCtrl, 'Monthly Savings', Icons.savings_rounded),
          ])),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.health_and_safety_rounded),
              label: const Text('Calculate Health Score', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
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

  Widget _buildResult(_HealthResult r) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Score circle
      AnimatedBuilder(
        animation: _scoreAnim,
        builder: (context, _) {
          final displayScore = (r.score * _scoreAnim.value).round();
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [r.gradeColor, r.gradeColor.withValues(alpha: 0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(
                  width: 120, height: 120,
                  child: CircularProgressIndicator(
                    value: _scoreAnim.value * r.score / 100,
                    strokeWidth: 10,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                Column(children: [
                  Text('$displayScore', style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                  const Text('/100', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ]),
              const SizedBox(height: 12),
              Text(r.grade, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const Text('Financial Health Score', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ]),
          );
        },
      ),
      const SizedBox(height: 16),

      // Score breakdown
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Score Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 12),
        _scoreBar('Debt-to-Income', r.dtiScore, 25, '${r.dti.toStringAsFixed(0)}% DTI', AppTheme.primaryColor),
        _scoreBar('Payment Streak', r.streakScore, 25, '${r.overdueCount} overdue', AppTheme.statusSuccess),
        _scoreBar('Savings Rate', r.savingsScore, 25, '${r.savingsRate.toStringAsFixed(0)}% saved', AppTheme.accentBlue),
        _scoreBar('Loan Diversity', r.diversityScore, 25, '${widget.loans.length} active loans', AppTheme.accentOrange),
      ])),
      const SizedBox(height: 16),

      // Tips
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('💡 Improvement Tips', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
        const SizedBox(height: 10),
        ...r.tips.map((tip) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('• ', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            Expanded(child: Text(tip, style: const TextStyle(fontSize: 13, color: AppTheme.textDark))),
          ]),
        )),
      ])),
    ]);
  }

  Widget _scoreBar(String label, int score, int max, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textDark)),
          Text('$score/$max', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: score / max,
          backgroundColor: AppTheme.bgLight,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6, borderRadius: BorderRadius.circular(3),
        ),
        const SizedBox(height: 2),
        Text(subtitle, style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
      ]),
    );
  }

  Widget _card(Widget c) => Container(
    width: double.infinity, padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
    child: c,
  );

  Widget _field(TextEditingController c, String label, IconData icon) => TextField(
    controller: c,
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      filled: true, fillColor: AppTheme.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );
}

class _HealthResult {
  final int score, dtiScore, streakScore, savingsScore, diversityScore, overdueCount;
  final String grade;
  final Color gradeColor;
  final double dti, savingsRate, totalEMI;
  final List<String> tips;
  _HealthResult({required this.score, required this.grade, required this.gradeColor, required this.dtiScore, required this.streakScore, required this.savingsScore, required this.diversityScore, required this.dti, required this.savingsRate, required this.tips, required this.totalEMI, required this.overdueCount});
}

