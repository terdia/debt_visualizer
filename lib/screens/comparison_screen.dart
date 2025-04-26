import 'package:flutter/material.dart';
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
  List<DebtProfile> _selectedProfiles = [];
  Map<String, double> _optimizedPayments = {};

  @override
  void dispose() {
    _extraPaymentController.dispose();
    super.dispose();
  }

  void _updateOptimization() {
    if (_selectedProfiles.isEmpty) return;

    final extraAmount = double.tryParse(_extraPaymentController.text) ?? 0;
    setState(() {
      _optimizedPayments = _comparisonService.optimizePayments(
        _selectedProfiles,
        extraAmount,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final theme = Theme.of(context);
    final provider = context.watch<DebtProvider>();
    final profiles = provider.profiles;

    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF121212) 
          : const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Debt Comparison'),
            backgroundColor: isDarkMode 
                ? Colors.black.withOpacity(0.7) 
                : Colors.white.withOpacity(0.7),
            foregroundColor: isDarkMode ? Colors.white : Colors.black87,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  color: isDarkMode 
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
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profiles.map((profile) {
                            final isSelected = _selectedProfiles.contains(profile);
                            return FilterChip(
                              label: Text(
                                profile.name,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : (isDarkMode ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              selectedColor: const Color(0xFF9C27B0),
                              backgroundColor: isDarkMode ? Colors.black38 : Colors.grey.shade200,
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedProfiles.add(profile);
                                  } else {
                                    _selectedProfiles.remove(profile);
                                  }
                                  _updateOptimization();
                                });
                              },
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
                  color: isDarkMode 
                      ? const Color(0xFF1E1E1E)
                      : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Optimization',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _extraPaymentController,
                            decoration: InputDecoration(
                              labelText: 'Available Extra Payment',
                              border: const OutlineInputBorder(),
                              prefixText: '\$',
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onChanged: (_) => _updateOptimization(),
                          ),
                          if (_optimizedPayments.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            Text(
                              'Recommended Distribution',
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ..._selectedProfiles.map((profile) {
                              final extra = _optimizedPayments[profile.id] ?? 0;
                              return ListTile(
                                title: Text(profile.name),
                                subtitle: Text(
                                  provider.formatCurrency(extra, profile.currency),
                                ),
                                trailing: Text(
                                  'Rate: ${provider.formatPercentage(profile.interestRate)}',
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
    if (_selectedProfiles.isEmpty) return const SizedBox.shrink();

    final comparisons = _comparisonService.compareProfiles(
      _selectedProfiles,
      extraPayments: _optimizedPayments,
    );

    final (totalSaved, monthsSaved) = _comparisonService.calculateOptimizationImpact(
      _selectedProfiles,
      _optimizedPayments,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comparison Results',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (totalSaved > 0) ...[
              const SizedBox(height: 16),
              _buildSavingsCard(provider, totalSaved, monthsSaved),
            ],
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 16 / 9,
              child: LineChart(
                LineChartData(
                  lineBarsData: comparisons.map((comparison) {
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
                      dotData: const FlDotData(show: false),
                    );
                  }).toList(),
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ...comparisons.map((comparison) {
              return _buildComparisonCard(provider, comparison);
            }),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            profile.name,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          _buildMetricRow(
            provider,
            'Time to Payoff:',
            provider.formatDuration(comparison.monthsToPayoff),
          ),
          _buildMetricRow(
            provider,
            'Total Interest:',
            provider.formatCurrency(comparison.totalInterest, profile.currency),
            color: theme.colorScheme.error,
          ),
          _buildMetricRow(
            provider,
            'Monthly Payment:',
            provider.formatCurrency(comparison.monthlyPayment, profile.currency),
          ),
          _buildMetricRow(
            provider,
            'Effective Rate:',
            provider.formatPercentage(comparison.effectiveInterestRate),
          ),
          const Divider(),
        ],
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
}
