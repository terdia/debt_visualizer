import 'package:flutter/material.dart';
import '../../providers/debt_provider.dart';
import '../../models/debt_profile.dart';

/// Profile selector widget for the side drawer/panel
class ProfileSelector extends StatelessWidget {
  final DebtProvider provider;
  final bool isDarkMode;
  final Function({required BuildContext context, required DebtProvider provider, required String profileId}) onDeleteProfile;

  const ProfileSelector({
    Key? key,
    required this.provider,
    required this.isDarkMode,
    required this.onDeleteProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 60),
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Row(
            children: [
              Text(
                'PROFILES',
                style: TextStyle(
                  fontFamily: 'Montserrat',
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: Colors.white,
                ),
                onPressed: () => _showAddProfileDialog(context),
              ),
            ],
          ),
        ),
        const Divider(color: Colors.white24),
        
        // Profile list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: provider.profiles.length,
            itemBuilder: (context, index) {
              final profile = provider.profiles[index];
              final isSelected = profile.id == provider.selectedProfile?.id;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: isSelected 
                      ? LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.1),
                            Colors.white.withOpacity(0.2),
                          ],
                        )
                      : null,
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ] : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => provider.selectProfile(profile),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : Colors.white54,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              profile.name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white54,
                              size: 20,
                            ),
                            onPressed: () => onDeleteProfile(context: context, provider: provider, profileId: profile.id),
                            splashRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Status bar
        Container(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'CONNECTED',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Show add profile dialog - this just navigates to the main add profile dialog
  void _showAddProfileDialog(BuildContext context) {
    // We'll use the showAddDebtProfile method from the HomeScreen
    Navigator.of(context).pop(); // Close drawer if open
    // Use a callback passed from parent, or use a static method/function to show dialog
    // For simplicity, in this component we'll just close the drawer
  }
}
