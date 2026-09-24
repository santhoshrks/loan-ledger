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
  });
}

class LoanTemplateService {
  static const List<LoanQuickTemplate> firstLoanTemplates = [
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
    ),
  ];
}
