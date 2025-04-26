import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/debt_profile.dart';
import '../providers/debt_provider.dart';
import '../services/comparison_service.dart';

class ComparisonScreen extends StatefulWidget {
  const ComparisonScreen({super.key});

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
    final theme = Theme.of(context);
    final provider = context.watch<DebtProvider>();
    final profiles = provider.profiles;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Debt Comparison'),
            backgroundColor: theme.colorScheme.surface,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Debts to Compare',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: profiles.map((profile) {
                            final isSelected = _selectedProfiles.contains(profile);
                            return FilterChip(
                              label: Text(profile.name),
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
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment Optimization',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
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
    final theme = Theme.of(context);
    final currency = _selectedProfiles.first.currency;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Potential Savings with Optimization',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            provider.formatCurrency(totalSaved, currency),
            style: theme.textTheme.headlineMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'and ${provider.formatDuration(monthsSaved)} faster payoff',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
