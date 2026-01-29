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

    final numerator = principal * monthlyRate * pow(1 + monthlyRate, tenureMonths);
    final denominator = pow(1 + monthlyRate, tenureMonths) - 1;

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
    final numerator = log(emi / (emi - principal * monthlyRate));
    final denominator = log(1 + monthlyRate);

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
}

/// Helper function for power calculation
double pow(double base, int exponent) {
  double result = 1.0;
  for (int i = 0; i < exponent; i++) {
    result *= base;
  }
  return result;
}

/// Helper function for natural logarithm
double log(double value) {
  if (value <= 0) return 0;
  // Using Taylor series approximation for ln(x)
  double result = 0.0;
  double x = (value - 1) / (value + 1);
  double xSquared = x * x;
  double numerator = x;

  for (int i = 1; i <= 100; i += 2) {
    result += numerator / i;
    numerator *= xSquared;
  }

  return 2.0 * result;
}
