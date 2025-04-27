import 'package:intl/intl.dart';
import '../models/debt_profile.dart';

/// Utility class for formatting currency values
class CurrencyFormatter {
  /// Format a currency value with the appropriate symbol
  static String format(
    double amount,
    Currency currency, {
    bool compact = false,
  }) {
    final formatter = compact
        ? NumberFormat.compactCurrency(symbol: currency.symbol)
        : NumberFormat.currency(
            symbol: currency.symbol,
            decimalDigits: 0,
          );
    return formatter.format(amount);
  }
}
