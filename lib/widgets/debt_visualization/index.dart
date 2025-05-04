import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/debt_profile.dart';
import '../../providers/debt_provider.dart';
import 'what_if_calculator.dart';
import 'progress_card.dart';
import 'payoff_chart.dart';

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
    // Use the provider for interactive elements and to get the latest profile data
    return Consumer<DebtProvider>(
      builder: (context, provider, _) {
        // Get the most current version of the profile directly from the provider's data store
        final currentProfile = provider.profiles.firstWhere(
          (p) => p.id == profile.id,
          orElse: () => profile, // Fallback to the passed profile if not found
        );
        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress visualization
                ProgressCard(
                  profile: currentProfile,
                  progress: provider.getProgressPercentage(currentProfile),
                  motivationalMessage: provider.getMotivationalMessage(currentProfile),
                  isDarkMode: isDarkMode,
                ),
                
                const SizedBox(height: 24),
                
                // Statistics grid
                _buildStatisticsGrid(context, provider, currentProfile),
                
                const SizedBox(height: 24),
                
                // Payoff chart visualization
                PayoffChart(
                  profile: currentProfile,
                  extraPayment: provider.extraPayment,
                  isDarkMode: isDarkMode,
                ),
                
                const SizedBox(height: 24),
                
                // What-if calculator for simulating extra payments
                WhatIfCalculator(
                  profile: currentProfile,
                  extraPayment: provider.extraPayment,
                  onExtraPaymentChanged: provider.setExtraPayment,
                  debtFreeDate: provider.getDebtFreeDate(currentProfile),
                  monthsToPayoff: provider.getMonthsToPayoff(currentProfile),
                  baseMonthsToPayoff: provider.getBaseMonthsToPayoff(currentProfile),
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
  Widget _buildStatisticsGrid(BuildContext context, DebtProvider provider, DebtProfile currentProfile) {
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

    final monthlyPayment = currentProfile.monthlyPayment;
    final interestPaid = provider.calculateTotalInterest(currentProfile);
    final monthsRemaining = provider.getMonthsToPayoff(currentProfile);
    final debtFreeDate = provider.getDebtFreeDate(currentProfile);
    final workHours = provider.calculateWorkHoursToPayOff(currentProfile);
    
    // Format the debt-free date
    final dateFormatter = _getMonthYearFormatter();
    final formattedDate = dateFormatter.format(debtFreeDate);
    
    // Prepare data for compact stats view
    final statData = [
      // Monthly payment
      {
        'title': 'Monthly Payment',
        'value': Provider.of<DebtProvider>(context)
            .formatCurrency(monthlyPayment, currentProfile.currency),
        'subtitle': 'Current payment',
        'icon': Icons.calendar_today,
        'colors': gradients[0],
      },
      // Interest cost
      {
        'title': 'Interest Cost',
        'value': Provider.of<DebtProvider>(context)
            .formatCurrency(interestPaid, currentProfile.currency),
        'subtitle': 'Total interest',
        'icon': Icons.attach_money,
        'colors': gradients[1],
      },
      // Time to freedom
      {
        'title': 'Time to Freedom',
        'value': '$monthsRemaining months',
        'subtitle': 'Until debt-free',
        'icon': Icons.hourglass_empty,
        'colors': gradients[2],
      },
      // Debt-free date
      {
        'title': 'Debt-Free Date',
        'value': formattedDate,
        'subtitle': 'Est. completion',
        'icon': Icons.event_available,
        'colors': gradients[3],
      },
    ];
    
    // Add work hours if available
    if (workHours != null) {
      statData.add({
        'title': 'Work Hours',
        'value': workHours.round().toString(),
        'subtitle': 'Hours to pay off',
        'icon': Icons.work,
        'colors': gradients[4],
      });
    }
    
    // Use more columns on wider screens
    final screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount;
    
    if (screenWidth > 900) {
      // Wide desktop - 5 columns if we have 5 stats
      crossAxisCount = statData.length >= 5 ? 5 : statData.length;
    } else if (screenWidth > 600) {
      // Tablet - 3 columns
      crossAxisCount = 3;
    } else {
      // Phone - 2 columns
      crossAxisCount = 2;
    }
    
    // Reduced spacing between cards
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 10, // Reduced from 16
        mainAxisSpacing: 10,  // Reduced from 16
        childAspectRatio: 1.5, // Make cards wider to prevent overflow
      ),
      itemCount: statData.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final data = statData[index];
        return CompactStatCard(
          title: data['title'] as String,
          value: data['value'] as String,
          subtitle: data['subtitle'] as String,
          icon: data['icon'] as IconData,
          gradientStartColor: (data['colors'] as List<Color>)[0],
          gradientEndColor: (data['colors'] as List<Color>)[1],
          isDarkMode: isDarkMode,
        );
      },
    );
  }
  
  /// A more compact version of the stat card widget
  Widget CompactStatCard({
    required String title, 
    required String value, 
    required String subtitle,
    required IconData icon,
    required Color gradientStartColor,
    required Color gradientEndColor,
    required bool isDarkMode,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gradientStartColor,
            gradientEndColor,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Further reduced padding
        child: Column(
          mainAxisSize: MainAxisSize.min, // Use minimum vertical space
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and icon in a more compact row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible( // Make text flexible to prevent overflow
                  child: Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w600,
                      fontSize: 12, // Even smaller title font
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(4), // Smaller icon container
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 14, // Smaller icon
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing
            // Main value
            Text(
              value,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20, // Smaller value font
              ),
            ),
            const SizedBox(height: 4),
            // Subtitle in pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                subtitle,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 10, // Smaller subtitle font
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// Returns a formatter for month/year date format
  DateFormat _getMonthYearFormatter() {
    return DateFormat('MMM yyyy'); // Using 3-letter abbreviated month format
  }
}
