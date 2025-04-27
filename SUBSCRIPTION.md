# Debt Visualizer App Monetization Implementation Guide

This document outlines the step-by-step process for implementing in-app subscriptions in the Debt Visualizer app.

## 1. Register Product IDs in App Store Connect and Google Play Console

### Apple App Store:
✅ **Completed**: Subscription "debt_visualizer_premium_monthly_ios" has been created

Steps to create an Apple subscription:
1. **Log in to App Store Connect**: https://appstoreconnect.apple.com
2. **Navigate to Your App**: Select your app from the "My Apps" section
3. **Go to In-App Purchases**: In the left sidebar, click on "Features" → "In-App Purchases"
4. **Create New IAP**:
   - Click the "+" button to create a new in-app purchase
   - Select "Auto-Renewable Subscription"
   - Enter "debt_visualizer_premium_monthly_ios" as the Reference Name (matching the ID in your code)
   - Create a subscription group (e.g., "debt_visualizer_premium")
   - Set pricing, duration (monthly), and localization details
   - Add description and marketing materials
5. **Create Subscription Tiers**: Add any additional tiers (e.g., yearly subscription)
6. **Submit for Review**: Save changes and submit for review along with your app

### Google Play Console:
1. **Log in to Google Play Console**: https://play.google.com/console
2. **Navigate to Your App**: Select your app from the dashboard
3. **Go to Monetization Setup**: In the left sidebar, click on "Monetize" → "Products" → "Subscriptions"
4. **Create Subscription**: 
   - Click "Create Subscription"
   - Enter "debt_visualizer_premium_monthly" as the Product ID (matching the ID in your code)
   - Set the name, description, pricing, and billing period (monthly)
   - Configure any free trial periods or introductory pricing
5. **Create Additional Tiers**: Add any other subscription options (e.g., yearly)
6. **Activate Subscriptions**: Ensure subscriptions are set to "Active" status
7. **Set Up Testing**: Configure test accounts for development testing

## 2. Implement Purchase Flow UI in the App

### Create a Subscription Screen:
```dart
// lib/screens/subscription_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/payment_service.dart';

class SubscriptionScreen extends StatefulWidget {
  final bool isDarkMode;

  const SubscriptionScreen({
    super.key,
    required this.isDarkMode,
  });

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  bool _isLoading = false;
  String _statusMessage = '';
  final PaymentService _paymentService = PaymentService(/* inject Supabase client */);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Subscription'),
        backgroundColor: widget.isDarkMode ? Colors.black : Colors.white,
        foregroundColor: widget.isDarkMode ? Colors.white : Colors.black,
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
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(
                  color: const Color(0xFF9C27B0),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Premium Features Card
                    Card(
                      margin: const EdgeInsets.all(20),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Premium Features',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildFeatureItem('Unlimited debt profiles'),
                            _buildFeatureItem('Advanced debt comparison tools'),
                            _buildFeatureItem('Export and backup data'),
                            _buildFeatureItem('Advanced debt payoff strategies'),
                            _buildFeatureItem('Premium educational content'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    
                    // Subscribe Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 15,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      onPressed: _subscribe,
                      child: const Text(
                        'Subscribe for \$4.99/month',
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _restorePurchases,
                      child: const Text('Restore Purchases'),
                    ),
                    if (_statusMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text(
                          _statusMessage,
                          style: TextStyle(
                            color: _statusMessage.contains('Error')
                                ? Colors.red
                                : Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFF9C27B0)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await _paymentService.purchaseSubscription();
      setState(() {
        _statusMessage = 'Subscription successful!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
      _statusMessage = '';
    });

    try {
      await _paymentService.restorePurchases();
      setState(() {
        _statusMessage = 'Purchases restored!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
```

### Update Navigation to Include Subscription Screen:
Add a way to navigate to the subscription screen from the app (e.g., from profile settings or as a prompt when accessing premium features).

## 3. Complete the Receipt Verification in Supabase Backend

### Update Supabase Functions:

1. **Create a Purchase Verification Function**:
This function will verify purchase receipts with Apple/Google and update the user's subscription status.

```sql
-- In your Supabase migrations
CREATE OR REPLACE FUNCTION verify_purchase(
  user_id UUID,
  receipt TEXT,
  is_ios BOOLEAN
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  subscription_id UUID;
  expiry_date TIMESTAMP;
  verification_result JSONB;
  is_valid BOOLEAN;
BEGIN
  -- In production, you would call the appropriate verification API here
  -- For Apple: https://buy.itunes.apple.com/verifyReceipt
  -- For Google: https://developers.google.com/android-publisher/api-ref/rest/v3/purchases.subscriptions/get
  
  -- Simplified example (replace with actual API calls)
  IF is_ios THEN
    -- Simulate Apple verification
    verification_result := '{
      "status": 0,
      "receipt": {
        "in_app": [{
          "product_id": "debt_visualizer_premium_monthly_ios",
          "expires_date_ms": ' || (EXTRACT(EPOCH FROM NOW() + INTERVAL '1 month') * 1000) || '
        }]
      }
    }'::JSONB;
  ELSE
    -- Simulate Google verification
    verification_result := '{
      "kind": "androidpublisher#subscriptionPurchase",
      "paymentState": 1,
      "expiryTimeMillis": ' || (EXTRACT(EPOCH FROM NOW() + INTERVAL '1 month') * 1000) || '
    }'::JSONB;
  END IF;

  -- Parse the verification result
  is_valid := verification_result->>'status' = '0' OR verification_result->>'paymentState' = '1';
  
  IF is_valid THEN
    -- Extract expiry date
    IF is_ios THEN
      expiry_date := to_timestamp((verification_result->'receipt'->'in_app'->0->>'expires_date_ms')::bigint/1000);
    ELSE
      expiry_date := to_timestamp((verification_result->>'expiryTimeMillis')::bigint/1000);
    END IF;
    
    -- Update or insert the subscription
    INSERT INTO subscriptions (user_id, product_id, receipt_data, expiry_date, platform)
    VALUES (
      user_id,
      CASE WHEN is_ios THEN 'debt_visualizer_premium_monthly_ios' ELSE 'debt_visualizer_premium_monthly' END,
      receipt,
      expiry_date,
      CASE WHEN is_ios THEN 'ios' ELSE 'android' END
    )
    ON CONFLICT (user_id)
    DO UPDATE SET
      receipt_data = EXCLUDED.receipt_data,
      expiry_date = EXCLUDED.expiry_date,
      updated_at = NOW();
    
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$;
```

