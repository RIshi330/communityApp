import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../services/razorpay_service.dart';
import '../../services/payment_api_service.dart';
import 'payment_success_screen.dart';
import '../../core/theme/app_colors.dart';

/// Payment Adjustment Modal
/// Handles payment method selection, balance distribution, and coupon application
/// This is the main payment interface shown after "Proceed to Checkout"
class PaymentAdjustmentModal extends StatefulWidget {
  final double amount;
  final String orderId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<String>? sites; // Cart items/sites for payment
  final VoidCallback? onPaymentComplete; // Callback to close modal
  final Future<Map<String, dynamic>> Function(double, List<String>?, String?, double?, double?)? onCreateOrder; // Custom order creation
  final Future<bool> Function()? onVerifyPayment; // Custom payment verification

  const PaymentAdjustmentModal({
    super.key,
    required this.amount,
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    this.sites,
    this.onPaymentComplete,
    this.onCreateOrder,
    this.onVerifyPayment,
  });

  @override
  State<PaymentAdjustmentModal> createState() => _PaymentAdjustmentModalState();
}

class _PaymentAdjustmentModalState extends State<PaymentAdjustmentModal> {
  // API Data
  double ecashBalance = 0;
  double ewalletBalance = 0;
  bool _isLoadingBalances = true;

  // Payment Distribution
  double ecashUsed = 0;
  double ewalletUsed = 0;
  double codUsed = 0;
  double couponDiscount = 0;
  double remainingAmount = 0;

  // UI State
  bool codEnabled = false;
  bool _isProcessing = false;
  bool _isValidatingCoupon = false;
  String _couponMessage = '';
  
