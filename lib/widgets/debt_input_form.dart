import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/debt_profile.dart';
import '../providers/debt_provider.dart';
import '../services/currency_service.dart';

class DebtInputForm extends StatefulWidget {
  final DebtProfile? initialProfile;

  const DebtInputForm({
    super.key,
    this.initialProfile,
  });

  @override
  State<DebtInputForm> createState() => _DebtInputFormState();
}

class _DebtInputFormState extends State<DebtInputForm> {
  final _formKey = GlobalKey<FormState>();
  final _currencyService = CurrencyService();
  
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _totalDebtController;
  late final TextEditingController _interestRateController;
  late final TextEditingController _monthlyPaymentController;
  late final TextEditingController _hourlyWageController;
  late final TextEditingController _amountPaidController;

  List<Currency> _currencies = [];
  Currency? _selectedCurrency;
  bool _isLoadingCurrencies = true;

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    _nameController = TextEditingController(text: profile?.name);
    _descriptionController = TextEditingController(text: profile?.description);
    _totalDebtController = TextEditingController(
      text: profile?.totalDebt.toString(),
    );
    _interestRateController = TextEditingController(
      text: profile?.interestRate.toString(),
    );
    _monthlyPaymentController = TextEditingController(
      text: profile?.monthlyPayment.toString(),
    );
    _hourlyWageController = TextEditingController(
      text: profile?.hourlyWage?.toString(),
    );
    _amountPaidController = TextEditingController(
      text: profile?.amountPaid.toString(),
    );
    
