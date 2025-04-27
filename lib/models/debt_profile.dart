import 'package:uuid/uuid.dart';

class DebtProfile {
  final String id;
  final String name;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double totalDebt;
  final double interestRate;
  final double monthlyPayment;
  final double? hourlyWage;
  final double amountPaid;
  final Currency currency;

  DebtProfile({
    String? id,
    required this.name,
    required this.description,
    required this.totalDebt,
    required this.interestRate,
    required this.monthlyPayment,
    this.hourlyWage,
    required this.amountPaid,
    required this.currency,
  })  : id = id ?? const Uuid().v4(),
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'totalDebt': totalDebt,
        'interestRate': interestRate,
        'monthlyPayment': monthlyPayment,
        'hourlyWage': hourlyWage,
        'amountPaid': amountPaid,
        'currency': currency.toJson(),
      };

  factory DebtProfile.fromJson(Map<dynamic, dynamic> json) => DebtProfile(
        id: json['id'].toString(),
        name: json['name'].toString(),
        description: json['description'].toString(),
        totalDebt: (json['totalDebt'] is int) ? (json['totalDebt'] as int).toDouble() : (json['totalDebt'] as num).toDouble(),
        interestRate: (json['interestRate'] is int) ? (json['interestRate'] as int).toDouble() : (json['interestRate'] as num).toDouble(),
        monthlyPayment: (json['monthlyPayment'] is int) ? (json['monthlyPayment'] as int).toDouble() : (json['monthlyPayment'] as num).toDouble(),
        hourlyWage: json['hourlyWage'] != null 
            ? (json['hourlyWage'] is int) 
                ? (json['hourlyWage'] as int).toDouble() 
                : (json['hourlyWage'] as num).toDouble()
            : null,
        amountPaid: (json['amountPaid'] is int) ? (json['amountPaid'] as int).toDouble() : (json['amountPaid'] as num).toDouble(),
        currency: Currency.fromJson(Map<String, dynamic>.from(json['currency'] as Map? ?? {})),
      );

  DebtProfile copyWith({
    String? name,
    String? description,
    double? totalDebt,
    double? interestRate,
    double? monthlyPayment,
    double? hourlyWage,
    double? amountPaid,
    Currency? currency,
  }) =>
      DebtProfile(
        id: id,
        name: name ?? this.name,
        description: description ?? this.description,
        totalDebt: totalDebt ?? this.totalDebt,
        interestRate: interestRate ?? this.interestRate,
        monthlyPayment: monthlyPayment ?? this.monthlyPayment,
        hourlyWage: hourlyWage ?? this.hourlyWage,
        amountPaid: amountPaid ?? this.amountPaid,
        currency: currency ?? this.currency,
      );
}

class Currency {
  final String code;
  final String symbol;
  final String name;

  const Currency({
    required this.code,
    required this.symbol,
    required this.name,
  });

  Map<String, dynamic> toJson() => {
        'code': code,
        'symbol': symbol,
        'name': name,
      };

  factory Currency.fromJson(Map<String, dynamic> json) => Currency(
        code: json['code']?.toString() ?? 'USD',
        symbol: json['symbol']?.toString() ?? '\$',
        name: json['name']?.toString() ?? 'US Dollar',
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Currency &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          symbol == other.symbol &&
          name == other.name;

  @override
  int get hashCode => code.hashCode ^ symbol.hashCode ^ name.hashCode;

  @override
  String toString() => '${code} (${symbol}) - ${name}';
}
