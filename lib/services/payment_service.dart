import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  static const _monthlySubId = Platform.isIOS 
      ? 'debt_visualizer_premium_monthly_ios'  // iOS product ID
      : 'debt_visualizer_premium_monthly';     // Android product ID

  final SupabaseClient _supabase;
  final InAppPurchase _iap;
  bool _isAvailable = false;

  PaymentService(this._supabase) : _iap = InAppPurchase.instance {
    _initialize();
  }

  Future<void> _initialize() async {
    _isAvailable = await _iap.isAvailable();
    
    if (_isAvailable) {
      // Listen to purchase updates
      _iap.purchaseStream.listen(_handlePurchaseUpdate);

      // Load product details
      final ProductDetailsResponse response = await _iap.queryProductDetails({_monthlySubId});
      if (response.notFoundIDs.isNotEmpty) {
        throw Exception('Product not found: ${response.notFoundIDs}');
      }
    }
  }

  Future<void> startSubscription() async {
    if (!_isAvailable) {
      throw Exception('In-app purchases not available');
    }

    // Get product details
    final ProductDetailsResponse response = 
        await _iap.queryProductDetails({_monthlySubId});

    if (response.productDetails.isEmpty) {
      throw Exception('Product not found');
    }

    // Create purchase
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: response.productDetails.first,
    );

    // Start subscription purchase flow
    await _iap.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> _handlePurchaseUpdate(List<PurchaseDetails> purchaseDetails) async {
    for (final purchase in purchaseDetails) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Verify with backend
        await _verifyPurchase(purchase);
        
        // Complete transaction
        if (Platform.isIOS) {
          await _iap.completePurchase(purchase);
        }
      }

      if (purchase.status == PurchaseStatus.error) {
        // Handle error
        throw Exception('Purchase error: ${purchase.error?.message}');
      }
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Call the database function to verify purchase
    final response = await _supabase
        .rpc('verify_purchase', params: {
          'p_user_id': user.id,
          'p_purchase_id': purchase.purchaseID,
          'p_product_id': purchase.productID,
          'p_platform': Platform.isIOS ? 'ios' : 'android',
          'p_receipt': Platform.isIOS 
              ? purchase.verificationData.serverVerificationData
              : purchase.verificationData.localVerificationData,
        });

    if (response.error != null) {
      throw Exception('Failed to verify purchase: ${response.error!.message}');
    }
  }

  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  Future<void> cancelSubscription() async {
    // Note: Users must cancel subscriptions through App Store/Play Store
    throw Exception(
      'Please cancel your subscription through the ${Platform.isIOS ? "App Store" : "Play Store"}',
    );
  }

  bool get isAvailable => _isAvailable;
}
