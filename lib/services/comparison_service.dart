import 'dart:math' as math;
import '../models/debt_profile.dart';

class DebtComparison {
  final DebtProfile profile;
  final int monthsToPayoff;
  final double totalInterest;
  final double totalPaid;
  final double monthlyPayment;
  final double effectiveInterestRate;
  final List<double> payoffData;

  DebtComparison({
    required this.profile,
    required this.monthsToPayoff,
    required this.totalInterest,
    required this.totalPaid,
    required this.monthlyPayment,
    required this.effectiveInterestRate,
    required this.payoffData,
  });
}

class ComparisonService {
  /// Calculate comparison metrics for multiple debt profiles
  List<DebtComparison> compareProfiles(
    List<DebtProfile> profiles, {
    Map<String, double> extraPayments = const {},
  }) {
    return profiles.map((profile) {
      final extraPayment = extraPayments[profile.id] ?? 0;
      return _analyzeProfile(profile, extraPayment);
    }).toList();
  }

  /// Calculate the difference in total cost between two scenarios
  double calculateSavings(DebtComparison base, DebtComparison alternative) {
    return base.totalPaid - alternative.totalPaid;
  }

  /// Calculate time saved between two scenarios in months
  int calculateTimeSaved(DebtComparison base, DebtComparison alternative) {
    return base.monthsToPayoff - alternative.monthsToPayoff;
  }

  /// Find the optimal payment distribution for multiple debts
  /// Returns a map of profile IDs to recommended extra payments
  Map<String, double> optimizePayments(
    List<DebtProfile> profiles,
    double availableExtra,
  ) {
    // Sort profiles by interest rate (highest first)
    final sortedProfiles = List<DebtProfile>.from(profiles)
      ..sort((a, b) => b.interestRate.compareTo(a.interestRate));

    final recommendations = <String, double>{};
    var remainingExtra = availableExtra;

    // Allocate extra money to highest interest debts first
    for (final profile in sortedProfiles) {
      if (remainingExtra <= 0) break;

      // Calculate remaining debt
      final remainingDebt = profile.totalDebt - profile.amountPaid;
      if (remainingDebt <= 0) continue;

      // Allocate up to the remaining debt or available extra
      final allocation = remainingExtra > remainingDebt
          ? remainingDebt
          : remainingExtra;

      recommendations[profile.id] = allocation;
      remainingExtra -= allocation;
    }

    return recommendations;
  }

  /// Generate a summary of savings from following the optimal payment plan
  (double totalSaved, int monthsSaved) calculateOptimizationImpact(
    List<DebtProfile> profiles,
    Map<String, double> optimizedPayments,
  ) {
    // Compare baseline vs optimized scenario
    final baselineComparisons = compareProfiles(profiles);
    final optimizedComparisons = compareProfiles(
      profiles,
      extraPayments: optimizedPayments,
    );

    var totalSaved = 0.0;
    var maxMonthsSaved = 0;

    for (var i = 0; i < profiles.length; i++) {
      final baseline = baselineComparisons[i];
      final optimized = optimizedComparisons[i];

      totalSaved += calculateSavings(baseline, optimized);
      maxMonthsSaved = maxMonthsSaved < calculateTimeSaved(baseline, optimized)
          ? calculateTimeSaved(baseline, optimized)
          : maxMonthsSaved;
    }

    return (totalSaved, maxMonthsSaved);
  }

  /// Private helper to analyze a single profile
  DebtComparison _analyzeProfile(DebtProfile profile, double extraPayment) {
    final monthlyPayment = profile.monthlyPayment + extraPayment;
    final balance = profile.totalDebt - profile.amountPaid;
    final monthlyRate = profile.interestRate / 12 / 100;

    // Calculate months to payoff using amortization formula
    final monthsToPayoff = balance > 0
        ? (math.log(monthlyPayment / (monthlyPayment - balance * monthlyRate)) /
                math.log(1 + monthlyRate))
            .ceil()
        : 0;

    // Generate monthly balance data
    final payoffData = <double>[];
    var currentBalance = balance;
    var totalInterest = 0.0;

    for (var i = 0; i < monthsToPayoff; i++) {
      final interestPayment = currentBalance * monthlyRate;
      final principalPayment = monthlyPayment - interestPayment;
      
      totalInterest += interestPayment;
      currentBalance -= principalPayment;
      
      if (currentBalance < 0) currentBalance = 0;
      payoffData.add(currentBalance);
    }

    // Calculate effective interest rate
    final totalPaid = balance + totalInterest;
    final effectiveRate = (totalPaid / balance - 1) * 100;

    return DebtComparison(
      profile: profile,
      monthsToPayoff: monthsToPayoff,
      totalInterest: totalInterest,
      totalPaid: totalPaid,
      monthlyPayment: monthlyPayment,
      effectiveInterestRate: effectiveRate,
      payoffData: payoffData,
    );
  }
}
