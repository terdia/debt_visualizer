import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../config/constants.dart';

class RevenueCatService {
  // RevenueCat API keys are loaded from AppConfig
  
  // RevenueCat identifiers
  static const String _entitlementID = 'premium';
  static const String _iosEntitlementID = 'entl9d99c0388e';
  static const String _androidEntitlementID = 'prod98baddc6ac';
  
  // RevenueCat offering identifiers
  static const String _defaultOfferingId = 'default';
  
  // Product IDs are loaded from AppConfig
  late String _monthlyProductId;
  late String _entitlementIdentifier;
  
  final SupabaseClient? _supabase;
  AuthService? _authService;
  
  // For tracking subscription status
  bool _isSubscriptionActive = false;
  
  RevenueCatService(this._supabase) {
    _initialize();
  }
  
  Future<void> _initialize() async {
    try {
      // Configure RevenueCat SDK with your API key
      await Purchases.setLogLevel(LogLevel.debug); // Use debug logging to troubleshoot
      
      // Get the AppConfig singleton
      final config = AppConfig();
      
      // Use the appropriate API key for the platform
      final apiKey = Platform.isIOS 
          ? config.revenueCatIosApiKey 
          : config.revenueCatAndroidApiKey;
      
      print('RevenueCat API Key: ${apiKey.isNotEmpty ? "[Set]" : "[Not Set]"}');
      
      // Set the product ID based on platform
      _monthlyProductId = Platform.isIOS
          ? config.iosSubscriptionId
          : config.androidSubscriptionId;
      
      print('Using ${Platform.isIOS ? "iOS" : "Android"} product ID: $_monthlyProductId');
      
      // Set the entitlement ID based on platform
      _entitlementIdentifier = Platform.isIOS
          ? _iosEntitlementID
          : _androidEntitlementID;
      
      print('Using entitlement ID: $_entitlementIdentifier');
      
      // Verify configuration
      if (!config.isRevenueCatConfigured) {
        print('WARNING: RevenueCat API keys not configured properly!');
      }
      
      // Configure RevenueCat
      await Purchases.configure(PurchasesConfiguration(apiKey));
      print('RevenueCat configured successfully');
      
      // Set up listener for customer info updates
      Purchases.addCustomerInfoUpdateListener((info) {
        print('Customer info updated: ${info.activeSubscriptions.length} active subscriptions');
        // Update subscription status when changes occur
        _updateSubscriptionStatusFromCustomerInfo(info);
      });
      
      // If user is logged in, identify them with RevenueCat
      if (_supabase != null && _supabase!.auth.currentUser != null) {
        await Purchases.logIn(_supabase!.auth.currentUser!.id);
        print('User identified with RevenueCat: ${_supabase!.auth.currentUser!.id}');
      } else {
        print('No user logged in, using anonymous user');
      }
      
      // Check subscription status
      await _checkSubscriptionStatus();
    } catch (e) {
      print('ERROR initializing RevenueCat: $e');
    }
  }

  /// Check if user has active subscription
  Future<bool> hasActiveSubscription() async {
    await _checkSubscriptionStatus();
    return _isSubscriptionActive;
  }
  
  /// Get available packages (subscription options)
  Future<List<Package>> getPackages() async {
    try {
      print('Attempting to get packages from RevenueCat...');
      
      // Get offerings from RevenueCat using the specific offering approach
      final offerings = await Purchases.getOfferings();
      
      // Try to get the "default" offering first (as seen in your RevenueCat dashboard)
      final defaultOffering = offerings.getOffering(_defaultOfferingId);
      
      if (defaultOffering != null && defaultOffering.availablePackages.isNotEmpty) {
        print('Successfully retrieved ${defaultOffering.availablePackages.length} package(s) from "$_defaultOfferingId" offering');
        for (var package in defaultOffering.availablePackages) {
          print('Package: ${package.identifier}, Product: ${package.storeProduct.identifier}, Price: ${package.storeProduct.priceString}');
        }
        return defaultOffering.availablePackages;
      }
      
      // Fall back to current offering if default offering is not available
      if (offerings.current != null) {
        print('Using current offering as fallback');
        return offerings.current!.availablePackages;
      }
      
      print('ERROR: No offerings available from RevenueCat');
      return [];
    } on PlatformException catch (e) {
      print('PLATFORM EXCEPTION getting packages from RevenueCat: ${e.message}, code: ${e.code}');
      return [];
    } catch (e) {
      print('ERROR getting packages from RevenueCat: $e');
      return [];
    }
  }

