import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../models/loan.dart';
import '../services/analytics_service.dart';
import '../services/loan_template_service.dart';
import '../services/loan_storage_service.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';

class AddLoanScreen extends StatefulWidget {
  final LoanStorageService storageService;
  final NotificationService notificationService;
  final Loan? existingLoan;
  final bool showQuickStartTemplates;

  const AddLoanScreen({
    super.key,
    required this.storageService,
    required this.notificationService,
    this.existingLoan,
    this.showQuickStartTemplates = false,
  });

  @override
  State<AddLoanScreen> createState() => _AddLoanScreenState();
}

class _AddLoanScreenState extends State<AddLoanScreen> {
  late TextEditingController _nameController;
  late TextEditingController _emiController;
  late TextEditingController _dueDayController;
  late TextEditingController _notesController;
  late TextEditingController _loanAmountController;
  late TextEditingController _interestRateController;
  late TextEditingController _tenureController;
  late TextEditingController _emisPaidController;
  late TextEditingController _bankNameController;

  DateTime? _selectedStartDate;
  bool _isLoading = false;
  bool _templateApplied = false;
  final _formKey = GlobalKey<FormState>();
  String _selectedLoanType = 'Other';
  String _selectedCurrency =
      'INR'; // Default currency (overridden from locale on init)

  final List<Map<String, dynamic>> _loanTypes = [
    {'name': 'Home Loan', 'icon': Icons.home_rounded},
    {'name': 'Car Loan', 'icon': Icons.directions_car_rounded},
    {'name': 'Two-Wheeler Loan', 'icon': Icons.two_wheeler_rounded},
    {'name': 'Personal Loan', 'icon': Icons.person_rounded},
    {'name': 'Education Loan', 'icon': Icons.school_rounded},
    {'name': 'Business Loan', 'icon': Icons.business_center_rounded},
    {'name': 'Gold Loan', 'icon': Icons.diamond_rounded},
    {'name': 'Chit Fund', 'icon': Icons.groups_rounded},
    {'name': 'Agricultural Loan', 'icon': Icons.agriculture_rounded},
    {'name': 'Microfinance', 'icon': Icons.handshake_rounded},
    {'name': 'Credit Card', 'icon': Icons.credit_card_rounded},
    {'name': 'Other', 'icon': Icons.account_balance_rounded},
  ];

  // Popular global banks & lenders
  static const List<String> popularBanks = [
    // Global / International
    'HSBC', 'Citibank', 'Standard Chartered', 'Barclays', 'Deutsche Bank',
    // USA
    'Chase', 'Bank of America', 'Wells Fargo', 'Goldman Sachs',
    // UK / Europe
    'Lloyds Bank', 'NatWest', 'Santander', 'BNP Paribas',
    // India
    'SBI',
    'HDFC Bank',
    'ICICI Bank',
    'Axis Bank',
    'Kotak Mahindra',
    'Bajaj Finance',
    // Southeast Asia
    'Maybank', 'CIMB', 'DBS', 'BRI', 'BCA', 'BDO', 'BPI',
    // Others
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _selectedCurrency = CurrencyHelper.getDefaultCurrency();
    _initializeControllers();
    if (widget.existingLoan != null) {
      _populateForm(widget.existingLoan!);
    } else {
      _selectedStartDate = DateTime.now();
    }
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _emiController = TextEditingController();
    _dueDayController = TextEditingController();
    _notesController = TextEditingController();
    _loanAmountController = TextEditingController();
    _interestRateController = TextEditingController();
    _tenureController = TextEditingController();
    _emisPaidController = TextEditingController(text: '0');
    _bankNameController = TextEditingController();
  }

