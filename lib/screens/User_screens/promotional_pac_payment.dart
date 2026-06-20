import 'dart:convert';
import 'package:commity_app1/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

// ─── API Config ────────────────────────────────────────────────────────────────
const String _kBaseUrl = '${baseUrl}new_apis/promotion_package_api.php';

// ─── Models ────────────────────────────────────────────────────────────────────

class PackageDetails {
  final int id;
  final String name;
  final String? description;
  final int durationValue;
  final String durationType;
  final Map<String, dynamic> pricing;
  final Map<String, dynamic> reach;

  PackageDetails({
    required this.id,
    required this.name,
    this.description,
    required this.durationValue,
    required this.durationType,
    required this.pricing,
    required this.reach,
  });

  factory PackageDetails.fromJson(Map<String, dynamic> json) {
    return PackageDetails(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      description: json['description'],
      durationValue: json['duration_value'] ?? 0,
      durationType: json['duration_type'] ?? '',
      pricing: Map<String, dynamic>.from(json['pricing'] ?? {}),
      reach: Map<String, dynamic>.from(json['reach'] ?? {}),
    );
  }

  /// Returns the display price regardless of pricing model
  double get displayPrice {
    final p = pricing;
    final raw = p['fixed_price'] ?? p['base_price'] ?? p['price_per_action'] ?? 0;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString()) ?? 0.0;
  }

  String get pricingType => pricing['type'] ?? 'fixed';
  String get durationLabel => '$durationValue $durationType';
}

// ─── API Service ───────────────────────────────────────────────────────────────

class PackageApiService {
  /// Fetches package details by ID from the PHP backend.
  static Future<PackageDetails> fetchPackageDetails(int packageId) async {
    final response = await http.post(
      Uri.parse(_kBaseUrl),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action': 'get_package_details',
        'id': packageId,
      }),
    );
    print(response.body);  //debug
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (body['success'] != true) {
      throw Exception(body['message'] ?? 'Failed to fetch package');
    }

    return PackageDetails.fromJson(body['data'] as Map<String, dynamic>);
  }

  /// Validates a coupon code against the backend.
  /// Extend this to call a real coupon validation endpoint.
  static Future<double> validateCoupon({
    required String code,
    required int packageId,
    required double price,
  }) async {
    // TODO: Replace with a real coupon endpoint when available.
    // Currently mirrors the mock logic from the original screen.
    await Future.delayed(const Duration(milliseconds: 600));
    if (code.trim().toUpperCase() == 'SAVE10') {
      return price * 0.10;
    }
    throw Exception('Invalid coupon code');
  }

  /// Fetches the user's wallet balances.
  /// Extend this to call your real wallet balance endpoint.
  static Future<Map<String, double>> fetchWalletBalances() async {
    // TODO: Replace with real wallet balance endpoint.
    // e.g. POST { action: 'get_wallet_balances' }
    await Future.delayed(const Duration(milliseconds: 400));
    return {
      'ecash': 45200.00,
      'ewallet': 169700.50,
    };
  }

  /// Places the order / processes payment.
  /// Extend this to call your real payment/order creation endpoint.
  static Future<Map<String, dynamic>> placeOrder({
    required int packageId,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${baseUrl}new_apis/buy_promotion_package_api.php',
      ),
      body: {
        'make_payment': '1',
        'package_id': packageId.toString(),
      },
    );

    print("Status Code: ${response.statusCode}");
    print("Response Body: ${response.body}");

    if (response.statusCode != 200) {
      throw Exception('Server Error: ${response.statusCode}');
    }

    return jsonDecode(response.body);
  }
}

// ─── Screen ────────────────────────────────────────────────────────────────────

class PaymentScreen_user extends StatefulWidget {
  /// The promotion package ID to purchase.
  final int packageId;

  const PaymentScreen_user({super.key, required this.packageId});

  @override
  State<PaymentScreen_user> createState() => _PaymentScreen_user();
}

class _PaymentScreen_user extends State<PaymentScreen_user> {
  // ── Loading / Error state ──
  bool _loading = true;
  String? _errorMessage;

