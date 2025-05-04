import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/debt_provider.dart';
import '../../models/debt_profile.dart';
import 'dialogs.dart';

class HorizontalProfileSelector extends StatelessWidget {
  final DebtProvider provider;
  final bool isDarkMode;
  final Function({required BuildContext context, required DebtProvider provider, required String profileId}) onDeleteProfile;
  final Function({required BuildContext context, required DebtProfile profile}) onEditProfile;

  const HorizontalProfileSelector({
    Key? key,
    required this.provider,
    required this.isDarkMode,
    required this.onDeleteProfile,
    required this.onEditProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with "My Profiles" and Add button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Text(
                'MY PROFILES',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: isDarkMode ? Colors.white70 : Colors.black54,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              _buildAddButton(context),
            ],
          ),
        ),
        
        // Scrollable profile cards
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            itemCount: provider.profiles.length,
            itemBuilder: (context, index) {
              final profile = provider.profiles[index];
              final isSelected = profile.id == provider.selectedProfile?.id;
              
              return _buildProfileCard(context, profile, isSelected);
            },
          ),
        ),
        
        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(
            color: isDarkMode ? Colors.white24 : Colors.black12,
            height: 1,
          ),
        ),
      ],
    );
  }
  
  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddProfileDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF9C27B0).withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              CupertinoIcons.add,
              color: Colors.white,
              size: 16,
            ),
            SizedBox(width: 8),
            Text(
              'NEW',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProfileCard(BuildContext context, DebtProfile profile, bool isSelected) {
    return GestureDetector(
      onTap: () => provider.selectProfile(profile),
      child: Container(
        width: 200,
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDarkMode
                      ? [Colors.grey.shade800, Colors.grey.shade900]
                      : [Colors.white, Colors.grey.shade100],
                ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFF9C27B0).withOpacity(0.3)
                  : Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Profile content
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile name and edit button row
                  Row(
                    children: [
                      // Profile name in constrained space
                      Expanded(
                        child: Text(
                          profile.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : (isDarkMode ? Colors.white : Colors.black87),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Buttons in a row
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Edit button
                          _buildActionButton(
                            icon: CupertinoIcons.pencil,
                            color: isSelected 
                                ? Colors.white.withOpacity(0.3) 
                                : isDarkMode 
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                            iconColor: isSelected
                                ? Colors.white
                                : isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.grey.shade800,
                            onTap: () => onEditProfile(context: context, profile: profile),
                          ),
                          const SizedBox(width: 4),
                          // Delete button
                          _buildActionButton(
                            icon: CupertinoIcons.trash,
                            color: isSelected 
                                ? Colors.white.withOpacity(0.3) 
                                : isDarkMode 
                                    ? Colors.grey.shade700
                                    : Colors.grey.shade300,
                            iconColor: isSelected
                                ? Colors.white
                                : isDarkMode
                                    ? Colors.white.withOpacity(0.8)
                                    : Colors.grey.shade800,
                            onTap: () => onDeleteProfile(context: context, provider: provider, profileId: profile.id),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Profile summary
                  Row(
                    children: [
                      _buildInfoChip(
                        icon: Icons.account_balance_wallet, // Generic wallet icon that's currency-neutral
                        label: Provider.of<DebtProvider>(context)
                            .formatCurrency(profile.totalDebt, profile.currency, compact: true),
                        isSelected: isSelected,
                      ),
                      const SizedBox(width: 8),
                      _buildInfoChip(
                        icon: CupertinoIcons.percent,
                        label: '${profile.interestRate}%',
                        isSelected: isSelected,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // No longer needed - buttons are inline with title
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.white.withOpacity(0.2)
            : isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: isSelected
                ? Colors.white
                : isDarkMode
                    ? Colors.white70
                    : Colors.black54,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? Colors.white
                  : isDarkMode
                      ? Colors.white70
                      : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 14,
          color: iconColor,
        ),
      ),
    );
  }
  
  void _showAddProfileDialog(BuildContext context) {
    // Use the function from dialogs.dart
    // This is imported from index.dart which re-exports dialogs.dart
    showAddDebtProfile(context);
  }
}
