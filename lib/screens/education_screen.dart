import 'package:flutter/material.dart';

class EducationScreen extends StatelessWidget {
  final bool isDarkMode;
  
  const EducationScreen({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF121212) 
          : const Color(0xFFF9F9F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Debt Education'),
            backgroundColor: isDarkMode 
                ? Colors.black.withOpacity(0.7) 
                : Colors.white.withOpacity(0.7),
            foregroundColor: isDarkMode ? Colors.white : Colors.black87,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildSection(
                  context,
                  title: 'Understanding Debt',
                  icon: Icons.school,
                  children: [
                    _buildCard(
                      context,
                      title: 'Types of Debt',
                      content: 'Learn about different types of debt and their impact:',
                      items: [
                        'Credit Card Debt - Usually has high interest rates',
                        'Student Loans - Often have fixed rates and special repayment options',
                        'Mortgage - Secured by property, typically lower rates',
                        'Personal Loans - Can be used to consolidate debt',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      context,
                      title: 'Interest Rates',
                      content: 'Understanding how interest affects your debt:',
                      items: [
                        'APR vs. APY',
                        'Simple vs. Compound Interest',
                        'Fixed vs. Variable Rates',
                        'How interest accrues over time',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  title: 'Debt Payoff Strategies',
                  icon: Icons.route,
                  children: [
                    _buildCard(
                      context,
                      title: 'Avalanche Method',
                      content: 'Pay off debts with the highest interest rate first while making minimum payments on others. This saves the most money in interest.',
                      items: [
                        'List debts by interest rate',
                        'Pay minimum on all debts',
                        'Put extra money toward highest-rate debt',
                        'Repeat until debt-free',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      context,
                      title: 'Snowball Method',
                      content: 'Pay off smallest debts first for psychological wins. This can help build momentum and motivation.',
                      items: [
                        'List debts by balance',
                        'Pay minimum on all debts',
                        'Put extra money toward smallest debt',
                        'Build momentum with each payoff',
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildSection(
                  context,
                  title: 'Tips for Success',
                  icon: Icons.tips_and_updates,
                  children: [
                    _buildCard(
                      context,
                      title: 'Building an Emergency Fund',
                      content: 'Having an emergency fund helps prevent new debt:',
                      items: [
                        'Start with a \$1,000 mini emergency fund',
                        'Build up to 3-6 months of expenses',
                        'Keep it liquid and accessible',
                        'Only use for true emergencies',
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCard(
                      context,
                      title: 'Staying Motivated',
                      content: 'Tips to stay on track with your debt payoff:',
                      items: [
                        'Celebrate small wins',
                        'Track your progress visually',
                        'Find an accountability partner',
                        'Remember your "why"',
                      ],
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final isLocalDarkMode = isDarkMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF9C27B0),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: isLocalDarkMode ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required String content,
    required List<String> items,
  }) {
    final theme = Theme.of(context);
    final isLocalDarkMode = isDarkMode;

    return Card(
      elevation: 0,
      color: isLocalDarkMode 
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isLocalDarkMode ? Colors.white10 : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: isLocalDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isLocalDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: const Color(0xFF9C27B0),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isLocalDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ),
      ),
    );
  }
}
