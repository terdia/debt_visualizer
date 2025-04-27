import 'package:flutter/material.dart';
import '../../providers/debt_provider.dart';
import '../../widgets/debt_input_form.dart';
import '../../models/debt_profile.dart';

/// Shows a dialog to confirm profile deletion
void showDeleteConfirmation({
  required BuildContext context, 
  required DebtProvider provider, 
  required String profileId,
}) {
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        'Delete Profile',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: isDarkMode ? Colors.white : Colors.black,
        ),
      ),
      content: Text(
        'Are you sure you want to delete this profile? This action cannot be undone.',
        style: TextStyle(
          color: isDarkMode ? Colors.white70 : Colors.black87,
        ),
      ),
      actions: [
        TextButton(
          child: Text(
            'CANCEL',
            style: TextStyle(
              color: isDarkMode ? Colors.white70 : Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text(
            'DELETE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          onPressed: () {
            provider.deleteProfile(profileId);
            Navigator.of(context).pop();
          },
        ),
      ],
    ),
  );
}

/// Shows the add debt profile dialog/sheet
/// Shows dialog to edit an existing debt profile
void showEditProfile({
  required BuildContext context,
  required DebtProfile profile,
}) {
  final isSmallScreen = MediaQuery.of(context).size.width < 800;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;

  if (isSmallScreen) {
    // Modern styled modal sheet for editing
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6A1B9A),
                          const Color(0xFF4A148C),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Gradient circle icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: const Icon(
                            Icons.edit_document,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'EDIT DEBT PROFILE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: DebtInputForm(initialProfile: profile),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } else {
    // Modern styled modal dialog for desktop
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(32),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6A1B9A),
                        Color(0xFF4A148C),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'EDIT DEBT PROFILE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form content in scrollable container
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? const Color(0xFF2A2A2A) 
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Edit your debt profile details below.',
                              style: TextStyle(height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          DebtInputForm(initialProfile: profile),
                        ],
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
}

/// Shows dialog to create a new debt profile
void showAddDebtProfile(BuildContext context) {
  final isSmallScreen = MediaQuery.of(context).size.width < 800;
  final isDarkMode = Theme.of(context).brightness == Brightness.dark;
  final backgroundColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
  
  if (isSmallScreen) {
    // Modern styled modal sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.9,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, -5),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF6A1B9A),
                          const Color(0xFF4A148C),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Gradient circle icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.2),
                          ),
                          child: const Icon(
                            Icons.add_chart,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'CREATE DEBT PROFILE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  // Form content
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: const DebtInputForm(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  } else {
    // Modern styled modal dialog for desktop
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(32),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          constraints: const BoxConstraints(maxWidth: 700, maxHeight: 800),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6A1B9A),
                        Color(0xFF4A148C),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'CREATE NEW DEBT PROFILE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                    ],
                  ),
                ),
                // Form content in scrollable container
                Flexible(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDarkMode 
                                  ? const Color(0xFF2A2A2A) 
                                  : const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: const Text(
                              'Fill in the details below to create a new debt profile. This will help you track and visualize your debt payoff journey.',
                              style: TextStyle(height: 1.5),
                            ),
                          ),
                          const SizedBox(height: 24),
                          const DebtInputForm(),
                        ],
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
}
