import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../Database/Database.dart';
import '../../services/auth_service.dart';

class AppTheme {
  static const Color primary = Color(0xFF7C83FD);
  static const Color primarySoft = Color(0xFFF1F2FF);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE6E6F0);
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class CommunityProfileScreen extends StatefulWidget {
  final String groupId;

  const CommunityProfileScreen({super.key, required this.groupId});

  @override
  State<CommunityProfileScreen> createState() => _CommunityProfileScreenState();
}

class _CommunityProfileScreenState extends State<CommunityProfileScreen> {
  bool _isLoading = true;
  bool _isJoining = false;
  String? _errorMessage;
  Map<String, dynamic> _community = {};
  late Razorpay _razorpay;
  String? _pendingPaymentVendorId;
  String? _pendingOrderId; // DB order_id from make_payment response

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _fetchCommunityDetails();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final vendorId = _pendingPaymentVendorId;
    if (vendorId == null || vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment completed, but join context was lost.'), backgroundColor: Colors.red),
      );
      return;
    }

    _verifyCommunityPayment(vendorId, response);
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: Colors.red),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  /// Check if the API response indicates success
  bool _isSuccessResponse(Map response) {
    if (response['success'] == true) return true;
    if (response['status'] == 200) return true;
    if (response['status'] == 'success') return true;
    if (response.containsKey('data') &&
        response['status'] != 300 &&
        response['error'] == null) return true;
    return false;
  }

  Future<void> _fetchCommunityDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vendorId = await AuthService.getVendorIdString();
      final database = Database();
      final response = await database.getData({
        'action': 'community_details',
        'group_id': widget.groupId,
        'vendor_id': vendorId,
      });

      print('📩 Community Details Response: $response');

      if (_isSuccessResponse(response)) {
        setState(() {
          _community = Map<String, dynamic>.from(response['data'] ?? {});
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ?? 'Failed to load community';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error fetching community details: $e');
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinCommunity() async {
    setState(() => _isJoining = true);
    try {
      final vendorIdInt = await AuthService.getVendorId();
      final vendorId = vendorIdInt?.toString() ?? '';
      final joiningRule = _community['joining_rule']?.toString() ?? 'free';
      final joiningFee = double.tryParse(_community['joining_fee']?.toString() ?? '0') ?? 0.0;

      // For paid communities - show payment dialog
      if (joiningRule != 'free' && joiningFee > 0) {
        setState(() => _isJoining = false);
        _showPaymentDialog(vendorId);
        return;
      }

      // For free communities - direct join
      final database = Database();
      final response = await database.getData({
        'action': 'join_community',
        'group_id': widget.groupId,
        'vendor_id': vendorId,
      });

      print('📩 Join Community Response: $response');

      if (_isSuccessResponse(response)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Joined successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchCommunityDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to join community'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error joining community: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isJoining = false);
    }
  }

  void _showPaymentDialog(String vendorId) {
    final joiningFee = double.tryParse(_community['joining_fee']?.toString() ?? '0') ?? 0.0;
    final title = _community['community_title']?.toString() ?? 'Community';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Join Premium Community'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Text('Joining Fee: ', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    '₹${joiningFee.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C3AED),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Pay the joining fee to become a member of this exclusive community and access all content.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initiatePayment(vendorId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
            ),
            child: Text('Pay ₹${joiningFee.toStringAsFixed(0)}'),
          ),
        ],
      ),
    );
  }

  void _initiatePayment(String vendorId) async {
    try {
      final db = Database();

      print('🔄 Initiating payment for community: ${widget.groupId}, vendor: $vendorId');

      Map<String, String> postBody = {
        'action': 'make_payment',
        'community_id': widget.groupId,
        'vendor_id': vendorId,
      };

      final paymentResponse = await db.getData(postBody);
      print('📩 make_payment response: $paymentResponse');

      if (!_isSuccessResponse(paymentResponse)) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(paymentResponse['error']?.toString() ?? paymentResponse['message']?.toString() ?? 'Payment gateway error'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // ✅ Get key from response directly (backend now returns it)
      final String key = paymentResponse['razorpay_key']?.toString() ??
          await db.getRazorpayKey() ??
          '';
      final String razorpayOrderId = paymentResponse['razorpay_order_id']?.toString() ?? '';
      // ✅ Store DB order_id so verify doesn't depend on server session
      _pendingOrderId = paymentResponse['order_id']?.toString() ?? '';
      final double joiningFee = double.tryParse(
              paymentResponse['amount_to_pay']?.toString() ??
              _community['joining_fee']?.toString() ??
              '0') ??
          0.0;

      if (key.isEmpty || razorpayOrderId.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment initialization failed: missing key or order ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      _pendingPaymentVendorId = vendorId;

      var options = {
        'key': key,
        'amount': (joiningFee * 100).toInt(),
        'order_id': razorpayOrderId,
        'name': _community['community_title'] ?? 'Community',
        'description': 'Community Joining Fee',
        'prefill': {'contact': '', 'email': ''},
        'external': {
          'wallets': ['paytm']
        }
      };

      print('🚀 Opening Razorpay with key: ${key.substring(0, 8)}..., order: $razorpayOrderId, amount: ${(joiningFee * 100).toInt()}');
      _razorpay.open(options);
    } catch (e) {
      print('❌ _initiatePayment error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _verifyCommunityPayment(String vendorId, PaymentSuccessResponse response) async {
    try {
      final database = Database();

      // ✅ Send our DB order_id (not just Razorpay's order_id) so backend
      // can find the order without relying on session (stateless Flutter requests)
      final String dbOrderId = _pendingOrderId ?? '';
      final String razorpayOrderId = response.orderId ?? '';

      print('🔄 Verifying payment: dbOrderId=$dbOrderId, razorpayOrderId=$razorpayOrderId, paymentId=${response.paymentId}');

      final verifyResponse = await database.getData({
        'verifyCommunityPayment': '1',
        'community_id': widget.groupId,
        'vendor_id': vendorId,
        'payment_id': response.paymentId ?? '',
        'order_id': dbOrderId,            // ✅ Our DB order_id
        'razorpay_order_id': razorpayOrderId, // ✅ Razorpay order id for signature verify
        'signature': response.signature ?? '',
      });

      print('📩 verifyCommunityPayment response: $verifyResponse');

      if (!mounted) return;

      if (_isSuccessResponse(verifyResponse)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🎉 Successfully joined the community!'),
            backgroundColor: Colors.green,
          ),
        );
        _fetchCommunityDetails();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(verifyResponse['error']?.toString() ??
                verifyResponse['message']?.toString() ??
                'Payment verified, but joining failed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ _verifyCommunityPayment error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying payment: $e'), backgroundColor: Colors.red),
      );
    } finally {
      _pendingPaymentVendorId = null;
      _pendingOrderId = null;
    }
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Community'),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _errorMessage != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.primarySoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.error_outline, color: AppTheme.primary, size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchCommunityDetails,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    // Extract fields from API response
    final String title = _community['community_title']?.toString() ?? 'Unknown Community';
    final String description = _community['description']?.toString() ?? '';
    final String visibility = _community['visibility']?.toString() ?? 'public';
    final String joiningRule = _community['joining_rule']?.toString() ?? 'free';
    final String communityType = _community['community_type']?.toString() ?? '';
    final int memberCount = int.tryParse(_community['member_count']?.toString() ?? '0') ?? 0;
    final int views = int.tryParse(_community['views']?.toString() ?? '0') ?? 0;
    final String coverImage = _community['cover_image']?.toString() ?? '';
    final String logo = _community['logo']?.toString() ?? '';
    final String tagsRaw = _community['tags']?.toString() ?? '';
    final String? myRole = _community['my_role']?.toString();
    final String? myJoinStatus = _community['my_join_status']?.toString();
    final bool isOwner = _community['is_owner']?.toString() == '1' || _community['is_owner'] == true;

    final bool alreadyJoined = myRole != null && myJoinStatus == 'approved';
    final bool isPending = myJoinStatus == 'pending';

    // Parse tags
    final List<String> tags = tagsRaw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Build initials from title
    final String initials = title
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    // Determine joining rule display
    String joiningRuleDisplay;
    IconData joiningIcon;
    if (joiningRule == 'free' || joiningRule == 'Free') {
      joiningRuleDisplay = 'Free to Join';
      joiningIcon = Icons.lock_open_outlined;
    } else if (joiningRule == 'approval') {
      joiningRuleDisplay = 'Requires Approval';
      joiningIcon = Icons.verified_user_outlined;
    } else {
      joiningRuleDisplay = 'Pay $joiningRule to Join';
      joiningIcon = Icons.payments_outlined;
    }

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner & Logo Section
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner image
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: coverImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(coverImage),
                          fit: BoxFit.cover,
                        )
                      : null,
                  gradient: coverImage.isEmpty
                      ? const LinearGradient(
                          colors: [Color(0xff8F7CFF), Color(0xffB5ACFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                ),
                child: coverImage.isEmpty
                    ? const Center(
                        child: Icon(Icons.group, color: Colors.white, size: 60),
                      )
                    : null,
              ),
              // Logo circle
              Positioned(
                bottom: -40,
                left: 20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: logo.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(logo),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: logo.isEmpty
                      ? Center(
                          child: Text(
                            initials,
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),

          // Header Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMain,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${visibility[0].toUpperCase()}${visibility.substring(1)} Group',
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '• ${_formatCount(memberCount)} Members',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    if (views > 0)
                      Text(
                        '• ${_formatCount(views)} Views',
                        style: const TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
                if (communityType.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    communityType,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Joining Rule Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(joiningIcon, color: AppTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Joining Rule',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          joiningRuleDisplay,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action Button
          if (!isOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: (alreadyJoined || isPending || _isJoining)
                      ? null
                      : _joinCommunity,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: alreadyJoined
                        ? Colors.green
                        : isPending
                            ? Colors.orange
                            : AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    disabledBackgroundColor: alreadyJoined
                        ? Colors.green.withOpacity(0.7)
                        : isPending
                            ? Colors.orange.withOpacity(0.7)
                            : null,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isJoining
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          alreadyJoined
                              ? 'Already Joined ✓'
                              : isPending
                                  ? 'Request Pending'
                                  : joiningRule == 'free' || joiningRule == 'Free'
                                      ? 'Join Community'
                                : 'Pay ₹${(double.tryParse(_community['joining_fee']?.toString() ?? '0') ?? 0.0).toStringAsFixed(0)} to Join',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),

          if (isOwner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'You own this community',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 20),

          // Tags
          if (tags.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: tags.map((tag) => _buildTag('#$tag')).toList(),
              ),
            ),
          if (tags.isNotEmpty) const SizedBox(height: 32),

          // About Section
          if (description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(color: AppTheme.textMuted, height: 1.6, fontSize: 14),
                  ),
                ],
              ),
            ),
          if (description.isNotEmpty) const SizedBox(height: 32),

          // Why Join Section
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Why Join Us?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
            ),
          ),
          const SizedBox(height: 16),
          _buildBenefitCard(
            icon: Icons.play_circle_outline,
            title: 'Exclusive Content',
            subtitle: 'Access members-only content, discussions, and resources.',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildSmallCard(
                    icon: Icons.people_outline,
                    title: 'Networking',
                    subtitle: 'Connect with ${_formatCount(memberCount)}+ members.',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSmallCard(
                    icon: Icons.verified_user_outlined,
                    title: 'Community',
                    subtitle: 'Be part of a growing community.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Community Info
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Community Info',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckItem('Visibility: ${visibility[0].toUpperCase()}${visibility.substring(1)}'),
          _buildCheckItem('Joining: $joiningRuleDisplay'),
          _buildCheckItem('Members: ${_formatCount(memberCount)}'),
          if (views > 0) _buildCheckItem('Total Views: ${_formatCount(views)}'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildBenefitCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textMain)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }

  Widget _buildSmallCard({required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textMain)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(color: AppTheme.textMuted, fontSize: 11, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildCheckItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, color: AppTheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(color: AppTheme.textMuted, fontSize: 14, height: 1.4))),
        ],
      ),
    );
  }
}
