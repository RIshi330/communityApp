import 'dart:convert';
import 'dart:developer' as dev;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_constants.dart';
import 'Payment.dart';

class PackageDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> packageData;

  const PackageDetailsScreen({super.key, required this.packageData});

  @override
  State<PackageDetailsScreen> createState() => _PackageDetailsScreenState();
}

class _PackageDetailsScreenState extends State<PackageDetailsScreen> {
  bool isFavorite = false;
  bool isLoading  = false;
  String? fetchError;

  /// Starts as the lightweight list-row data so the screen shows instantly.
  /// Replaced by the full `get_package_details` payload once loaded.
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.packageData);
    _fetchFullDetails();
  }

  // ── Full-detail fetch ──────────────────────────────────────────────────────
  // FIX: the list screen only passes a lightweight row (no description,
  // placements, addons, reach breakdown, community info).
  // We call get_package_details to get the complete data.

  Future<void> _fetchFullDetails() async {
    final id = _toInt(_data['id']);
    //print(id);

    if (id <= 0) {
      setState(() {
        fetchError = 'Invalid Package ID';
      });
      return;
    }

    setState(() {
      isLoading = true;
      fetchError = null;
    });

    // request code here...
    try {
      final response = await http.post(
        Uri.parse('${baseUrl}new_apis/promotion_package_api.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'action': 'get_package_details',
          'id': id.toString(), // send as string
        }),
      );

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['success'] == true) {
          setState(() {
            _data = {
              ..._data,
              ...Map<String, dynamic>.from(json['data']),
            };
            fetchError = null;
            isLoading = false;
          });
        } else {
          setState(() {
            fetchError = json['message'] ?? 'Unknown error';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          fetchError =
          'Server returned ${response.statusCode}\n${response.body}';
          isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('API Error: $e');
      debugPrint('$stackTrace');

      if (mounted) {
        setState(() {
          fetchError = 'Exception: $e';
          isLoading = false;
        });
      }
    }
  }
  // ── Safe type helpers ──────────────────────────────────────────────────────

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  String _str(String key, {String fallback = ''}) {
    final v = _data[key];
    if (v == null) return fallback;
    return v.toString();
  }

  // ── Pricing resolution ─────────────────────────────────────────────────────
  // get_package_details returns:
  //   pricing: { type, fixed_price, base_price, price_per_action, ... }
  // get_packages (list row rawData) returns:
  //   price (flat double), pricing_type (flat string)
  // We handle both so the screen works whether the detail fetch succeeded or not.

  Map<String, dynamic> get _pricingMap {
    final p = _data['pricing'];
    if (p is Map) return Map<String, dynamic>.from(p);
    return {};
  }

  String get _pricingType {
    // flat key from list row
    final flat = (_data['pricing_type'] ?? '').toString();
    if (flat.isNotEmpty) return flat;
    // nested key from details
    return (_pricingMap['type'] ?? '').toString();
  }

  double get _price {
    // flat key (list row)
    final flat = _toDouble(_data['price']);
    if (flat > 0) return flat;
    // nested (details row) — pick whichever sub-field is set
    return _toDouble(
      _pricingMap['fixed_price'] ??
          _pricingMap['base_price']  ??
          _pricingMap['price_per_action'] ??
          0,
    );
  }

  String get _priceUnitLabel {
    switch (_pricingType.toLowerCase()) {
      case 'cpa':    return '/action';
      case 'hybrid': return '/camp. + CPA';
      default:       return '/camp.';
    }
  }

  String get _formattedPrice => '₹${_price.toStringAsFixed(0)}';

  // ── Title ──────────────────────────────────────────────────────────────────

  String get _title {
    final n = _str('name');
    if (n.isNotEmpty) return n;
    return _str('title', fallback: 'Package Details');
  }

  // ── Category / applicable_to ───────────────────────────────────────────────
  // get_package_details returns applicable_to as a JSON array.
  // The list row does NOT include it, so we fall back gracefully.

  String get _categoryLabel {
    final raw = _data['applicable_to'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).join(', ');
    }
    return _str('category', fallback: 'Marketing');
  }

  // ── Duration ───────────────────────────────────────────────────────────────

  String get _duration {
    // flat from list row
    final flat = _str('duration');
    if (flat.isNotEmpty) return flat;
    // build from details fields
    final val  = _str('duration_value');
    final type = _str('duration_type');
    if (val.isNotEmpty) return '$val $type';
    return '';
  }

  // ── Reach / impressions / clicks ───────────────────────────────────────────
  // get_package_details nests these inside reach: { impressions, clicks }.
  // The list row exposes them as flat keys.

  double get _impressions {
    final flat = _toDouble(_data['impressions']);
    if (flat > 0) return flat;
    final reach = _data['reach'];
    if (reach is Map) return _toDouble(reach['impressions']);
    return 0;
  }

  double get _clicks {
    final flat = _toDouble(_data['clicks']);
    if (flat > 0) return flat;
    final reach = _data['reach'];
    if (reach is Map) return _toDouble(reach['clicks']);
    return 0;
  }

  // ── Number formatting ──────────────────────────────────────────────────────

  String _fmt(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildHero(),
                  if (fetchError != null) _buildErrorBanner(),
                  const SizedBox(height: 24),
                  _buildPricingAndAction(),
                  const SizedBox(height: 24),
                  _buildPerformanceMetrics(),
                  if (_str('description').isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _buildDescription(),
                  ],
                  const SizedBox(height: 24),
                  _buildSellerCard(),
                  const SizedBox(height: 24),
                  _buildSimilarPackages(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
            if (isLoading)
              const Positioned(
                top: 0, left: 0, right: 0,
                child: LinearProgressIndicator(
                  color: Color(0xFF474DC5),
                  backgroundColor: Color(0xFFE0E0FF),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────────

  Widget _buildErrorBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Showing cached data — $fetchError',
                style: const TextStyle(fontSize: 12, color: Colors.orange),
              ),
            ),
            TextButton(
              onPressed: _fetchFullDetails,
              child: const Text('Retry',
                  style: TextStyle(fontSize: 12, color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hero ───────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    final imageUrl   = _str('imageUrl');
    final isLive     = _data['isLive']     ?? true;
    final isFeatured = _data['isFeatured'] ?? false;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2))
                ],
              ),
              child: const Icon(Icons.arrow_back,
                  color: Color(0xFF474DC5), size: 24),
            ),
          ),
          const SizedBox(height: 16),

          // Hero image
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E6F0)),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder())
                      : _imgPlaceholder(),
                ),
                Positioned(
                  top: 16, left: 16,
                  child: Row(
                    children: [
                      if (isLive == true)
                        _pill('Live', const Color(0xFF474DC5)),
                      if (isFeatured == true)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _pill('Featured', const Color(0xFF805200)),
                        ),
                    ],
                  ),
                ),
                Positioned(
                  top: 16, right: 16,
                  child: GestureDetector(
                    onTap: () => setState(() => isFavorite = !isFavorite),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.8),
                          shape: BoxShape.circle),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : const Color(0xFF464653),
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          Text(_title,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF151C27))),
          const SizedBox(height: 8),

          // Category — uses applicable_to from details response
          Row(
            children: [
              const Icon(Icons.category, size: 16, color: Color(0xFF6B7280)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(_categoryLabel,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF6B7280))),
              ),
            ],
          ),

          if (_duration.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.timer_outlined,
                    size: 16, color: Color(0xFF6B7280)),
                const SizedBox(width: 4),
                Text(_duration,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF6B7280))),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _imgPlaceholder() => Container(
      color: const Color(0xFFE2E8F8),
      child: const Center(
          child:
          Icon(Icons.image, color: Color(0xFF474DC5), size: 40)));

  Widget _pill(String label, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white)));

  // ── Pricing + CTA ──────────────────────────────────────────────────────────

  Widget _buildPricingAndAction() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // FIX: uses _price getter which reads nested pricing map
                    Text(_formattedPrice,
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF474DC5))),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(_priceUnitLabel,
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF6B7280))),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('Includes full strategy & content creation',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280))),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>  PaymentScreen(packageId: _toInt(_data['id']) ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF474DC5),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Buy Now',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          )
        ],
      ),
    );
  }

  // ── Performance metrics ────────────────────────────────────────────────────

  Widget _buildPerformanceMetrics() {
    // FIX: impressions/clicks may be nested inside reach{} in details response.
    // The _impressions / _clicks getters handle both flat and nested.
    final orders  = _toDouble(_data['orders']);
    final revenue = _toDouble(_data['revenue']);

    final Map<String, String> metrics = {};
    if (_impressions > 0) metrics['Impressions'] = _fmt(_impressions);
    if (_clicks      > 0) metrics['Clicks']      = _fmt(_clicks);
    if (orders       > 0) metrics['Orders']      = _fmt(orders);
    if (revenue      > 0) metrics['Revenue']     = '₹${_fmt(revenue)}';

    if (metrics.isEmpty) {
      metrics['CVR']        = '—';
      metrics['Impressions']= '—';
      metrics['Orders']     = '—';
      metrics['ROI']        = '—';
    }

    const iconMap = <String, IconData>{
      'CVR':        Icons.trending_up,
      'Impressions':Icons.visibility,
      'Clicks':     Icons.touch_app,
      'Orders':     Icons.shopping_cart,
      'Revenue':    Icons.currency_rupee,
      'ROI':        Icons.rocket_launch,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performance Metrics',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF151C27))),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: metrics.entries.map((e) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F2FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE6E6F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(iconMap[e.key] ?? Icons.star,
                        color: const Color(0xFF474DC5), size: 24),
                    const SizedBox(height: 8),
                    Text(e.value,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF151C27))),
                    const SizedBox(height: 4),
                    Text(e.key,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280))),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Description ────────────────────────────────────────────────────────────

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('About this Package',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF151C27))),
          const SizedBox(height: 10),
          Text(_str('description'),
              style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF464653),
                  height: 1.5)),
        ],
      ),
    );
  }

  // ── Seller card ────────────────────────────────────────────────────────────

  Widget _buildSellerCard() {
    final sellerName   = _str('sellerName', fallback: 'Digital Boost Pro');
    final sellerRating = _toDouble(_data['sellerRating']);
    final sellerImage  = _str('sellerImage');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Sold by',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF151C27))),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE6E6F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFFE0E0FF), width: 2),
                  ),
                  child: ClipOval(
                    child: sellerImage.isNotEmpty
                        ? Image.network(sellerImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 40,
                            color: Color(0xFF474DC5)))
                        : const Icon(Icons.person,
                        size: 40, color: Color(0xFF474DC5)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(sellerName,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF151C27))),
                          ),
                          const Icon(Icons.verified,
                              color: Color(0xFF474DC5), size: 18),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                                color: const Color(0xFFFFDDB5),
                                borderRadius: BorderRadius.circular(4)),
                            child: Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFF805200), size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  sellerRating > 0
                                      ? sellerRating.toStringAsFixed(1)
                                      : '4.9',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF2A1800)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text('Top Seller',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF474DC5))),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Color(0xFF474DC5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Similar packages ───────────────────────────────────────────────────────

  Widget _buildSimilarPackages() {
    final list = _data['similarPackages'] as List? ?? [];
    if (list.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Similar Packages',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF151C27))),
          const SizedBox(height: 16),
          SizedBox(
            height: 260,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              itemBuilder: (context, i) {
                final pkg      = list[i] as Map;
                final title    = (pkg['title'] ?? pkg['name'] ?? 'Package').toString();
                final rating   = _toDouble(pkg['rating']);
                final reviews  = (pkg['reviews'] ?? '0').toString();
                final rawPrice = _toDouble(pkg['price']);
                final price    = rawPrice > 0
                    ? '₹${rawPrice.toStringAsFixed(0)}'
                    : (pkg['price']?.toString() ?? '₹0');
                final imageUrl = (pkg['imageUrl'] ?? '').toString();

                return Container(
                  width: 260,
                  margin: EdgeInsets.only(right: i == list.length - 1 ? 0 : 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE6E6F0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12)),
                        child: imageUrl.isNotEmpty
                            ? Image.network(imageUrl,
                            height: 140,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                _similarPlaceholder())
                            : _similarPlaceholder(),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF151C27))),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.star,
                                    color: Color(0xFFFFB300), size: 14),
                                const SizedBox(width: 2),
                                Text(
                                  rating > 0
                                      ? rating.toStringAsFixed(1)
                                      : '—',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF6B7280)),
                                ),
                                const SizedBox(width: 4),
                                Text('($reviews)',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF6B7280))),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                Text(price,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF151C27))),
                                ElevatedButton(
                                  onPressed: () {},
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFFF1F2FF),
                                    foregroundColor:
                                    const Color(0xFF474DC5),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 6),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                        BorderRadius.circular(8)),
                                  ),
                                  child: const Text('Details',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _similarPlaceholder() => Container(
      height: 140,
      color: const Color(0xFFE2E8F8),
      child: const Center(
          child:
          Icon(Icons.image, color: Color(0xFF474DC5), size: 36)));

}