import 'dart:math' as math;
import '../models/debt_profile.dart';

class DebtService {
  /// Calculate months needed to pay off debt with optional extra payment
  int calculateMonthsToPayoff(DebtProfile profile, {double extraPayment = 0}) {
    final remainingDebt = profile.totalDebt - profile.amountPaid;
    final monthlyRate = (profile.interestRate / 100) / 12;
    final totalMonthlyPayment = profile.monthlyPayment + extraPayment;

    if (profile.interestRate == 0) {
      return (remainingDebt / totalMonthlyPayment).ceil();
    }

    return (-math.log(1 - (monthlyRate * remainingDebt) / totalMonthlyPayment) /
            math.log(1 + monthlyRate))
        .ceil();
  }

  /// Calculate payoff data points for visualization
  List<double> generatePayoffData(DebtProfile profile, {double extraPayment = 0}) {
    final months = calculateMonthsToPayoff(profile, extraPayment: extraPayment);
    final monthlyRate = (profile.interestRate / 100) / 12;
    var balance = profile.totalDebt - profile.amountPaid;
    final balances = [balance];
    final totalMonthlyPayment = profile.monthlyPayment + extraPayment;

    for (var i = 1; i <= months; i++) {
      final interest = balance * monthlyRate;
      balance = balance + interest - totalMonthlyPayment;
      if (balance < 0) balance = 0;
      balances.add(balance);
    }

    return balances;
  }

  /// Calculate work hours needed to pay off debt
  int calculateWorkHoursNeeded(DebtProfile profile) {
    if (profile.hourlyWage == null || profile.hourlyWage! <= 0) return 0;
    return ((profile.totalDebt - profile.amountPaid) / profile.hourlyWage!).ceil();
  }

  /// Get progress percentage
  double getProgressPercentage(DebtProfile profile) {
    return (profile.amountPaid / profile.totalDebt) * 100;
  }

  /// Get motivational message based on progress
  String getMotivationalMessage(double progressPercentage) {
    if (progressPercentage >= 100) return "Congratulations! You're debt-free! 🎉";
    if (progressPercentage >= 75) return "Almost there! The finish line is in sight! 🏃";
    if (progressPercentage >= 50) return "Halfway there! Keep up the momentum! 💪";
    if (progressPercentage >= 25) return "Great progress! You're crushing it! 🌟";
    if (progressPercentage > 0) return "Great start! Keep building momentum! 🚀";
    return "Ready to start your debt-free journey! 🎯";
  }

  /// Calculate debt-free date
  DateTime calculateDebtFreeDate(DebtProfile profile, {double extraPayment = 0}) {
    final months = calculateMonthsToPayoff(profile, extraPayment: extraPayment);
    return DateTime.now().add(Duration(days: (months * 30.44).round())); // Average month length
  }
}

