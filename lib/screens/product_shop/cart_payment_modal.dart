import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../Database/Database.dart';
import '../../core/theme/app_colors.dart';
import '../../services/payment_api_service.dart';
import 'cart_item.dart';
import 'payment_success_screen.dart';

/// Cart Payment Modal
/// Specifically designed for cart checkout with address and delivery integration
class CartPaymentModal extends StatefulWidget {
  final double amount;
  final String orderId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<String> cartItems; // Cart item IDs
  final VoidCallback? onPaymentComplete;

  const CartPaymentModal({
    super.key,
    required this.amount,
    required this.orderId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.cartItems,
    this.onPaymentComplete,
  });

  @override
  State<CartPaymentModal> createState() => _CartPaymentModalState();
}

class _CartPaymentModalState extends State<CartPaymentModal> {
  // Form Controllers
  final TextEditingController _pincodeController = TextEditingController();
  final TextEditingController _fullnameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();

  // State Variables
  bool _isLoadingAddresses = false;
  bool _isLoadingDelivery = false;
  bool _isLoadingBalances = false;
  bool _isProcessingPayment = false;
  bool _useNewAddress = false;
  bool _deliveryAvailable = false;
  double _deliveryPrice = 0.0;
  double _couponDiscount = 0.0;
  String _selectedAddressId = '';
  String _paymentMode = 'RAZORPAY'; // RAZORPAY, WALLET, COD
  
  // Data
  List<Map<String, dynamic>> _addresses = [];
  Map<String, dynamic> _paymentSummary = {};
  double _eCashBalance = 0.0;
  double _eWalletBalance = 0.0;
  double _useFromEbanking = 0.0;
  double _useFromEwallet = 0.0;

  // Services
  final PaymentApiService _paymentApiService = PaymentApiService();
  final Database _database = Database();