  // ── Data ──
  PackageDetails? _package;
  double _ecashBalance = 0;
  double _ewalletBalance = 0;

  // ── Coupon ──
  final TextEditingController _couponController = TextEditingController();
  double _couponDiscount = 0.0;
  bool _applyingCoupon = false;

  // ── Wallet selection ──
  bool _isEcashSelected = false;
  bool _isEwalletSelected = false;
  final TextEditingController _ecashAmountController = TextEditingController();
  final TextEditingController _ewalletAmountController = TextEditingController();

  // ── Payment processing ──
  bool _processingPayment = false;

  // ─── Computed values ───────────────────────────────────────────────────────

  double get _productPrice => _package?.displayPrice ?? 0;

  double get _appliedWalletAmount {
    final base = _productPrice - _couponDiscount;
    if (_isEcashSelected) {
      final val = double.tryParse(_ecashAmountController.text) ?? 0;
      return val.clamp(0, base);
    } else if (_isEwalletSelected) {
      final val = double.tryParse(_ewalletAmountController.text) ?? 0;
      return val.clamp(0, base);
    }
    return 0;
  }

  double get _finalPayable =>
      (_productPrice - _couponDiscount - _appliedWalletAmount).clamp(0, double.infinity);

  // ─── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _ecashAmountController.addListener(_rebuild);
    _ewalletAmountController.addListener(_rebuild);
    _loadData();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _ecashAmountController.dispose();
    _ewalletAmountController.dispose();
    super.dispose();
  }

  void _rebuild() => setState(() {});

  // ─── Data fetching ─────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        PackageApiService.fetchPackageDetails(widget.packageId),
        PackageApiService.fetchWalletBalances(),
      ]);

      final pkg = results[0] as PackageDetails;
      final wallets = results[1] as Map<String, double>;

      if (!mounted) return;
      setState(() {
        _package = pkg;
        _ecashBalance = wallets['ecash'] ?? 0;
        _ewalletBalance = wallets['ewallet'] ?? 0;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  // ─── Interactions ──────────────────────────────────────────────────────────

  void _toggleWallet(String type) {
    setState(() {
      if (type == 'ecash') {
        if (!_isEcashSelected) {
          _isEcashSelected = true;
          _isEwalletSelected = false;
          if (_ecashAmountController.text.isEmpty) {
            _ecashAmountController.text = _productPrice.toStringAsFixed(0);
          }
        } else {
          _isEcashSelected = false;
          _ecashAmountController.clear();
        }
      } else {
        if (!_isEwalletSelected) {
          _isEwalletSelected = true;
          _isEcashSelected = false;
          if (_ewalletAmountController.text.isEmpty) {
            _ewalletAmountController.text = _productPrice.toStringAsFixed(0);
          }
        } else {
          _isEwalletSelected = false;
          _ewalletAmountController.clear();
        }
      }
    });
  }

  Future<void> _applyCoupon() async {
    final code = _couponController.text;
    if (code.isEmpty) {
      setState(() => _couponDiscount = 0.0);
      return;
    }

    setState(() => _applyingCoupon = true);

    try {
      final discount = await PackageApiService.validateCoupon(
        code: code,
        packageId: widget.packageId,
        price: _productPrice,
      );
      if (!mounted) return;
      setState(() => _couponDiscount = discount);
      _showSnack('Coupon applied! Saved ₹${discount.toStringAsFixed(2)}', success: true);
    } catch (e) {
      if (!mounted) return;
      _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _applyingCoupon = false);
    }
  }

  Future<void> _processPayment() async {
    setState(() {
      _processingPayment = true;
    });

    try {
      final result = await PackageApiService.placeOrder(
        packageId: widget.packageId,
      );

      setState(() {
        _processingPayment = false;
      });

      print(result);

      if (result["status"] == "success") {
        if (result["flow"] == "wallet") {
          _showSnack(
            "Payment completed successfully",
            success: true,
          );
        } else if (result["flow"] == "razorpay") {
          final razorpayData = result["razorpay"];

          print(
            "Razorpay Order Id: ${razorpayData["order_id"]}",
          );

          print(
            "Amount: ${razorpayData["amount"]}",
          );

          _showSnack(
            "Order created successfully",
            success: true,
          );

          // Open Razorpay here
        }
      }else {
        _showSnack(
          result["message"] ?? "Payment failed",
        );
      }
    } catch (e) {
      setState(() {
        _processingPayment = false;
      });

      _showSnack(
        "Error: $e",
      );
    }
  }
  // ─── Dialogs / Snackbars ───────────────────────────────────────────────────

  void _showSnack(String message, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: success ? const Color(0xFF474DC5) : null,
    ));
  }

  // void _showSuccessDialog(String orderId) {
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (ctx) => AlertDialog(
  //       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //       title: const Text('Payment Successful'),
  //       content: Text(
  //         'Your order has been placed successfully!\n\n'
  //             'Package: ${_package!.name}\n'
  //             'Amount Paid: ₹${_finalPayable.toStringAsFixed(2)}\n'
  //             'Order ID: $orderId',
  //         style: GoogleFonts.manrope(),
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.pop(ctx);
  //             Navigator.pop(context);
  //           },
  //           child: const Text('Done'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Need Help?'),
        content: const Text(
          'Contact our support team at support@example.com\nor call +91-XXXXXXXXXX',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F2FF),
      body: SafeArea(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              _buildHeader(),
              if (_loading)
                const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF474DC5))))
              else if (_errorMessage != null)
                Expanded(child: _buildError())
              else
                Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E6F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.arrow_back, color: Color(0xFF474DC5)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Complete Payment',
              style: GoogleFonts.manrope(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF151C27),
              ),
            ),
          ),
          GestureDetector(
            onTap: _showHelpDialog,
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.help_outline, color: Color(0xFF464653)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error state ─────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: Color(0xFFBA1A1A)),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(color: const Color(0xFF464653)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF474DC5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main body ───────────────────────────────────────────────────────────────

  Widget _buildBody() {
    final pkg = _package!;
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderSummaryCard(pkg),
                const SizedBox(height: 24),
                _buildCouponSection(),
                const SizedBox(height: 24),
                _buildWalletSection(),
                const SizedBox(height: 24),
                _buildPriceBreakdown(),
                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
        _buildPayButton(),
      ],
    );
  }

  // ── Order summary ────────────────────────────────────────────────────────────

  Widget _buildOrderSummaryCard(PackageDetails pkg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFFE7EEFE),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.campaign_rounded, color: Color(0xFF474DC5), size: 36),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pkg.name,
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF151C27),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${pkg.pricingType.toUpperCase()} · ${pkg.durationLabel}',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF464653),
                  ),
                ),
                if (pkg.description != null && pkg.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    pkg.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: const Color(0xFF767685),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  '₹${pkg.displayPrice.toStringAsFixed(0)}',
                  style: GoogleFonts.manrope(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF474DC5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Coupon ───────────────────────────────────────────────────────────────────

  Widget _buildCouponSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COUPON CODE',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF464653),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'Enter coupon code',
                  hintStyle: GoogleFonts.manrope(color: const Color(0xFF767685)),
                  prefixIcon: const Icon(Icons.sell, color: Color(0xFF767685), size: 20),
                  border: _inputBorder(),
                  enabledBorder: _inputBorder(),
                  focusedBorder: _inputBorder(focused: true),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _applyingCoupon ? null : _applyCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6067DF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _applyingCoupon
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
                  : Text('Apply', style: GoogleFonts.manrope(fontSize: 14, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        if (_couponDiscount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '✓ Coupon applied — saving ₹${_couponDiscount.toStringAsFixed(2)}',
              style: GoogleFonts.manrope(fontSize: 12, color: const Color(0xFF2E7D32)),
            ),
          ),
      ],
    );
  }

  // ── Wallet ───────────────────────────────────────────────────────────────────

  Widget _buildWalletSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WALLET OPTIONS',
          style: GoogleFonts.manrope(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF464653),
          ),
        ),
        const SizedBox(height: 8),
        _buildWalletCard(
          type: 'ecash',
          label: 'Ecash Balance',
          balance: _ecashBalance,
          icon: Icons.account_balance_wallet,
          iconBg: const Color(0xFFE0E0FF),
          iconColor: const Color(0xFF474DC5),
          balanceColor: const Color(0xFF474DC5),
          isSelected: _isEcashSelected,
          controller: _ecashAmountController,
        ),
        const SizedBox(height: 16),
        _buildWalletCard(
          type: 'ewallet',
          label: 'Ewallet Balance',
          balance: _ewalletBalance,
          icon: Icons.payment,
          iconBg: const Color(0xFFDEDFEC),
          iconColor: const Color(0xFF5C5E69),
          balanceColor: const Color(0xFF60626D),
          isSelected: _isEwalletSelected,
          controller: _ewalletAmountController,
        ),
      ],
    );
  }

  Widget _buildWalletCard({
    required String type,
    required String label,
    required double balance,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required Color balanceColor,
    required bool isSelected,
    required TextEditingController controller,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F3FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? const Color(0xFF474DC5) : const Color(0xFFE6E6F0),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF151C27),
                      ),
                    ),
                    Text(
                      '₹${balance.toStringAsFixed(2)} available',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: balanceColor,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isSelected,
                onChanged: (_) => _toggleWallet(type),
                activeColor: const Color(0xFF474DC5),
              ),
            ],
          ),
          if (isSelected) ...[
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Specify Amount',
                suffixText: 'INR',
                suffixStyle: GoogleFonts.manrope(color: const Color(0xFF464653)),
                border: _inputBorder(),
                enabledBorder: _inputBorder(),
                focusedBorder: _inputBorder(focused: true),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Breakdown ────────────────────────────────────────────────────────────────

  Widget _buildPriceBreakdown() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6F0), width: 2),
      ),
      child: Column(
        children: [
          _breakdownRow('Subtotal', '₹${_productPrice.toStringAsFixed(2)}'),
          const SizedBox(height: 8),
          _breakdownRow(
            'Coupon Discount',
            _couponDiscount > 0 ? '-₹${_couponDiscount.toStringAsFixed(2)}' : '-₹0.00',
            highlight: _couponDiscount > 0,
          ),
          const SizedBox(height: 8),
          _breakdownRow(
            'Wallet Applied',
            _appliedWalletAmount > 0 ? '-₹${_appliedWalletAmount.toStringAsFixed(2)}' : '-₹0.00',
            highlight: _appliedWalletAmount > 0,
          ),
          const Divider(height: 24, color: Color(0xFFE6E6F0)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TOTAL PAYABLE',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF151C27),
                  letterSpacing: 1,
                ),
              ),
              Text(
                '₹${_finalPayable.toStringAsFixed(2)}',
                style: GoogleFonts.manrope(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF151C27),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _breakdownRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.manrope(fontSize: 14, color: const Color(0xFF464653))),
        Text(
          value,
          style: GoogleFonts.manrope(
            fontSize: 14,
            color: highlight ? const Color(0xFFBA1A1A) : const Color(0xFF464653),
          ),
        ),
      ],
    );
  }

  // ── Pay button ───────────────────────────────────────────────────────────────

  Widget _buildPayButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E6F0))),
      ),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _processingPayment ? null : _processPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF7C83FD).withOpacity(0.6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 8,
                shadowColor: const Color(0xFF7C83FD).withOpacity(0.3),
              ),
              child: _processingPayment
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock, color: Colors.white, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Pay ₹${_finalPayable.toStringAsFixed(2)}',
                    style: GoogleFonts.manrope(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 14, color: Color(0xFF767685)),
              const SizedBox(width: 4),
              Text(
                'Secure 256-bit SSL Encrypted Payment',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF767685),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  OutlineInputBorder _inputBorder({bool focused = false}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: focused ? const Color(0xFF474DC5) : const Color(0xFFE6E6F0)),
    );
  }
}

// ─── Usage ─────────────────────────────────────────────────────────────────────
// Navigate to this screen by passing the package ID:
//
//   Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (context) => const PaymentScreen(packageId: 42),
//     ),
//   );