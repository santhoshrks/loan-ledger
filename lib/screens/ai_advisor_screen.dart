import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class AiAdvisorScreen extends StatefulWidget {
  final List<Loan> loans;
  const AiAdvisorScreen({super.key, required this.loans});
  @override
  State<AiAdvisorScreen> createState() => _AiAdvisorScreenState();
}

class _AiAdvisorScreenState extends State<AiAdvisorScreen> {
  final _incomeCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _desiredEMICtrl = TextEditingController();
  List<_Advice> _advices = [];
  double? _eligibleLoanAmount;
  double? _safeNewEMI;

  void _analyze() {
    final income = double.tryParse(_incomeCtrl.text) ?? 0;
    final age = int.tryParse(_ageCtrl.text) ?? 30;
    final desiredEMI = double.tryParse(_desiredEMICtrl.text) ?? 0;
    if (income <= 0) return;

    final loans = widget.loans;
    final totalEMI = loans.fold(0.0, (s, l) => s + l.emiAmount);
    final dti = totalEMI / income * 100;
    final safeEMILimit = income * 0.40; // 40% DTI safe limit
    final safeNew = (safeEMILimit - totalEMI).clamp(0.0, double.infinity);
    final eligibleAmt = safeNew * 60; // rough 5-yr personal loan estimate

    final advices = <_Advice>[];

    // DTI advice
    if (dti > 50) {
      advices.add(_Advice('🚨 High Debt Load', 'Your EMI-to-income ratio is ${dti.toStringAsFixed(0)}%. Avoid new loans immediately. Focus on paying off existing debt.', AppTheme.statusError));
    } else if (dti > 40) {
      advices.add(_Advice('⚠️ Caution Zone', 'DTI at ${dti.toStringAsFixed(0)}%. You can take a small loan but be careful. Any new EMI above ${IndianNumberFormat.formatCompact(safeNew)} is risky.', AppTheme.statusWarning));
    } else {
      advices.add(_Advice('✅ Healthy DTI', 'Your DTI is ${dti.toStringAsFixed(0)}%. You can safely afford up to ${IndianNumberFormat.formatCompact(safeNew)} more in monthly EMI.', AppTheme.statusSuccess));
    }

    // Loan eligibility
    if (safeNew > 0) {
      advices.add(_Advice('💰 Loan Eligibility', 'Based on your income, you can take a new loan up to ${IndianNumberFormat.formatCompact(eligibleAmt)} (approx, 5yr personal loan @ 12%).', AppTheme.accentBlue));
    }

    // Age-based advice
    if (age > 50) {
      advices.add(_Advice('🎯 Age Advisory', 'At age $age, consider taking loans with shorter tenure (≤5 years). Lenders may have age limits for long-term loans.', AppTheme.accentOrange));
    } else if (age < 30) {
      advices.add(_Advice('🌱 Early Career Tip', 'Great time to build credit! Taking a home or education loan at low rates early can be very beneficial over the long term.', AppTheme.primaryColor));
    }

    // Desired EMI feasibility
    if (desiredEMI > 0) {
      if (desiredEMI <= safeNew) {
        advices.add(_Advice('✅ New EMI Feasible', 'Your desired EMI of ${IndianNumberFormat.formatCompact(desiredEMI)} is within safe limits. DTI will be ${((totalEMI + desiredEMI) / income * 100).toStringAsFixed(0)}%.', AppTheme.statusSuccess));
      } else {
        final excess = desiredEMI - safeNew;
        advices.add(_Advice('⚠️ EMI Too High', 'Desired EMI exceeds safe limit by ${IndianNumberFormat.formatCompact(excess)}. Consider increasing income or reducing existing EMIs first.', AppTheme.statusError));
      }
    }

    // Overdue advice
    final overdue = loans.where((l) => l.isOverdue()).toList();
    if (overdue.isNotEmpty) {
      advices.add(_Advice('🔴 Overdue Alert', '${overdue.length} EMI(s) overdue! Pay immediately. Missed EMIs negatively impact your credit score and may lead to penalty charges.', AppTheme.statusError));
    }

    // Best time advice
    final month = DateTime.now().month;
    if (month == 1 || month == 4) {
      advices.add(_Advice('📅 Good Time for Loan', 'Q1/Q2 start — Banks offer competitive rates. Good time to compare and negotiate.', AppTheme.secondaryColor));
    }

    setState(() {
      _advices = advices;
      _safeNewEMI = safeNew;
      _eligibleLoanAmount = eligibleAmt;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(title: const Text('AI EMI Advisor'), backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(16)),
            child: Row(children: [
              const Icon(Icons.psychology_rounded, color: Colors.white, size: 32),
              const SizedBox(width: 12),
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Smart Financial Advisor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                Text('Personalized EMI & loan recommendations', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Your Details', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            _field(_incomeCtrl, 'Monthly Take-Home Income', Icons.account_balance_wallet_rounded),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: _field(_ageCtrl, 'Your Age', Icons.cake_rounded)),
              const SizedBox(width: 10),
              Expanded(child: _field(_desiredEMICtrl, 'Desired New EMI', Icons.add_card_rounded)),
            ]),
          ])),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _analyze,
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Get AI Advice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          if (_advices.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Text('Personalized Advice', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark)),
            const SizedBox(height: 12),
            ..._advices.map((a) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: a.color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: a.color.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: a.color)),
                const SizedBox(height: 6),
                Text(a.body, style: const TextStyle(fontSize: 13, color: AppTheme.textDark, height: 1.4)),
              ]),
            )),
          ],
          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _card(Widget c) => Container(width: double.infinity, padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow), child: c);
  Widget _field(TextEditingController c, String label, IconData icon) => TextField(controller: c, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppTheme.primaryColor), filled: true, fillColor: AppTheme.bgLight, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12), labelStyle: const TextStyle(fontSize: 12)));
}

class _Advice { final String title, body; final Color color; _Advice(this.title, this.body, this.color); }

