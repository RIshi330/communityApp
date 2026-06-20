import 'dart:convert';
import 'dart:developer' as dev;
import 'package:commity_app1/screens/User_screens/promotional_pac_details.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../app_constants.dart';
import '../business_user/promotional_details.dart';

class PromoMarketScreen_user extends StatefulWidget {
  const PromoMarketScreen_user({super.key});

  @override
  State<PromoMarketScreen_user> createState() => _PromoMarketScreen_user();
}

class _PromoMarketScreen_user extends State<PromoMarketScreen_user> {
  bool isFilterModalVisible = false;
  bool isLoading            = true;
  String selectedCategory   = 'All';
  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> packages = [];
  String? errorMessage;
  String currentSort = 'newest';

  String selectedPricingType = ''; // '', 'fixed', 'cpa', 'hybrid'
  String selectedDuration    = ''; // '', '1-3', '7', '15+'

  final List<String> categories = [
    'All',
    'Social Media',
    'Influencer',
    'Search Ads',
    'Email',
  ];

  @override
  void initState() {
    super.initState();
    // FIX: listener so the search clear (×) button actually appears/hides
    searchController.addListener(() => setState(() {}));
    fetchPackages();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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

  static List<String> _toStringList(dynamic v) {
    if (v == null) return [];
    if (v is List) return v.map((e) => e.toString()).toList();
    return [];
  }

  // ── Normalize one row from get_packages ────────────────────────────────────
  // PHP returns impressions/clicks via JSON_EXTRACT which can be a quoted
  // string, null, or int depending on MySQL version — normalise everything.

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> raw) {
    return {
      ...raw,
      'id':           _toInt(raw['id']),
      'price':        _toDouble(raw['price']),
      'pricing_type': (raw['pricing_type'] ?? '').toString(),
      'duration':     (raw['duration']     ?? '').toString(),
      'impressions':  _toInt(raw['impressions']),
      'clicks':       _toInt(raw['clicks']),
      'orders':       _toInt(raw['orders']),
      'revenue':      _toDouble(raw['revenue']),
      'badges':       _toStringList(raw['badges']),
      'audience':     _toStringList(raw['audience']),
      'interests':    _toStringList(raw['interests']),
    };
  }

  // ── API call ───────────────────────────────────────────────────────────────

  Future<void> fetchPackages({
    String? overridePricingType,
    String? overrideDuration,
  }) async {
    setState(() {
      isLoading    = true;
      errorMessage = null;
    });

    final String pricingType = overridePricingType ?? selectedPricingType;
    final String duration    = overrideDuration    ?? selectedDuration;

    try {
      final url = '${baseUrl}new_apis/promotion_package_api.php';
      final requestBody = {
        'action':       'get_packages',
        'search':       searchController.text.trim(),
        'sort':         currentSort,
        'category':     selectedCategory != 'All' ? selectedCategory : '',
        'pricing_type': pricingType,
        'duration':     duration,
        'status':       1,
      };

      if (kDebugMode) {
        dev.log('→ $url');
        dev.log('→ body: $requestBody');
      }

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (kDebugMode) {
        dev.log('← ${response.statusCode}');
        dev.log('← ${response.body}');
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;

        if (json['success'] == true) {
          final raw = json['data'];
          List<Map<String, dynamic>> rows = [];

          if (raw is List) {
            rows = raw
                .map((e) => _normalizeRow(Map<String, dynamic>.from(e as Map)))
                .toList();
          } else if (raw is Map) {
            rows = [_normalizeRow(Map<String, dynamic>.from(raw))];
          }

          setState(() {
            packages  = rows;
            isLoading = false;
          });
        } else {
          setState(() {
            errorMessage = json['message'] ?? 'Failed to load packages';
            isLoading    = false;
          });
        }
      } else {
        setState(() {
          errorMessage = 'Server error: ${response.statusCode}';
          isLoading    = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Network error: $e';
          isLoading    = false;
        });
      }
    }
  }

  // ── Filter helpers ─────────────────────────────────────────────────────────

  Future<void> applyFilters() async {
    setState(() => isFilterModalVisible = false);
    await fetchPackages();
  }

  void resetFilters() {
    setState(() {
      selectedPricingType = '';
      selectedDuration    = '';
      selectedCategory    = 'All';
      searchController.clear();
    });
    fetchPackages();
  }

  // ── Utility ────────────────────────────────────────────────────────────────

