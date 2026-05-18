import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/savings_goal.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class SavingsGoalScreen extends StatelessWidget {
  final List<Loan> loans;
  const SavingsGoalScreen({super.key, required this.loans});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<SavingsGoal>('savings_goals');
    final totalMonthlyEMI = loans.fold(0.0, (s, l) => s + l.emiAmount);

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('Savings Goals'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<SavingsGoal> b, _) {
          final goals = b.values.toList();
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAfterEMICard(totalMonthlyEMI),
                ),
              ),
              if (goals.isEmpty)
                SliverFillRemaining(
                  child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.savings_rounded, size: 64, color: AppTheme.textLight),
                    const SizedBox(height: 12),
                    const Text('No savings goals yet', style: TextStyle(fontSize: 16, color: AppTheme.textMedium)),
                    const SizedBox(height: 8),
                    const Text('Add a goal to start tracking your savings!', style: TextStyle(fontSize: 13, color: AppTheme.textLight)),
                  ])),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (ctx, i) => _buildGoalCard(context, goals[i]),
                      childCount: goals.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context, box),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Goal'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildAfterEMICard(double totalEMI) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 32),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Monthly EMI Commitment', style: TextStyle(color: Colors.white70, fontSize: 12)),
          Text(IndianNumberFormat.formatCompact(totalEMI), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          const Text('After paying all EMIs, remaining income is available for savings',
              style: TextStyle(color: Colors.white60, fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildGoalCard(BuildContext context, SavingsGoal goal) {
    final box = Hive.box<SavingsGoal>('savings_goals');
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: goal.isCompleted ? Border.all(color: AppTheme.statusSuccess, width: 1.5) : null,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(goal.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(goal.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            Text('Target: ${DateFormat('MMM yyyy').format(goal.targetDate)} • ${goal.monthsRemaining}m left',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(IndianNumberFormat.formatCompact(goal.savedAmount),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryColor)),
            Text('of ${IndianNumberFormat.formatCompact(goal.targetAmount)}',
                style: const TextStyle(fontSize: 11, color: AppTheme.textLight)),
          ]),
        ]),
        const SizedBox(height: 12),
        Stack(children: [
          LinearProgressIndicator(
            value: goal.progressPercent,
            backgroundColor: AppTheme.bgLight,
            valueColor: AlwaysStoppedAnimation<Color>(
                goal.isCompleted ? AppTheme.statusSuccess : AppTheme.primaryColor),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Text('${(goal.progressPercent * 100).toStringAsFixed(0)}% achieved',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
          const Spacer(),
          if (goal.isCompleted)
            const Text('🎉 Goal Achieved!', style: TextStyle(fontSize: 11, color: AppTheme.statusSuccess, fontWeight: FontWeight.bold))
          else
            Text('${IndianNumberFormat.formatCompact(goal.remaining)} remaining',
                style: const TextStyle(fontSize: 11, color: AppTheme.textMedium)),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showAddMoneySheet(context, goal),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add Money', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
                side: const BorderSide(color: AppTheme.primaryColor),
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final key = goal.key;
              await box.delete(key);
            },
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.statusError, size: 20),
          ),
        ]),
      ]),
    );
  }

  void _showAddMoneySheet(BuildContext context, SavingsGoal goal) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Add to "${goal.name}"', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: ctrl, keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Amount', prefixIcon: Icon(Icons.payments_rounded)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                final amt = double.tryParse(ctrl.text) ?? 0;
                goal.savedAmount = (goal.savedAmount + amt).clamp(0, goal.targetAmount);
                await goal.save();
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Save'),
            ),
          ),
        ]),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, Box<SavingsGoal> box) {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    final monthlyCtrl = TextEditingController();
    String selectedEmoji = '🎯';
    DateTime targetDate = DateTime.now().add(const Duration(days: 365));
    const emojis = ['🎯', '🏠', '🚗', '✈️', '💍', '📱', '🎓', '💰', '🌴', '🏥'];

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setInner) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('New Savings Goal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            // Emoji picker
            Wrap(
              spacing: 8,
              children: emojis.map((e) => GestureDetector(
                onTap: () => setInner(() => selectedEmoji = e),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selectedEmoji == e ? AppTheme.primaryColor.withValues(alpha: 0.1) : AppTheme.bgLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: selectedEmoji == e ? AppTheme.primaryColor : Colors.transparent),
                  ),
                  child: Text(e, style: const TextStyle(fontSize: 22)),
                ),
              )).toList(),
            ),
            const SizedBox(height: 12),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Goal Name (e.g., New Car, Trip to Goa)')),
            const SizedBox(height: 8),
            TextField(controller: amtCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Target Amount')),
            const SizedBox(height: 8),
            TextField(controller: monthlyCtrl, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'Monthly Contribution')),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
              title: Text('Target Date: ${DateFormat('d MMM yyyy').format(targetDate)}'),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () async {
                final picked = await showDatePicker(context: ctx, initialDate: targetDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 3650)));
                if (picked != null) setInner(() => targetDate = picked);
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameCtrl.text.trim().isEmpty || amtCtrl.text.isEmpty) return;
                  final goal = SavingsGoal(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameCtrl.text.trim(),
                    targetAmount: double.parse(amtCtrl.text),
                    targetDate: targetDate,
                    emoji: selectedEmoji,
                    monthlyContribution: double.tryParse(monthlyCtrl.text) ?? 0,
                  );
                  await box.add(goal);
                  if (context.mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('Create Goal', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