    _loadCurrencies();
  }

  Future<void> _loadCurrencies() async {
    setState(() {
      _isLoadingCurrencies = true;
    });

    try {
      // Get provider for default currencies
      final provider = Provider.of<DebtProvider>(context, listen: false);
      
      // Start with default currencies for immediate display
      _currencies = provider.getDefaultCurrencies();
      
      // Set initial selected currency
      if (widget.initialProfile != null) {
        _selectedCurrency = _currencies.firstWhere(
          (c) => c.code == widget.initialProfile!.currency.code,
          orElse: () => _currencies.first,
        );
      } else {
        _selectedCurrency = _currencies.first;
      }
      
      // Then load full list asynchronously
      final currencies = await provider.getSupportedCurrencies();
      
      if (mounted) {
        setState(() {
          _currencies = currencies;
          
          // Re-select currency if needed
          if (widget.initialProfile != null) {
            _selectedCurrency = _currencies.firstWhere(
              (c) => c.code == widget.initialProfile!.currency.code,
              orElse: () => _selectedCurrency ?? _currencies.first,
            );
          }
          
          _isLoadingCurrencies = false;
        });
      }
    } catch (e) {
      // Handle error - keep default currencies
      if (mounted) {
        setState(() {
          _isLoadingCurrencies = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalDebtController.dispose();
    _interestRateController.dispose();
    _monthlyPaymentController.dispose();
    _hourlyWageController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.initialProfile == null ? 'New Debt Profile' : 'Edit Profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildInputSection(
            title: 'Basic Information',
            children: [
              _buildTextField(
                controller: _nameController,
                label: 'Name',
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _descriptionController,
                label: 'Description (optional)',
                maxLines: 2,
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildInputSection(
            title: 'Debt Details',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _totalDebtController,
                      label: 'Total Debt',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*$'),  // Allow both dot and comma as decimal separators
                        ),
                      ],
                      validator: _validateNumber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _interestRateController,
                      label: 'Interest Rate (%)',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*$'),  // Allow both dot and comma as decimal separators
                        ),
                      ],
                      validator: _validateNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _monthlyPaymentController,
                      label: 'Monthly Payment',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*$'),  // Allow both dot and comma as decimal separators
                        ),
                      ],
                      validator: _validateNumber,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _hourlyWageController,
                      label: 'Hourly Wage (optional)',
                      suffix: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Hourly Wage'),
                              content: const Text(
                                'Adding your hourly wage allows the app to calculate how many work hours you need to pay off your debt.\n\nThis can be an eye-opening perspective on the real cost of debt in terms of your time and effort.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('GOT IT'),
                                ),
                              ],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Icon(
                          Icons.help_outline_rounded,
                          size: 16,
                          color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        ),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*$'),  // Allow both dot and comma as decimal separators
                        ),
                      ],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return null;
                        try {
                          final number = _parseNumber(value!);
                          if (number <= 0) {
                            return 'Must be greater than 0';
                          }
                          return null;
                        } catch (e) {
                          return 'Enter a valid number';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _amountPaidController,
                label: 'Amount Already Paid',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d*[.,]?\d*$'),  // Allow both dot and comma as decimal separators
                  ),
                ],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'This field is required';
                  
                  try {
                    final number = _parseNumber(value!);
                    if (number < 0) {
                      return 'Must be 0 or greater';
                    }
                    if (_totalDebtController.text.isNotEmpty) {
                      final totalDebt = _parseNumber(_totalDebtController.text);
                      if (number > totalDebt) {
                        return 'Cannot exceed total debt';
                      }
                    }
                    return null;
                  } catch (e) {
                    return 'Enter a valid number';
                  }
                },
              ),
              const SizedBox(height: 16),
              _buildCurrencySelector(),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.grey.shade300 
                      : Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton(
                onPressed: () {
                  // Dismiss keyboard before submitting form
                  FocusManager.instance.primaryFocus?.unfocus();
                  _submitForm();
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).brightness == Brightness.dark 
                    ? const Color(0xFF7B1FA2) 
                    : const Color(0xFF9C27B0),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  widget.initialProfile == null ? 'Create Profile' : 'Save Changes',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildCurrencySelector() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (_isLoadingCurrencies) {
      return Container(
        height: 58,  
        decoration: BoxDecoration(
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.0),
          color: isDark ? Colors.grey.shade900 : Colors.white,
        ),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDark ? const Color(0xFF7B1FA2) : const Color(0xFF9C27B0),
              ),
            ),
          ),
        ),
      );
    }

    if (_currencies.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Enter Currency Details",
            style: TextStyle(
              fontSize: 12, 
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: _selectedCurrency?.code ?? 'USD',
                  decoration: InputDecoration(
                    labelText: 'Currency Code',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF7B1FA2) : const Color(0xFF9C27B0),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLength: 3,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Code is required';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = Currency(
                        code: value,
                        symbol: _selectedCurrency?.symbol ?? '\$',
                        name: _selectedCurrency?.name ?? 'Currency',
                      );
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: _selectedCurrency?.symbol ?? '\$',
                  decoration: InputDecoration(
                    labelText: 'Currency Symbol',
                    labelStyle: TextStyle(
                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF7B1FA2) : const Color(0xFF9C27B0),
                        width: 2,
                      ),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey.shade900 : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLength: 2,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Symbol is required';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      _selectedCurrency = Currency(
                        code: _selectedCurrency?.code ?? 'USD',
                        symbol: value,
                        name: _selectedCurrency?.name ?? 'Currency',
                      );
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      );
    }

    return DropdownButtonFormField<Currency>(
      decoration: InputDecoration(
        labelText: 'Currency',
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF7B1FA2) : const Color(0xFF9C27B0),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      value: _selectedCurrency,
      isExpanded: true,
      icon: Icon(
        Icons.keyboard_arrow_down_rounded,
        color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
      ),
      dropdownColor: isDark ? Colors.grey.shade800 : Colors.white,
      style: TextStyle(
        color: isDark ? Colors.white : Colors.grey.shade900,
      ),
      items: _currencies.map((currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(
            '${currency.code} (${currency.symbol}) - ${currency.name}',
            overflow: TextOverflow.ellipsis,
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCurrency = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a currency';
        }
        return null;
      },
    );
  }

  Widget _buildInputSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark 
          ? Colors.grey.shade900.withOpacity(0.3) 
          : Colors.grey.shade100.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white 
                      : const Color(0xFF9C27B0),
                  ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    Widget? suffix,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int? maxLength,
    int? maxLines,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? const Color(0xFF7B1FA2) : const Color(0xFF9C27B0),
            width: 2,
          ),
        ),
        filled: true,
        fillColor: isDark ? Colors.grey.shade900 : Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        suffixIcon: suffix != null ? Padding(
          padding: const EdgeInsets.only(right: 12),
          child: suffix,
        ) : null,
      ),
      style: TextStyle(
        color: isDark ? Colors.white : Colors.grey.shade900,
      ),
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLength: maxLength,
      maxLines: maxLines ?? 1,
    );
  }

  String? _validateNumber(String? value) {
    if (value?.isEmpty ?? true) return 'This field is required';
    
    try {
      final number = _parseNumber(value!);
      if (number <= 0) return 'Must be greater than 0';
      return null;
    } catch (e) {
      return 'Must be a valid number';
    }
  }

  double _parseNumber(String text) {
    if (text.contains(',')) {
      text = text.replaceAll(',', '.');
    }
    return double.parse(text);
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCurrency == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a currency')),
      );
      return;
    }

    final profile = DebtProfile(
      id: widget.initialProfile?.id,
      name: _nameController.text,
      description: _descriptionController.text,
      totalDebt: _parseNumber(_totalDebtController.text),
      interestRate: _parseNumber(_interestRateController.text),
      monthlyPayment: _parseNumber(_monthlyPaymentController.text),
      hourlyWage: _hourlyWageController.text.isNotEmpty
          ? _parseNumber(_hourlyWageController.text)
          : null,
      amountPaid: _parseNumber(_amountPaidController.text),
      currency: _selectedCurrency!,
    );

    final provider = context.read<DebtProvider>();
    if (widget.initialProfile == null) {
      provider.createProfile(profile);
    } else {
      provider.updateProfile(profile);
    }

    Navigator.of(context).pop();
  }
}
