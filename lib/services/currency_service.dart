import 'package:intl/intl.dart';
import '../models/debt_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart'; // For AppConfig

class CurrencyService {
  static final _cache = <String, NumberFormat>{};
  // Singleton instance
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;

  CurrencyService._internal();

  /// Format currency with proper locale support
  String formatCurrency(
    double amount,
    Currency currency, {
    bool compact = false,
    String locale = 'en_US',
    int? maxDecimals,
  }) {
    final cacheKey = '${currency.code}_${compact}_${maxDecimals ?? "null"}_$locale';
    
    final formatter = _cache.putIfAbsent(cacheKey, () {
      return NumberFormat.currency(
        locale: locale,
        symbol: currency.symbol,
        decimalDigits: maxDecimals,
      );
    });

    if (compact && amount >= 1000) {
      return _formatCompact(amount, currency, locale);
    }

    return formatter.format(amount);
  }

  /// Format currency in compact notation (e.g., $1.2K, $1.5M)
  String _formatCompact(double amount, Currency currency, String locale) {
    if (amount >= 1000000000) {
      return '${currency.symbol}${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '${currency.symbol}${(amount / 1000000).toStringAsFixed(1)}M';
    }
    if (amount >= 1000) {
      return '${currency.symbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount, currency, locale: locale);
  }

  /// Format percentage with proper locale support
  String formatPercentage(
    double value, {
    String locale = 'en_US',
    int decimalPlaces = 1,
  }) {
    final formatter = NumberFormat.percentPattern(locale)
      ..maximumFractionDigits = decimalPlaces;
    return formatter.format(value / 100);
  }

  /// Get a list of supported currencies from the database
  /// Falls back to a default list if offline or error occurs
  Future<List<Currency>> getSupportedCurrencies() async {
    try {
      final response = await Supabase.instance.client
          .from('currencies')
          .select()
          .order('code');

      if (response == null || response.isEmpty) {
        return _getDefaultCurrencies();
      }

      return response.map<Currency>((json) => Currency(
        code: json['code'] as String,
        symbol: json['symbol'] as String,
        name: json['name'] as String,
      )).toList();
    } catch (e) {
      // Fall back to default currencies on error
      return _getDefaultCurrencies();
    }
  }

  /// Get currency by code
  Future<Currency?> getCurrencyByCode(String code) async {
    try {
      final response = await Supabase.instance.client
          .from('currencies')
          .select()
          .eq('code', code)
          .single();

      if (response == null) {
        return null;
      }

      return Currency(
        code: response['code'] as String,
        symbol: response['symbol'] as String,
        name: response['name'] as String,
      );
    } catch (e) {
      // Return null on error
      return null;
    }
  }

  /// Default currencies for offline use
  List<Currency> _getDefaultCurrencies() {
    // Include AppConfig default currency first
    final appConfig = AppConfig();
    return [
      Currency(
        code: appConfig.defaultCurrency.code,
        symbol: appConfig.defaultCurrency.symbol,
        name: appConfig.defaultCurrency.name,
      ),
      const Currency(code: 'EUR', symbol: '€', name: 'Euro'),
      const Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
      const Currency(code: 'JPY', symbol: '¥', name: 'Japanese Yen'),
      const Currency(code: 'AUD', symbol: 'A\$', name: 'Australian Dollar'),
      const Currency(code: 'CAD', symbol: 'C\$', name: 'Canadian Dollar'),
      const Currency(code: 'CHF', symbol: 'Fr', name: 'Swiss Franc'),
      const Currency(code: 'CNY', symbol: '¥', name: 'Chinese Yuan'),
      const Currency(code: 'INR', symbol: '₹', name: 'Indian Rupee'),
      const Currency(code: 'NZD', symbol: 'NZ\$', name: 'New Zealand Dollar'),
    ];
  }

  /// Format monthly payment with period
  String formatMonthlyPayment(
    double amount,
    Currency currency, {
    String locale = 'en_US',
  }) {
    return '${formatCurrency(amount, currency, locale: locale)}/mo';
  }

  /// Format large numbers with proper grouping
  String formatNumber(
    double number, {
    String locale = 'en_US',
    int decimalPlaces = 0,
  }) {
    final formatter = NumberFormat.decimalPattern(locale)
      ..maximumFractionDigits = decimalPlaces;
    return formatter.format(number);
  }
}
