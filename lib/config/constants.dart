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
  
  // RevenueCat API keys
  late String revenueCatIosApiKey;
  late String revenueCatAndroidApiKey;
  
  // Platform-specific subscription product IDs
  late String iosSubscriptionId;
  late String androidSubscriptionId;
  
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
      
      // Supabase credentials
      supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      
      // RevenueCat API keys
      revenueCatIosApiKey = dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';
      revenueCatAndroidApiKey = dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? '';
      
      // Platform-specific subscription product IDs
      iosSubscriptionId = dotenv.env['IOS_SUBSCRIPTION_ID'] ?? 'debt_visualizer_premium_monthly'; 
      androidSubscriptionId = dotenv.env['ANDROID_SUBSCRIPTION_ID'] ?? 'debt_visualizer_premium_monthly:debt-visualizer-premiu-monthly';
    } catch (e) {
      // Default empty values if environment loading fails
      supabaseUrl = '';
      supabaseAnonKey = '';
      revenueCatIosApiKey = '';
      revenueCatAndroidApiKey = '';
      iosSubscriptionId = 'debt_visualizer_premium_monthly';
      androidSubscriptionId = 'debt_visualizer_premium_monthly:debt-visualizer-premiu-monthly';
      print('Failed to load environment variables: $e');
    }
  }
  
  /// Check if Supabase is properly configured
  bool get isSupabaseConfigured => 
      supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
      
  /// Check if RevenueCat is properly configured
  bool get isRevenueCatConfigured => 
      revenueCatIosApiKey.isNotEmpty && revenueCatAndroidApiKey.isNotEmpty;
}

