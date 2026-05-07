import 'package:flutter/material.dart';
import '../../Database/Database.dart';
import '../../services/auth_service.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

void main() {
  runApp(const DiscoverCommunitiesApp());
}

class DiscoverCommunitiesApp extends StatelessWidget {
  const DiscoverCommunitiesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Discover Communities',
      theme: AppTheme.theme,
      home: const DiscoverCommunitiesScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF7C83FD);
  static const Color primarySoft = Color(0xFFF1F2FF);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE6E6F0);
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}

class Community {
  final String id;
  final String name;
  final String members;
  final String status;
  final String price;
  final String joiningRule;
  final double joiningFee;
  final String? badge;
  final List<String> tags;
  final String bannerUrl;
  final String logoInitials;
  bool isJoined;
  bool isLoading;

  Community({
    required this.id,
    required this.name,
    required this.members,
    required this.status,
    required this.price,
    required this.joiningRule,
    required this.joiningFee,
    this.badge,
    required this.tags,
    required this.bannerUrl,
    required this.logoInitials,
    this.isJoined = false,
    this.isLoading = false,
  });
}

class DiscoverCommunitiesScreen extends StatefulWidget {
  const DiscoverCommunitiesScreen({super.key});

  @override
  State<DiscoverCommunitiesScreen> createState() => _DiscoverCommunitiesScreenState();
}

class _DiscoverCommunitiesScreenState extends State<DiscoverCommunitiesScreen> {
  String selectedCategory = 'All';
  final List<String> categories = ['All', 'Development', 'Design', 'Artificial Intelligence', 'Business'];
  List<Community> communities = [];
  bool isLoading = true;
  late Razorpay _razorpay;
  String? razorpayKey;
  Community? _pendingPaymentCommunity;
  String? _pendingPaymentVendorId;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadCommunities();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    final community = _pendingPaymentCommunity;
    final vendorId = _pendingPaymentVendorId;