  String _formatNumber(dynamic value) {
    final num n = value is num
        ? value
        : (num.tryParse(value.toString()) ?? 0);
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000)    return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toStringAsFixed(0);
  }

  List<StatItem> _buildStats(Map<String, dynamic> p) {
    final List<StatItem> stats = [];

    if ((p['impressions'] as int) > 0) {
      stats.add(StatItem(label: 'Impressions', value: _formatNumber(p['impressions'])));
    }
    if ((p['clicks'] as int) > 0) {
      stats.add(StatItem(label: 'Clicks', value: _formatNumber(p['clicks'])));
    }
    if ((p['orders'] as int) > 0) {
      stats.add(StatItem(label: 'Orders', value: _formatNumber(p['orders'])));
    }
    if ((p['revenue'] as double) > 0) {
      stats.add(StatItem(
        label: 'Revenue',
        value: '₹${_formatNumber(p['revenue'])}',
        isPositive: true,
      ));
    }

    if (stats.isEmpty) {
      return const [
        StatItem(label: 'CVR',         value: '—'),
        StatItem(label: 'Impressions', value: '—'),
        StatItem(label: 'Orders',      value: '—'),
        StatItem(label: 'ROI',         value: '—', isPositive: true),
      ];
    }
    return stats;
  }

  String _description(Map<String, dynamic> p) {
    if ((p['impressions'] as int) > 0) {
      return '${_formatNumber(p['impressions'])}+ Impressions guaranteed';
    }
    if ((p['clicks'] as int) > 0) {
      return '${_formatNumber(p['clicks'])}+ Clicks expected';
    }
    return 'Premium marketing package';
  }

  IconData _icon(Map<String, dynamic> p) {
    final name = (p['name'] ?? '').toString().toLowerCase();
    if (name.contains('instagram'))  return Icons.photo_camera;
    if (name.contains('linkedin'))   return Icons.business_center;
    if (name.contains('twitter'))    return Icons.trending_up;
    if (name.contains('facebook'))   return Icons.facebook;
    if (name.contains('influencer')) return Icons.people;
    if (name.contains('search'))     return Icons.search;
    if (name.contains('email'))      return Icons.email;
    return Icons.campaign;
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Promo Market', style: TextStyle(fontSize: 25)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() => currentSort = value);
              fetchPackages();
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest',      child: Text('Newest First')),
              PopupMenuItem(value: 'most_orders', child: Text('Most Orders')),
              PopupMenuItem(value: 'most_views',  child: Text('Most Views')),
              PopupMenuItem(value: 'revenue',     child: Text('Highest Revenue')),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      backgroundColor: const Color(0xFFF9F9FF),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchAndFilter(),
              const SizedBox(height: 16),
              _buildCategoryChips(),
              const SizedBox(height: 24),
              Expanded(child: _buildList()),
            ],
          ),
          if (isFilterModalVisible) _buildFilterModal(),
        ],
      ),
    );
  }

  // ── Package list ───────────────────────────────────────────────────────────

  Widget _buildList() {
    if (isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF7C83FD)));
    }

    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: fetchPackages,
                style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (packages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 64, color: Color(0xFF7C83FD)),
            SizedBox(height: 16),
            Text('No packages found'),
            SizedBox(height: 8),
            Text('Try adjusting your search or filters'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final p = packages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PackageCard(
            id:          p['id']          as int,
            title:       (p['name']       ?? 'Package Name').toString(),
            duration:    p['duration']    as String,
            price:       '₹${_formatNumber(p['price'])}',
            pricingType: p['pricing_type']as String,
            badges:      p['badges']      as List<String>,
            impressions: p['impressions'] as int,
            clicks:      p['clicks']      as int,
            orders:      p['orders']      as int,
            revenue:     p['revenue']     as double,
            audience:    p['audience']    as List<String>,
            interests:   p['interests']   as List<String>,
            isLive:      true,
            isFeatured:  (p['badges'] as List<String>).contains('Featured'),
            stats:       _buildStats(p),
            description: _description(p),
            icon:        _icon(p),
            rawData:     p,
          ),
        );
      },
    );
  }

  // ── Search + filter bar ────────────────────────────────────────────────────

  Widget _buildSearchAndFilter() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6F0)),
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: (_) => fetchPackages(),
                decoration: InputDecoration(
                  hintText: 'Search packages...',
                  hintStyle: const TextStyle(
                      fontSize: 14, color: Color(0xFF464653)),
                  prefixIcon: const Icon(Icons.search,
                      color: Color(0xFF464653), size: 20),
                  // FIX: listener on controller triggers rebuild so this works
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, size: 20),
                    onPressed: () {
                      searchController.clear();
                      fetchPackages();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() => isFilterModalVisible = true),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE6E6F0)),
              ),
              child: const Icon(Icons.filter_list,
                  color: Color(0xFF7C83FD), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  // ── Category chips ─────────────────────────────────────────────────────────

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        itemBuilder: (_, index) {
          final category   = categories[index];
          final isSelected = selectedCategory == category;
          return GestureDetector(
            onTap: () {
              setState(() => selectedCategory = category);
              fetchPackages();
            },
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF7C83FD) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: isSelected
                    ? null
                    : Border.all(color: const Color(0xFFE6E6F0)),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: const Color(0xFF7C83FD).withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
                    : null,
              ),
              child: Text(
                category,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white : const Color(0xFF464653),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Filter modal ───────────────────────────────────────────────────────────

  Widget _buildFilterModal() {
    return GestureDetector(
      onTap: () => setState(() => isFilterModalVisible = false),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: Container(
              height: MediaQuery.of(context).size.height * 0.75,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 6,
                    margin: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC6C5D6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Filters',
                            style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF151C27))),
                        TextButton(
                          onPressed: resetFilters,
                          child: const Text('Reset',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF7C83FD))),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pricing Type',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF151C27))),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 4,
                            children: [
                              _pricingRadio('Fixed Price', 'fixed'),
                              _pricingRadio('Cost Per Action', 'cpa'),
                              _pricingRadio('Hybrid', 'hybrid'),
                              _pricingRadio('Any', ''),
                            ],
                          ),
                          const SizedBox(height: 24),
                          const Text('Duration',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF151C27))),
                          const SizedBox(height: 12),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 4,
                            children: [
                              _durationRadio('1–3 Days', '1-3'),
                              _durationRadio('7 Days',   '7'),
                              _durationRadio('15+ Days', '15+'),
                              _durationRadio('Any',      ''),
                            ],
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: applyFilters,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C83FD),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(12)),
                              ),
                              child: const Text('Apply Filters',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pricingRadio(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE6E6F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: selectedPricingType,
            onChanged: (val) =>
                setState(() => selectedPricingType = val ?? ''),
            activeColor: const Color(0xFF7C83FD),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF151C27)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _durationRadio(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE6E6F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: selectedDuration,
            onChanged: (val) =>
                setState(() => selectedDuration = val ?? ''),
            activeColor: const Color(0xFF7C83FD),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    fontSize: 13, color: Color(0xFF151C27)),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}

