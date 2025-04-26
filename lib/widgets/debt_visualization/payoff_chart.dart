import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/debt_profile.dart';
import '../../utils/currency_formatter.dart';

class PayoffChart extends StatelessWidget {
  final DebtProfile profile;
  final double extraPayment;
  final bool isDarkMode;

  const PayoffChart({
    super.key,
    required this.profile,
    required this.extraPayment,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate data points for the chart
    final basePaymentData = _calculatePayoffData(extraPayment: 0);
    final extraPaymentData = extraPayment > 0 
        ? _calculatePayoffData(extraPayment: extraPayment)
        : null;

    return Card(
      elevation: 10,
      shadowColor: Colors.black38,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDarkMode
                  ? [const Color(0xFF1A237E), const Color(0xFF0D47A1)]
                  : [const Color(0xFF0097A7), const Color(0xFF006064)],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text(
                      'DEBT PAYOFF TIMELINE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Spacer(),
                    Icon(
                      Icons.timeline,
                      color: Colors.white70,
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Legend for the chart
                if (extraPayment > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLegendItem(
                          'Current Plan',
                          const Color(0xFFFFFFFF),
                        ),
                        const SizedBox(width: 24),
                        _buildLegendItem(
                          'With Extra Payments',
                          const Color(0xFF4CAF50),
                        ),
                      ],
                    ),
                  ),
                
                // Chart container with glass effect
                Container(
                  height: 260,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
                  ),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: profile.totalDebt / 5,
                        verticalInterval: basePaymentData.length > 24 ? 6 : 3, // Adjust interval based on data length
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.15),
                            strokeWidth: 1,
                          );
                        },
                        getDrawingVerticalLine: (value) {
                          return FlLine(
                            color: Colors.white.withOpacity(0.15),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          // Remove axis title to save space
                          axisNameWidget: null,
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 25,
                            getTitlesWidget: (value, meta) {
                              // Only show every nth month based on total length
                              final months = value.toInt();
                              final interval = basePaymentData.length > 24 ? 6 : 3;
                              if (months % interval != 0 && months != 0) {
                                return const SizedBox.shrink();
                              }
                              
                              // Format as year if applicable
                              String label;
                              if (months >= 12) {
                                final years = (months / 12).floor();
                                label = '${years}y';
                              } else {
                                label = '${months}m';
                              }
                              
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 4, // Minimal space to maximize chart
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          // Remove axis title to save space
                          axisNameWidget: null,
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: profile.totalDebt / 5,
                            reservedSize: 38,
                            getTitlesWidget: (value, meta) {
                              // Format the currency value in a more compact way
                              String formattedValue;
                              if (value >= 1000) {
                                formattedValue = '${(value / 1000).toStringAsFixed(0)}K';
                              } else {
                                formattedValue = value.toStringAsFixed(0);
                              }
                              
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                space: 8, // Add more spacing
                                child: Text(
                                  formattedValue,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      minX: 0,
                      maxX: basePaymentData.length.toDouble() - 1,
                      minY: 0,
                      maxY: profile.totalDebt * 1.05,
                      lineBarsData: [
                        // Base payment line
                        LineChartBarData(
                          spots: List.generate(
                            basePaymentData.length,
                            (i) => FlSpot(i.toDouble(), basePaymentData[i]),
                          ),
                          isCurved: true,
                          gradient: const LinearGradient(
                            colors: [
                              Colors.white70,
                              Colors.white,
                            ],
                          ),
                          barWidth: 4,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withOpacity(0.3),
                                Colors.white.withOpacity(0.0),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                        
                        // Extra payment line (if applicable)
                        if (extraPaymentData != null)
                          LineChartBarData(
                            spots: List.generate(
                              extraPaymentData.length,
                              (i) => FlSpot(i.toDouble(), extraPaymentData[i]),
                            ),
                            isCurved: true,
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4CAF50),
                                Color(0xFF8BC34A),
                              ],
                            ),
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4CAF50).withOpacity(0.3),
                                  const Color(0xFF4CAF50).withOpacity(0.0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                      ],
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          tooltipBgColor: isDarkMode 
                              ? const Color(0xFF303030)
                              : Colors.white,
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final isExtraPayment = extraPaymentData != null && 
                                  spot.barIndex == 1;
                              
                              return LineTooltipItem(
                                CurrencyFormatter.format(spot.y, profile.currency),
                                TextStyle(
                                  color: isExtraPayment
                                      ? const Color(0xFF4CAF50)
                                      : isDarkMode 
                                          ? Colors.white
                                          : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            }).toList();
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<double> _calculatePayoffData({required double extraPayment}) {
    final monthlyPayment = profile.monthlyPayment + extraPayment;
    final interestRate = profile.interestRate / 100 / 12; // Monthly interest rate
    
    final data = <double>[];
    double remainingDebt = profile.totalDebt - profile.amountPaid;
    
    while (remainingDebt > 0) {
      data.add(remainingDebt);
      final interestThisMonth = remainingDebt * interestRate;
      remainingDebt = remainingDebt + interestThisMonth - monthlyPayment;
      if (remainingDebt < 0) remainingDebt = 0;
    }
    
    return data;
  }
}