    if (community == null || vendorId == null || vendorId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment completed, but join context was lost.'), backgroundColor: Colors.red),
      );
      return;
    }

    _verifyCommunityPayment(community, vendorId, response);
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

  Future<void> _loadCommunities() async {
    try {
      setState(() => isLoading = true);
      final db = Database();
      final vendorIdInt = await AuthService.getVendorId();
      final vendorId = vendorIdInt?.toString() ?? '';
      
      Map<String, String> postBody = {
        'action': 'search_communities',
        'vendor_id': vendorId,
        'search': '',
      };
      
      final response = await db.getData(postBody);
      
      if (_isSuccessResponse(response)) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          communities = data.map((community) {
            final joiningFee = double.tryParse(
                  community['joining_fee']?.toString() ?? '0',
                ) ??
                0.0;
            final price = joiningFee > 0 ? '₹${joiningFee.toStringAsFixed(0)}' : 'Free';
            return Community(
              id: community['id']?.toString() ?? '',
              name: community['community_title'] ?? 'Unknown',
              members: community['member_count']?.toString() ?? '0',
              status: community['status']?.toString().toUpperCase() == 'ACTIVE' ? 'ONLINE' : 'OFFLINE',
              price: price,
              joiningRule: community['joining_rule'] ?? 'free',
              joiningFee: joiningFee,
              tags: [community['tags']?.toString() ?? '#General'],
              bannerUrl: community['cover_image'] ??
                  'https://images.unsplash.com/photo-1617042375876-a13e36734a04?auto=format&fit=crop&q=80&w=400',
              logoInitials: (community['community_title'] ?? 'C').substring(0, 1).toUpperCase(),
            );
          }).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['message'] ?? 'Failed to load communities'}')),
        );
      }
      
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading communities: $e')),
      );
    }
  }

  bool _isSuccessResponse(dynamic response) {
    return response != null && response['success'] == true;
  }

  Future<void> _joinCommunity(Community community) async {
    try {
      setState(() => community.isLoading = true);
      
      final db = Database();
      final vendorIdInt = await AuthService.getVendorId();
      final vendorId = vendorIdInt?.toString() ?? '';
      
      // For paid communities - show payment dialog and payment flow
      if (community.joiningRule != 'free' && community.joiningFee > 0) {
        setState(() => community.isLoading = false);
        _showPaymentDialog(community, vendorId);
        return;
      }
      
      // For free communities - direct join
      Map<String, String> postBody = {
        'action': 'join_community',
        'community_id': community.id,
        'vendor_id': vendorId,
      };
      
      final response = await db.getData(postBody);
      
      if (_isSuccessResponse(response)) {
        setState(() {
          community.isJoined = true;
          community.isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined community!'), backgroundColor: Colors.green),
        );
      } else {
        setState(() => community.isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${response['message'] ?? 'Failed to join'}')),
        );
      }
    } catch (e) {
      setState(() => community.isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showPaymentDialog(Community community, String vendorId) {
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
              community.name,
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
                    '₹${community.joiningFee.toStringAsFixed(0)}',
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
              _initiatePayment(community, vendorId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
            ),
            child: Text('Pay ₹${community.joiningFee.toStringAsFixed(0)}'),
          ),
        ],
      ),
    );
  }

  void _initiatePayment(Community community, String vendorId) async {
    try {
      final db = Database();
      
      Map<String, String> postBody = {
        'make_payment': '1',
        'community_id': community.id,
        'vendor_id': vendorId,
      };
      
      final paymentResponse = await db.getData(postBody);

      if (!_isSuccessResponse(paymentResponse)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(paymentResponse['message']?.toString() ?? paymentResponse['error']?.toString() ?? 'Payment gateway error')),
        );
        return;
      }

      final String key = (await db.getRazorpayKey()) ?? paymentResponse['razorpay_key']?.toString() ?? paymentResponse['key']?.toString() ?? '';
      final String razorpayOrderId = paymentResponse['razorpay_order_id']?.toString() ?? '';
      final double amountToPay = double.tryParse(paymentResponse['amount_to_pay']?.toString() ?? community.joiningFee.toString()) ?? community.joiningFee;

      if (key.isEmpty || razorpayOrderId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment initialization failed')),
        );
        return;
      }

      _pendingPaymentCommunity = community;
      _pendingPaymentVendorId = vendorId;
      
      var options = {
        'key': key,
        'amount': (amountToPay * 100).toInt(),
        'order_id': razorpayOrderId,
        'name': community.name,
        'description': 'Community Joining Fee',
        'prefill': {'contact': '', 'email': ''},
        'external': {
          'wallets': ['paytm']
        }
      };
      
      _razorpay.open(options);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment error: $e')),
      );
    }
  }

  Future<void> _verifyCommunityPayment(
    Community community,
    String vendorId,
    PaymentSuccessResponse response,
  ) async {
    try {
      final db = Database();
      final verifyResponse = await db.getData({
        'verifyCommunityPayment': '1',
        'community_id': community.id,
        'vendor_id': vendorId,
        'payment_id': response.paymentId ?? '',
        'order_id': response.orderId ?? '',
        'signature': response.signature ?? '',
      });

      if (_isSuccessResponse(verifyResponse)) {
        final int index = communities.indexWhere((c) => c.id == community.id);
        if (index != -1) {
          setState(() {
            communities[index].isJoined = true;
            communities[index].isLoading = false;
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully joined community!'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(verifyResponse['message']?.toString() ?? verifyResponse['error']?.toString() ?? 'Payment verified, but joining failed')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying payment: $e')),
      );
    } finally {
      _pendingPaymentCommunity = null;
      _pendingPaymentVendorId = null;
    }
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
          icon: const Icon(Icons.menu),
          onPressed: () {},
        ),
        title: const Text('Discover'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search communities...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppTheme.textMuted),
                ),
              ),
            ),
          ),

          // Categories Slider
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: categories.map((cat) {
                bool active = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(cat),
                    selected: active,
                    onSelected: (val) => setState(() => selectedCategory = cat),
                    selectedColor: AppTheme.primary,
                    backgroundColor: Colors.white,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppTheme.textMuted,
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: active ? AppTheme.primary : AppTheme.border),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          // Communities Grid
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : GridView.count(
                    crossAxisCount: 1,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                    children: communities.map((community) => _buildCommunityCard(community)).toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primary,
        unselectedItemColor: AppTheme.textMuted,
        currentIndex: 1,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Discover'),
          BottomNavigationBarItem(icon: Icon(Icons.group_outlined), label: 'Groups'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // Banner Image
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                child: Image.network(
                  community.bannerUrl,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              if (community.badge != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars, color: AppTheme.warning, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          community.badge!,
                          style: const TextStyle(color: AppTheme.warning, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              Positioned(
                bottom: -20,
                left: 20,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      community.logoInitials,
                      style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 25),

          // Community Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      community.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: community.status == 'ONLINE' ? AppTheme.success : AppTheme.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            community.status,
                            style: TextStyle(
                              color: community.status == 'ONLINE' ? AppTheme.success : AppTheme.warning,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '👥 ${community.members} Members',
                      style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: community.joiningRule == 'free' ? const Color(0xFFD1FAE5) : const Color(0xFFEDE9FE),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        community.joiningRule == 'free'
                            ? 'Free'
                            : '₹${community.joiningFee.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: community.joiningRule == 'free' ? const Color(0xFF059669) : const Color(0xFF7C3AED),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: community.tags.map((tag) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.border),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('View', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: community.isLoading
                            ? null
                            : () => _joinCommunity(community),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: community.isLoading
                            ? const SizedBox(
                                height: 16,
                                width: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                              )
                            : Text(
                                community.isJoined
                                    ? 'Joined ✓'
                                    : community.joiningRule == 'free'
                                        ? 'Join Free'
                                        : 'Pay ₹${community.joiningFee.toStringAsFixed(0)} to Join',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
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
}

