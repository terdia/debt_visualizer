import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/debt_profile.dart';
import '../services/debt_service.dart';
import '../services/currency_service.dart';
import '../providers/debt_provider.dart';

class CalculatorScreen extends StatefulWidget {
  final bool isDarkMode;
  
  const CalculatorScreen({super.key, this.isDarkMode = false});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _debtService = DebtService();
  final _currencyService = CurrencyService();
  
  late final TextEditingController _debtController;
  late final TextEditingController _interestController;
  late final TextEditingController _paymentController;
  late final TextEditingController _extraPaymentController;
  
  Currency _selectedCurrency = const Currency(code: 'USD', symbol: '\$', name: 'US Dollar');
  List<Currency> _availableCurrencies = [];
  
  DebtProfile? _calculatedProfile;
  List<double>? _payoffData;
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    _debtController = TextEditingController();
    _interestController = TextEditingController();
    _paymentController = TextEditingController();
    _extraPaymentController = TextEditingController(text: '0');
    // Load available currencies
    _availableCurrencies = _currencyService.getCurrencies();
  }

  @override
  void dispose() {
    _debtController.dispose();
    _interestController.dispose();
    _paymentController.dispose();
    _extraPaymentController.dispose();
    super.dispose();
  }

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;

    // Dismiss keyboard
    FocusScope.of(context).unfocus();

    final profile = DebtProfile(
      name: 'Calculator',
      description: '',
      totalDebt: _parseNumber(_debtController.text),
      interestRate: _parseNumber(_interestController.text),
      monthlyPayment: _parseNumber(_paymentController.text),
      amountPaid: 0,
      currency: _selectedCurrency,
    );

    final double extraPayment = _extraPaymentController.text.isEmpty ? 0.0 : _parseNumber(_extraPaymentController.text);
    
    setState(() {
      _calculatedProfile = profile;
      _payoffData = _debtService.generatePayoffData(profile, extraPayment: extraPayment);
      _showResults = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final theme = Theme.of(context);

    return GestureDetector(
      // Add tap handler to dismiss keyboard when tapping outside text fields
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: isDarkMode 
            ? const Color(0xFF121212) 
            : const Color(0xFFF9F9F9),
        // Set resizeToAvoidBottomInset to true to handle keyboard properly
        resizeToAvoidBottomInset: true,
        body: CustomScrollView(
          slivers: [
            SliverAppBar.medium(
              title: const Text('Debt Calculator'),
              backgroundColor: isDarkMode 
                  ? Colors.black.withOpacity(0.7) 
                  : Colors.white.withOpacity(0.7),
              foregroundColor: isDarkMode ? Colors.white : Colors.black87,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Card(
                    color: isDarkMode 
                        ? const Color(0xFF1E1E1E)
                        : Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.purple.shade800,
                                        Colors.pink.shade700,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.calculate,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Calculate Debt Payoff',
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Description
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode ? Colors.black26 : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    CupertinoIcons.info_circle,
                                    color: isDarkMode ? Colors.blue.shade200 : Colors.blue.shade700,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Enter your debt details to see how quickly you can be debt-free',
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            const SizedBox(height: 16),
                            // Currency Selector
                            Row(
                              children: [
                                Text('Currency:', 
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDarkMode ? Colors.white24 : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<Currency>(
                                        value: _selectedCurrency,
                                        isDense: true,
                                        dropdownColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
                                        iconEnabledColor: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                          fontSize: 15,
                                        ),
                                        items: _availableCurrencies.map((currency) {
                                          return DropdownMenuItem<Currency>(
                                            value: currency,
                                            child: Text('${currency.code} (${currency.symbol})'),
                                          );
                                        }).toList(),
                                        onChanged: (Currency? currency) {
                                          if (currency != null) {
                                            setState(() {
                                              _selectedCurrency = currency;
                                            });
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _debtController,
                              label: 'Total Debt Amount',
                              prefix: _selectedCurrency.symbol,
                              validator: _validateNumber,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _interestController,
                              label: 'Annual Interest Rate',
                              suffix: '%',
                              validator: _validateNumber,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _paymentController,
                              label: 'Monthly Payment',
                              prefix: _selectedCurrency.symbol,
                              validator: _validateNumber,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _extraPaymentController,
                              label: 'Extra Monthly Payment (Optional)',
                              prefix: _selectedCurrency.symbol,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                // Reset button
                                Expanded(
                                  flex: 1,
                                  child: OutlinedButton(
                                    onPressed: () {
                                      setState(() {
                                        // Clear all input fields
                                        _debtController.clear();
                                        _interestController.clear();
                                        _paymentController.clear();
                                        _extraPaymentController.text = '0';
                                        _showResults = false;
                                        _calculatedProfile = null;
                                        _payoffData = null;
                                      });
                                    },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: const Color(0xFF9C27B0).withOpacity(0.5),
                                        width: 1,
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          CupertinoIcons.refresh,
                                          size: 16,
                                          color: const Color(0xFF9C27B0),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Reset',
                                          style: TextStyle(
                                            color: const Color(0xFF9C27B0),
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Calculate button
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        // Dismiss keyboard before calculation
                                        FocusManager.instance.primaryFocus?.unfocus();
                                        _calculate();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF9C27B0),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        elevation: 0,
                                      ),
                                      child: Text('Calculate', style: TextStyle(fontSize: 16)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            if (_showResults) SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: _buildResults(theme, isDarkMode),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? prefix,
    String? suffix,
    String? Function(String?)? validator,
  }) {
    final isDarkMode = widget.isDarkMode;
    final iconColor = const Color(0xFF9C27B0);
    
    // Determine which icon to use based on the field type
    IconData getIconForField() {
      if (label.contains('Interest')) {
        return Icons.percent; // Interest rate uses percent icon
      } else if (label.contains('Payment') || label.contains('Debt')) {
        return Icons.attach_money; // Any payment or debt amount uses money icon
      } else {
        return Icons.monetization_on; // Default money icon
      }
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white12 : Colors.black12,
          width: 0.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(getIconForField(), color: iconColor, size: 20),
          prefixText: prefix,
          suffixText: suffix,
          labelStyle: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black54,
            fontSize: 14,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
        style: TextStyle(
          color: isDarkMode ? Colors.white : Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          // Allow both dot and comma decimal separators
          DecimalTextInputFormatter(),
        ],
        validator: validator,
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a number';
    }
    
    try {
      final number = _parseNumber(value);
      if (number <= 0) {
        return 'Must be greater than zero';
      }
    } catch (e) {
      return 'Please enter a valid number';
    }
    
    return null;
  }
  
  // Parse a number that may use comma as decimal separator
  double _parseNumber(String text) {
    // Replace comma with dot for parsing
    final normalizedText = text.replaceAll(',', '.');
    return double.parse(normalizedText);
  }

  Widget _buildResults(ThemeData theme, bool isDarkMode) {
    if (_calculatedProfile == null || _payoffData == null) {
      return const SizedBox.shrink();
    }

    final profile = _calculatedProfile!;
    final extraPayment = double.tryParse(_extraPaymentController.text) ?? 0;
    
    // Calculate scenario with extra payment
    final monthsToPayoff = _debtService.calculateMonthsToPayoff(
      profile,
      extraPayment: extraPayment,
    );
    final debtFreeDate = _debtService.calculateDebtFreeDate(
      profile,
      extraPayment: extraPayment,
    );
    
    // Calculate scenario without extra payment (standard payment)
    final standardMonthsToPayoff = extraPayment > 0 ? _debtService.calculateMonthsToPayoff(
      profile,
      extraPayment: 0,
    ) : monthsToPayoff;
    final standardDebtFreeDate = extraPayment > 0 ? _debtService.calculateDebtFreeDate(
      profile,
      extraPayment: 0,
    ) : debtFreeDate;
    
    // Calculate differences if there is an extra payment
    final monthsSaved = extraPayment > 0 ? standardMonthsToPayoff - monthsToPayoff : 0;
    final showExtraPaymentImpact = extraPayment > 0 && monthsSaved > 0;
    
    // Use the correct currency symbol from the selected profile
    final formatter = NumberFormat.currency(symbol: profile.currency.symbol);
    
    // Calculate interest and total paid with extra payment
    final totalInterest = (profile.monthlyPayment + extraPayment) * monthsToPayoff - profile.totalDebt;
    final totalPaid = profile.totalDebt + totalInterest;
    
    // Calculate standard interest (without extra payment)
    final standardTotalInterest = extraPayment > 0 ?
        (profile.monthlyPayment * standardMonthsToPayoff) - profile.totalDebt : totalInterest;
    final interestSaved = extraPayment > 0 ? standardTotalInterest - totalInterest : 0;
    
    // Calculate percentage of interest vs principal
    final interestPercentage = (totalInterest / totalPaid * 100).round();
    final principalPercentage = 100 - interestPercentage;

    // Accent colors
    final accentColor = isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF9C27B0);
    final secondaryColor = isDarkMode ? Colors.tealAccent : Colors.teal;

    return Card(
      color: isDarkMode 
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      elevation: isDarkMode ? 0 : 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentColor,
                        secondaryColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Debt Payoff Summary',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'You\'ll be debt-free by ${DateFormat('MMMM yyyy').format(debtFreeDate)}',
                        style: TextStyle(
                          color: isDarkMode ? Colors.white70 : Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            
            // Main highlight - Time to pay off
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : accentColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDarkMode ? accentColor.withOpacity(0.3) : accentColor.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time to pay off - use Flexible to allow text wrapping
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today, 
                              size: 16,
                              color: accentColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Time to Pay Off',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$monthsToPayoff months',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Monthly payment - use Flexible to allow text wrapping
                  Flexible(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.payments, 
                              size: 16,
                              color: secondaryColor,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                'Monthly Payment',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            formatter.format(profile.monthlyPayment + extraPayment),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: secondaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Cost breakdown section header
            Text(
              'Cost Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            
            // Percentage visualizer
            Container(
              height: 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDarkMode ? Colors.black26 : Colors.grey.shade200,
              ),
              child: Row(
                children: [
                  // Principal percentage
                  Expanded(
                    flex: principalPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(12),
                          bottomLeft: const Radius.circular(12),
                          topRight: Radius.circular(principalPercentage == 100 ? 12 : 0),
                          bottomRight: Radius.circular(principalPercentage == 100 ? 12 : 0),
                        ),
                        color: secondaryColor,
                      ),
                    ),
                  ),
                  // Interest percentage
                  Expanded(
                    flex: interestPercentage,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.only(
                          topRight: const Radius.circular(12),
                          bottomRight: const Radius.circular(12),
                          topLeft: Radius.circular(interestPercentage == 100 ? 12 : 0),
                          bottomLeft: Radius.circular(interestPercentage == 100 ? 12 : 0),
                        ),
                        color: accentColor,
                      ),
                      child: interestPercentage > 15 ? Center(
                        child: Text(
                          '$interestPercentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ) : const SizedBox(),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Legend and values
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  flex: 1,
                  child: _buildLegendItem(
                    'Principal',
                    formatter.format(profile.totalDebt),
                    '$principalPercentage%',
                    secondaryColor,
                    isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  flex: 1,
                  child: _buildLegendItem(
                    'Interest',
                    formatter.format(totalInterest),
                    '$interestPercentage%',
                    accentColor,
                    isDarkMode,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Total amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.black26 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDarkMode ? Colors.white12 : Colors.grey.shade200,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Payment',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        formatter.format(totalPaid),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Additional Payment Impact Section (only shown when there's an extra payment with impact)
            if (showExtraPaymentImpact) ...[  
              const SizedBox(height: 32),
              
              // Section header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.green.withOpacity(0.3) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.green.withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.trending_down,
                      color: Colors.green,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Extra Payment Impact',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'Adding ${formatter.format(extraPayment)} monthly',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Impact details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.black26 : Colors.green.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode ? Colors.green.withOpacity(0.3) : Colors.green.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    // Time saved row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.access_time,
                            color: Colors.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Time Saved',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '$monthsSaved months',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '(${(monthsSaved / standardMonthsToPayoff * 100).round()}% faster)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: isDarkMode ? Colors.white60 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),
                    
                    // Money saved row
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.savings,
                            color: Colors.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Interest Saved',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  children: [
                                    Text(
                                      formatter.format(interestSaved),
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${(interestSaved / standardTotalInterest * 100).round()}% less interest)',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: isDarkMode ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildLegendItem(String label, String amount, String percentage, Color color, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label with color indicator
        Row(
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Amount and percentage in a column for better space usage
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                percentage,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResultItem(String title, String value, IconData icon, TextStyle titleStyle, TextStyle valueStyle) {
    final isDarkMode = widget.isDarkMode;
    final highlightColor = isDarkMode ? const Color(0xFFBB86FC) : const Color(0xFF9C27B0);
    
    return Container(
      height: 90, // Fixed height to ensure consistency
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title always visible at the top
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                width: 1,
              )),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: highlightColor.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 14,
                    color: highlightColor,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          // Value on its own line with more space
          Center(
            child: Text(
              value,
              style: valueStyle.copyWith(
                color: highlightColor,
                fontSize: 18, // Larger for values
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.visible, // Allow text to be fully visible
            ),
          ),
        ],
      ),
    );
  }
}

// Allow both dot and comma decimal separators
class DecimalTextInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final regEx = RegExp(r'^\d*[.,]?\d*$');
    if (regEx.hasMatch(newValue.text)) {
      return newValue;
    }
    return oldValue;
  }
}
