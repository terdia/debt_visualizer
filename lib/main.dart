import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'config/constants.dart';
import 'providers/debt_provider.dart';
import 'repositories/repository_factory.dart';
import 'services/debt_service.dart';
import 'services/theme_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize Theme Service
  await ThemeService.initialize();

  // Initialize configuration
  final appConfig = AppConfig();
  await appConfig.initialize();
  
  // Initialize Supabase if configured
  if (appConfig.isSupabaseConfigured) {
    try {
      await Supabase.initialize(
        url: appConfig.supabaseUrl,
        anonKey: appConfig.supabaseAnonKey,
      );
      print('Supabase initialized successfully');
    } catch (e) {
      print('Failed to initialize Supabase: $e');
    }
  } else {
    print('Supabase not configured. Running in local mode.');
  }
  
  // Initialize RevenueCat if configured
  if (appConfig.isRevenueCatConfigured) {
    try {
      // Set log level for debugging
      await Purchases.setLogLevel(LogLevel.debug);
      
      // Get the appropriate API key based on platform
      final apiKey = Platform.isIOS 
          ? appConfig.revenueCatIosApiKey 
          : appConfig.revenueCatAndroidApiKey;
      
      // Configure RevenueCat
      await Purchases.configure(PurchasesConfiguration(apiKey));
      print('RevenueCat initialized successfully');
    } catch (e) {
      print('Failed to initialize RevenueCat: $e');
    }
  } else {
    print('RevenueCat not configured. Subscription features will be limited.');
  }

  runApp(MyApp(appConfig: appConfig));
}

class MyApp extends StatelessWidget {
  final AppConfig appConfig;
  
  const MyApp({required this.appConfig, super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DebtProvider(
        repository: RepositoryFactory.getDebtRepository(StorageType.local),
        debtService: DebtService(),
        supabaseClient: appConfig.isSupabaseConfigured ? Supabase.instance.client : null,
      ),
      child: MaterialApp(
        title: 'Debt Visualizer',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
