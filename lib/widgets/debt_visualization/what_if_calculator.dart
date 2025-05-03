import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/debt_profile.dart';
import '../../providers/debt_provider.dart';

class WhatIfCalculator extends StatelessWidget {
  final DebtProfile profile;
  final double extraPayment;
  final Function(double) onExtraPaymentChanged;
  final DateTime debtFreeDate;
  final int monthsToPayoff;
  final int baseMonthsToPayoff;
  final bool isDarkMode;

  const WhatIfCalculator({
    super.key,
    required this.profile,
    required this.extraPayment,
    required this.onExtraPaymentChanged,
    required this.debtFreeDate,
    required this.monthsToPayoff,
    required this.baseMonthsToPayoff,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate the time saved
    final monthsSaved = baseMonthsToPayoff - monthsToPayoff;
    final moneySaved = _calculateInterestSaved();
    
    // Calculate colors based on dark mode - keeping with purple theme for brand consistency
    final gradientColors = isDarkMode
        ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)] // Deep purple to match other dark mode components
        : [const Color(0xFF9C27B0), const Color(0xFFAB47BC)]; // Lighter purples for light mode

    return Card(
      elevation: 10,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              color: Colors.yellow.shade300,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'WHAT IF CALCULATOR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'See how extra payments can accelerate your debt freedom',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Extra payment slider with glass effect
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Extra Monthly Payment',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            Provider.of<DebtProvider>(context, listen: false).formatCurrency(
                              extraPayment,
                              profile.currency,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: Colors.white,
                        inactiveTrackColor: Colors.white.withOpacity(0.3),
                        thumbColor: Colors.white,
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 8,
                        ),
                        overlayColor: Colors.white.withOpacity(0.2),
                      ),
                      child: Slider(
                        // Use a higher max value - 5x monthly payment for more flexibility
                        value: extraPayment.clamp(0.0, profile.monthlyPayment * 5),
                        min: 0.0,
                        max: profile.monthlyPayment * 5,
                        onChanged: onExtraPaymentChanged,
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          Provider.of<DebtProvider>(context, listen: false).formatCurrency(0, profile.currency),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          Provider.of<DebtProvider>(context, listen: false)
                              .formatCurrency(profile.monthlyPayment * 5, profile.currency),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Results section
              if (extraPayment > 0) ...[
                const SizedBox(height: 24),
                // Results cards with glass effect
                Row(
                  children: [
                    // Time saved card
                    Expanded(
                      child: _buildResultCard(
                        title: 'TIME SAVED',
                        value: _formatMonthsSaved(monthsSaved),
                        icon: Icons.timer,
                        color: Colors.greenAccent,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Money saved card
                    Expanded(
                      child: _buildResultCard(
                        title: 'INTEREST SAVED',
                        value: Provider.of<DebtProvider>(context, listen: false).formatCurrency(
                          moneySaved,
                          profile.currency,
                        ),
                        icon: Icons.savings,
                        color: Colors.amberAccent,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                // New debt-free date
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'NEW DEBT-FREE DATE',
                        style: TextStyle(
                          color: gradientColors[0],
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(debtFreeDate),
                        style: TextStyle(
                          color: gradientColors[0],
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    // Fixed-size container with no overflow
    return Container(
      height: 76, // Further reduced to exactly fit content
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, // Use min size to prevent stretching
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: color,
                size: 18, // Slightly smaller icon
              ),
              const SizedBox(width: 6), // Reduced spacing
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11, // Smaller font
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Minimal spacing
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15, // Smaller font size
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthsSaved(int months) {
    if (months <= 0) return '0 months';
    if (months == 1) return '1 month';
    
    final years = months ~/ 12;
    final remainingMonths = months % 12;
    
    if (years == 0) return '$months months';
    if (remainingMonths == 0) return '$years years';
    return '$years years, $remainingMonths months';
  }

  String _formatDate(DateTime date) {
    final monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    
    return '${monthNames[date.month - 1]} ${date.year}';
  }

  double _calculateInterestSaved() {
    // Calculate total payments with and without extra payments
    final basePayments = _calculateTotalPayments(profile.monthlyPayment);
    final extraPayments = _calculateTotalPayments(
      profile.monthlyPayment + extraPayment
    );
    
    // The difference is interest saved
    return basePayments - extraPayments;
  }

  double _calculateTotalPayments(double monthlyPayment) {
    final interestRate = profile.interestRate / 100 / 12; // Monthly rate
    double remainingDebt = profile.totalDebt - profile.amountPaid;
    double totalPaid = 0;
    
    while (remainingDebt > 0) {
      final interestThisMonth = remainingDebt * interestRate;
      final principalThisMonth = monthlyPayment - interestThisMonth;
      
      if (principalThisMonth >= remainingDebt) {
        // Last payment
        totalPaid += remainingDebt + interestThisMonth;
        remainingDebt = 0;
      } else {
        totalPaid += monthlyPayment;
        remainingDebt -= principalThisMonth;
      }
    }
    
    return totalPaid;
  }
}
