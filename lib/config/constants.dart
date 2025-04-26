import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/debt_profile.dart';

/// Application configuration class
class AppConfig {
  // Singleton implementation
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();
  
  // Properties
  late String supabaseUrl;
  late String supabaseAnonKey;
  final String appName = 'Debt Visualizer';
  final String appVersion = '1.0.0';
  final int maxProfileLimit = 10; // For free tier
  
  // Currency defaults
  final Currency defaultCurrency = const Currency(
    code: 'USD',
    symbol: '\$',
    name: 'US Dollar'
  );
  
  /// Initialize configuration from environment variables
  Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
    } catch (e) {
      supabaseUrl = '';
      supabaseAnonKey = '';
      print('Failed to load environment variables: $e');
    }
  }
  
  /// Check if Supabase is properly configured
  bool get isSupabaseConfigured => 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
}

