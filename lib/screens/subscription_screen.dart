import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/subscription.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

class SubscriptionScreen extends StatefulWidget {
  final NotificationService notificationService;

  const SubscriptionScreen({
    super.key,
    required this.notificationService,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  late final Box<Subscription> _subscriptionsBox;

  @override
  void initState() {
    super.initState();
    _subscriptionsBox = Hive.box<Subscription>('subscriptions');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Subscriptions'),
        backgroundColor: Colors.white,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addSubscription,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Subscription'),
      ),
      body: ValueListenableBuilder(
        valueListenable: _subscriptionsBox.listenable(),
        builder: (context, Box<Subscription> box, _) {
          final subscriptions = box.values.toList()
            ..sort((a, b) => a.daysUntilDue().compareTo(b.daysUntilDue()));

          if (subscriptions.isEmpty) {
            return const _EmptySubscriptions();
          }

          final monthlyTotal = subscriptions
              .where((s) => s.isActive)
              .fold<double>(0, (sum, s) => sum + s.amount);

          return Column(
            children: [
              _MonthlyTotalCard(total: monthlyTotal),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: subscriptions.length,
                  itemBuilder: (context, index) {
                    final sub = subscriptions[index];
                    return _SubscriptionCard(
                      subscription: sub,
                      onMarkPaid: () => _markPaid(sub),
                      onMarkUnpaid: () => _markUnpaid(sub),
                      onToggleActive: (value) => _toggleActive(sub, value),
                      onEdit: () => _editSubscription(sub),
                      onDelete: () => _deleteSubscription(sub),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _addSubscription() async {
    final draft = await showDialog<Subscription>(
      context: context,
      builder: (context) => const _SubscriptionEditorDialog(),
    );

    if (draft == null) return;

    await _subscriptionsBox.put(draft.id, draft);
    await widget.notificationService.scheduleSubscriptionReminders(draft);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${draft.name} added')),
    );
  }

  Future<void> _editSubscription(Subscription existing) async {
    final updated = await showDialog<Subscription>(
      context: context,
      builder: (context) => _SubscriptionEditorDialog(existing: existing),
    );

    if (updated == null) return;

    await _subscriptionsBox.put(updated.id, updated);
    await widget.notificationService.scheduleSubscriptionReminders(updated);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${updated.name} updated')),
    );
  }

  Future<void> _deleteSubscription(Subscription subscription) async {
    await widget.notificationService.cancelSubscriptionReminders(subscription.id);
    await _subscriptionsBox.delete(subscription.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${subscription.name} deleted')),
    );
  }

  Future<void> _markPaid(Subscription subscription) async {
    subscription.markPaid();
    await subscription.save();
    await widget.notificationService.scheduleSubscriptionReminders(subscription);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${subscription.name} marked paid for this cycle')),
    );
  }

  Future<void> _markUnpaid(Subscription subscription) async {
    subscription.markUnpaid();
    await subscription.save();
    await widget.notificationService.scheduleSubscriptionReminders(subscription);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${subscription.name} marked unpaid')),
    );
  }

  Future<void> _toggleActive(Subscription subscription, bool value) async {
    subscription.isActive = value;
    await subscription.save();
    if (value) {
      await widget.notificationService.scheduleSubscriptionReminders(subscription);
    } else {
      await widget.notificationService.cancelSubscriptionReminders(subscription.id);
    }
  }
}

class _MonthlyTotalCard extends StatelessWidget {
  final double total;

  const _MonthlyTotalCard({required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.subscriptions_rounded, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Monthly Subscription Total',
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Rs ${total.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onMarkPaid;
  final VoidCallback onMarkUnpaid;
  final ValueChanged<bool> onToggleActive;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SubscriptionCard({
    required this.subscription,
    required this.onMarkPaid,
    required this.onMarkUnpaid,
    required this.onToggleActive,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final nextDue = subscription.getNextDueDate();
    final isPaid = subscription.isPaidForCycle(subscription.getCurrentCycleDueDate());
    final days = subscription.daysUntilDue();

    final dueLabel = days < 0
        ? 'Overdue by ${days.abs()} days'
        : days == 0
            ? 'Due today'
            : 'Due in $days days';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  subscription.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              Switch(
                value: subscription.isActive,
                onChanged: onToggleActive,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${subscription.category} • ${_symbolForCurrency(subscription.currencyCode)}${subscription.amount.toStringAsFixed(0)}',
            style: TextStyle(color: Colors.grey[700], fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                '${nextDue.day}/${nextDue.month}/${nextDue.year} • $dueLabel',
                style: TextStyle(color: Colors.grey[700], fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isPaid ? onMarkUnpaid : onMarkPaid,
                  icon: Icon(isPaid ? Icons.undo_rounded : Icons.check_circle_outline_rounded, size: 18),
                  label: Text(isPaid ? 'Mark Unpaid' : 'Mark Paid'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded),
                color: AppTheme.statusError,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _symbolForCurrency(String code) {
    switch (code) {
      case 'USD':
        return '\$';
      case 'EUR':
        return 'EUR ';
      case 'GBP':
        return 'GBP ';
      default:
        return 'Rs ';
    }
  }
}

class _EmptySubscriptions extends StatelessWidget {
  const _EmptySubscriptions();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.subscriptions_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 14),
            const Text(
              'No subscriptions yet',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Add Netflix, Spotify, YouTube Premium and get renewal reminders.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubscriptionEditorDialog extends StatefulWidget {
  final Subscription? existing;

  const _SubscriptionEditorDialog({this.existing});

  @override
  State<_SubscriptionEditorDialog> createState() => _SubscriptionEditorDialogState();
}

class _SubscriptionEditorDialogState extends State<_SubscriptionEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _billingDayController = TextEditingController();
  final _notesController = TextEditingController();

  String _category = 'Streaming';
  String _currencyCode = 'INR';
  bool _isActive = true;

  static const List<String> _categories = [
    'Streaming',
    'Music',
    'Productivity',
    'Cloud',
    'Education',
    'General',
  ];

  static const List<String> _currencies = ['INR', 'USD', 'EUR', 'GBP'];

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.amount.toStringAsFixed(0);
      _billingDayController.text = existing.billingDay.toString();
      _notesController.text = existing.notes ?? '';
      _category = existing.category;
      _currencyCode = existing.currencyCode;
      _isActive = existing.isActive;
    } else {
      _billingDayController.text = DateTime.now().day.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _billingDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add Subscription' : 'Edit Subscription'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter subscription name' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Monthly amount'),
                  validator: (v) {
                    final parsed = double.tryParse(v ?? '');
                    if (parsed == null || parsed <= 0) return 'Enter a valid amount';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _billingDayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Billing day (1-31)'),
                  validator: (v) {
                    final day = int.tryParse(v ?? '');
                    if (day == null || day < 1 || day > 31) return 'Enter day between 1 and 31';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => _category = value ?? 'General'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _currencyCode,
                  decoration: const InputDecoration(labelText: 'Currency'),
                  items: _currencies
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (value) => setState(() => _currencyCode = value ?? 'INR'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                ),
                const SizedBox(height: 10),
                SwitchListTile.adaptive(
                  value: _isActive,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active'),
                  onChanged: (value) => setState(() => _isActive = value),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.existing;

    final result = Subscription(
      id: existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      billingDay: int.parse(_billingDayController.text.trim()),
      createdAt: existing?.createdAt ?? DateTime.now(),
      category: _category,
      isActive: _isActive,
      currencyCode: _currencyCode,
      lastPaidAt: existing?.lastPaidAt,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
    );

    Navigator.pop(context, result);
  }
}

