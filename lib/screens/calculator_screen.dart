import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import '../models/debt_profile.dart';
import '../services/debt_service.dart';

class CalculatorScreen extends StatefulWidget {
  final bool isDarkMode;
  
  const CalculatorScreen({super.key, this.isDarkMode = false});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final _debtService = DebtService();
  final _formKey = GlobalKey<FormState>();
  
  final _debtController = TextEditingController();
  final _interestController = TextEditingController();
  final _paymentController = TextEditingController();
  final _extraPaymentController = TextEditingController(text: '0');
  
  DebtProfile? _calculatedProfile;
  List<double>? _payoffData;
  bool _showResults = false;

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

    final profile = DebtProfile(
      name: 'Calculator',
      description: '',
      totalDebt: double.parse(_debtController.text),
      interestRate: double.parse(_interestController.text),
      monthlyPayment: double.parse(_paymentController.text),
      amountPaid: 0,
      currency: const Currency(code: 'USD', symbol: '\$', name: 'US Dollar'),
    );

    final extraPayment = double.tryParse(_extraPaymentController.text) ?? 0;
    
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

    return Scaffold(
      backgroundColor: isDarkMode 
          ? const Color(0xFF121212) 
          : const Color(0xFFF9F9F9),
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
                                      const Color(0xFF9C27B0),
                                      Colors.purple.shade700,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.calculate_outlined,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Enter Debt Details',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'Debt Calculator',
                                        style: TextStyle(
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: SingleChildScrollView(
                                        child: ListBody(
                                          children: [
                                            Text(
                                              'How to use this calculator:',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              '• Enter your total debt amount',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '• Enter the annual interest rate',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '• Enter your regular monthly payment',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            Text(
                                              '• Optionally add extra monthly payment',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'This will calculate your payoff timeline and total costs.',
                                              style: TextStyle(
                                                color: isDarkMode ? Colors.white : Colors.black87,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.of(context).pop(),
                                          child: Text(
                                            'Got it',
                                            style: TextStyle(
                                              color: const Color(0xFF9C27B0),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.info_outline,
                                    color: isDarkMode ? Colors.white70 : Colors.black45,
                                    size: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _debtController,
                            label: 'Total Debt Amount',
                            prefix: '\$',
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
                            prefix: '\$',
                            validator: _validateNumber,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _extraPaymentController,
                            label: 'Extra Monthly Payment (Optional)',
                            prefix: '\$',
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              // Reset button
                              Expanded(
                                flex: 1,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
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
                              ),
                              // Calculate button
                              Expanded(
                                flex: 2,
                                child: Container(
                                  child: ElevatedButton(
                                    onPressed: _calculate,
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
          prefixIcon: prefix != null 
              ? Icon(prefix == '\$' ? Icons.attach_money : Icons.percent, color: iconColor, size: 20)
              : null,
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
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        validator: validator,
      ),
    );
  }

  String? _validateNumber(String? value) {
    if (value?.isEmpty ?? true) return 'This field is required';
    if (double.tryParse(value!) == null) return 'Must be a valid number';
    if (double.parse(value) <= 0) return 'Must be greater than 0';
    return null;
  }

  Widget _buildResults(ThemeData theme, bool isDarkMode) {
    if (_calculatedProfile == null || _payoffData == null) {
      return const SizedBox.shrink();
    }

    final profile = _calculatedProfile!;
    final extraPayment = double.tryParse(_extraPaymentController.text) ?? 0;
    final monthsToPayoff = _debtService.calculateMonthsToPayoff(
      profile,
      extraPayment: extraPayment,
    );
    final debtFreeDate = _debtService.calculateDebtFreeDate(
      profile,
      extraPayment: extraPayment,
    );
    
    final formatter = NumberFormat.currency(symbol: '\$');
    // Calculate total interest correctly
    // Interest = (Total payments) - Principal
    final totalInterest = (profile.monthlyPayment + extraPayment) * monthsToPayoff - profile.totalDebt;
    final totalPaid = profile.totalDebt + totalInterest;

    return Card(
      color: isDarkMode 
          ? const Color(0xFF1E1E1E)
          : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        Colors.blue.shade600,
                        Colors.purple.shade700,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.insights,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Results',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildResultRow(
              theme,
              label: 'Months to Pay Off:',
              value: '$monthsToPayoff months',
            ),
            _buildResultRow(
              theme,
              label: 'Debt-Free Date:',
              value: DateFormat.yMMMd().format(debtFreeDate),
            ),
            _buildResultRow(
              theme,
              label: 'Total Interest:',
              value: formatter.format(totalInterest),
              color: theme.colorScheme.error,
            ),
            _buildResultRow(
              theme,
              label: 'Total Amount Paid:',
              value: formatter.format(totalPaid),
              bold: true,
            ),
            if (extraPayment > 0) ...[
              const Divider(height: 32),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withOpacity(isDarkMode ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_down,
                      size: 16,
                      color: isDarkMode ? Colors.purpleAccent : const Color(0xFF9C27B0),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Impact of Extra Payments',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildResultRow(
                theme,
                label: 'Monthly Savings:',
                value: formatter.format(
                  profile.monthlyPayment * (_debtService.calculateMonthsToPayoff(profile, extraPayment: 0) - monthsToPayoff),
                ),
                color: theme.colorScheme.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(
    ThemeData theme, {
    required String label,
    required String value,
    Color? color,
    bool bold = false,
  }) {
    final isDarkMode = widget.isDarkMode;
    final defaultColor = isDarkMode ? Colors.white : Colors.black87;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.black.withOpacity(0.2) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color != null 
              ? color.withOpacity(isDarkMode ? 0.3 : 0.1) 
              : (isDarkMode ? Colors.white12 : Colors.black12),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: isDarkMode ? Colors.white70 : Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: color ?? defaultColor,
            ),
          ),
        ],
      ),
    );
  }
}
