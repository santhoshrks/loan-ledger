import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math';
import '../models/loan.dart';
import '../services/loan_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanStorageService storageService;
  final NotificationService notificationService;
  final Loan? existingLoan;

  const AddLoanScreen({
    Key? key,
    required this.storageService,
    required this.notificationService,
    this.existingLoan,
  }) : super(key: key);

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emiController;
  late TextEditingController _dueDayController;
  late TextEditingController _notesController;

  DateTime? _selectedStartDate;
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    if (widget.existingLoan != null) {
      _populateForm(widget.existingLoan!);
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emiController = TextEditingController();
    _dueDayController = TextEditingController();
    _notesController = TextEditingController();
  }

  void _populateForm(Loan loan) {
    _nameController.text = loan.name;
    _emiController.text = loan.emiAmount.toString();
    _dueDayController.text = loan.dueDay.toString();
    _notesController.text = loan.notes ?? '';
    _selectedStartDate = loan.startDate;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(widget.existingLoan == null ? 'Add Loan' : 'Edit Loan'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGreen, AppTheme.primaryGreenLight],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Loan Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Loan Name',
                  hintText: 'e.g., Car Loan, Home Loan',
                  prefixIcon: const Icon(Icons.label),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter loan name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // EMI Amount
              TextFormField(
                controller: _emiController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'EMI Amount (₹)',
                  hintText: '15000',
                  prefixIcon: const Icon(Icons.currency_rupee),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter EMI amount';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Due Day
              TextFormField(
                controller: _dueDayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Due Day of Month (1-31)',
                  hintText: '15',
                  prefixIcon: const Icon(Icons.calendar_month),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter due day';
                  }
                  final day = int.tryParse(value!);
                  if (day == null || day < 1 || day > 31) {
                    return 'Please enter a valid day (1-31)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Start Date
              GestureDetector(
                onTap: _selectStartDate,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppTheme.textLight),
                    borderRadius: BorderRadius.circular(8),
                    color: AppTheme.bgLight,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppTheme.textMedium),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Start Date',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedStartDate != null
                                  ? DateFormat('MMM d, yyyy').format(_selectedStartDate!)
                                  : 'Select start date',
                              style: TextStyle(
                                fontSize: 14,
                                color: _selectedStartDate != null
                                    ? AppTheme.textDark
                                    : AppTheme.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: AppTheme.textLight,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (Optional)',
                  hintText: 'Add any additional details...',
                  prefixIcon: const Icon(Icons.notes),
                ),
              ),
              const SizedBox(height: 16),

              // Test Notification Button (for debugging)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await widget.notificationService.showTestNotification();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l.testNotificationSent)),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.notifications_active),
                  label: Text(l.testNotification),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.orange,
                    side: const BorderSide(color: Colors.orange),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveLoan,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: AppTheme.primaryGreen,
                    disabledBackgroundColor: AppTheme.textLight,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.existingLoan == null
                              ? 'Add Loan'
                              : 'Update Loan',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedStartDate = pickedDate;
      });
    }
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate() || _selectedStartDate == null) {
      if (_selectedStartDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a start date')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loan = Loan(
        id: widget.existingLoan?.id ?? _generateId(),
        name: _nameController.text,
        emiAmount: double.parse(_emiController.text),
        dueDay: int.parse(_dueDayController.text),
        startDate: _selectedStartDate!,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        isPaid: widget.existingLoan?.isPaid ?? false,
      );

      if (widget.existingLoan == null) {
        await widget.storageService.addLoan(loan);
        // TODO: Set testMode to false for production
        await widget.notificationService.scheduleLoadReminders(loan, testMode: true);
      } else {
        await widget.storageService.updateLoan(loan.id, loan);
        // Reschedule notifications for updated loan
        await widget.notificationService.cancelLoanReminders(loan.id, tenureMonths: 12);
        // TODO: Set testMode to false for production
        await widget.notificationService.scheduleLoadReminders(loan, testMode: true);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving loan: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _generateId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(10000);
    return '${timestamp}_$random';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emiController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
