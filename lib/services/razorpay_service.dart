import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../app_constants.dart';
import '../Database/Database.dart';

/// Service for handling Razorpay payment gateway integration
/// Manages payment order creation, verification, and checkout flow
class RazorpayService {
  final Razorpay _razorpay = Razorpay();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool _isInitialized = false;

  /// Initialize Razorpay event handlers
  /// Sets up callbacks for payment success, error, and external wallet events
  void initialize({
    required Function(PaymentSuccessResponse) onPaymentSuccess,
    required Function(PaymentFailureResponse) onPaymentError,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    if (_isInitialized) return;
    
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (response) {
      debugPrint("✅ Razorpay Payment Success!");
      debugPrint("Payment ID: ${response.paymentId}");
      debugPrint("Order ID: ${response.orderId}");
      debugPrint("Signature: ${response.signature}");
      onPaymentSuccess(response);
    });
    
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (response) {
      debugPrint("❌ Razorpay Payment Error: ${response.code} - ${response.message}");
      onPaymentError(response);
    });
    
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (response) {
      debugPrint("👛 External Wallet: ${response.walletName}");
      onExternalWallet(response);
    });
    
    _isInitialized = true;
    
    debugPrint("✅ Razorpay service initialized");
  }

  /// Create payment order with backend
  /// Handles both wallet payments and Razorpay order creation
  Future<Map<String, dynamic>> createPaymentOrder({
    required List<String> sites,
    String? couponCode,
    required double eBankingAmount,
    required double eWalletAmount,
  }) async {
    try {
      debugPrint("🔄 Creating payment order...");
      
      final database = Database();
      
      final requestBody = {
        'action': 'make_payment',
        'sites': sites.join(','), // Comma-separated site IDs
        'coupon_applied': couponCode?.isNotEmpty == true ? couponCode : '',
        'use_from_ebanking': eBankingAmount.toString(),
        'use_from_ewallet': eWalletAmount.toString(),
      };
      
      debugPrint("📤 Request Body: $requestBody");
      
      final response = await database.getData(requestBody);

      debugPrint("📡 Payment Order Response: $response");
      debugPrint("📊 Response Status: ${response['status']}");
      debugPrint("📊 Response Data: ${response['data']}");
      
      // Check status first, then handle data
      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];
        
        debugPrint("📊 Data Keys: ${data.keys.toList()}");
        
        // Handle wallet payment FIRST
        if (data['wallet'] == true) {
          debugPrint("✅ Payment completed via wallet");
          return data;
        }
        
        // Then handle Razorpay order creation
        if (data['id'] != null) {
          debugPrint("✅ Payment order created successfully");
          return data;
        }
        
        // Unknown successful response
        debugPrint("✅ Payment request completed successfully");
        return data;
      }
      
      // Handle error cases
      final message = response['message'] ?? response['error'] ?? 'Payment order creation failed';
      debugPrint("❌ Error Message: $message");
      throw Exception(message);
      
    } catch (e) {
      debugPrint("❌ Failed to create payment order: $e");
      throw Exception('Failed to create payment order: $e');
    }
  }

  /// Open Razorpay checkout with payment options
  /// Displays payment gateway UI to user
  void openCheckout({
    required String key,
    required int amount,
    String? orderId, // Made optional
    required String name,
    required String email,
    required String contact,
    required String description,
  }) {
    final options = {
      'key': key,
      'amount': amount,
      'name': name,
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email,
      },
      'theme': {
        'color': '#3399cc',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    // Only add order_id if it's provided and not empty
    if (orderId != null && orderId.isNotEmpty) {
      options['order_id'] = orderId;
      debugPrint("🔄 Using Razorpay order: $orderId");
    } else {
      debugPrint("🔄 Opening Razorpay without pre-created order (Razorpay will create one)");
    }

    try {
      debugPrint("🔄 Opening Razorpay checkout...");
      debugPrint("📋 Checkout Options: $options");
      _razorpay.open(options);
    } catch (e) {
      debugPrint("❌ Failed to open Razorpay checkout: $e");
      throw Exception('Failed to open Razorpay checkout: $e');
    }
  }

  /// Verify payment with backend
  /// Confirms payment authenticity using signature verification
  Future<bool> verifyPayment({
    required String paymentId,
    required String orderId,
    required String signature,
  }) async {
    try {
      debugPrint("🔄 Verifying payment...");
      
      final database = Database();
      
      final requestBody = {
        'action': 'verifyProliferationPayment',
        'razorpay_payment_id': paymentId,
        'razorpay_order_id': orderId,
        'razorpay_signature': signature,
      };
      
      debugPrint("📤 Verification Request: $requestBody");
      
      final response = await database.getData(requestBody);

      debugPrint("📡 Payment Verification Response: $response");
      
      final isVerified = response['status'] == true;
      
      if (isVerified) {
        debugPrint("✅ Payment verified successfully");
      } else {
        debugPrint("❌ Payment verification failed");
      }
      
      return isVerified;
    } catch (e) {
      debugPrint("❌ Payment verification error: $e");
      throw Exception('Payment verification failed: $e');
    }
  }

  /// Get Razorpay key from LoginService
  /// Retrieves API key for payment processing
  Future<String> getRazorpayKey() async {
    try {
      debugPrint("🔄 Getting Razorpay key from secure storage/database...");
      final razorpayKey = await Database().getRazorpayKey();
      
      if (razorpayKey != null && razorpayKey.isNotEmpty) {
        debugPrint("✅ Razorpay key retrieved: $razorpayKey");
        return razorpayKey;
      }
      return razorpayTestKey;
    } catch (e) {
      debugPrint("❌ Error getting Razorpay key: $e");
      // Fallback to default test key
      debugPrint("🔄 Using fallback test key");
      return razorpayTestKey;
    }
  }

  /// Get user details from LoginService
  /// Retrieves customer information for payment processing
  Future<Map<String, String>> getUserDetails() async {
    try {
      debugPrint("🔄 Getting user details from secure storage...");
      final userJson = await _storage.read(key: 'user_data');
      final userInfo = userJson != null
          ? Map<String, dynamic>.from(jsonDecode(userJson) as Map)
          : <String, dynamic>{};
      
      final userDetails = {
        'name': userInfo['name']?.toString() ?? 'Guest User',
        'email': userInfo['email']?.toString() ?? 'guest@example.com',
        'contact': userInfo['phone']?.toString() ?? '9999999999',
      };
      
      debugPrint("✅ User details retrieved: $userDetails");
      return userDetails;
    } catch (e) {
      debugPrint("❌ Error getting user details: $e");
      // Fallback to default values
      return {
        'name': 'Guest User',
        'email': 'guest@example.com',
        'contact': '9999999999',
      };
    }
  }

  /// Dispose Razorpay instance
  /// Clean up event handlers and resources
  void dispose() {
    if (_isInitialized) {
      _razorpay.clear();
      _isInitialized = false;
      debugPrint("🗑️ Razorpay service disposed");
    }
  }
}
