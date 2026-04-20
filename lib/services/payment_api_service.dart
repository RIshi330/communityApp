import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../database/database.dart';

/// Service for handling payment-related API calls
/// Handles balances, calculations, and coupon validation
class PaymentApiService {
  final Database _database = Database();

  /// Get user balances from API
  /// Returns ECash and EWallet balances
  Future<Map<String, double>> getBalances() async {
    try {
      debugPrint("🔄 Getting user balances...");
      
      final requestBody = {
        'action': 'get_balances',
      };
      
      debugPrint("📤 Request Body: $requestBody");
      
      final response = await _database.getData(requestBody);
      
      debugPrint("📡 Balances Response: $response");
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        final ecashBalance = double.tryParse(data['ecash_balance'].toString()) ?? 0.0;
        final ewalletBalance = double.tryParse(data['ewallet_balance'].toString()) ?? 0.0;
        
        debugPrint("✅ Balances retrieved successfully");
        debugPrint("💰 ECash Balance: ₹$ecashBalance");
        debugPrint("💰 EWallet Balance: ₹$ewalletBalance");
        
        return {
          'ecash_balance': ecashBalance,
          'ewallet_balance': ewalletBalance,
        };
      }
      
      debugPrint("❌ Failed to get balances");
      throw Exception('Failed to retrieve balances');
      
    } catch (e) {
      debugPrint("❌ Error getting balances: $e");
      throw Exception('Failed to retrieve balances: $e');
    }
  }

  /// Calculate remaining amount after applying balances and coupons
  /// Returns calculation results with coupon validation
  Future<Map<String, dynamic>> calculateRemaining({
    required double totalPrice,
    required double ecashUsed,
    required double ewalletUsed,
    String? couponCode,
    String marketplace = "5",
  }) async {
    try {
      debugPrint("🔄 Calculating remaining amount...");
      
      final requestBody = {
        'action': 'calculate_remaining',
        'total_price': totalPrice.toStringAsFixed(2),
        'ecash_used': ecashUsed.toStringAsFixed(2),
        'ewallet_used': ewalletUsed.toStringAsFixed(2),
        'coupon_code': couponCode?.isNotEmpty == true ? couponCode : '',
        'marketplace': marketplace,
      };
      
      debugPrint("📤 Request Body: $requestBody");
      
      final response = await _database.getData(requestBody);
      
      debugPrint("📡 Calculate Remaining Response: $response");
      
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        
        final result = {
          'total_price': double.tryParse(data['total_price'].toString()) ?? 0.0,
          'ecash_used': double.tryParse(data['ecash_used'].toString()) ?? 0.0,
          'ewallet_used': double.tryParse(data['ewallet_used'].toString()) ?? 0.0,
          'coupon_code': data['coupon_code']?.toString() ?? '',
          'coupon_discount': double.tryParse(data['coupon_discount'].toString()) ?? 0.0,
          'coupon_valid': data['coupon_valid'] == true,
          'coupon_message': data['coupon_message']?.toString() ?? '',
          'remaining_amount': double.tryParse(data['remaining_amount'].toString()) ?? 0.0,
        };
        
        debugPrint("✅ Remaining amount calculated successfully");
        debugPrint("💰 Remaining Amount: ₹${result['remaining_amount']}");
        debugPrint("🎫 Coupon Valid: ${result['coupon_valid']}");
        debugPrint("💸 Coupon Discount: ₹${result['coupon_discount']}");
        
        return result;
      }
      
      debugPrint("❌ Failed to calculate remaining amount");
      throw Exception('Failed to calculate remaining amount');
      
    } catch (e) {
      debugPrint("❌ Error calculating remaining amount: $e");
      throw Exception('Failed to calculate remaining amount: $e');
    }
  }

  /// Validate coupon code independently
  Future<bool> validateCoupon(String couponCode) async {
    try {
      debugPrint("🔄 Validating coupon: $couponCode");
      
      final result = await calculateRemaining(
        totalPrice: 0.0,
        ecashUsed: 0.0,
        ewalletUsed: 0.0,
        couponCode: couponCode,
      );
      
      return result['coupon_valid'] == true;
      
    } catch (e) {
      debugPrint("❌ Error validating coupon: $e");
      return false;
    }
  }

  /// Get available balance for specific payment method
  Future<double> getAvailableBalance(String paymentMethod) async {
    try {
      final balances = await getBalances();
      
      switch (paymentMethod.toLowerCase()) {
        case 'ecash':
          return balances['ecash_balance'] ?? 0.0;
        case 'ewallet':
          return balances['ewallet_balance'] ?? 0.0;
        default:
          return 0.0;
      }
    } catch (e) {
      debugPrint("❌ Error getting available balance for $paymentMethod: $e");
      return 0.0;
    }
  }

  /// Calculate optimal payment distribution
  /// Automatically distributes payment across available balances
  Future<Map<String, double>> optimizePaymentDistribution({
    required double totalPrice,
    String? couponCode,
  }) async {
    try {
      debugPrint("🔄 Optimizing payment distribution...");
      
      final balances = await getBalances();
      final ecashBalance = balances['ecash_balance'] ?? 0.0;
      final ewalletBalance = balances['ewallet_balance'] ?? 0.0;
      
      // Calculate with coupon first
      final calculation = await calculateRemaining(
        totalPrice: totalPrice,
        ecashUsed: 0.0,
        ewalletUsed: 0.0,
        couponCode: couponCode,
      );
      
      final adjustedTotal = calculation['remaining_amount'] as double;
      
      double ecashUsed = 0.0;
      double ewalletUsed = 0.0;
      
      // Use ECash first
      if (ecashBalance > 0) {
        ecashUsed = ecashBalance >= adjustedTotal ? adjustedTotal : ecashBalance;
      }
      
      // Use EWallet for remaining amount
      final remainingAfterEcash = adjustedTotal - ecashUsed;
      if (remainingAfterEcash > 0 && ewalletBalance > 0) {
        ewalletUsed = ewalletBalance >= remainingAfterEcash ? remainingAfterEcash : ewalletBalance;
      }
      
      // Final calculation
      final finalCalculation = await calculateRemaining(
        totalPrice: totalPrice,
        ecashUsed: ecashUsed,
        ewalletUsed: ewalletUsed,
        couponCode: couponCode,
      );
      
      final result = {
        'ecash_used': ecashUsed,
        'ewallet_used': ewalletUsed,
        'remaining_amount': finalCalculation['remaining_amount'] as double,
        'coupon_discount': finalCalculation['coupon_discount'] as double,
      };
      
      debugPrint("✅ Payment distribution optimized");
      debugPrint("💰 ECash Used: ₹${result['ecash_used']}");
      debugPrint("💰 EWallet Used: ₹${result['ewallet_used']}");
      debugPrint("💰 Remaining: ₹${result['remaining_amount']}");
      
      return result;
      
    } catch (e) {
      debugPrint("❌ Error optimizing payment distribution: $e");
      throw Exception('Failed to optimize payment distribution: $e');
    }
  }
}
