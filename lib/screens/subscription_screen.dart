import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_feature.dart';
import '../services/auth_service.dart';
import '../services/revenue_cat_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final RevenueCatService revenueCatService;
  final bool isDarkMode;

  const SubscriptionScreen({
    required this.revenueCatService,
    required this.isDarkMode,
    super.key,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _loading = false;
  String? _error;
  bool _showAuthOptions = false;
  List<SubscriptionFeature> _features = [];
  bool _loadingFeatures = true;
  
  // Form controllers for login/register
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true; // toggle between login/register
  
  @override
  void initState() {
    super.initState();
    _loadFeatures();
  }
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  // Load subscription features from the database
  Future<void> _loadFeatures() async {
    try {
      setState(() => _loadingFeatures = true);
      
      // Check if Supabase is available
      if (!widget.revenueCatService.isSupabaseAvailable() || widget.revenueCatService.supabase == null) {
        // Use default features if Supabase is not available
        _setDefaultFeatures();
        return;
      }
      
      // Fetch features from database, ordered by priority (ascending)
      final response = await widget.revenueCatService.supabase!
          .from('subscription_features')
          .select()
          .eq('is_active', true)
          .order('priority', ascending: true);
      
      final List<SubscriptionFeature> features = (response as List)
          .map((feature) => SubscriptionFeature.fromJson(feature))
          .toList();
      
      // Debug print to see features from database
      print('Loaded ${features.length} features from database:');
      for (var feature in features) {
        print('Feature: ${feature.title}, Priority: ${feature.priority}');
      }
      
      // Make sure features are sorted by priority (ascending)
      features.sort((a, b) => a.priority.compareTo(b.priority));
      
      if (mounted) {
        setState(() {
          _features = features;
          _loadingFeatures = false;
        });
      }
    } catch (e) {
      print('Error loading subscription features: $e');
      // Fallback to default features
      _setDefaultFeatures();
    }
  }
  
  // Set default features if loading from database fails
  void _setDefaultFeatures() {
    // Debug print when falling back to default features
    print('Using default features, no database connection');
    setState(() {
      _features = [
        SubscriptionFeature(
          id: '1',
          title: 'Unlimited Profiles',
          description: 'Create and compare as many debt profiles as you need with no limits',
          iconName: 'collections_bookmark',
          priority: 1,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SubscriptionFeature(
          id: '2',
          title: 'Advanced Comparison',
          description: 'Compare different debt repayment strategies and see their long-term impact',
          iconName: 'analytics',
          priority: 2,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SubscriptionFeature(
          id: '3',
          title: 'Data Export',
          description: 'Export your debt data and reports in multiple formats',
          iconName: 'download',
          priority: 3,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SubscriptionFeature(
          id: '4',
          title: 'Cloud Sync',
          description: 'Sync your debt data across multiple devices by upgrading to Debt Visualizer Premium',
          iconName: 'sync',
          priority: 4,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        SubscriptionFeature(
          id: '5',
          title: 'Premium Education',
          description: 'Access exclusive financial education content and debt management strategies',
          iconName: 'school',
          priority: 5,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      
      // Make sure default features are sorted by priority (ascending)
      _features.sort((a, b) => a.priority.compareTo(b.priority));
      print('Default features sorted, count: ${_features.length}');
      for (var feature in _features) {
        print('Default Feature: ${feature.title}, Priority: ${feature.priority}');
      }
      
      _loadingFeatures = false;
    });
  }

  Future<void> _handleSubscription() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // First check if we have a valid Supabase instance to handle auth
      if (!widget.revenueCatService.isSupabaseAvailable()) {
        // Show login/register options instead of proceeding
        setState(() {
          _showAuthOptions = true;
          _loading = false;
        });
        return;
      }
      
      // Check if user is authenticated
      if (!widget.revenueCatService.isUserAuthenticated()) {
        // Show login/register options instead of proceeding
        setState(() {
          _showAuthOptions = true;
          _loading = false;
        });
        return;
      }
      
      // Get offering details
      final offeringDetails = await widget.revenueCatService.getPremiumOfferingDetails();
      
      if (offeringDetails == null) {
        throw Exception('Unable to load subscription details');
      }
      
      // Check if we're in development mode (no package available)
      if (offeringDetails['package'] == null) {
        // Development mode - create a simulated subscription
        print('DEVELOPMENT MODE: Using simulated subscription');
        
        // Show dialog to simulate purchase
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Development Mode'),
            content: const Text(
              'This is a simulated purchase since RevenueCat products are not yet configured. '
              'In production, users would be taken to the App Store purchase flow.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Simulate Purchase'),
              ),
            ],
          ),
        ) ?? false;
        
        if (shouldProceed && widget.revenueCatService.supabase != null) {
          try {
            // Create a mock subscription in the database
            final authService = AuthService(widget.revenueCatService.supabase!);
            await authService.createSubscription(paymentMethodId: 'development_mode_simulation');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Development mode: Subscription simulated successfully!')),
              );
              setState(() => _loading = false);
            }
            return;
          } catch (e) {
            throw Exception('Failed to simulate subscription: $e');
          }
        } else {
          // User cancelled simulated purchase
          setState(() => _loading = false);
          return;
        }
      }
      
      // User is authenticated, proceed with real subscription purchase
      final success = await widget.revenueCatService.purchasePackage(offeringDetails['package']);
      
      if (success) {
        // Purchase was successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription activated successfully!')),
          );
          setState(() => _loading = false);
        }
      } else {
        // Purchase failed or was cancelled
        setState(() {
          _error = 'Subscription purchase failed or was cancelled';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }
  
  // Handle login flow
  Future<void> _handleAuth() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        throw Exception('Please enter both email and password');
      }
      
      final success = await widget.revenueCatService.authenticateUser(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        isLogin: _isLogin,
      );
      
      if (success) {
        // User authenticated successfully
        setState(() {
          _showAuthOptions = false;
          _loading = false;
        });
        
        // Now attempt the subscription again
        await _handleSubscription();
      } else {
        // Authentication failed
        setState(() {
          _error = 'Authentication failed';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _handleRestoreSubscription() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Check if we're in development mode (no package available)
      final offeringDetails = await widget.revenueCatService.getPremiumOfferingDetails();
      if (offeringDetails == null || offeringDetails['package'] == null) {
        // Development mode - create a simulated subscription
        print('DEVELOPMENT MODE: Using simulated subscription restore');
        
        // Show dialog to simulate restore
        final shouldProceed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Development Mode'),
            content: const Text(
              'This is a simulated restore since RevenueCat products are not yet configured. '
              'In production, users would be taken to the App Store restore flow.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Simulate Restore'),
              ),
            ],
          ),
        ) ?? false;
        
        if (shouldProceed && widget.revenueCatService.supabase != null) {
          try {
            // Create a mock subscription in the database
            final authService = AuthService(widget.revenueCatService.supabase!);
            await authService.createSubscription(paymentMethodId: 'development_mode_simulation');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Development mode: Subscription restored successfully!')),
              );
              setState(() => _loading = false);
            }
            return;
          } catch (e) {
            throw Exception('Failed to simulate subscription restore: $e');
          }
        } else {
          // User cancelled simulated restore
          setState(() => _loading = false);
          return;
        }
      }
      
      // User is authenticated, proceed with real subscription restore
      final success = await widget.revenueCatService.restorePurchases();
      
      if (success) {
        // Restore was successful
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Subscription restored successfully!')),
          );
          setState(() => _loading = false);
        }
      } else {
        // Restore failed or was cancelled
        setState(() {
          _error = 'Subscription restore failed or was cancelled';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : Colors.white,
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: widget.isDarkMode
                ? [const Color(0xFF1A1A1A), const Color(0xFF121212)]
                : [Colors.white, const Color(0xFFF5F5F5)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium badge
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 30),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            CupertinoIcons.star_fill,
                            color: Colors.amber,
                            size: 30,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'DEBT VISUALIZER PREMIUM',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Feature section title
                  Text(
                    'Unlock Premium Features',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accelerate your debt freedom journey with advanced tools',
                    style: TextStyle(
                      fontSize: 16,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Features list
                  Text(
                    'Premium Features',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Show loading indicator while features are loading
                  if (_loadingFeatures) ...[  
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ] else if (_features.isEmpty) ...[  
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'No premium features available',
                          style: TextStyle(
                            fontSize: 16,
                            color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ),
                    ),
                  ] else ...[  
                    // Dynamic list of features from the database
                    for (int i = 0; i < _features.length; i++) ...[  
                      if (i > 0) const SizedBox(height: 16),
                      _buildFeatureRow(
                        icon: _features[i].icon,
                        title: _features[i].title,
                        description: _features[i].description,
                      ),
                    ],
                  ],
                  const SizedBox(height: 30),
                  
                  // Pricing card
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: widget.isDarkMode
                            ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                            : [const Color(0xFF9C27B0), const Color(0xFFAB47BC)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.purple.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            FutureBuilder<Map<String, dynamic>?>(
                              future: widget.revenueCatService.getPremiumOfferingDetails(),
                              builder: (context, snapshot) {
                                String priceText = '\$1.99';
                                if (snapshot.hasData && snapshot.data != null && snapshot.data!['price'] != null) {
                                  priceText = snapshot.data!['price'];
                                }
                                return Text(
                                  priceText,
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              '/month',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Cancel anytime. Pricing in USD.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 50,
                          child: _loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(25),
                                  onPressed: _handleSubscription,
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        CupertinoIcons.arrow_right_circle_fill,
                                        color: Color(0xFF9C27B0),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Subscribe Now',
                                        style: TextStyle(
                                          color: Color(0xFF9C27B0),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Restore purchases button
                  Center(
                    child: TextButton(
                      onPressed: !_loading ? _handleRestoreSubscription : null,
                      child: Text(
                        'Restore Purchases',
                        style: TextStyle(
                          color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                  
                  // Show auth panel when required
                  if (_showAuthOptions) ...[                  
                    const SizedBox(height: 30),
                    Container(
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.9),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isLogin ? 'Sign In' : 'Create Account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: widget.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Premium features require an account',
                            style: TextStyle(
                              fontSize: 14,
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Email field
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
                          // Password field
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
                          // Submit button
                          SizedBox(
                            height: 50,
                            child: _loading
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : CupertinoButton(
                                    padding: EdgeInsets.zero,
                                    color: const Color(0xFF9C27B0),
                                    borderRadius: BorderRadius.circular(10),
                                    onPressed: _handleAuth,
                                    child: Text(
                                      _isLogin ? 'Login' : 'Register',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          // Toggle login/register
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin
                                  ? 'Don\'t have an account? Register'
                                  : 'Already have an account? Sign in',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white70 : const Color(0xFF9C27B0),
                              ),
                            ),
                          ),
                          // Cancel button
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _showAuthOptions = false;
                              });
                            },
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white54 : Colors.black45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.red),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                  Center(
                    child: Text(
                      'You can cancel anytime through ${Platform.isIOS ? "App Store" : "Play Store"} settings.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.white54 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.isDarkMode
                  ? [const Color(0xFF4A148C), const Color(0xFF7B1FA2)]
                  : [const Color(0xFF9C27B0), const Color(0xFFAB47BC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.purple.withOpacity(0.2),
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