2. **Create a Function to Check Subscription Status**:

```sql
CREATE OR REPLACE FUNCTION has_active_subscription(user_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  sub_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1 FROM subscriptions
    WHERE subscriptions.user_id = $1
    AND expiry_date > NOW()
  ) INTO sub_exists;
  
  RETURN sub_exists;
END;
$$;
```

### Update Your AuthService to Check Subscription Status:

```dart
class AuthService {
  final SupabaseClient _supabase;
  
  AuthService(this._supabase);
  
  User? get currentUser => _supabase.auth.currentUser;
  
  Future<bool> hasActiveSubscription() async {
    if (currentUser == null) return false;
    
    try {
      final response = await _supabase
          .rpc('has_active_subscription', params: {
            'user_id': currentUser!.id,
          });
          
      return response as bool;
    } catch (e) {
      print('Error checking subscription: $e');
      return false;
    }
  }
}
```

## 4. Add Subscription Status Checks Throughout App Features

### Create a Subscription Check Wrapper Widget:

```dart
// lib/widgets/premium_feature_wrapper.dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class PremiumFeatureWrapper extends StatelessWidget {
  final Widget child;
  final Widget fallbackWidget;
  final AuthService authService;

  const PremiumFeatureWrapper({
    required this.child,
    required this.fallbackWidget,
    required this.authService,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: authService.hasActiveSubscription(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final hasSubscription = snapshot.data ?? false;
        if (hasSubscription) {
          return child;
        } else {
          return fallbackWidget;
        }
      },
    );
  }
}
```

### Use the Wrapper Around Premium Features:

```dart
// Example implementation in a screen
PremiumFeatureWrapper(
  authService: authService,
  fallbackWidget: SubscriptionPromptWidget(
    onSubscribe: () => Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubscriptionScreen(isDarkMode: isDarkMode),
      ),
    ),
  ),
  child: AdvancedComparisonWidget(profile: profile),
),
```

### Create a Subscription Prompt Widget:

```dart
// lib/widgets/subscription_prompt_widget.dart
import 'package:flutter/material.dart';

class SubscriptionPromptWidget extends StatelessWidget {
  final VoidCallback onSubscribe;

  const SubscriptionPromptWidget({
    required this.onSubscribe,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFF4A148C), Color(0xFF7B1FA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock,
            color: Colors.white,
            size: 48,
          ),
          const SizedBox(height: 16),
          const Text(
            'Premium Feature',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This feature is available with a premium subscription.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSubscribe,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF7B1FA2),
              padding: const EdgeInsets.symmetric(
                horizontal: 32,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text('Subscribe Now'),
          ),
        ],
      ),
    );
  }
}
```

## 5. Test the Implementation

### Testing In-App Purchases:

1. **Apple TestFlight**:
   - Add test users in App Store Connect
   - Use sandbox environment for testing
   - Check receipts are correctly validated

2. **Google Play Testing**:
   - Set up a closed testing track
   - Add test accounts
   - Use Google's test environment

### Debugging Tips:

- Check receipts being sent to and from Supabase
- Verify subscription status updates in the database
- Test purchase flow with test accounts before live deployment
- Monitor subscription lifecycle events (renewal, cancellation)

## 6. Production Deployment Checklist

1. **Fully test** all in-app purchase flows with test accounts
2. **Update privacy policy** to include information about subscriptions
3. **Include subscription terms** in the app (renewal, cancellation policy)
4. **Implement** a way for users to manage subscriptions
5. **Test receipt validation** with production endpoints
6. **Deploy** updated backend functions to production
7. **Submit app updates** to both app stores

## 7. Subscription Management

Create a simple interface in the app where users can:

1. **View subscription status**
2. **See expiration date**
3. **Access the platform's subscription management**
4. **Restore purchases** across devices

## References:

- [Flutter In-App Purchase Plugin](https://pub.dev/packages/in_app_purchase)
- [Apple In-App Purchase Documentation](https://developer.apple.com/in-app-purchase/)
- [Google Play Billing Library Documentation](https://developer.android.com/google/play/billing)
- [Supabase Database Functions](https://supabase.com/docs/guides/database/functions)