  void _populateForm(Loan loan) {
    _nameController.text = loan.name;
    _emiController.text = loan.emiAmount.toStringAsFixed(0);
    _dueDayController.text = loan.dueDay.toString();
    _notesController.text = loan.notes ?? '';
    _loanAmountController.text = loan.loanAmount?.toStringAsFixed(0) ?? '';
    _interestRateController.text = loan.interestRate?.toString() ?? '';
    _tenureController.text = loan.tenureMonths?.toString() ?? '';
    _emisPaidController.text = loan.emisPaidCount.toString();
    _bankNameController.text = loan.bankName ?? '';
    _selectedStartDate = loan.startDate;
    _selectedCurrency = loan.currencyCode;

    // Set loan type from persisted value
    if (loan.loanTypeName != null) {
      _selectedLoanType = loan.loanTypeName!;
    } else {
      // Try to determine loan type from name (legacy)
      final name = loan.name.toLowerCase();
      for (var type in _loanTypes) {
        if (name.contains(
          type['name'].toString().toLowerCase().split(' ')[0],
        )) {
          _selectedLoanType = type['name'];
          break;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          widget.existingLoan == null
                              ? AppLocalizations.of(context).addLoanTitle
                              : AppLocalizations.of(context).editLoanTitle,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.existingLoan == null
                              ? AppLocalizations.of(
                                  context,
                                ).trackYourEmiPayments
                              : AppLocalizations.of(context).updateLoanDetails,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Form Content
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.existingLoan == null &&
                        widget.showQuickStartTemplates) ...[
                      _buildQuickStartTemplates(),
                      const SizedBox(height: 24),
                    ],

                    // Loan Type Selection
                    _buildSectionTitle(AppLocalizations.of(context).loanType),
                    const SizedBox(height: 12),
                    _buildLoanTypeSelector(),
                    const SizedBox(height: 24),

                    // Loan Name
                    _buildSectionTitle(
                      AppLocalizations.of(context).loanDetails,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nameController,
                      label: AppLocalizations.of(context).loanName,
                      hint: 'e.g., HSBC Home Loan',
                      icon: Icons.label_rounded,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Please enter loan name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Currency & EMI Row
                    Row(
                      children: [
                        // Currency Selector
                        _buildCurrencySelector(),
                        const SizedBox(width: 12),
                        // EMI Amount
                        Expanded(
                          flex: 2,
                          child: _buildTextField(
                            controller: _emiController,
                            label: AppLocalizations.of(context).emiAmount,
                            hint:
                                '${CurrencyHelper.getSymbol(_selectedCurrency)}0',
                            icon: Icons.payments_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              if (double.tryParse(value!) == null) {
                                return 'Invalid';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tenure Field
                    _buildTextField(
                      controller: _tenureController,
                      label: AppLocalizations.of(context).tenure,
                      hint: '60 months',
                      icon: Icons.schedule_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) => setState(() {}),
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Required';
                        }
                        if (int.tryParse(value!) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // EMIs Already Paid (shown only if start date is in the past)
                    if (_selectedStartDate != null && _isStartDateInPast()) ...[
                      _buildTextField(
                        controller: _emisPaidController,
                        label: 'EMIs Already Paid',
                        hint: _getExpectedEmisPaid().toString(),
                        icon: Icons.check_circle_rounded,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        helperText:
                            'Your loan started ${_getMonthsSinceStart()} months ago. Enter how many EMIs you\'ve already paid.',
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return null;
                          } // Optional
                          final paid = int.tryParse(value!);
                          if (paid == null || paid < 0) {
                            return 'Invalid';
                          }
                          final tenure =
                              int.tryParse(_tenureController.text) ?? 0;
                          if (tenure > 0 && paid > tenure) {
                            return 'Cannot exceed tenure';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Summary Card
                    _buildLoanSummaryCard(),
                    const SizedBox(height: 24),

                    // Due Date
                    _buildSectionTitle(
                      AppLocalizations.of(context).paymentSchedule,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _dueDayController,
                            label: AppLocalizations.of(context).dueDay,
                            hint: '1-31',
                            icon: Icons.calendar_month_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Required';
                              }
                              final day = int.tryParse(value!);
                              if (day == null || day < 1 || day > 31) {
                                return 'Invalid day';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: _buildDatePicker()),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Optional Details
                    _buildSectionTitle(
                      AppLocalizations.of(context).additionalDetails,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _loanAmountController,
                            label: AppLocalizations.of(context).loanAmount,
                            hint:
                                '${CurrencyHelper.getSymbol(_selectedCurrency)}0',
                            icon: Icons.account_balance_wallet_rounded,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTextField(
                            controller: _interestRateController,
                            label: AppLocalizations.of(context).interestRate,
                            hint: '0%',
                            icon: Icons.percent_rounded,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Bank / NBFC Name
                    _buildBankNameField(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _notesController,
                      label: AppLocalizations.of(context).notes,
                      hint: 'Add any additional details...',
                      icon: Icons.notes_rounded,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 32),

                    // Save Button
                    _buildSaveButton(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.textDark,
      ),
    );
  }

  Widget _buildLoanTypeSelector() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: _loanTypes.length,
        itemBuilder: (context, index) {
          final type = _loanTypes[index];
          final isSelected = _selectedLoanType == type['name'];
          return GestureDetector(
            onTap: () {
              setState(() {
                // Check if current name matches any loan type (auto-generated) in any language
                final l = AppLocalizations.of(context);
                final isAutoName = _loanTypes.any(
                  (t) =>
                      _nameController.text == t['name'] ||
                      _nameController.text == l.getLoanTypeName(t['name']) ||
                      _nameController.text.isEmpty,
                );

                _selectedLoanType = type['name'];

                // Update name only if it's empty or was auto-generated from another type
                // Use localized name
                if (isAutoName) {
                  _nameController.text = l.getLoanTypeName(type['name']);
                }
              });
            },
            child: Container(
              width: 80,
              margin: EdgeInsets.only(
                right: index < _loanTypes.length - 1 ? 12 : 0,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryColor : AppTheme.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.primaryColor
                      : AppTheme.textLight.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected ? AppTheme.cardShadow : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    type['icon'],
                    color: isSelected ? Colors.white : AppTheme.textMedium,
                    size: 28,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(
                      context,
                    ).getLoanTypeName(type['name']).split(' ')[0],
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppTheme.textMedium,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final currencies = [
      // Primary markets
      'INR', 'PKR', 'PHP', 'BDT',
      // Spanish-speaking markets
      'MXN', 'COP', 'ARS', 'PEN', 'CLP',
      // Other major currencies
      'USD', 'EUR', 'GBP', 'AED', 'SAR', 'SGD', 'AUD', 'CAD',
      'MYR', 'IDR', 'THB', 'JPY', 'CNY', 'KRW',
      'BRL', 'ZAR', 'TRY', 'RUB', 'CHF', 'HKD', 'NZD',
    ];

    return Expanded(
      flex: 1,
      child: GestureDetector(
        onTap: () => _showCurrencyPicker(currencies),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Currency',
                style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    CurrencyHelper.getSymbol(_selectedCurrency),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _selectedCurrency,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down_rounded,
                    color: AppTheme.textMedium,
                    size: 20,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCurrencyPicker(List<String> currencies) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.5,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: CurrencyHelper.supportedCurrencies.length,
                itemBuilder: (context, index) {
                  final code = CurrencyHelper.supportedCurrencies[index];
                  final isSelected = code == _selectedCurrency;
                  return ListTile(
                    onTap: () {
                      setState(() {
                        _selectedCurrency = code;
                      });
                      Navigator.pop(context);
                    },
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.bgLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          CurrencyHelper.getSymbol(code),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textDark,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      code,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppTheme.primaryColor
                            : AppTheme.textDark,
                      ),
                    ),
                    subtitle: Text(CurrencyHelper.getName(code)),
                    trailing: isSelected
                        ? Icon(
                            Icons.check_circle_rounded,
                            color: AppTheme.primaryColor,
                          )
                        : null,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int maxLines = 1,
    String? helperText,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onChanged: onChanged,
        maxLines: maxLines,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppTheme.textDark,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          helperMaxLines: 3,
          prefixIcon: Icon(icon, color: AppTheme.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.bgCard,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _selectStartDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.softShadow,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context).startDate,
                    style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedStartDate != null
                        ? DateFormat('MMM d, yyyy').format(_selectedStartDate!)
                        : 'Select date',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _selectedStartDate != null
                          ? AppTheme.textDark
                          : AppTheme.textLight,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppTheme.textLight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanSummaryCard() {
    double emi = double.tryParse(_emiController.text) ?? 0;
    int tenure = int.tryParse(_tenureController.text) ?? 0;
    double totalAmount = emi * tenure;

    if (emi == 0 && tenure == 0) {
      return const SizedBox.shrink();
    }

    // Use selected currency symbol for display
    final currencySymbol = CurrencyHelper.getSymbol(_selectedCurrency);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context).loanSummary,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$tenure ${AppLocalizations.of(context).months}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  AppLocalizations.of(context).monthlyEmi,
                  '$currencySymbol${NumberFormat('#,##,###').format(emi)}',
                  Icons.calendar_month_rounded,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              Expanded(
                child: _buildSummaryItem(
                  AppLocalizations.of(context).totalPayment,
                  '$currencySymbol${NumberFormat('#,##,###').format(totalAmount)}',
                  Icons.account_balance_wallet_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveLoan,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.existingLoan == null
                        ? Icons.add_rounded
                        : Icons.check_rounded,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.existingLoan == null
                        ? AppLocalizations.of(context).addLoan
                        : AppLocalizations.of(context).save,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.textDark,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked;
      });
    }
  }

  Future<void> _saveLoan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStartDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date'),
          backgroundColor: AppTheme.statusError,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final loan = Loan(
        id: widget.existingLoan?.id ?? _generateId(),
        name: _nameController.text.trim(),
        emiAmount: double.parse(_emiController.text),
        dueDay: int.parse(_dueDayController.text),
        startDate: _selectedStartDate!,
        notes: _notesController.text.isEmpty
            ? null
            : _notesController.text.trim(),
        loanAmount: _loanAmountController.text.isEmpty
            ? null
            : double.tryParse(_loanAmountController.text),
        interestRate: _interestRateController.text.isEmpty
            ? null
            : double.tryParse(_interestRateController.text),
        tenureMonths: _tenureController.text.isEmpty
            ? null
            : int.tryParse(_tenureController.text),
        currencyCode: _selectedCurrency,
        emisPaidCount: _emisPaidController.text.isEmpty
            ? 0
            : int.tryParse(_emisPaidController.text) ?? 0,
        bankName: _bankNameController.text.isEmpty
            ? null
            : _bankNameController.text.trim(),
        loanTypeName: _selectedLoanType,
      );

      if (widget.existingLoan != null) {
        await widget.storageService.updateLoan(widget.existingLoan!.id, loan);
      } else {
        await widget.storageService.addLoan(loan);
        await AnalyticsService.trackLoanCreated(
          loanType: _selectedLoanType,
          fromTemplate: _templateApplied,
        );
        await _markQuickStartTemplatesSeen();
      }

      // Schedule reminders
      await widget.notificationService.scheduleLoadReminders(loan);

      if (mounted) {
        Navigator.pop(context, loan);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving loan: $e'),
            backgroundColor: AppTheme.statusError,
          ),
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

  Widget _buildQuickStartTemplates() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Start (Recommended)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tap a template to prefill common values. You can edit everything before saving.',
          style: TextStyle(
            fontSize: 13,
            color: AppTheme.textMedium,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: LoanTemplateService.firstLoanTemplates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final template = LoanTemplateService.firstLoanTemplates[index];
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => _applyTemplate(template),
                child: Ink(
                  width: 210,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
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
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.flash_on_rounded,
                              size: 16,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              template.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        template.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMedium,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${CurrencyHelper.getSymbol(_selectedCurrency)}${template.suggestedEmi}/mo  •  ${template.suggestedTenureMonths}m',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _applyTemplate(LoanQuickTemplate template) {
    setState(() {
      _templateApplied = true;
      _selectedLoanType = template.loanType;
      _nameController.text = template.suggestedName;
      _emiController.text = template.suggestedEmi.toString();
      _tenureController.text = template.suggestedTenureMonths.toString();
      _dueDayController.text = template.suggestedDueDay.toString();
      _interestRateController.text = template.suggestedInterestRate
          .toStringAsFixed(1);
      _selectedStartDate = DateTime.now();
      _emisPaidController.text = '0';
    });
  }

  Future<void> _markQuickStartTemplatesSeen() async {
    if (!widget.showQuickStartTemplates) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_add_loan_quick_start_seen', true);
  }

  /// Check if start date is in the past (before current month)
  bool _isStartDateInPast() {
    if (_selectedStartDate == null) return false;
    final now = DateTime.now();
    // Consider past if start date is before current month
    return _selectedStartDate!.year < now.year ||
        (_selectedStartDate!.year == now.year &&
            _selectedStartDate!.month < now.month);
  }

  /// Get months since start date (including start month)
  int _getMonthsSinceStart() {
    if (_selectedStartDate == null) return 0;
    final now = DateTime.now();
    // June 2025 to January 2026 = 8 months (including both June and January)
    return (now.year - _selectedStartDate!.year) * 12 +
        (now.month - _selectedStartDate!.month) +
        1;
  }

  /// Get expected EMIs paid based on months since start
  int _getExpectedEmisPaid() {
    return _getMonthsSinceStart();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emiController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    _loanAmountController.dispose();
    _interestRateController.dispose();
    _tenureController.dispose();
    _emisPaidController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Widget _buildBankNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildTextField(
          controller: _bankNameController,
          label: 'Bank / NBFC Name',
          hint: 'e.g., HSBC, Chase, Barclays, HDFC Bank',
          icon: Icons.account_balance_rounded,
        ),
        const SizedBox(height: 8),
        // Quick select chips
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: popularBanks.take(8).map((bank) {
            final isSelected = _bankNameController.text == bank;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _bankNameController.text = bank == 'Other' ? '' : bank;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : AppTheme.bgLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : AppTheme.textLight,
                  ),
                ),
                child: Text(
                  bank,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Colors.white : AppTheme.textMedium,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
