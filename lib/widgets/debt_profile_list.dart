import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/debt_profile.dart';

class DebtProfileList extends StatelessWidget {
  final List<DebtProfile> profiles;
  final DebtProfile? selectedProfile;
  final Function(DebtProfile?) onProfileSelected;
  final Function(String) onProfileDeleted;

  const DebtProfileList({
    super.key,
    required this.profiles,
    required this.selectedProfile,
    required this.onProfileSelected,
    required this.onProfileDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: theme.dividerColor.withOpacity(0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Debt Profiles',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${profiles.length} ${profiles.length == 1 ? 'Profile' : 'Profiles'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          // List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: profiles.length,
              itemBuilder: (context, index) {
                final profile = profiles[index];
                final isSelected = selectedProfile?.id == profile.id;
                final progressPercentage = (profile.amountPaid / profile.totalDebt) * 100;

                return _ProfileListTile(
                  profile: profile,
                  isSelected: isSelected,
                  onTap: () => onProfileSelected(profile),
                  onDelete: () => _showDeleteConfirmation(context, profile),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, DebtProfile profile) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Profile'),
        content: Text(
          'Are you sure you want to delete "${profile.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
            onPressed: () {
              onProfileDeleted(profile.id);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileListTile extends StatelessWidget {
  final DebtProfile profile;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ProfileListTile({
    required this.profile,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercentage = (profile.amountPaid / profile.totalDebt) * 100;
    final formatter = NumberFormat.currency(
      symbol: profile.currency.symbol,
      decimalDigits: 0,
    );

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withOpacity(0.1)
            : null,
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withOpacity(0.1),
          ),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (profile.description.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            profile.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withOpacity(0.7),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildProgressBar(context, progressPercentage),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text(
                              formatter.format(profile.amountPaid),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              ' / ${formatter.format(profile.totalDebt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.textTheme.bodySmall?.color
                                    ?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${progressPercentage.toStringAsFixed(1)}%',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'paid off',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(BuildContext context, double percentage) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final theme = Theme.of(context);
        final width = constraints.maxWidth;
        final progressWidth = (width * percentage / 100).clamp(0.0, width);

        return Container(
          height: 4,
          width: width,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Row(
            children: [
              Container(
                width: progressWidth,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
