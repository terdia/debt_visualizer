import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/debt_provider.dart';
import '../services/payment_service.dart';
import '../services/auth_service.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isDarkMode;

  const ProfileScreen({
    required this.isDarkMode,
    Key? key,
  }) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = false;
  bool _isSubscribed = false;
  bool _isLoggedIn = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    setState(() => _isLoading = true);

    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final paymentService = debtProvider.getPaymentService();

    // Check if user is logged in
    final isLoggedIn = paymentService.isUserAuthenticated();
    
    // If logged in, check subscription status
    bool isSubscribed = false;
    if (isLoggedIn && paymentService.supabase != null) {
      try {
        final authService = AuthService(paymentService.supabase!);
        isSubscribed = await authService.hasActiveSubscription();
      } catch (e) {
        print('Error checking subscription: $e');
      }
    }

    setState(() {
      _isLoggedIn = isLoggedIn;
      _isSubscribed = isSubscribed;
      _isLoading = false;
    });
  }

  Future<void> _handleAuth() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter both email and password');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final paymentService = debtProvider.getPaymentService();

      final success = await paymentService.authenticateUser(
        email: _emailController.text,
        password: _passwordController.text,
        isLogin: _isLogin,
      );

      if (success) {
        _emailController.clear();
        _passwordController.clear();
        await _checkAuthStatus();
      } else {
        setState(() => _errorMessage = 'Authentication failed. Please try again.');
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignOut() async {
    setState(() => _isLoading = true);
    
    try {
      final debtProvider = Provider.of<DebtProvider>(context, listen: false);
      final paymentService = debtProvider.getPaymentService();
      
      if (paymentService.isSupabaseAvailable() && paymentService.supabase != null) {
        final authService = AuthService(paymentService.supabase!);
        await authService.signOut();
        await _checkAuthStatus();
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _navigateToSubscription() {
    final debtProvider = Provider.of<DebtProvider>(context, listen: false);
    final paymentService = debtProvider.getPaymentService();
    
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => SubscriptionScreen(
          paymentService: paymentService,
          isDarkMode: widget.isDarkMode,
        ),
      ),
    ).then((_) => _checkAuthStatus());
  }

  @override
  Widget build(BuildContext context) {
    final brightness = widget.isDarkMode ? Brightness.dark : Brightness.light;
    final backgroundColor = widget.isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = widget.isDarkMode ? Colors.white : Colors.black;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.purple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile Card
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade900,
                            Colors.purple.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.2),
                                radius: 30,
                                child: Icon(
                                  _isLoggedIn ? CupertinoIcons.person_fill : CupertinoIcons.person,
                                  color: Colors.white,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLoggedIn ? 'Logged In' : 'Guest User',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_isLoggedIn) ...[
                                      const SizedBox(height: 5),
                                      Text(
                                        _isSubscribed ? 'Premium Subscription' : 'Free Account',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (_isLoggedIn) ...[
                                IconButton(
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.white,
                                  ),
                                  onPressed: _handleSignOut,
                                ),
                              ],
                            ],
                          ),
                          if (_isSubscribed) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade300,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    CupertinoIcons.star_fill,
                                    color: Colors.deepPurple,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'PREMIUM',
                                    style: TextStyle(
                                      color: Colors.purple.shade900,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Subscription Info
                    const SizedBox(height: 30),
                    Text(
                      'Subscription',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.grey.shade800.withOpacity(0.8) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _isSubscribed ? 'Premium Plan' : 'Free Plan',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: widget.isDarkMode ? Colors.white : Colors.black,
                                ),
                              ),
                              if (_isSubscribed)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    'Active',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            _isSubscribed
                                ? 'You have access to all premium features of Debt Visualizer.'
                                : 'Upgrade to premium to unlock all features of Debt Visualizer.',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              color: _isSubscribed ? 
                                     (widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300) : 
                                     const Color(0xFF9C27B0),
                              borderRadius: BorderRadius.circular(10),
                              onPressed: _navigateToSubscription,
                              child: Text(
                                _isSubscribed ? 'Manage Subscription' : 'Upgrade to Premium',
                                style: TextStyle(
                                  color: _isSubscribed ? 
                                         (widget.isDarkMode ? Colors.white : Colors.black87) : 
                                         Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Authentication Section (if not logged in)
                    if (!_isLoggedIn) ...[
                      const SizedBox(height: 30),
                      Text(
                        _isLogin ? 'Login' : 'Create Account',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isDarkMode ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? Colors.grey.shade800 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(15),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              obscureText: true,
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white : Colors.black,
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: CupertinoButton(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                color: const Color(0xFF9C27B0),
                                borderRadius: BorderRadius.circular(10),
                                onPressed: _handleAuth,
                                child: Text(
                                  _isLogin ? 'Login' : 'Create Account',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isLogin = !_isLogin;
                                });
                              },
                              child: Text(
                                _isLogin ? 'Don\'t have an account? Sign up' : 'Already have an account? Login',
                                style: TextStyle(
                                  color: widget.isDarkMode ? Colors.white70 : const Color(0xFF9C27B0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // Error message
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade800),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
