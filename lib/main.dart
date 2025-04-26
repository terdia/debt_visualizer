import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/constants.dart';
import 'providers/debt_provider.dart';
import 'repositories/repository_factory.dart';
import 'services/debt_service.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DebtProvider(
        repository: RepositoryFactory.getDebtRepository(StorageType.local),
        debtService: DebtService(),
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