  /// Get offerings with placement identifier
  /// This method is kept for API compatibility but uses getOfferingByIdentifier internally
  /// as the Flutter SDK doesn't have a direct placement API
  Future<Offering?> getOfferingForPlacement(String placementId) async {
    // In the Flutter SDK, we don't have a direct method for placements
    // Use the current offering or fall back to getting a specific offering
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current;
    } catch (e) {
      return null;
    }
  }
  
  /// Get offering by custom identifier
  /// This allows access to offerings besides the current offering
  Future<Offering?> getOfferingByIdentifier(String identifier) async {
    try {
      final offerings = await Purchases.getOfferings();
      
      final offering = offerings.getOffering(identifier);
      
      return offering;
    } catch (e) {
      print('ERROR getting offering by identifier: $e');
      return null;
    }
  }
  
  /// Get monthly package from the current offering
  /// This uses the direct monthly property from RevenueCat
  /// Following the exact pattern from the documentation
  Future<Package?> getCurrentMonthlyPackage() async {
    try {
      final offerings = await Purchases.getOfferings();
      
      if (offerings.current != null && offerings.current!.monthly != null) {
        final monthlyPackage = offerings.current!.monthly!;
        print('Found monthly package from current offering: ${monthlyPackage.storeProduct.identifier}');
        return monthlyPackage;
      }
      
      print('No monthly package found in current offering');
      return null;
    } on PlatformException catch (e) {
      print('PLATFORM EXCEPTION getting monthly package: ${e.message}, code: ${e.code}');
      return null;
    } catch (e) {
      print('ERROR getting monthly package: $e');
      return null;
    }
  }
  
  /// Get monthly package from a specific offering
  /// This uses the direct monthly property from RevenueCat
  Future<Package?> getMonthlyPackage(String offeringIdentifier) async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(offeringIdentifier);
      
      if (offering == null) {
        print('No offering found with identifier: $offeringIdentifier');
        return null;
      }
      
      // Access the monthly package directly using the property
      final monthlyPackage = offering.monthly;
      
      if (monthlyPackage == null) {
        print('No monthly package found in offering: $offeringIdentifier');
        return null;
      }
      
      print('Found monthly package: ${monthlyPackage.storeProduct.identifier}');
      return monthlyPackage;
    } catch (e) {
      print('ERROR getting monthly package: $e');
      return null;
    }
  }
  
  /// Get a specific package by ID from an offering
  Future<Package?> getPackageById(String offeringIdentifier, String packageId) async {
    try {
      final offerings = await Purchases.getOfferings();
      final offering = offerings.getOffering(offeringIdentifier);
      
      if (offering == null) {
        print('No offering found with identifier: $offeringIdentifier');
        return null;
      }
      
      // Get a specific package by ID
      final package = offering.getPackage(packageId);
      
      if (package == null) {
        print('No package found with ID $packageId in offering: $offeringIdentifier');
        return null;
      }
      
      print('Found package with ID $packageId: ${package.storeProduct.identifier}');
      return package;
    } catch (e) {
      print('ERROR getting package by ID: $e');
      return null;
    }
  }
  
  /// Helper method to update subscription status from CustomerInfo
  void _updateSubscriptionStatusFromCustomerInfo(CustomerInfo customerInfo) {
    try {
      // Check if the premium entitlement is active
      _isSubscriptionActive = customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
    } catch (e) {
      _isSubscriptionActive = false;
    }
  }
  
  /// Purchase a subscription package
  Future<bool> purchasePackage(Package package) async {
    try {
      // First, ensure the user is authenticated if Supabase is available
      if (_supabase != null && _supabase!.auth.currentUser == null) {
        print('User must be logged in to purchase');
        return false;
      }
      
      // Make the purchase
      final purchaseResult = await Purchases.purchasePackage(package);
      
      // The new API returns CustomerInfo, which we need to check for entitlements
      final CustomerInfo customerInfo = purchaseResult;
      
      // Check if the purchase includes premium entitlement
      final isPremium = customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
      
      if (isPremium) {
        // Update Supabase subscription status
        if (_supabase != null && _supabase!.auth.currentUser != null) {
          await _updateSupabaseSubscription(true);
        }
        
        _isSubscriptionActive = true;
      }
      
      return isPremium;
    } catch (e) {
      if (e is PlatformException) {
        // Handle specific error codes
        final error = e as PlatformException;
        print('Purchase error: ${error.code} - ${error.message}');
        if (error.code == 'purchase_cancelled') {
          print('User cancelled purchase');
        }
      } else {
        print('Error purchasing package: $e');
      }
      return false;
    }
  }
  
  /// Restore purchases
  Future<bool> restorePurchases() async {
    try {
      // Restore purchases from App Store/Google Play
      final CustomerInfo customerInfo = await Purchases.restorePurchases();
      
      // Check if restored purchases include premium entitlement
      final isPremium = customerInfo.entitlements.all[_entitlementID]?.isActive ?? false;
      
      if (isPremium && _supabase != null && _supabase!.auth.currentUser != null) {
        // Update Supabase subscription status
        await _updateSupabaseSubscription(true);
      }
      
      _isSubscriptionActive = isPremium;
      return isPremium;
    } catch (e) {
      print('Error restoring purchases: $e');
      return false;
    }
  }
  
  /// Check current subscription status
  Future<void> _checkSubscriptionStatus() async {
    try {
      print('Checking subscription status...');
      // Get latest customer info
      final customerInfo = await Purchases.getCustomerInfo();
      print('Customer info retrieved. Active entitlements: ${customerInfo.entitlements.active.length}');
      print('Active subscriptions: ${customerInfo.activeSubscriptions.length}');
      _updateSubscriptionStatusFromCustomerInfo(customerInfo);
      print('Subscription active: $_isSubscriptionActive');
    } catch (e) {
      print('Error checking subscription status: $e');
      _isSubscriptionActive = false;
    }
  }
  
  /// Update subscription status in Supabase
  Future<void> _updateSupabaseSubscription(bool isActive) async {
    try {
      if (_supabase == null || _supabase!.auth.currentUser == null) return;
      
      // Get or create auth service
      final authService = _getAuthService();
      
      if (isActive) {
        // Create subscription record
        await authService.createSubscription(
          paymentMethodId: 'revenuecat_${Platform.isIOS ? 'ios' : 'android'}',
        );
      } else {
        // Cancel subscription (though this would typically happen through App Store/Play Store)
        // This is just to update our database
        await authService.cancelSubscription();
      }
    } catch (e) {
      print('Error updating Supabase subscription: $e');
    }
  }
  
  /// Get or create auth service
  AuthService _getAuthService() {
    if (_authService == null) {
      if (_supabase == null) {
        throw Exception('Supabase client is null, cannot create AuthService');
      }
      _authService = AuthService(_supabase!);
    }
    return _authService!;
  }
  
  /// Check if Supabase client is available
  bool isSupabaseAvailable() {
    return _supabase != null;
  }
  
  /// Check if user is authenticated
  bool isUserAuthenticated() {
    if (_supabase == null) return false;
    return _supabase!.auth.currentUser != null;
  }
  
  /// Get the Supabase client
  SupabaseClient? get supabase => _supabase;
  
  /// Sign in user with RevenueCat
  Future<void> identifyUser(String userId) async {
    try {
      await Purchases.logIn(userId);
    } catch (e) {
      print('Error identifying user with RevenueCat: $e');
    }
  }
  
  /// Sign out user from RevenueCat
  Future<void> signOut() async {
    try {
      await Purchases.logOut();
    } catch (e) {
      print('Error signing out from RevenueCat: $e');
    }
  }
  
  /// Authenticate user (login or register)
  Future<bool> authenticateUser({
    required String email,
    required String password,
    required bool isLogin,
  }) async {
    try {
      if (_supabase == null) {
        throw Exception('Supabase client is null, cannot authenticate');
      }
      
      final authService = _getAuthService();
      
      if (isLogin) {
        // Login
        final authResponse = await authService.signIn(email: email, password: password);
        if (authResponse.user != null) {
          // Identify user with RevenueCat
          await identifyUser(authResponse.user!.id);
          return true;
        }
      } else {
        // Register
        final authResponse = await authService.signUp(email: email, password: password);
        if (authResponse.user != null) {
          // Identify user with RevenueCat
          await identifyUser(authResponse.user!.id);
          return true;
        }
      }
      
      return false;
    } catch (e) {
      print('Error authenticating user: $e');
      return false;
    }
  }
  
  /// Get available offerings following RevenueCat documentation
  /// Reference: https://www.revenuecat.com/docs/getting-started/displaying-products
  Future<Offerings?> getOfferings() async {
    try {
      // Directly call Purchases.getOfferings() as shown in the docs
      final offerings = await Purchases.getOfferings();
      
      // Log results for debugging
      if (offerings.current != null && offerings.current!.availablePackages.isNotEmpty) {
        print('Current offering: ${offerings.current!.identifier}');
        print('Available packages: ${offerings.current!.availablePackages.length}');
      } else {
        print('No current offering available');
      }
      
      return offerings;
    } on PlatformException catch (e) {
      print('PLATFORM EXCEPTION getting offerings: ${e.message}, code: ${e.code}');
      return null;
    } catch (e) {
      print('ERROR getting offerings: $e');
      return null;
    }
  }
  
  /// Get all packages from the current offering
  Future<List<Package>> getCurrentPackages() async {
    try {
      final offerings = await Purchases.getOfferings();
      if (offerings.current == null) {
        return [];
      }
      return offerings.current!.availablePackages;
    } catch (e) {
      print('ERROR getting current packages: $e');
      return [];
    }
  }
  

  /// Get premium offering description (for display in UI)
  /// Following RevenueCat best practices for dynamic paywalls
  Future<Map<String, dynamic>?> getPremiumOfferingDetails() async {
    try {
      // Following the documentation approach
      final offerings = await Purchases.getOfferings();
      
      // Try to get current offering's monthly package
      if (offerings.current != null) {
        Package? targetPackage;
        String title;
        String description;
        
        // Use offering server description as title if available
        title = offerings.current!.serverDescription ?? 'Premium Subscription';
        
        // Check for monthly package first (per docs)
        if (offerings.current!.monthly != null) {
          targetPackage = offerings.current!.monthly;
          print('Using monthly package from current offering');
        } 
        // Otherwise, get first available package
        else if (offerings.current!.availablePackages.isNotEmpty) {
          targetPackage = offerings.current!.availablePackages.first;
          print('Using first available package from current offering');
        }
        
        if (targetPackage != null) {
          final product = targetPackage.storeProduct;
          
          // Use product description if available, otherwise use default
          description = product.description.isNotEmpty ? 
              product.description : 'Unlock all premium features';
          
          print('Package: ${product.identifier}, Price: ${product.priceString}');
          print('Title: $title, Description: $description');
          
          // Create dynamic offering details
          return {
            'title': title,
            'price': product.priceString,
            'description': description,
            'package': targetPackage,
            // Additional data that might be useful
            'productIdentifier': product.identifier,
            'offeringIdentifier': offerings.current!.identifier,
          };
        }
      }
      
      print('No valid offering packages available');
      return null;
    } on PlatformException catch (e) {
      print('PLATFORM EXCEPTION getting premium offering details: ${e.message}, code: ${e.code}');
      return null;
    } catch (e) {
      print('ERROR getting premium offering details: $e');
      return null;
    }
  }
  
  /// Check if user has a specific entitlement
  Future<bool> hasEntitlement(String entitlementId) async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.entitlements.active.containsKey(entitlementId);
    } catch (e) {
      return false;
    }
  }
}
