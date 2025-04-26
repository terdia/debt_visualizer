import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/debt_profile.dart';
import '../services/debt_service.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

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
      currency: const Currency(code: 'USD', symbol: '\$'),
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
    final theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.medium(
            title: const Text('Debt Calculator'),
            backgroundColor: theme.colorScheme.surface,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enter Debt Details',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 24),
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
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _calculate,
                              child: const Text('Calculate'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (_showResults && _calculatedProfile != null) ...[
                  const SizedBox(height: 24),
                  _buildResults(theme),
                ],
              ]),
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
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: prefix,
        suffixText: suffix,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      validator: validator,
    );
  }

  String? _validateNumber(String? value) {
    if (value?.isEmpty ?? true) return 'This field is required';
    if (double.tryParse(value!) == null) return 'Must be a valid number';
    if (double.parse(value) <= 0) return 'Must be greater than 0';
    return null;
  }

  Widget _buildResults(ThemeData theme) {
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
    final totalInterest = _payoffData!.reduce((a, b) => a + b) - profile.totalDebt;
    final totalPaid = profile.totalDebt + totalInterest;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Results',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
              Text(
                'Impact of Extra Payments',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              _buildResultRow(
                theme,
                label: 'Monthly Savings:',
                value: formatter.format(
                  (totalPaid / monthsToPayoff) - profile.monthlyPayment,
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge,
          ),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: bold ? FontWeight.w600 : null,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
