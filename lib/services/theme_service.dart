import 'package:hive_flutter/hive_flutter.dart';

class ThemeService {
  static const String _themesBoxName = 'themes';
  static const String _darkModeKey = 'is_dark_mode';
  
  // Initialize the themes box
  static Future<void> initialize() async {
    await Hive.openBox(_themesBoxName);
  }
  
  // Get the current theme mode (dark or light)
  static bool isDarkMode() {
    final box = Hive.box(_themesBoxName);
    return box.get(_darkModeKey, defaultValue: false);
  }
  
  // Save the current theme mode
  static Future<void> setDarkMode(bool isDarkMode) async {
    final box = Hive.box(_themesBoxName);
    await box.put(_darkModeKey, isDarkMode);
  }
}
