import 'package:flutter/foundation.dart';
import '../models/debt_profile.dart';
import '../repositories/debt_repository.dart';
import '../services/debt_service.dart';
import '../services/export_service.dart';
import '../services/currency_service.dart';
import '../services/date_service.dart';

class DebtProvider extends ChangeNotifier {
  final DebtRepository _repository;
  final DebtService _debtService;
  final ExportService _exportService;
  final CurrencyService _currencyService;
  final DateService _dateService;
  
  List<DebtProfile> _profiles = [];
  DebtProfile? _selectedProfile;
  double _extraPayment = 0;
  String _locale = 'en_US';

  DebtProvider({
    required DebtRepository repository,
    required DebtService debtService,
  })  : _repository = repository,
        _debtService = debtService,
        _exportService = ExportService(),
        _currencyService = CurrencyService(),
        _dateService = DateService() {
    _initialize();
  }

  List<DebtProfile> get profiles => _profiles;
  DebtProfile? get selectedProfile => _selectedProfile;
  double get extraPayment => _extraPayment;

  Future<void> _initialize() async {
    print('DebtProvider: Initializing repository');
    await _repository.initialize();
    
    print('DebtProvider: Getting all profiles');
    _profiles = await _repository.getAllProfiles();
    print('DebtProvider: Initial profiles count: ${_profiles.length}');
    
    // Select the first profile if we have any and none is selected
    if (_profiles.isNotEmpty && _selectedProfile == null) {
      _selectedProfile = _profiles[0];
      print('DebtProvider: Auto-selected profile: ${_selectedProfile?.name}');
    }
    
    // Make sure we notify listeners after the initial load
    notifyListeners();
    
    // Watch for future changes
    _repository.watchProfiles().listen((profiles) {
      print('DebtProvider: Profile stream updated, count: ${profiles.length}');
      _profiles = profiles;
      
      // If selected profile was deleted, select another one
      if (_selectedProfile != null && !_profiles.any((p) => p.id == _selectedProfile!.id)) {
        _selectedProfile = _profiles.isNotEmpty ? _profiles[0] : null;
        print('DebtProvider: Re-selected profile: ${_selectedProfile?.name}');
      }
      
      notifyListeners();
    });
  }

  void setExtraPayment(double amount) {
    _extraPayment = amount;
    notifyListeners();
  }

  void selectProfile(DebtProfile? profile) {
    _selectedProfile = profile;
    notifyListeners();
  }

  Future<void> createProfile(DebtProfile profile) async {
    await _repository.createProfile(profile);
  }

  Future<void> updateProfile(DebtProfile profile) async {
    await _repository.updateProfile(profile);
  }

  Future<void> deleteProfile(String id) async {
    await _repository.deleteProfile(id);
    if (_selectedProfile?.id == id) {
      _selectedProfile = null;
    }
  }