  // Services
  final RazorpayService _razorpayService = RazorpayService();
  final PaymentApiService _paymentApiService = PaymentApiService();
  final TextEditingController couponCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadBalances();
  }

  /// Load user balances from API
  Future<void> _loadBalances() async {
    try {
      setState(() => _isLoadingBalances = true);
      
      final balances = await _paymentApiService.getBalances();
      
      setState(() {
        ecashBalance = balances['ecash_balance'] ?? 0;
        ewalletBalance = balances['ewallet_balance'] ?? 0;
        _isLoadingBalances = false;
      });
      
      // Auto-optimize after loading balances
      autoOptimize();
      
    } catch (e) {
      setState(() => _isLoadingBalances = false);
      _snack('Failed to load balances: ${e.toString()}');
    }
  }

  /// Initialize Razorpay event handlers
  void _initializeRazorpay() {
    _razorpayService.initialize(
      onPaymentSuccess: _handlePaymentSuccess,
      onPaymentError: _handlePaymentError,
      onExternalWallet: _handleExternalWallet,
    );
  }

  // CALCULATION METHODS

  /// Get total amount after coupon discount
  double get adjustedTotal =>
      widget.amount - couponDiscount < 0 ? 0 : widget.amount - couponDiscount;

  /// Get total amount used from all payment methods
  double get totalUsed => ecashUsed + ewalletUsed + codUsed;

  /// Get final payable amount after all deductions
  double get finalPayable {
    final remaining = adjustedTotal - totalUsed;
    return remaining < 0 ? 0 : remaining;
  }

  // ACTION METHODS

  /// Automatically optimize payment distribution
  /// Uses API to calculate optimal balance usage
  Future<void> autoOptimize() async {
    try {
      final distribution = await _paymentApiService.optimizePaymentDistribution(
        totalPrice: widget.amount,
        couponCode: couponCtrl.text.trim().isNotEmpty ? couponCtrl.text.trim() : null,
      );
      
      setState(() {
        ecashUsed = distribution['ecash_used'] ?? 0;
        ewalletUsed = distribution['ewallet_used'] ?? 0;
        couponDiscount = distribution['coupon_discount'] ?? 0;
        remainingAmount = distribution['remaining_amount'] ?? 0;
        codUsed = 0;
        codEnabled = false;
      });
      
    } catch (e) {
      // Fallback to local optimization if API fails
      setState(() {
        ecashUsed = ecashBalance >= adjustedTotal ? adjustedTotal : ecashBalance;
        final remaining = adjustedTotal - ecashUsed;
        ewalletUsed = remaining > 0 ? remaining.clamp(0, ewalletBalance) : 0;
        codUsed = 0;
      });
    }
  }

  /// Recalculate remaining amount after manual adjustments
  Future<void> _recalculateRemaining() async {
    try {
      final result = await _paymentApiService.calculateRemaining(
        totalPrice: widget.amount,
        ecashUsed: ecashUsed,
        ewalletUsed: ewalletUsed,
        couponCode: couponCtrl.text.trim().isNotEmpty ? couponCtrl.text.trim() : null,
      );
      
      setState(() {
        remainingAmount = result['remaining_amount'] ?? 0;
      });
      
    } catch (e) {
      // Fallback to local calculation
      setState(() {
        remainingAmount = (adjustedTotal - totalUsed).clamp(0.0, double.infinity);
      });
    }
  }

  /// Apply coupon code and validate
  Future<void> applyCoupon() async {
    final couponCode = couponCtrl.text.trim();
    if (couponCode.isEmpty) {
      setState(() {
        couponDiscount = 0;
        _couponMessage = '';
      });
      return;
    }

    setState(() => _isValidatingCoupon = true);
    
    try {
      final result = await _paymentApiService.calculateRemaining(
        totalPrice: widget.amount,
        ecashUsed: ecashUsed,
        ewalletUsed: ewalletUsed,
        couponCode: couponCode,
      );
      
      setState(() {
        couponDiscount = result['coupon_discount'] ?? 0;
        remainingAmount = result['remaining_amount'] ?? 0;
        _couponMessage = result['coupon_message'] ?? '';
        _isValidatingCoupon = false;
      });
      
      if (result['coupon_valid'] == true) {
        _snack('Coupon applied successfully!');
      } else {
        _snack(_couponMessage.isNotEmpty ? _couponMessage : 'Invalid coupon');
      }
      
    } catch (e) {
      setState(() {
        couponDiscount = 0;
        _couponMessage = '';
        _isValidatingCoupon = false;
      });
      _snack('Error validating coupon: ${e.toString()}');
    }
  }

  /// Proceed to payment after validation
  Future<void> _proceedToPayment() async {
    if (_isProcessing) return;

    // Validate that payment amounts cover the total
    if (totalUsed < adjustedTotal) {
      _snack("Payment amounts must cover the total amount");
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Use custom order creation callback if provided
      if (widget.onCreateOrder != null) {
        final orderData = await widget.onCreateOrder!(
          adjustedTotal,
          widget.sites,
          couponCtrl.text.trim().isNotEmpty ? couponCtrl.text.trim() : null,
          ewalletUsed,
          0, // ECash is being used instead
        );

        // Check if Razorpay was opened directly (special case for proliferate screen)
        if (orderData['razorpay_opened_directly'] == true) {
          setState(() => _isProcessing = false);
          // Razorpay is already opened, so just wait for payment success
          return;
        }

        // Check if this is a wallet-only payment
        if (orderData['wallet'] == true) {
          setState(() => _isProcessing = false);
          
          // Show success message for wallet payment
          _snack("Payment completed via wallet!");

          // Call custom verification callback if provided
          if (widget.onVerifyPayment != null) {
            await widget.onVerifyPayment!();
            // Don't call onPaymentComplete here - let verification callback handle navigation
          } else {
            // Default behavior - navigate to success screen
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => PaymentSuccessScreen(
                  orderId: widget.orderId,
                  paymentId: 'WALLET_PAYMENT',
                  amount: widget.amount,
                ),
              ),
            );
          }
          return;
        }

        // Open Razorpay checkout with backend order
        final razorpayKey = orderData['key'] ?? await _razorpayService.getRazorpayKey();
        final amount = orderData['amount'] ?? (finalPayable * 100).toInt();
        // Handle order ID carefully - only use it if it's a valid Razorpay order ID
        String? orderId;
        if (orderData['id'] != null && orderData['id'] != 'null' && orderData['id'].toString().isNotEmpty) {
          orderId = orderData['id'].toString();
        }
        final description = orderData['description'] ?? 'Membership Purchase';
        final name = orderData['name'] ?? widget.customerName;
        final email = orderData['email'] ?? widget.customerEmail;
        final contact = orderData['contact'] ?? widget.customerPhone;
        
        debugPrint("🔄 Opening Razorpay with: key=$razorpayKey, amount=$amount, orderId=$orderId");
        
        _razorpayService.openCheckout(
          key: razorpayKey,
          amount: amount,
          orderId: orderId, // This can be null for direct orders
          name: name,
          description: description,
          email: email,
          contact: contact,
        );
      } else {
        // Default behavior - use Razorpay service
        final razorpayKey = await _razorpayService.getRazorpayKey();
        
        final orderData = await _razorpayService.createPaymentOrder(
          sites: widget.sites ?? ['1'],
          couponCode: couponCtrl.text.trim(),
          eBankingAmount: 0, // ECash is being used instead
          eWalletAmount: ewalletUsed,
        );

        // Check if this is a wallet-only payment
        if (orderData['wallet'] == true) {
          setState(() => _isProcessing = false);
          
          // Show success message for wallet payment
          _snack("Payment completed via wallet!");

          // Navigate to success screen
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                orderId: widget.orderId,
                paymentId: 'WALLET_PAYMENT',
                amount: widget.amount,
              ),
            ),
          );
          return;
        }

        // Open Razorpay checkout with backend order
        _razorpayService.openCheckout(
          key: razorpayKey,
          amount: orderData['amount'] ?? (finalPayable * 100).toInt(),
          orderId: orderData['id'] ?? widget.orderId,
          name: widget.customerName,
          description: 'Membership Purchase',
          email: widget.customerEmail,
          contact: widget.customerPhone,
        );
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _snack("Payment Error: $e");
    }
  }

  /// Handle successful payment from Razorpay
  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Early exit if widget is disposed
    if (!mounted) return;
    
    try {
      // Log the REAL payment data from Razorpay
      debugPrint("✅ Razorpay Payment Success!");
      debugPrint("Real Payment ID: ${response.paymentId}");
      debugPrint("Real Order ID: ${response.orderId}");
      debugPrint("Real Signature: ${response.signature}");
      
      // Create REAL payment data map from Razorpay response
      final realPaymentData = {
        'razorpay_payment_id': response.paymentId,
        'razorpay_order_id': response.orderId,
        'razorpay_signature': response.signature,
      };
      
      // Use custom verification callback if provided
      if (widget.onVerifyPayment != null) {
        if (mounted) setState(() => _isProcessing = false);
        if (mounted) _snack('Payment Successful! Order ID: ${response.paymentId ?? 'Unknown'}');
        
        // Store REAL payment data for verification method to use
        final storage = FlutterSecureStorage();
        await storage.write(key: 'temp_razorpay_payment_id', value: response.paymentId ?? '');
        await storage.write(key: 'temp_razorpay_order_id', value: response.orderId ?? '');
        await storage.write(key: 'temp_razorpay_signature', value: response.signature ?? '');
        
        debugPrint("💾 Stored REAL payment data: paymentId=${response.paymentId}, orderId=${response.orderId}, signature=${response.signature}");
        
        // Call custom verification callback with REAL data
        await widget.onVerifyPayment!();
        
        // Check if still mounted after async callback
        if (!mounted) return;
        
        // Call payment complete callback
        if (widget.onPaymentComplete != null) {
          widget.onPaymentComplete!();
        }
        return;
      }
      
      // Default behavior - Verify payment with backend using REAL data
      final success = await _razorpayService.verifyPayment(
        paymentId: response.paymentId ?? '',
        orderId: response.orderId ?? '',
        signature: response.signature ?? '',
      );

      // Check if still mounted after async verification
      if (!mounted) return;

      if (mounted) setState(() => _isProcessing = false);

      if (success) {
        if (mounted) _snack('Payment Successful! Order ID: ${response.paymentId ?? 'Unknown'}');

        // Navigate to success screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => PaymentSuccessScreen(
                orderId: widget.orderId,
                paymentId: response.paymentId ?? 'Unknown',
                amount: widget.amount,
              ),
            ),
          );
        }
        
        // Call payment complete callback
        if (widget.onPaymentComplete != null) {
          widget.onPaymentComplete!();
        }
      } else {
        if (mounted) _snack('Payment verification failed');
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      if (mounted) _snack('Payment processing failed: ${e.toString()}');
    }
  }

  /// Handle payment error from Razorpay
  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (mounted) _snack('Payment Failed: ${response.message ?? 'Unknown error'}');
  }

  /// Handle external wallet selection
  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
    if (mounted) _snack('External wallet selected: ${response.walletName ?? 'Unknown'}');
  }

  @override
  void dispose() {
    _razorpayService.dispose();
    couponCtrl.dispose();
    super.dispose();
  }

  // UI BUILD METHODS

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHandleBar(),
          _buildHeader(),
          const SizedBox(height: 8),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildHandleBar() {
    return Container(
      width: 40,
      height: 4,
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.grey300,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text(
            "Adjust Payment",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOrderInfoCard(),
        const SizedBox(height: 16),
        _buildTotalCard(),
        const SizedBox(height: 16),
        _buildAutoOptimizeButton(),
        const SizedBox(height: 16),
        _buildEcashSlider(),
        const SizedBox(height: 16),
        _buildEwalletSlider(),
        const SizedBox(height: 16),
        _buildCodSection(),
        const SizedBox(height: 16),
        _buildCouponSection(),
        const SizedBox(height: 20),
        _buildFinalSummaryCard(),
        const SizedBox(height: 20),
        _buildProceedButton(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildOrderInfoCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Order #${widget.orderId}",
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.customerName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Total Payable", style: TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text(
            "₹${adjustedTotal.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          if (_isLoadingBalances)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text("Loading balances...", style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAutoOptimizeButton() {
    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: autoOptimize,
        icon: const Icon(Icons.auto_fix_high),
        label: const Text("Auto Optimize Payment Split"),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildEcashSlider() {
    return _sliderSection(
      title: "E-Cash",
      tooltip: "In-app cashback and rewards balance.",
      balance: ecashBalance,
      value: ecashUsed,
      max: ecashBalance,
      onChanged: _isLoadingBalances ? (v) {} : (v) {
        setState(() => ecashUsed = v);
        _recalculateRemaining();
      },
    );
  }

  Widget _buildEwalletSlider() {
    return _sliderSection(
      title: "E-Wallet",
      tooltip: "Digital wallet balance for payments.",
      balance: ewalletBalance,
      value: ewalletUsed,
      max: ewalletBalance,
      onChanged: _isLoadingBalances ? (v) {} : (v) {
        setState(() => ewalletUsed = v);
        _recalculateRemaining();
      },
    );
  }

  Widget _buildCodSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Cash on Delivery", style: TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              Switch(
                value: codEnabled,
                onChanged: (v) {
                  setState(() {
                    codEnabled = v;
                    codUsed = v ? finalPayable : 0;
                  });
                },
              )
            ],
          ),
          if (codEnabled)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Slider(
                  min: 0,
                  max: finalPayable,
                  value: codUsed,
                  onChanged: (v) => setState(() => codUsed = v),
                ),
                Text(
                  "COD Amount: ₹${codUsed.toStringAsFixed(0)}",
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              ],
            )
        ],
      ),
    );
  }

  Widget _buildCouponSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: couponCtrl,
                  decoration: InputDecoration(
                    hintText: "Coupon Code",
                    border: OutlineInputBorder(),
                    suffixIcon: _isValidatingCoupon
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: (value) {
                    if (_couponMessage.isNotEmpty) {
                      setState(() => _couponMessage = '');
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isValidatingCoupon ? null : applyCoupon,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Apply"),
              )
            ],
          ),
          if (_couponMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _couponMessage,
                style: TextStyle(
                  color: couponDiscount > 0 ? AppColors.success : AppColors.error,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinalSummaryCard() {
    return _card(
      child: Column(
        children: [
          _row("E-Cash Used", ecashUsed),
          _row("E-Wallet Used", ewalletUsed),
          if (codEnabled) _row("COD Used", codUsed),
          if (couponDiscount > 0) _row("Coupon Discount", couponDiscount),
          const Divider(),
          _row("Final Payable", finalPayable, bold: true),
        ],
      ),
    );
  }

  Widget _buildProceedButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isProcessing ? null : _proceedToPayment,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        child: _isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : const Text(
                "Proceed to Payment",
                style: TextStyle(fontSize: 16),
              ),
      ),
    );
  }

  // HELPER WIDGETS

  Widget _sliderSection({
    required String title,
    required String tooltip,
    required double balance,
    required double value,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(width: 6),
              Tooltip(
                message: tooltip,
                child: const Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Available: ₹${balance.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Slider(
            min: 0,
            max: max,
            value: value,
            onChanged: onChanged,
          ),
          Text(
            "Using: ₹${value.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            "₹${value.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.grey900.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
