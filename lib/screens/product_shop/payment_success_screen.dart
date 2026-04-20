import 'package:flutter/material.dart';
import '../../app_constants.dart';
import '../../core/theme/app_theme.dart';

/// Payment Success Screen
/// Displays payment completion details and navigation options
/// Shown after successful payment verification
class PaymentSuccessScreen extends StatelessWidget {
  final String orderId;
  final String paymentId;
  final double amount;

  const PaymentSuccessScreen({
    super.key,
    required this.orderId,
    required this.paymentId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Payment Success'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success Icon
              _buildSuccessIcon(),
              const SizedBox(height: 32),
              
              // Success Message
              _buildSuccessMessage(),
              const SizedBox(height: 16),
              
              // Order Details
              _buildOrderDetailsCard(),
              const SizedBox(height: 32),
              
              // Action Buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build success icon with animation
  Widget _buildSuccessIcon() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_circle,
        size: 60,
        color: Colors.green,
      ),
    );
  }

  /// Build success message
  Widget _buildSuccessMessage() {
    return const Text(
      'Payment Successful!',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
      textAlign: TextAlign.center,
    );
  }

  /// Build order details card
  Widget _buildOrderDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildDetailRow('Order ID', orderId),
            const Divider(),
            _buildDetailRow('Payment ID', paymentId),
            const Divider(),
            _buildDetailRow('Amount Paid', '${rs}${amount.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  /// Build action buttons for navigation
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Back to Home Button
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              // Navigate back to home screen (pop all screens)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: AppTheme.primaryColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Back to Home',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        
        // Continue Shopping Button
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              // Navigate back to cart to continue shopping
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Continue Shopping',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build detail row for order information
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