  // Calculation methods that use DebtService
  int getMonthsToPayoff([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return 0;
    return _debtService.calculateMonthsToPayoff(profile, extraPayment: _extraPayment);
  }

  List<double> getPayoffData([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return [];
    return _debtService.generatePayoffData(profile, extraPayment: _extraPayment);
  }

  int getWorkHoursNeeded([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return 0;
    return _debtService.calculateWorkHoursNeeded(profile);
  }

  double getProgressPercentage([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return 0;
    return _debtService.getProgressPercentage(profile);
  }

  String getMotivationalMessage([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return _debtService.getMotivationalMessage(0);
    return _debtService.getMotivationalMessage(getProgressPercentage(profile));
  }

  DateTime getDebtFreeDate([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return DateTime.now();
    return _debtService.calculateDebtFreeDate(profile, extraPayment: _extraPayment);
  }
  
  /// Calculate the total interest paid over the life of the loan
  double calculateTotalInterest([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return 0;
    
    // Calculate future payments
    final futurePayments = _calculateTotalPayments(profile);
    
    // Calculate total interest over the life of the loan
    // Interest = (Already paid + Future payments) - Original principal
    return (profile.amountPaid + futurePayments) - profile.totalDebt;
  }
  
  /// Get the base months to payoff without extra payments
  int getBaseMonthsToPayoff([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null) return 0;
    // Use 0 for extra payment
    return _debtService.calculateMonthsToPayoff(profile, extraPayment: 0);
  }
  
  /// Calculate the total payments over the life of the loan
  /// Returns the total amount that will be paid including interest
  /// Throws exceptions for invalid inputs
  double _calculateTotalPayments(DebtProfile profile, {double? extraPayment}) {
    // Input validation
    if (profile.monthlyPayment <= 0) {
      throw Exception('Monthly payment must be positive');
    }
    if (profile.interestRate < 0) {
      throw Exception('Interest rate cannot be negative');
    }
    
    final effectiveExtraPayment = extraPayment ?? _extraPayment;
    final monthlyPayment = profile.monthlyPayment + effectiveExtraPayment;
    final interestRate = profile.interestRate / 100 / 12; // Monthly interest rate
    double remainingDebt = profile.totalDebt - profile.amountPaid;
    
    // If debt is already paid off
    if (remainingDebt <= 0) {
      return 0;
    }
    
    // Check if payment covers interest (prevent infinite loop)
    if (monthlyPayment <= remainingDebt * interestRate) {
      throw Exception('Monthly payment too low to cover interest');
    }
    
    double totalPaid = 0;
    
    while (remainingDebt > 0) {
      final interestThisMonth = remainingDebt * interestRate;
      final principalThisMonth = monthlyPayment - interestThisMonth;
      
      if (principalThisMonth >= remainingDebt) {
        // Last payment
        totalPaid += remainingDebt + interestThisMonth;
        remainingDebt = 0;
      } else {
        totalPaid += monthlyPayment;
        remainingDebt -= principalThisMonth;
      }
      
      // Round to avoid floating-point precision issues
      remainingDebt = (remainingDebt * 100).round() / 100;
      totalPaid = (totalPaid * 100).round() / 100;
    }
    
    return totalPaid;
  }

  // Export/Import methods
  String exportData() {
    return _exportService.exportToJson(_profiles);
  }

  Future<(bool success, String message)> importData(String jsonStr) async {
    final (profiles, errors) = await _exportService.importFromJson(jsonStr);
    
    if (errors.isNotEmpty) {
      return (false, errors.join('\n'));
    }

    final validationErrors = _exportService.validateProfiles(profiles);
    if (validationErrors.isNotEmpty) {
      return (false, validationErrors.join('\n'));
    }

    // Clear existing profiles and add imported ones
    for (final profile in _profiles) {
      await _repository.deleteProfile(profile.id);
    }

    for (final profile in profiles) {
      await _repository.createProfile(profile);
    }

    return (true, 'Successfully imported ${profiles.length} profiles');
  }

  // Currency formatting methods
  String formatCurrency(double amount, Currency currency, {bool compact = false}) {
    return _currencyService.formatCurrency(
      amount,
      currency,
      compact: compact,
      locale: _locale,
    );
  }

  String formatPercentage(double value) {
    return _currencyService.formatPercentage(value, locale: _locale);
  }

  String formatMonthlyPayment(double amount, Currency currency) {
    return _currencyService.formatMonthlyPayment(
      amount,
      currency,
      locale: _locale,
    );
  }

  // Updated to async to match the service implementation
  Future<List<Currency>> getSupportedCurrencies() {
    return _currencyService.getSupportedCurrencies();
  }
  
  // Provides default currencies synchronously for immediate UI needs
  List<Currency> getDefaultCurrencies() {
    return [
      const Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
      const Currency(code: 'EUR', symbol: '€', name: 'Euro'),
      const Currency(code: 'GBP', symbol: '£', name: 'British Pound'),
    ];
  }

  void setLocale(String locale) {
    _locale = locale;
    notifyListeners();
  }

  // Date formatting methods
  String formatDate(DateTime date, {String format = 'medium'}) {
    return _dateService.formatDate(date, format: format, locale: _locale);
  }

  String formatRelativeDate(DateTime date) {
    return _dateService.formatRelative(date, locale: _locale);
  }
  
  /// Calculates work hours needed to pay off debt based on hourly wage
  /// Returns null if hourly wage is not set
  double? calculateWorkHoursToPayOff([DebtProfile? profile]) {
    profile ??= _selectedProfile;
    if (profile == null || profile.hourlyWage == null || profile.hourlyWage! <= 0) return null;
    
    // Calculate total payment (debt + interest)
    final totalPayment = _calculateTotalPayments(profile);
    
    // Calculate remaining payment (what's left after amount already paid)
    final remainingPayment = totalPayment - profile.amountPaid;
    
    // If already paid off, return 0 hours
    if (remainingPayment <= 0) return 0;
    
    // Calculate how many work hours needed to earn the remaining payment
    return remainingPayment / profile.hourlyWage!;
  }

  String formatDuration(int months, {bool abbreviated = false}) {
    return _dateService.formatDuration(
      months,
      locale: _locale,
      abbreviated: abbreviated,
    );
  }

  String formatDateRange(DateTime start, DateTime end, {bool includeYear = true}) {
    return _dateService.formatDateRange(
      start,
      end,
      locale: _locale,
      includeYear: includeYear,
    );
  }

  List<(String code, String name)> getSupportedLocales() {
    return _dateService.getSupportedLocales();
  }

  @override
  void dispose() {
    _repository.dispose();
    super.dispose();
  }
}