  // Razorpay
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadData();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadAddresses(),
      _loadBalances(),
    ]);
  }

  Future<void> _loadAddresses() async {
    if (_isLoadingAddresses) return;
    setState(() => _isLoadingAddresses = true);
    try {
      // Check session before making API call
      final sessionId = await _database.getSessionId();
      if (sessionId == null) {
        debugPrint("❌ No session found - user not logged in");
        _showMessage("Please login to view addresses");
        setState(() {
          _addresses = [];
          _selectedAddressId = '';
        });
        return;
      }
      
      // NOTE: Backend may return plain-text "Access Denied" when pincode is sent
      // with get_all_address; keep request minimal and pincode-agnostic.
      final requestData = {
        "action": "get_all_address",
      };
      
      debugPrint("📍 Address API Request: $requestData");
      
      // Get session info for debugging
      final currentSessionId = await _database.getSessionId();
      debugPrint("🆔 Current Session ID: $currentSessionId");
      
      final response = await _database.getData(requestData);

      debugPrint("📍 Address API Response: $response");
      debugPrint("📍 Session after address call: ${await _database.getSessionId()}");
      debugPrint("📍 Response Type: ${response.runtimeType}");

      // Handle different response structures
      if (response == null) {
        debugPrint("❌ Null response from address API");
        setState(() {
          _addresses = [];
          _selectedAddressId = '';
        });
      } else if (response['success'] == true && response['data'] != null) {
        // Handle success response with data
        final addressesData = response['data'];
        debugPrint("📍 Addresses Data Type: ${addressesData.runtimeType}");
        debugPrint("📍 Addresses Data: $addressesData");
        
        List<Map<String, dynamic>> addressList = [];
        
        if (addressesData is Map && addressesData['addresses'] != null) {
          addressList = List<Map<String, dynamic>>.from(addressesData['addresses']);
        } else if (addressesData is List) {
          addressList = List<Map<String, dynamic>>.from(addressesData);
        }
        
        setState(() {
          _addresses = addressList;
          if (_addresses.isNotEmpty && _selectedAddressId.isEmpty) {
            _selectedAddressId = _addresses[0]['id']?.toString() ?? '';
          }
        });

        // Auto-select first address and fetch delivery options.
        if (_addresses.isNotEmpty) {
          final selectedAddress = _addresses.firstWhere(
            (addr) => addr['id']?.toString() == _selectedAddressId,
            orElse: () => _addresses.first,
          );
          _pincodeController.text = selectedAddress['pincode']?.toString() ?? '';
          if (_pincodeController.text.isNotEmpty) {
            await _checkDeliveryAvailability();
          }
        }

        debugPrint("✅ Loaded ${_addresses.length} addresses");
      } else if (response['status'] == 401 || response['error']?.toString().toLowerCase().contains('unauthorized') == true) {
        // Handle session expired/unauthorized
        debugPrint("❌ Session expired or unauthorized");
        _showMessage("Session expired. Please login again");
        setState(() {
          _addresses = [];
          _selectedAddressId = '';
        });
      } else if (response['status'] == 300 || response['error'] != null) {
        final rawResponse = response['raw_response']?.toString().toLowerCase() ?? '';
        if (rawResponse.contains('access denied')) {
          debugPrint("⚠️ Address API returned Access Denied; keeping cached addresses");

          // Keep old addresses instead of clearing, so checkout can continue.
          if (_addresses.isNotEmpty) {
            if (_selectedAddressId.isEmpty) {
              _selectedAddressId = _addresses.first['id']?.toString() ?? '';
            }

            final selectedAddress = _addresses.firstWhere(
              (addr) => addr['id']?.toString() == _selectedAddressId,
              orElse: () => _addresses.first,
            );
            _pincodeController.text = selectedAddress['pincode']?.toString() ?? _pincodeController.text;
            return;
          }
        }

        // Handle server error
        debugPrint("❌ Server error: ${response['error'] ?? 'Unknown error'}");
        debugPrint("❌ Full error response: $response");
        setState(() {
          _addresses = [];
          _selectedAddressId = '';
        });
      } else {
        // Handle other response formats
        debugPrint("❌ Unexpected response format or no addresses found");
        debugPrint("❌ Response keys: ${response.keys.toList()}");
        setState(() {
          _addresses = [];
          _selectedAddressId = '';
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading addresses: $e");
      debugPrint("❌ Error type: ${e.runtimeType}");
      setState(() {
        _addresses = [];
        _selectedAddressId = '';
      });
    } finally {
      setState(() => _isLoadingAddresses = false);
    }
  }

  Future<void> _loadBalances() async {
    setState(() => _isLoadingBalances = true);
    try {
      // Check session before making API call
      final sessionId = await _database.getSessionId();
      if (sessionId == null) {
        debugPrint("❌ No session found - user not logged in");
        setState(() {
          _eCashBalance = 0.0;
          _eWalletBalance = 0.0;
        });
        return;
      }
      
      // Debug session before balances call
      final sessionIdBeforeBalances = await _database.getSessionId();
      debugPrint("💰 Session ID before balances: $sessionIdBeforeBalances");
      
      final balances = await _paymentApiService.getBalances();
      
      // Debug session after balances call  
      final sessionIdAfterBalances = await _database.getSessionId();
      debugPrint("💰 Session ID after balances: $sessionIdAfterBalances");
      
      setState(() {
        _eCashBalance = balances['ecash_balance'] ?? 0.0;
        _eWalletBalance = balances['ewallet_balance'] ?? 0.0;
      });
      
      debugPrint("✅ Balances loaded successfully");
      debugPrint("💰 ECash Balance: ₹$_eCashBalance");
      debugPrint("💰 EWallet Balance: ₹$_eWalletBalance");
      
    } catch (e) {
      debugPrint("❌ Error loading balances: $e");
      setState(() {
        _eCashBalance = 0.0;
        _eWalletBalance = 0.0;
      });
    } finally {
      setState(() => _isLoadingBalances = false);
    }
  }

  Future<void> _checkDeliveryAvailability() async {
    if (_pincodeController.text.isEmpty) {
      _showMessage("Please enter pincode first");
      return;
    }

    setState(() => _isLoadingDelivery = true);
    try {
      final requestData = {
        "action": "is_delivery_services",
        "logistic_id": "1,2,3", // Required logistic provider IDs
        "pincode": _pincodeController.text,
        "all_marketplace_id": widget.cartItems.join(','),
      };
      
      debugPrint("🚚 Delivery API Request: $requestData");
      
      final response = await _database.getData(requestData);

      debugPrint("🚚 Delivery API Response: $response");
      debugPrint("🚚 Response Type: ${response.runtimeType}");
      debugPrint("🚚 Response keys: ${response.keys.toList()}");
      debugPrint("🚚 Success check: ${response['success']} - Available check: ${response['available']}");

      if (response == null) {
        debugPrint("❌ Null response from delivery API");
        setState(() {
          _deliveryAvailable = false;
          _deliveryPrice = 0.0;
        });
        _showMessage("Unable to check delivery availability");
      } else if (response['success'] == true || response['success'] == 'success' || response['available'] == true) {
        setState(() {
          _deliveryAvailable = true;
          _deliveryPrice = double.tryParse(response['price']?.toString() ?? '0') ?? 0.0;
        });
        debugPrint("✅ Delivery available: ₹$_deliveryPrice");
      } else if (response['status'] == 300 || response['error'] != null) {
        debugPrint("❌ Delivery API error: ${response['error'] ?? 'Unknown error'}");
        debugPrint("❌ Full delivery error response: $response");
        setState(() {
          _deliveryAvailable = false;
          _deliveryPrice = 0.0;
        });
        _showMessage("Delivery service temporarily unavailable");
      } else {
        setState(() {
          _deliveryAvailable = false;
          _deliveryPrice = 0.0;
        });
        _showMessage("Delivery not available for this pincode");
        debugPrint("❌ Delivery not available");
        debugPrint("❌ Response keys: ${response.keys.toList()}");
      }
    } catch (e) {
      debugPrint("❌ Error checking delivery: $e");
      debugPrint("❌ Error type: ${e.runtimeType}");
      setState(() {
        _deliveryAvailable = false;
        _deliveryPrice = 0.0;
      });
      _showMessage("Error checking delivery availability");
    } finally {
      setState(() => _isLoadingDelivery = false);
    }
  }

  Future<void> _addNewAddress() async {
    if (_fullnameController.text.isEmpty ||
        _addressController.text.isEmpty ||
        _pincodeController.text.isEmpty ||
        _mobileController.text.isEmpty) {
      _showMessage("Please fill all required fields");
      return;
    }

    try {
      // Check session before making API call
      final sessionId = await _database.getSessionId();
      if (sessionId == null) {
        debugPrint("❌ No session found - user not logged in");
        _showMessage("Please login to add addresses");
        return;
      }
      
      final response = await _database.getData({
        "action": "add_new_address",
        "fullname": _fullnameController.text,
        "form_address": _addressController.text,
        "landmark": _landmarkController.text,
        "zip_code": _pincodeController.text,
        "mobile": _mobileController.text,
        "add_type": "Home",
        "default_add": "0",
      });

      debugPrint("🏠 Add Address API Response: $response");

      if (response == null) {
        debugPrint("❌ Null response from add address API");
        _showMessage("Unable to add address. Please try again.");
      } else if (response['success'] == true) {
        _showMessage("Address added successfully");
        setState(() => _useNewAddress = false);
        _loadAddresses(); // Reload addresses
        debugPrint("✅ Address added successfully");
      } else if (response['status'] == 300 || response['error'] != null) {
        debugPrint("❌ Add address API error: ${response['error'] ?? 'Unknown error'}");
        _showMessage("Server error. Please try again later.");
      } else {
        final errorMessage = response['message']?.toString() ?? 'Failed to add address';
        _showMessage(errorMessage);
        debugPrint("❌ Failed to add address: $errorMessage");
      }
    } catch (e) {
      debugPrint("Error adding address: $e");
      _showMessage("Error adding address. Please try again.");
    }
  }

  double get _totalAmount {
    return widget.amount + _deliveryPrice - _couponDiscount;
  }

  double get _remainingAmount {
    return _totalAmount - _useFromEbanking - _useFromEwallet;
  }

  Future<void> _setPaymentSession() async {
    try {
      final response = await _database.getData({
        "action": "set_session_payment_value",
        "updateEbank": _useFromEbanking.toString(),
        "ewallet": _useFromEwallet.toString(),
        "address": _selectedAddressId,
        "payment_mode": _paymentMode,
      });

      debugPrint("💳 Payment Session API Response: $response");

      if (response == null) {
        debugPrint("❌ Null response from payment session API");
      } else if (response['success'] == true) {
        debugPrint("✅ Payment session set successfully");
      } else if (response['status'] == 300 || response['error'] != null) {
        debugPrint("❌ Payment session API error: ${response['error'] ?? 'Unknown error'}");
      } else {
        debugPrint("❌ Failed to set payment session: ${response['message'] ?? 'Unknown error'}");
      }
    } catch (e) {
      debugPrint("Error setting payment session: $e");
    }
  }

  Future<void> _proceedToPayment() async {
    // Ensure address and delivery availability are resolved before checkout.
    if (_addresses.isEmpty) {
      await _loadAddresses();
    }

    if (_addresses.isEmpty) {
      _showMessage("No address found. Please add a delivery address.");
      return;
    }

    if (_selectedAddressId.isEmpty) {
      final fallbackAddress = _addresses.first;
      setState(() {
        _selectedAddressId = fallbackAddress['id']?.toString() ?? '';
      });
      _pincodeController.text = fallbackAddress['pincode']?.toString() ?? '';
    }

    if (_pincodeController.text.isEmpty) {
      final selectedAddress = _addresses.firstWhere(
        (addr) => addr['id']?.toString() == _selectedAddressId,
        orElse: () => _addresses.first,
      );
      _pincodeController.text = selectedAddress['pincode']?.toString() ?? '';
    }

    await _checkDeliveryAvailability();

    if (!_deliveryAvailable) {
      _showMessage("Delivery not available for this pincode");
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      debugPrint("🔄 Setting payment session...");
      
      // Set payment session
      await _setPaymentSession();
      
      debugPrint("✅ Payment session set successfully");
      debugPrint("💰 Proceeding with wallet payment");
      debugPrint("📊 E-Cash: ₹$_useFromEbanking, E-Wallet: ₹$_useFromEwallet");
      
      // For wallet payment, we can directly complete the order
      // or integrate with Razorpay for remaining amount
      if (_remainingAmount > 0) {
        // If there's remaining amount after wallet adjustment, use Razorpay
        await _initiateRazorpayPayment();
      } else {
        // Full payment covered by wallet
        await _completeWalletPayment();
      }
      
    } catch (e) {
      debugPrint("❌ Payment processing error: $e");
      _showMessage("Payment failed: ${e.toString()}");
    } finally {
      setState(() => _isProcessingPayment = false);
    }
  }

  Future<void> _completeWalletPayment() async {
    // Simulate wallet payment completion
    await Future.delayed(const Duration(seconds: 2));
    
    _showMessage("Payment completed successfully!");
    
    // Call payment complete callback
    if (widget.onPaymentComplete != null) {
      widget.onPaymentComplete!();
    }
    
    Navigator.of(context).pop();
  }

  Future<void> _initiateRazorpayPayment() async {
    var options = {
      'key': 'rzp_test_1DP5mmOlF5G5ag', // Test key
      'amount': (_remainingAmount * 100).toInt(),
      'name': widget.customerName,
      'description': 'Cart Purchase',
      'prefill': {
        'contact': widget.customerPhone,
        'email': widget.customerEmail,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
      _showMessage("Payment gateway error");
    }
  }

  void _calculateRemaining() {
    setState(() {
      // This will trigger a rebuild with updated _remainingAmount
    });
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
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
      
      if (widget.onPaymentComplete != null) {
        widget.onPaymentComplete!();
      }
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) {
      _showMessage('Payment Failed: ${response.message ?? 'Unknown error'}');
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) {
      _showMessage('External wallet selected: ${response.walletName ?? 'Unknown'}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    _pincodeController.dispose();
    _fullnameController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _mobileController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.95,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1, color: AppColors.border),
          Expanded(child: _buildContent()),
          _buildBottomSummary(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 24, color: Colors.white),
          ),
          const Expanded(
            child: Text(
              "Checkout",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 48), // Balance for close button
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDeliveryAddressSection(),
          _buildDeliveryOptionsSection(),
          _buildPaymentMethodSection(),
          _buildOrderSummary(),
          const SizedBox(height: 120), // Space for bottom summary
        ],
      ),
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  "Delivery address",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (!_useNewAddress)
                  TextButton(
                    onPressed: () => setState(() => _useNewAddress = true),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.primary,
                    ),
                    child: const Text("Change"),
                  ),
              ],
            ),
          ),
          if (_useNewAddress)
            _buildNewAddressForm()
          else
            _buildSelectedAddress(),
        ],
      ),
    );
  }

  Widget _buildSelectedAddress() {
    if (_addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text("No delivery addresses found"),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => setState(() => _useNewAddress = true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text("Add a new address"),
              ),
            ),
          ],
        ),
      );
    }

    final selectedAddress = _addresses.isNotEmpty 
        ? _addresses.firstWhere(
            (addr) => addr['id'].toString() == _selectedAddressId,
            orElse: () => _addresses.first,
          )
        : {};

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selectedAddress['name'] ?? 'Unknown',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(selectedAddress['address'] ?? ''),
          if (selectedAddress['landmark'] != null && selectedAddress['landmark'].isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(selectedAddress['landmark']),
          ],
          const SizedBox(height: 4),
          Text("${selectedAddress['pincode'] ?? ''} • ${selectedAddress['mobile'] ?? ''}"),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _useNewAddress = true),
                  child: const Text("Add New Address"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    if (_addresses.length == 1) {
                      // If only one address, use it directly
                      final onlyAddress = _addresses.first;
                      setState(() => _selectedAddressId = onlyAddress['id'].toString());
                      _pincodeController.text = onlyAddress['pincode']?.toString() ?? '';
                      _checkDeliveryAvailability();
                      debugPrint("✅ Used single address directly: ${onlyAddress['name']}");
                    } else {
                      // If multiple addresses, show selection dialog
                      _showAddressSelectionDialog();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(_addresses.length == 1 ? "Use This Address" : "Select Address"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewAddressForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Add a new address",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _fullnameController,
            decoration: const InputDecoration(
              labelText: "Full name *",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: "Address *",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _landmarkController,
            decoration: const InputDecoration(
              labelText: "Landmark (Optional)",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _pincodeController,
                  decoration: const InputDecoration(
                    labelText: "Pincode *",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    if (value.length == 6) {
                      _checkDeliveryAvailability();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    labelText: "Mobile *",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ),
            ],
          ),
          if (_isLoadingDelivery)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text("Checking delivery availability..."),
                ],
              ),
            ),
          if (!_isLoadingDelivery && _deliveryAvailable)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                border: Border.all(color: AppColors.success),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Delivery available • ₹${_deliveryPrice.toStringAsFixed(2)}",
                      style: TextStyle(color: AppColors.success),
                    ),
                  ),
                ],
              ),
            ),
          if (!_isLoadingDelivery && !_deliveryAvailable && _pincodeController.text.length == 6)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                border: Border.all(color: AppColors.error),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      "Delivery not available for this pincode",
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() => _useNewAddress = false);
                },
                child: const Text("Cancel"),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _deliveryAvailable ? _addNewAddress : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text("Add Address"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryOptionsSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  "Delivery options",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_deliveryAvailable)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppColors.success, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Standard Delivery",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              "Estimated delivery: 3-5 business days",
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        "₹${_deliveryPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                else if (_isLoadingDelivery)
                  Row(
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Fetching delivery options...",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  )
                else if (_selectedAddressId.isEmpty)
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.warning, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Select address to fetch delivery options",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.cancel, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Delivery not available for this pincode",
                          style: TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  "Payment Adjustment",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (_isLoadingBalances)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  Text(
                    "Available Balance: ₹${(_eCashBalance + _eWalletBalance).toStringAsFixed(2)}",
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildWalletSlider(
                    title: "E-Cash Balance",
                    balance: _eCashBalance,
                    value: _useFromEbanking,
                    onChanged: (value) {
                      setState(() {
                        _useFromEbanking = value;
                        _calculateRemaining();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildWalletSlider(
                    title: "E-Wallet Balance", 
                    balance: _eWalletBalance,
                    value: _useFromEwallet,
                    onChanged: (value) {
                      setState(() {
                        _useFromEwallet = value;
                        _calculateRemaining();
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletSlider({
    required String title,
    required double balance,
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(
              "Available: ₹${balance.toStringAsFixed(2)}",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.primary,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.1),
          ),
          child: Slider(
            value: value,
            max: balance,
            onChanged: onChanged,
          ),
        ),
        Text(
          "Using: ₹${value.toStringAsFixed(2)}",
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderSummary() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.grey50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.receipt_long_outlined, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text(
                  "Order summary",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _summaryRow("Items (${widget.cartItems.length})", widget.amount),
                _summaryRow("Delivery", _deliveryPrice),
                if (_couponDiscount > 0)
                  _summaryRow("Coupon Discount", -_couponDiscount, isGreen: true),
                _summaryRow("E-Cash Applied", -_useFromEbanking, isGreen: true),
                _summaryRow("E-Wallet Applied", -_useFromEwallet, isGreen: true),
                const Divider(color: AppColors.border),
                _summaryRow("Order Total", _remainingAmount, isBold: true),
                const SizedBox(height: 16),
                TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    labelText: "Enter coupon code",
                    border: const OutlineInputBorder(),
                    suffixIcon: TextButton(
                      onPressed: _applyCoupon,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: const Text("Apply"),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Order Total:",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  "₹${_remainingAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : _proceedToPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: _isProcessingPayment
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
                        "Place Your Order",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "By placing your order, you agree to our terms and conditions",
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddressSelectionDialog() async {
    debugPrint("🏠 Opening address selection dialog");
    debugPrint("🏠 Addresses count: ${_addresses.length}");
    debugPrint("🏠 Addresses data: $_addresses");
    
    if (_addresses.isEmpty) {
      debugPrint("❌ No addresses available to show");
      _showMessage("No addresses available. Please add an address first.");
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select Delivery Address"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _addresses.length,
            itemBuilder: (context, index) {
              final address = _addresses[index];
              final isSelected = address['id'].toString() == _selectedAddressId;
              
              return RadioListTile<String>(
                value: address['id'].toString(),
                groupValue: _selectedAddressId,
                onChanged: (value) {
                  Navigator.of(context).pop(value);
                },
                title: Text(address['name'] ?? 'Unknown'),
                subtitle: Text(
                  "${address['address'] ?? ''}, ${address['pincode'] ?? ''}",
                ),
                dense: true,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );

    if (selected != null) {
      setState(() => _selectedAddressId = selected);
      final selectedAddress = _addresses.firstWhere(
        (addr) => addr['id'].toString() == selected,
      );
      _pincodeController.text = selectedAddress['pincode']?.toString() ?? '';
      _checkDeliveryAvailability();
    }
  }

  Future<void> _applyCoupon() async {
    final couponCode = _couponController.text.trim();
    if (couponCode.isEmpty) {
      setState(() => _couponDiscount = 0.0);
      _showMessage("Please enter a coupon code");
      return;
    }

    try {
      debugPrint("🔄 Applying coupon: $couponCode");
      
      final result = await _paymentApiService.calculateRemaining(
        totalPrice: widget.amount + _deliveryPrice,
        ecashUsed: _useFromEbanking,
        ewalletUsed: _useFromEwallet,
        couponCode: couponCode,
      );
      
      setState(() {
        _couponDiscount = result['coupon_discount'] ?? 0.0;
      });
      
      if (result['coupon_valid'] == true) {
        _showMessage("Coupon applied successfully!");
        debugPrint("✅ Coupon applied: ₹$_couponDiscount discount");
      } else {
        _showMessage(result['coupon_message'] ?? 'Invalid coupon code');
        setState(() => _couponDiscount = 0.0);
      }
      
    } catch (e) {
      debugPrint("❌ Error applying coupon: $e");
      _showMessage("Error applying coupon");
      setState(() => _couponDiscount = 0.0);
    }
  }

  Widget _summaryRow(String label, double amount, {bool isBold = false, bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            amount >= 0 ? "₹${amount.toStringAsFixed(2)}" : "-₹${amount.abs().toStringAsFixed(2)}",
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isGreen ? AppColors.success : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
