import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/debt_profile.dart';
import '../providers/debt_provider.dart';
import '../services/comparison_service.dart';

class ComparisonScreen extends StatefulWidget {
  final bool isDarkMode;
  
  const ComparisonScreen({super.key, this.isDarkMode = false});

  @override
  State<ComparisonScreen> createState() => _ComparisonScreenState();
}

class _ComparisonScreenState extends State<ComparisonScreen> {
  final _comparisonService = ComparisonService();
  final _extraPaymentController = TextEditingController(text: '0');
  // Store profile IDs instead of profile objects for better update handling
  List<String> _selectedProfileIds = [];
  Map<String, double> _optimizedPayments = {};
  
  // Get currently selected profiles from their IDs
  List<DebtProfile> get _selectedProfiles {
    final provider = Provider.of<DebtProvider>(context, listen: false);
    final result = <DebtProfile>[];
    
    for (final id in _selectedProfileIds) {
      try {
        final profile = provider.profiles.firstWhere((profile) => profile.id == id);
        result.add(profile);
      } catch (e) {
        // Profile with this ID no longer exists, ignore it
      }
    }
    
    return result;
  }

  @override
  void dispose() {
    _extraPaymentController.dispose();
    super.dispose();
  }

  void _updateOptimization() {
    final selectedProfiles = _selectedProfiles;
    if (selectedProfiles.isEmpty) return;

    final extraAmount = double.tryParse(_extraPaymentController.text) ?? 0;
    
    // Create a new map to force update
    final newOptimizations = _comparisonService.optimizePayments(
      selectedProfiles,
      extraAmount,
    );
    
    // Only trigger setState if the optimizations actually changed
    if (_optimizedPayments.toString() != newOptimizations.toString()) {
      setState(() {
        _optimizedPayments = newOptimizations;
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will ensure optimization is recalculated when any profile data changes
    if (_selectedProfileIds.isNotEmpty) {
      _updateOptimization();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final theme = Theme.of(context);
    final provider = context.watch<DebtProvider>();
    final profiles = provider.profiles;

    return Scaffold(
      backgroundColor: widget.isDarkMode 
          ? const Color(0xFF121212) 
          : const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Debt Comparison'),
            backgroundColor: widget.isDarkMode 
                ? Colors.black.withOpacity(0.7) 
                : Colors.white.withOpacity(0.7),
            foregroundColor: widget.isDarkMode ? Colors.white : Colors.black87,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  color: widget.isDarkMode 
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Debts to Compare',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Stylized profile selection chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profiles.map((profile) {
                            final isSelected = _selectedProfileIds.contains(profile.id);
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              child: FilterChip(
                                label: Text(
                                  profile.name,
                                  style: TextStyle(
                                    color: isSelected
                                      ? Colors.white
                                      : (widget.isDarkMode ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                                avatar: isSelected 
                                    ? const Icon(CupertinoIcons.checkmark_circle_fill, size: 16, color: Colors.white)
                                    : null,
                                selectedColor: const Color(0xFF9C27B0),
                                backgroundColor: widget.isDarkMode ? Colors.black38 : Colors.grey.shade200,
                                shadowColor: Colors.black26,
                                elevation: isSelected ? 2 : 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    if (!_selectedProfileIds.contains(profile.id)) {
                                      _selectedProfileIds.add(profile.id);
                                    }
                                  } else {
                                    _selectedProfileIds.remove(profile.id);
                                  }
                                  _updateOptimization();
                                });
                              },
                            ),
                          );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_selectedProfiles.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    color: widget.isDarkMode 
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFF9C27B0),
                                      Colors.purple.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  CupertinoIcons.wand_stars,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Payment Optimization',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'Payment Optimization',
                                        style: TextStyle(
                                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: [
                                            Text(
                                              'This feature uses the Debt Avalanche method:',
                                              style: TextStyle(
                                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              '• Prioritizes debts with higher interest rates',
                                              style: TextStyle(
                                                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '• Applies extra payments to most expensive debts first',
                                              style: TextStyle(
                                                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '• Minimizes total interest paid over time',
                                              style: TextStyle(
                                                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '• Mathematically optimal for reducing costs',
                                              style: TextStyle(
                                                color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'The amount you enter will be distributed optimally across your debts to save you the most money in interest.',
                                              style: TextStyle(
                                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text(
                                            'Got it',
                                            style: TextStyle(
                                              color: const Color(0xFF9C27B0),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    CupertinoIcons.info,
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black45,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Set extra payment amount to optimize your debt payoff strategy',
                            style: TextStyle(
                              color: isDarkMode ? Colors.white70 : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: widget.isDarkMode ? Colors.black12 : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                                width: 0.5,
                              ),
                            ),
                            child: TextFormField(
                              controller: _extraPaymentController,
                              decoration: InputDecoration(
                                labelText: 'Extra Monthly Payment',
                                labelStyle: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                  fontSize: 14,
                                ),
                                prefixIcon: Icon(
                                  CupertinoIcons.money_dollar_circle,
                                  color: const Color(0xFF9C27B0),
                                  size: 18,
                                ),
                                prefixText: '\$',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                              ),
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              onChanged: (value) {
                                _updateOptimization();
                              },
                            ),
                          ),
                          if (_optimizedPayments.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                Text(
                                  'Recommended Distribution',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: Text(
                                          'Recommended Distribution',
                                          style: TextStyle(
                                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        content: SingleChildScrollView(
                                          child: ListBody(
                                            children: [
                                              Text(
                                                'How this works:',
                                                style: TextStyle(
                                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                '• Higher interest debts get priority',
                                                style: TextStyle(
                                                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                '• Payments are allocated in order of interest rate',
                                                style: TextStyle(
                                                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                '• Once a debt is covered, remaining funds move to the next',
                                                style: TextStyle(
                                                  color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              Text(
                                                'This approach saves you the most money over time by tackling expensive debts first.',
                                                style: TextStyle(
                                                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(),
                                            child: Text(
                                              'Got it',
                                              style: TextStyle(
                                                color: const Color(0xFF9C27B0),
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: widget.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      CupertinoIcons.info,
                                      color: widget.isDarkMode ? Colors.white70 : Colors.black45,
                                      size: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ..._selectedProfiles.map((profile) {
                              final extra = _optimizedPayments[profile.id] ?? 0;
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: widget.isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 6,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            profile.name,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 15,
                                              color: widget.isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Allocation: ${provider.formatCurrency(extra, profile.currency)}',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF9C27B0).withOpacity(widget.isDarkMode ? 0.3 : 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          'Rate: ${provider.formatPercentage(profile.interestRate)}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildComparisonResults(provider),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonResults(DebtProvider provider) {
    final selectedProfiles = _selectedProfiles;
    if (selectedProfiles.isEmpty) return const SizedBox.shrink();

    final comparisons = _comparisonService.compareProfiles(
      selectedProfiles,
      extraPayments: _optimizedPayments,
    );

    final (totalSaved, monthsSaved) = _comparisonService.calculateOptimizationImpact(
      selectedProfiles,
      _optimizedPayments,
    );

    return Card(
      color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
            ),
            if (totalSaved > 0) ...[
              const SizedBox(height: 16),
              _buildSavingsCard(provider, totalSaved, monthsSaved),
              Container(
                height: 220,
                padding: const EdgeInsets.only(top: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: widget.isDarkMode ? Colors.black.withOpacity(0.3) : Colors.white.withOpacity(0.9),
                ),
                margin: const EdgeInsets.symmetric(vertical: 16),
                child: LineChart(
                  LineChartData(
                    lineBarsData: comparisons.asMap().entries.map((entry) {
                      final index = entry.key;
                      final comparison = entry.value;
                      final colors = [
                        const Color(0xFF9C27B0), // Purple
                        const Color(0xFF00BCD4), // Cyan
                        const Color(0xFFFFC107), // Amber
                        const Color(0xFF4CAF50), // Green
                        const Color(0xFFF44336), // Red
                      ];
                      return LineChartBarData(
                        spots: comparison.payoffData
                            .asMap()
                            .entries
                            .map((entry) => FlSpot(
                                  entry.key.toDouble(),
                                  entry.value,
                                ))
                            .toList(),
                        isCurved: true,
                        color: colors[index % colors.length],
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: false,
                          getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                            radius: 3,
                            color: colors[entry.key % colors.length],
                            strokeWidth: 1,
                            strokeColor: Colors.white,
                          ),
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: colors[index % colors.length].withOpacity(0.15),
                        ),
                      );
                    }).toList(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: true,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                        strokeWidth: 0.5,
                      ),
                      getDrawingVerticalLine: (value) => FlLine(
                        color: widget.isDarkMode ? Colors.white24 : Colors.black12,
                        strokeWidth: 0.5,
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            if (value % 6 == 0) { // Show every 6 months
                              return SideTitleWidget(
                                axisSide: meta.axisSide,
                                child: Text(
                                  '${value.toInt()}m',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final currency = _selectedProfiles.first.currency;
                            final compact = provider.formatCurrency(value, currency, compact: true);
                            return SideTitleWidget(
                              axisSide: meta.axisSide,
                              child: Text(
                                compact,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: widget.isDarkMode ? Colors.grey[800]! : Colors.white,
                        tooltipBorder: BorderSide(
                          color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                          width: 0.5,
                        ),
                        tooltipRoundedRadius: 12,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            final index = barSpot.barIndex;
                            final profile = comparisons[index].profile;
                            return LineTooltipItem(
                              '${profile.name}\n',
                              TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                              children: [
                                TextSpan(
                                  text: provider.formatCurrency(barSpot.y, profile.currency),
                                  style: TextStyle(
                                    color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                                    fontWeight: FontWeight.normal,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            );
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            ...comparisons.map((comparison) {
              return _buildComparisonCard(provider, comparison);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSavingsCard(
    DebtProvider provider,
    double totalSaved,
    int monthsSaved,
  ) {
    final isDarkMode = widget.isDarkMode;
    final theme = Theme.of(context);
    final currency = _selectedProfiles.first.currency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
              : [const Color(0xFF9C27B0), const Color(0xFFAB47BC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Potential Savings with Optimization',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.formatCurrency(totalSaved, currency),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'and ${provider.formatDuration(monthsSaved)} faster payoff',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard(
    DebtProvider provider,
    DebtComparison comparison,
  ) {
    final isDarkMode = widget.isDarkMode;
    final theme = Theme.of(context);
    final profile = comparison.profile;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9C27B0).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    CupertinoIcons.creditcard_fill,
                    color: const Color(0xFF9C27B0),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    profile.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Metrics grid in 2x2 layout for better visualization
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    provider,
                    title: 'Time to Payoff',
                    value: provider.formatDuration(comparison.monthsToPayoff),
                    icon: CupertinoIcons.time,
                    color: const Color(0xFF9C27B0),
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    provider,
                    title: 'Total Interest',
                    value: provider.formatCurrency(comparison.totalInterest, profile.currency),
                    icon: CupertinoIcons.money_dollar_circle,
                    color: theme.colorScheme.error,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    provider,
                    title: 'Monthly Payment',
                    value: provider.formatCurrency(comparison.monthlyPayment, profile.currency),
                    icon: CupertinoIcons.calendar_badge_plus,
                    color: Colors.blue,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricBox(
                    provider,
                    title: 'Effective Rate',
                    value: provider.formatPercentage(comparison.effectiveInterestRate),
                    icon: CupertinoIcons.percent,
                    color: Colors.green,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    DebtProvider provider,
    String label,
    String value, {
    Color? color,
  }) {
    final isDarkMode = widget.isDarkMode;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color ?? (isDarkMode ? Colors.white : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
  
  // Apple-inspired metric box with icon and value
  Widget _buildMetricBox(
    DebtProvider provider, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? Colors.black.withOpacity(0.2) : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