// ── PackageCard ───────────────────────────────────────────────────────────────

class PackageCard extends StatelessWidget {
  final int id;
  final String title;
  final String duration;
  final String price;
  final String pricingType;
  final bool isLive;
  final bool isFeatured;
  final List<StatItem> stats;
  final String description;
  final IconData icon;
  final List<String> badges;
  final int impressions;
  final int clicks;
  final int orders;
  final double revenue;
  final List<String> audience;
  final List<String> interests;
  final Map<String, dynamic> rawData;

  const PackageCard({
    super.key,
    required this.id,
    required this.title,
    required this.duration,
    required this.price,
    required this.pricingType,
    this.isLive      = true,
    this.isFeatured  = false,
    required this.stats,
    required this.description,
    required this.icon,
    this.badges      = const [],
    this.impressions = 0,
    this.clicks      = 0,
    this.orders      = 0,
    this.revenue     = 0,
    this.audience    = const [],
    this.interests   = const [],
    required this.rawData,
  });

  String get _priceUnitLabel {
    switch (pricingType.toLowerCase()) {
      case 'cpa':    return '/action';
      case 'hybrid': return '/camp. + CPA';
      default:       return '/camp.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6E6F0)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (isLive)
                        _Chip(
                            label: 'Live',
                            bgColor: Colors.green.shade100,
                            textColor: const Color(0xFF2E7D32)),
                      if (isFeatured)
                        _Chip(
                            label: 'Featured',
                            bgColor:
                            const Color(0xFF7C83FD).withOpacity(0.15),
                            textColor: const Color(0xFF7C83FD)),
                      ...badges
                          .where((b) => b != 'Featured')
                          .map((b) => _Chip(
                        label: b,
                        bgColor: const Color(0xFF5C5E69)
                            .withOpacity(0.1),
                        textColor: const Color(0xFF5C5E69),
                      )),
                    ],
                  ),
                ),
                const Icon(Icons.favorite_border,
                    color: Color(0xFF464653), size: 20),
              ],
            ),
            const SizedBox(height: 16),

            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF151C27))),
            const SizedBox(height: 4),

            if (duration.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Text(duration,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF6B7280))),
                ],
              ),
            const SizedBox(height: 6),

            Row(
              children: [
                Icon(icon, size: 18, color: const Color(0xFF464653)),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(description,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFF464653))),
                ),
              ],
            ),

            if (audience.isNotEmpty || interests.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  ...audience.map((a) => _Chip(
                      label: a,
                      bgColor: const Color(0xFFEDE7F6),
                      textColor: const Color(0xFF512DA8))),
                  ...interests.map((i) => _Chip(
                      label: i,
                      bgColor: const Color(0xFFE8F5E9),
                      textColor: const Color(0xFF2E7D32))),
                ],
              ),
            ],

            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: stats.length > 3 ? 4 : stats.length,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: stats.map((stat) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(stat.label,
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF464653))),
                      const SizedBox(height: 4),
                      Text(stat.value,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: stat.isPositive
                                ? Colors.green.shade600
                                : const Color(0xFF7C83FD),
                          )),
                    ],
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(price,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF151C27))),
                    Text(_priceUnitLabel,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF464653))),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _navigate(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PackageDetailsScreen_user(packageData: rawData),
      ),
    );
  }
}

// ── Chip ──────────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;

  const _Chip(
      {required this.label,
        required this.bgColor,
        required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(999)),
      child: Text(label,
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: textColor)),
    );
  }
}

// ── StatItem ──────────────────────────────────────────────────────────────────

class StatItem {
  final String label;
  final String value;
  final bool isPositive;

  const StatItem(
      {required this.label,
        required this.value,
        this.isPositive = false});
}
