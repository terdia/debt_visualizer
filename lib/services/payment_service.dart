import 'dart:async';
import 'dart:io' show Platform;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class PaymentService {
  final InAppPurchase _iap = InAppPurchase.instance;
  // iOS product IDs
  final Set<String> _iosProductIds = {
    'debt_visualizer_premium_monthly',           // Standard format
    'debt_visualizer_premium_monthly_ios',       // iOS specific format
    'debt.visualizer.premium.monthly',           // Dot format sometimes used
    'debt_visualizer_premium',                   // Shorter version
  };
  
  // Android product IDs
  final Set<String> _androidProductIds = {
    'debt_visualizer_premium_monthly_android',   // Android specific format
    'debt.visualizer.premium.monthly.android',   // Android dot format
    'debt_visualizer_premium_monthly',           // Standard format might also work
    'debt_visualizer_premium',                   // Shorter version
  };
  
  // Get the appropriate product IDs for the current platform
  Set<String> get _platformProductIds => 
      Platform.isIOS ? _iosProductIds : _androidProductIds;
  final SupabaseClient? _supabase;
  AuthService? _authService;

  bool _isAvailable = false;
  List<ProductDetails> _products = [];
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final _purchaseController = StreamController<PurchaseDetails>.broadcast();

  PaymentService(this._supabase) {
    _initialize();
  }
  
  void dispose() {
    _subscription?.cancel();
    _purchaseController.close();
  }

  Future<void> _initialize() async {
    try {
      _isAvailable = await _iap.isAvailable();
      
      if (_isAvailable) {
        // Listen to purchase updates
        _subscription = _iap.purchaseStream.listen(_handlePurchaseUpdate);

        // Load product details
        await _loadProducts();
      } else {
        print('In-app purchases not available on this device');
      }
    } catch (e) {
      print('Error initializing payment service: $e');
      _isAvailable = false;
    }
  }
  
  Future<void> _loadProducts() async {
    try {
      // Query for platform-specific product IDs
      print('Querying for ${Platform.isIOS ? "iOS" : "Android"} products: $_platformProductIds');
      final ProductDetailsResponse response = 
          await _iap.queryProductDetails(_platformProductIds);
          
      if (response.notFoundIDs.isNotEmpty) {
        print('Product not found: ${response.notFoundIDs}');
      }
      
      _products = response.productDetails;
      print('Loaded ${_products.length} products:');
      for (var product in _products) {
        print('- ${product.id}: ${product.title} (${product.price})');
      }
    } catch (e) {
      print('Error loading products: $e');
      _products = [];
    }
  }

  /// Start a subscription purchase flow for the monthly subscription
  /// Throws exceptions if products are not available or if purchase fails
  Future<void> purchaseSubscription() async {
    if (!_isAvailable) {
      throw Exception('In-app purchases not available');
    }

    // Ensure products are loaded
    if (_products.isEmpty) {
      await _loadProducts();
      if (_products.isEmpty) {
        throw Exception('Subscription products not found. Please make sure you have created the subscription products in App Store Connect and Play Console.');
      }
    }

    // Find the first available subscription product
    // Since we're trying multiple IDs, we'll take the first one that works
    if (_products.isEmpty) {
      throw Exception('No subscription products available');
    }
    
    // Use the first available product
    final product = _products.first;
    print('Using subscription product: ${product.id} (${product.title})');

    // Create purchase
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
    );

    // Start subscription purchase flow
    print('Starting subscription purchase for ${product.title}');
    // For subscriptions in this version of the package, we use buyNonConsumable
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  void _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      try {
        if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          _verifyPurchase(purchaseDetails);
        } else if (purchaseDetails.status == PurchaseStatus.error) {
          print('Purchase error: ${purchaseDetails.error?.message}');
          // Handle error - this could display an error message to the user
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          print('Purchase canceled by user');
        }

        // Complete transaction
        if (purchaseDetails.pendingCompletePurchase) {
          _iap.completePurchase(purchaseDetails);
        }
      } catch (e) {
        print('Error handling purchase update: $e');
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchaseDetails) async {
    if (_supabase == null) {
      print('Supabase client is null, cannot verify purchase');
      return;
    }

    // Get current user
    final user = _supabase!.auth.currentUser;
    if (user == null) {
      print('User is not authenticated, cannot verify purchase');
      return;
    }

    try {
      // Call Supabase Edge Function to verify the purchase
      final response = await _supabase!.functions.invoke(
        'verify-purchase',
        body: {
          'receipt': purchaseDetails.verificationData.serverVerificationData,
          'productId': purchaseDetails.productID,
          'platform': purchaseDetails.verificationData.source,
        },
      );

      if (response.status != 200) {
        print('Purchase verification failed: ${response.data}');
        throw Exception('Purchase verification failed');
      }

      print('Purchase verified successfully: ${response.data}');
      
      // Update auth service subscription status
      final authService = _getAuthService();
      await authService.createSubscription(paymentMethodId: 'iap_${purchaseDetails.productID}');
      
    } catch (e) {
      print('Error verifying purchase: $e');
      throw Exception('Error verifying purchase: $e');
    }
  }

  /// Restore previous purchases
  /// This lets users recover their purchases if they reinstall the app
  Future<void> restorePurchases() async {
    if (!_isAvailable) {
      throw Exception('In-app purchases not available');
    }
    
    print('Restoring purchases...');
    await _iap.restorePurchases();
  }

  Future<void> cancelSubscription() async {
    // Note: Users must cancel subscriptions through App Store/Play Store
    throw Exception(
      'Please cancel your subscription through the App Store or Play Store',
    );
  }

  /// Check if in-app purchases are available on this device
  bool get isAvailable => _isAvailable;
  
  /// Get the list of available products
  List<ProductDetails> get products => _products;
  
  /// Get the premium subscription product
  ProductDetails? get subscriptionProduct => 
      _products.isEmpty ? null : _products.first; // Just use the first product we found
      
  /// Check if any subscription product is available
  bool hasSubscriptionProduct() => _products.isNotEmpty;
  
  /// Get the Supabase client
  SupabaseClient? get supabase => _supabase;
  
  /// Check if Supabase client is available
  bool isSupabaseAvailable() {
    return _supabase != null;
  }
  
  /// Check if the user is authenticated
  bool isUserAuthenticated() {
    if (_supabase == null) return false;
    return _supabase!.auth.currentUser != null;
  }
  
  /// Get or create the auth service
  AuthService _getAuthService() {
    if (_authService == null) {
      // Make sure we never pass null to AuthService
      if (_supabase == null) {
        throw Exception('Supabase client is null, cannot create AuthService');
      }
      _authService = AuthService(_supabase!);
    }
    return _authService!;
  }
  
  /// Authenticate user (login or register)
  Future<bool> authenticateUser({
    required String email,
    required String password,
    required bool isLogin,
  }) async {
    if (_supabase == null) {
      throw Exception('Supabase client not available');
    }
    
    try {
      final authService = _getAuthService();
      
      if (isLogin) {
        final response = await authService.signIn(
          email: email,
          password: password,
        );
        return response != null;
      } else {
        // Register new user
        final response = await authService.signUp(
          email: email,
          password: password,
        );
        return response != null;
      }
    } catch (e) {
      print('Authentication error: $e');
      return false;
    }
  }
}
