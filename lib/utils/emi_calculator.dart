import 'dart:math' as math;

/// EMI Calculator for calculating loan EMI, interest, and tenure
class EMICalculator {
  /// Calculate EMI (Equated Monthly Installment)
  /// Formula: EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)
  /// Where:
  /// P = Principal (Loan Amount)
  /// r = Monthly Interest Rate (Annual Rate / 12 / 100)
  /// n = Number of Months (Tenure)
  static double calculateEMI({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    if (principal <= 0 || annualRate < 0 || tenureMonths <= 0) {
      return 0;
    }

    final monthlyRate = annualRate / 12 / 100;

    if (monthlyRate == 0) {
      // If no interest, simple division
      return principal / tenureMonths;
    }

    final factor = math.pow(1 + monthlyRate, tenureMonths).toDouble();
    final numerator = principal * monthlyRate * factor;
    final denominator = factor - 1;

    return numerator / denominator;
  }

  /// Calculate total interest for the loan
  static double calculateTotalInterest({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final emi = calculateEMI(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
    final totalAmount = emi * tenureMonths;
    return totalAmount - principal;
  }

  /// Calculate total amount to be paid
  static double calculateTotalAmount({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final emi = calculateEMI(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
    return emi * tenureMonths;
  }

  /// Calculate tenure given principal, rate, and EMI
  static int calculateTenure({
    required double principal,
    required double annualRate,
    required double emi,
  }) {
    if (principal <= 0 || annualRate < 0 || emi <= 0) {
      return 0;
    }

    final monthlyRate = annualRate / 12 / 100;

    if (monthlyRate == 0) {
      return (principal / emi).ceil();
    }

    // Using the formula: n = log(EMI / (EMI - P*r)) / log(1 + r)
    final numerator = math.log(emi / (emi - principal * monthlyRate));
    final denominator = math.log(1 + monthlyRate);

    return (numerator / denominator).ceil();
  }

  /// Calculate rate given principal, EMI, and tenure (iterative approach)
  static double calculateRate({
    required double principal,
    required double emi,
    required int tenureMonths,
  }) {
    if (principal <= 0 || emi <= 0 || tenureMonths <= 0) {
      return 0;
    }

    // Simple interest rate estimation
    final maxPossibleRate = 36.0; // 36% max
    double low = 0.0;
    double high = maxPossibleRate;

    for (int i = 0; i < 100; i++) {
      final mid = (low + high) / 2;
      final calculatedEmi = calculateEMI(
        principal: principal,
        annualRate: mid,
        tenureMonths: tenureMonths,
      );

      if ((calculatedEmi - emi).abs() < 0.01) {
        return mid;
      }

      if (calculatedEmi < emi) {
        low = mid;
      } else {
        high = mid;
      }
    }

    return (low + high) / 2;
  }

  /// Get loan breakdown
  static Map<String, dynamic> getLoanBreakdown({
    required double principal,
    required double annualRate,
    required int tenureMonths,
  }) {
    final emi = calculateEMI(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
    final totalInterest = calculateTotalInterest(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );
    final totalAmount = calculateTotalAmount(
      principal: principal,
      annualRate: annualRate,
      tenureMonths: tenureMonths,
    );

    return {
      'emi': emi,
      'totalInterest': totalInterest,
      'totalAmount': totalAmount,
      'principal': principal,
      'rate': annualRate,
      'tenure': tenureMonths,
    };
  }

  /// Calculate future value for a compound interest (principal compounded periodically)
  /// principal: initial amount
  /// annualRate: annual nominal rate in percent (e.g., 8.5)
  /// years: number of years
  /// compoundingPerYear: times interest compounds per year (default 12 - monthly)
  static double calculateCompoundFutureValue({
    required double principal,
    required double annualRate,
    required int years,
    int compoundingPerYear = 12,
  }) {
    if (principal <= 0 || annualRate < 0 || years <= 0 || compoundingPerYear <= 0) return 0;
    final ratePerPeriod = annualRate / compoundingPerYear / 100;
    final totalPeriods = years * compoundingPerYear;
    return principal * math.pow(1 + ratePerPeriod, totalPeriods).toDouble();
  }

  /// Calculate SIP future value with optional missed months.
  /// monthlyInvestment: amount invested each period (monthly)
  /// annualRate: annual rate in percent
  /// months: total number of months
  /// missedMonths: optional list of 1-based month indices that were missed (e.g., [3,5])
  /// contributionAtStart: if true, treat contribution as at start of month (compounds one extra period)
  /// Returns a map with 'futureValue' and 'totalInvested'
  static Map<String, double> calculateSIP({
    required double monthlyInvestment,
    required double annualRate,
    required int months,
    List<int>? missedMonths,
    bool contributionAtStart = false,
  }) {
    if (monthlyInvestment <= 0 || months <= 0 || annualRate < 0) {
      return {'futureValue': 0.0, 'totalInvested': 0.0};
    }

    final monthlyRate = annualRate / 12 / 100;
    double fv = 0.0;
    double invested = 0.0;

    // Normalize missedMonths to a set for quick lookup
    final missed = <int>{};
    if (missedMonths != null) {
      for (var m in missedMonths) {
        if (m >= 1 && m <= months) missed.add(m);
      }
    }

    for (int m = 1; m <= months; m++) {
      if (missed.contains(m)) continue; // skipped contribution
      invested += monthlyInvestment;

      // Number of compounding periods the contribution will enjoy
      // If contribution is at end of month m, it compounds for (months - m) periods
      // If at start, compounds for (months - m + 1)
      final remainingPeriods = contributionAtStart ? (months - m + 1) : (months - m);
      final factor = remainingPeriods > 0 ? math.pow(1 + monthlyRate, remainingPeriods).toDouble() : 1.0;
      fv += monthlyInvestment * factor;
    }

    return {'futureValue': fv, 'totalInvested': invested};
  }
}
