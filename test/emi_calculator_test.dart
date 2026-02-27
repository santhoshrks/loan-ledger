import 'package:flutter_test/flutter_test.dart';
import 'package:emi_reminder/utils/emi_calculator.dart';

void main() {
  test('EMI relations: total amount = emi * tenure and interest = total - principal', () {
    final principal = 100000.0;
    final rate = 12.0;
    final tenure = 12;

    final emi = EMICalculator.calculateEMI(principal: principal, annualRate: rate, tenureMonths: tenure);
    final totalAmount = EMICalculator.calculateTotalAmount(principal: principal, annualRate: rate, tenureMonths: tenure);
    final totalInterest = EMICalculator.calculateTotalInterest(principal: principal, annualRate: rate, tenureMonths: tenure);

    expect((emi * tenure - totalAmount).abs() < 0.01, true);
    expect((totalAmount - principal - totalInterest).abs() < 0.01, true);
  });

  test('Compound future value grows with positive rate', () {
    final principal = 50000.0;
    final rate = 8.0;
    final years = 5;
    final fv = EMICalculator.calculateCompoundFutureValue(principal: principal, annualRate: rate, years: years, compoundingPerYear: 12);

    expect(fv > principal, true);
  });

  test('SIP: missed months reduce invested amount and future value; start contribution increases FV', () {
    final monthly = 1000.0;
    final rate = 12.0;
    final months = 12;

    final full = EMICalculator.calculateSIP(monthlyInvestment: monthly, annualRate: rate, months: months);
    final missed = EMICalculator.calculateSIP(monthlyInvestment: monthly, annualRate: rate, months: months, missedMonths: [3,6]);
    final startContribution = EMICalculator.calculateSIP(monthlyInvestment: monthly, annualRate: rate, months: months, contributionAtStart: true);

    // total invested with missed months should be less
    expect(missed['totalInvested']! < full['totalInvested']!, true);

    // future value with missed months should be less than full
    expect(missed['futureValue']! < full['futureValue']!, true);

    // contribution at start should give greater or equal FV compared to end-of-month contributions
    expect(startContribution['futureValue']! > full['futureValue']! || (startContribution['futureValue']! - full['futureValue']!).abs() < 1e-6, true);
  });
}
