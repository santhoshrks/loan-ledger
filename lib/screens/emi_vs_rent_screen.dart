import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/indian_number_format.dart';

class EmiVsRentScreen extends StatefulWidget {
  const EmiVsRentScreen({super.key});
  @override
  State<EmiVsRentScreen> createState() => _EmiVsRentScreenState();
}

class _EmiVsRentScreenState extends State<EmiVsRentScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;
  // Buy params
  final _propValueCtrl = TextEditingController(text: '5000000');
  final _downPayCtrl = TextEditingController(text: '1000000');
  final _loanRateCtrl = TextEditingController(text: '8.5');
  final _loanTenureCtrl = TextEditingController(text: '240');
  final _maintCtrl = TextEditingController(text: '3000');
  final _propAppCtrl = TextEditingController(text: '5');
  // Rent params
  final _rentCtrl = TextEditingController(text: '15000');
  final _rentHikeCtrl = TextEditingController(text: '5');
  final _investReturnCtrl = TextEditingController(text: '10');
  _EVRResult? _result;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  double _emi(double p, double r, int n) {
    if (r == 0) return p / n;
    final mr = r / 12 / 100;
    final f = math.pow(1 + mr, n).toDouble();
    return p * mr * f / (f - 1);
  }

  void _calculate() {
    final propVal = double.tryParse(_propValueCtrl.text) ?? 0;
    final downPay = double.tryParse(_downPayCtrl.text) ?? 0;
    final loanRate = double.tryParse(_loanRateCtrl.text) ?? 8.5;
    final tenure = int.tryParse(_loanTenureCtrl.text) ?? 240;
    final maint = double.tryParse(_maintCtrl.text) ?? 0;
    final propApp = double.tryParse(_propAppCtrl.text) ?? 5;
    final rent = double.tryParse(_rentCtrl.text) ?? 0;
    final rentHike = double.tryParse(_rentHikeCtrl.text) ?? 5;
    final investReturn = double.tryParse(_investReturnCtrl.text) ?? 10;
    final years = tenure ~/ 12;

    // BUY path
    final loanAmt = propVal - downPay;
    final emi = _emi(loanAmt, loanRate, tenure);
    final totalPaid = downPay + (emi * tenure) + (maint * tenure);
    final propFutureVal = propVal * math.pow(1 + propApp / 100, years);
    final buyNetWorth = propFutureVal - 0; // loan fully paid

    // RENT path — invest down payment
    double investedVal = downPay;
    double totalRentPaid = 0;
    double curRent = rent;
    for (int y = 0; y < years; y++) {
      totalRentPaid += curRent * 12;
      // Monthly savings from not paying EMI go to investment
      final monthlySaving = math.max(0.0, emi - curRent);
      investedVal = investedVal * math.pow(1 + investReturn / 100, 1) +
          monthlySaving * 12 * (math.pow(1 + investReturn / 100, 1) - 1) / (investReturn / 100);
      curRent *= (1 + rentHike / 100);
    }
    final rentNetWorth = investedVal;

    setState(() {
      _result = _EVRResult(
        emi: emi, totalBuyCost: totalPaid,
        propFutureVal: propFutureVal, buyNetWorth: buyNetWorth,
        totalRentPaid: totalRentPaid, rentNetWorth: rentNetWorth,
        buyWins: buyNetWorth > rentNetWorth,
        years: years, loanAmt: loanAmt,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('EMI vs Rent Calculator'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.home_rounded), text: 'Buy'),
            Tab(icon: Icon(Icons.apartment_rounded), text: 'Rent'),
          ],
        ),
      ),
      body: Column(children: [
        Expanded(
          child: TabBarView(controller: _tab, children: [
            _buildBuyTab(),
            _buildRentTab(),
          ]),
        ),
        // Calculate button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _calculate,
              icon: const Icon(Icons.compare_rounded),
              label: const Text('Compare Buy vs Rent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ),
        if (_result != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildVerdict(_result!),
          ),
      ]),
    );
  }

  Widget _buildBuyTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Property Details'),
      const SizedBox(height: 12),
      _f(_propValueCtrl, 'Property Value', Icons.home_rounded),
      const SizedBox(height: 10),
      _f(_downPayCtrl, 'Down Payment', Icons.savings_rounded),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _f(_loanRateCtrl, 'Loan Rate (%)', Icons.percent_rounded, dec: true)),
        const SizedBox(width: 10),
        Expanded(child: _f(_loanTenureCtrl, 'Tenure (months)', Icons.schedule_rounded)),
      ]),
      const SizedBox(height: 10),
      _f(_maintCtrl, 'Monthly Maintenance', Icons.build_rounded),
      const SizedBox(height: 10),
      _f(_propAppCtrl, 'Expected Property Appreciation (%/yr)', Icons.trending_up_rounded, dec: true),
    ])),
  );

  Widget _buildRentTab() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('Rental Details'),
      const SizedBox(height: 12),
      _f(_rentCtrl, 'Monthly Rent', Icons.apartment_rounded),
      const SizedBox(height: 10),
      _f(_rentHikeCtrl, 'Annual Rent Increase (%)', Icons.arrow_upward_rounded, dec: true),
      const SizedBox(height: 10),
      _f(_investReturnCtrl, 'Investment Return on Savings (%/yr)', Icons.show_chart_rounded, dec: true),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10)),
        child: const Text(
          '💡 In the Rent scenario, the down payment amount and monthly savings (vs EMI) are invested at the specified return rate.',
          style: TextStyle(fontSize: 12, color: AppTheme.textMedium),
        ),
      ),
    ])),
  );

  Widget _buildVerdict(_EVRResult r) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      gradient: LinearGradient(
        colors: r.buyWins
            ? [AppTheme.primaryColor, AppTheme.primaryLight]
            : [AppTheme.secondaryColor, AppTheme.secondaryLight],
        begin: Alignment.topLeft, end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(children: [
      Text(r.buyWins ? '🏠 BUYING is better!' : '🏢 RENTING is better!',
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _vStat('EMI', IndianNumberFormat.formatCompact(r.emi), r.buyWins),
        _vStat('Buy Net Worth', IndianNumberFormat.formatCompact(r.buyNetWorth), r.buyWins),
        _vStat('Rent Net Worth', IndianNumberFormat.formatCompact(r.rentNetWorth), !r.buyWins),
      ]),
    ]),
  );

  Widget _vStat(String l, String v, bool highlight) => Column(children: [
    Text(v, style: TextStyle(color: highlight ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
    Text(l, style: const TextStyle(color: Colors.white60, fontSize: 10)),
  ]);

  Widget _card(Widget c) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: AppTheme.bgCard, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
    child: c,
  );

  Widget _label(String t) => Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textDark));

  Widget _f(TextEditingController c, String label, IconData icon, {bool dec = false}) => TextField(
    controller: c,
    keyboardType: dec ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(dec ? r'[\d.]' : r'\d'))],
    decoration: InputDecoration(
      labelText: label, prefixIcon: Icon(icon, color: AppTheme.primaryColor),
      filled: true, fillColor: AppTheme.bgLight,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      labelStyle: const TextStyle(fontSize: 12),
    ),
  );
}

class _EVRResult {
  final double emi, totalBuyCost, propFutureVal, buyNetWorth, totalRentPaid, rentNetWorth, loanAmt;
  final bool buyWins;
  final int years;
  _EVRResult({required this.emi, required this.totalBuyCost, required this.propFutureVal, required this.buyNetWorth, required this.totalRentPaid, required this.rentNetWorth, required this.buyWins, required this.years, required this.loanAmt});
}

