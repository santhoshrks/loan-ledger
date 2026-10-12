class LoanQuickTemplate {
  final String id;
  final String title;
  final String subtitle;
  final String loanType;
  final String suggestedName;
  final int suggestedEmi;
  final int suggestedTenureMonths;
  final int suggestedDueDay;
  final double suggestedInterestRate;
  final String? suggestedCurrencyCode;

  const LoanQuickTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.loanType,
    required this.suggestedName,
    required this.suggestedEmi,
    required this.suggestedTenureMonths,
    required this.suggestedDueDay,
    required this.suggestedInterestRate,
    this.suggestedCurrencyCode,
  });
}

class LoanTemplateService {
  static List<LoanQuickTemplate> templatesForCountry({
    required String countryCode,
    required String currencyCode,
  }) {
    switch (countryCode.toUpperCase()) {
      case 'PK':
        return [
          LoanQuickTemplate(
            id: 'pk_home',
            title: 'Home Finance',
            subtitle: 'Common Pakistan tenure setup',
            loanType: 'Home Loan',
            suggestedName: 'Home Loan',
            suggestedEmi: 85000,
            suggestedTenureMonths: 240,
            suggestedDueDay: 5,
            suggestedInterestRate: 18.0,
            suggestedCurrencyCode: 'PKR',
          ),
          LoanQuickTemplate(
            id: 'pk_personal',
            title: 'Personal Loan',
            subtitle: 'Fast setup for short-term debt',
            loanType: 'Personal Loan',
            suggestedName: 'Personal Loan',
            suggestedEmi: 22000,
            suggestedTenureMonths: 24,
            suggestedDueDay: 10,
            suggestedInterestRate: 24.0,
            suggestedCurrencyCode: 'PKR',
          ),
          LoanQuickTemplate(
            id: 'pk_bike',
            title: 'Bike Loan',
            subtitle: 'Popular two-wheeler financing',
            loanType: 'Two-Wheeler Loan',
            suggestedName: 'Bike Loan',
            suggestedEmi: 14000,
            suggestedTenureMonths: 36,
            suggestedDueDay: 12,
            suggestedInterestRate: 20.0,
            suggestedCurrencyCode: 'PKR',
          ),
        ];
      case 'PH':
        return [
          LoanQuickTemplate(
            id: 'ph_home',
            title: 'Housing Loan',
            subtitle: 'Long tenure housing setup',
            loanType: 'Home Loan',
            suggestedName: 'Housing Loan',
            suggestedEmi: 24000,
            suggestedTenureMonths: 180,
            suggestedDueDay: 5,
            suggestedInterestRate: 7.5,
            suggestedCurrencyCode: 'PHP',
          ),
          LoanQuickTemplate(
            id: 'ph_salary',
            title: 'Salary Loan',
            subtitle: 'Quick personal cash loan',
            loanType: 'Personal Loan',
            suggestedName: 'Salary Loan',
            suggestedEmi: 6200,
            suggestedTenureMonths: 24,
            suggestedDueDay: 15,
            suggestedInterestRate: 11.5,
            suggestedCurrencyCode: 'PHP',
          ),
          LoanQuickTemplate(
            id: 'ph_car',
            title: 'Auto Loan',
            subtitle: 'Typical bank auto installment',
            loanType: 'Car Loan',
            suggestedName: 'Car Loan',
            suggestedEmi: 18000,
            suggestedTenureMonths: 60,
            suggestedDueDay: 20,
            suggestedInterestRate: 8.0,
            suggestedCurrencyCode: 'PHP',
          ),
        ];
      case 'BD':
        return [
          LoanQuickTemplate(
            id: 'bd_home',
            title: 'Home Loan',
            subtitle: 'Long tenure monthly EMI plan',
            loanType: 'Home Loan',
            suggestedName: 'Home Loan',
            suggestedEmi: 28000,
            suggestedTenureMonths: 240,
            suggestedDueDay: 6,
            suggestedInterestRate: 9.8,
            suggestedCurrencyCode: 'BDT',
          ),
          LoanQuickTemplate(
            id: 'bd_personal',
            title: 'Personal Loan',
            subtitle: 'Easy short tenure setup',
            loanType: 'Personal Loan',
            suggestedName: 'Personal Loan',
            suggestedEmi: 9500,
            suggestedTenureMonths: 30,
            suggestedDueDay: 10,
            suggestedInterestRate: 13.5,
            suggestedCurrencyCode: 'BDT',
          ),
          LoanQuickTemplate(
            id: 'bd_bike',
            title: 'Bike Loan',
            subtitle: 'Two-wheeler financing example',
            loanType: 'Two-Wheeler Loan',
            suggestedName: 'Bike Loan',
            suggestedEmi: 7800,
            suggestedTenureMonths: 36,
            suggestedDueDay: 14,
            suggestedInterestRate: 11.5,
            suggestedCurrencyCode: 'BDT',
          ),
        ];
      case 'AE':
      case 'QA':
      case 'MY':
      case 'MM':
      case 'US':
      case 'IN':
      default:
        return firstLoanTemplates(currencyCode: currencyCode);
    }
  }

  static List<LoanQuickTemplate> firstLoanTemplates({
    String currencyCode = 'INR',
  }) {
    return [
      LoanQuickTemplate(
        id: 'home_loan',
        title: 'Home Loan',
        subtitle: 'Long tenure, predictable EMI',
        loanType: 'Home Loan',
        suggestedName: 'Home Loan',
        suggestedEmi: 22000,
        suggestedTenureMonths: 240,
        suggestedDueDay: 5,
        suggestedInterestRate: 8.5,
        suggestedCurrencyCode: currencyCode,
      ),
      LoanQuickTemplate(
        id: 'personal_loan',
        title: 'Personal Loan',
        subtitle: 'Shorter tenure setup',
        loanType: 'Personal Loan',
        suggestedName: 'Personal Loan',
        suggestedEmi: 6500,
        suggestedTenureMonths: 36,
        suggestedDueDay: 8,
        suggestedInterestRate: 13.0,
        suggestedCurrencyCode: currencyCode,
      ),
      LoanQuickTemplate(
        id: 'car_loan',
        title: 'Car Loan',
        subtitle: 'Common monthly structure',
        loanType: 'Car Loan',
        suggestedName: 'Car Loan',
        suggestedEmi: 12000,
        suggestedTenureMonths: 60,
        suggestedDueDay: 10,
        suggestedInterestRate: 9.5,
        suggestedCurrencyCode: currencyCode,
      ),
    ];
  }
}
