import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/debt_provider.dart';
import '../../models/debt_profile.dart';
import 'progress_card.dart';
import 'stat_card.dart';
import 'payoff_chart.dart';
import 'what_if_calculator.dart';

/// Main widget that combines all debt visualization components
class DebtVisualizationView extends StatelessWidget {
  final DebtProfile profile;
  final bool isDarkMode;

  const DebtVisualizationView({
    super.key,
    required this.profile,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Use the provider for interactive elements
    return Consumer<DebtProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress visualization
                ProgressCard(
                  profile: profile,
                  progress: provider.getProgressPercentage(),
                  motivationalMessage: provider.getMotivationalMessage(),
                  isDarkMode: isDarkMode,
                ),
                
                const SizedBox(height: 24),
                
                // Statistics grid
                _buildStatisticsGrid(context, provider),
                
                const SizedBox(height: 24),
                
                // Payoff chart visualization
                PayoffChart(
                  profile: profile,
                  extraPayment: provider.extraPayment,
                  isDarkMode: isDarkMode,
                ),
                
                const SizedBox(height: 24),
                
                // What-if calculator for simulating extra payments
                WhatIfCalculator(
                  profile: profile,
                  extraPayment: provider.extraPayment,
                  onExtraPaymentChanged: provider.setExtraPayment,
                  debtFreeDate: provider.getDebtFreeDate(),
                  monthsToPayoff: provider.getMonthsToPayoff(),
                  baseMonthsToPayoff: provider.getBaseMonthsToPayoff(),
                  isDarkMode: isDarkMode,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// Builds a grid of statistics cards with varying colors
  Widget _buildStatisticsGrid(BuildContext context, DebtProvider provider) {
    // For a visually interesting design, use different gradients for each card
    final gradients = [
      // Purple gradient
      [const Color(0xFF7E57C2), const Color(0xFF5E35B1)],
      // Blue gradient
      [const Color(0xFF42A5F5), const Color(0xFF1976D2)],
      // Green gradient
      [const Color(0xFF66BB6A), const Color(0xFF388E3C)],
      // Pink gradient
      [const Color(0xFFEC407A), const Color(0xFFC2185B)],
      // Orange gradient (for work hours)
      [const Color(0xFFFF9800), const Color(0xFFE65100)],
    ];

    final monthlyPayment = profile.monthlyPayment;
    final interestPaid = provider.calculateTotalInterest();
    final monthsRemaining = provider.getMonthsToPayoff();
    final debtFreeDate = provider.getDebtFreeDate();
    final workHours = provider.calculateWorkHoursToPayOff();
    
    // Format the debt-free date
    final dateFormatter = _getMonthYearFormatter();
    final formattedDate = dateFormatter.format(debtFreeDate);
    
    // Prepare stats cards
    final statCards = [
      // Monthly payment card
      StatCard(
        title: 'Monthly Payment',
        value: profile.currency.symbol + monthlyPayment.toStringAsFixed(0),
        subtitle: 'Current monthly payment',
        icon: Icons.calendar_today,
        gradientStartColor: gradients[0][0],
        gradientEndColor: gradients[0][1],
        isDarkMode: isDarkMode,
      ),
      
      // Interest paid card - ensure it's displayed as a positive number
      StatCard(
        title: 'Interest Cost',
        value: profile.currency.symbol + interestPaid.toStringAsFixed(0),
        subtitle: 'Total interest over loan life',
        icon: Icons.attach_money,
        gradientStartColor: gradients[1][0],
        gradientEndColor: gradients[1][1],
        isDarkMode: isDarkMode,
      ),
      
      // Months remaining card
      StatCard(
        title: 'Time to Freedom',
        value: '$monthsRemaining months',
        subtitle: 'Until debt-free',
        icon: Icons.hourglass_empty,
        gradientStartColor: gradients[2][0],
        gradientEndColor: gradients[2][1],
        isDarkMode: isDarkMode,
      ),
      
      // Debt-free date card
      StatCard(
        title: 'Debt-Free Date',
        value: formattedDate,
        subtitle: 'Estimated completion',
        icon: Icons.event_available,
        gradientStartColor: gradients[3][0],
        gradientEndColor: gradients[3][1],
        isDarkMode: isDarkMode,
      ),
    ];
    
    // Add work hours card if hourly wage is available
    if (workHours != null) {
      final formattedHours = workHours.round().toString();
      final hoursCard = StatCard(
        title: 'Work Hours',
        value: formattedHours,
        subtitle: 'Hours needed to pay off debt',
        icon: Icons.work,
        gradientStartColor: gradients[4][0],
        gradientEndColor: gradients[4][1],
        isDarkMode: isDarkMode,
      );
      
      // Add the work hours card as the fifth card
      statCards.add(hoursCard);
    }
    
    // Calculate the cross axis count based on screen width
    // Use 3 cards per row if screen is wide and we have 5 or more cards
    int crossAxisCount = 2;
    if (MediaQuery.of(context).size.width > 900) {
      crossAxisCount = statCards.length >= 5 ? 3 : (statCards.length >= 4 ? 4 : 2);
    }
    
    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: statCards,
    );
  }
  
  /// Returns a formatter for month/year date format
  DateFormat _getMonthYearFormatter() {
    return DateFormat('MMMM yyyy');
  }
}
