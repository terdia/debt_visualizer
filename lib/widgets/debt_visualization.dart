import 'package:flutter/material.dart';
import '../models/debt_profile.dart';
import 'debt_visualization/index.dart';

class DebtVisualization extends StatelessWidget {
  final DebtProfile profile;
  final bool isDarkMode;
  
  const DebtVisualization({
    Key? key,
    required this.profile,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Use the new modular DebtVisualizationView component
    return DebtVisualizationView(
      profile: profile,
      isDarkMode: isDarkMode,
    );
  }
}
