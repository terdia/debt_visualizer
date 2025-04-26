import 'package:intl/intl.dart';

class DateService {
  static final _cache = <String, DateFormat>{};

  /// Format a date with the given format and locale
  String formatDate(
    DateTime date, {
    String format = 'medium',
    String locale = 'en_US',
  }) {
    final cacheKey = '${format}_$locale';
    
    final formatter = _cache.putIfAbsent(cacheKey, () {
      switch (format) {
        case 'short':
          return DateFormat.yMd(locale);
        case 'medium':
          return DateFormat.yMMMd(locale);
        case 'long':
          return DateFormat.yMMMMd(locale);
        case 'full':
          return DateFormat.yMMMMEEEEd(locale);
        case 'monthYear':
          return DateFormat.yMMMM(locale);
        case 'relative':
          return DateFormat.yMMMd(locale);
        default:
          return DateFormat(format, locale);
      }
    });

    return formatter.format(date);
  }

  /// Format a date relative to now (e.g., "in 2 months", "3 months ago")
  String formatRelative(
    DateTime date, {
    String locale = 'en_US',
    DateTime? reference,
  }) {
    final now = reference ?? DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays.abs() <= 1) {
      if (difference.isNegative) {
        return 'yesterday';
      }
      return 'tomorrow';
    }

    if (difference.inDays.abs() < 30) {
      final days = difference.inDays.abs();
      if (difference.isNegative) {
        return '$days ${days == 1 ? 'day' : 'days'} ago';
      }
      return 'in $days ${days == 1 ? 'day' : 'days'}';
    }

    final months = (difference.inDays / 30).round();
    if (months.abs() < 12) {
      if (difference.isNegative) {
        return '$months ${months == 1 ? 'month' : 'months'} ago';
      }
      return 'in $months ${months == 1 ? 'month' : 'months'}';
    }

    final years = (months / 12).round();
    if (difference.isNegative) {
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
    return 'in $years ${years == 1 ? 'year' : 'years'}';
  }

  /// Format a duration in months and years
  String formatDuration(
    int months, {
    String locale = 'en_US',
    bool abbreviated = false,
  }) {
    if (months < 12) {
      return abbreviated
          ? '${months}mo'
          : '$months ${months == 1 ? 'month' : 'months'}';
    }

    final years = months ~/ 12;
    final remainingMonths = months % 12;

    if (remainingMonths == 0) {
      return abbreviated
          ? '${years}yr'
          : '$years ${years == 1 ? 'year' : 'years'}';
    }

    if (abbreviated) {
      return '${years}yr ${remainingMonths}mo';
    }

    return '$years ${years == 1 ? 'year' : 'years'} '
        'and $remainingMonths ${remainingMonths == 1 ? 'month' : 'months'}';
  }

  /// Format a date range
  String formatDateRange(
    DateTime start,
    DateTime end, {
    String locale = 'en_US',
    bool includeYear = true,
  }) {
    final startYear = start.year;
    final endYear = end.year;
    final sameYear = startYear == endYear;

    if (sameYear && !includeYear) {
      return '${DateFormat.MMMMd(locale).format(start)} - '
          '${DateFormat.MMMMd(locale).format(end)}';
    }

    return '${DateFormat.yMMMd(locale).format(start)} - '
        '${DateFormat.yMMMd(locale).format(end)}';
  }

  /// Get the first day of the month
  DateTime getFirstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the last day of the month
  DateTime getLastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get a list of supported locales
  List<(String code, String name)> getSupportedLocales() {
    return [
      ('en_US', 'English (US)'),
      ('en_GB', 'English (UK)'),
      ('es_ES', 'Español'),
      ('fr_FR', 'Français'),
      ('de_DE', 'Deutsch'),
      ('it_IT', 'Italiano'),
      ('pt_BR', 'Português'),
      ('ja_JP', '日本語'),
      ('zh_CN', '中文'),
      ('ko_KR', '한국어'),
    ];
  }
}
