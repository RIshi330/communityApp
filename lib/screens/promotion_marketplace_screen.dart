import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';

// Theme Colors (Updated with Lavender)
class AppColors {
  static const accent = Color(0xFF7C83FD);
  static const accent2 = Color(0xFF9EA3FF);
  static const bg = Color(0xFFf3f7fb);
  static const bgGradient = Color(0xFFeef8f9);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFe6edf5);
  static const muted = Color(0xFF6b7280);
  static const text = Color(0xFF07202a);
}

// Community Model
class Community {
  final String name;
  final String members;

  Community({required this.name, required this.members});
}

// Package Model — supports both local and API data
class Package {
  final int? id;
  final String title;
  final String community;
  final List<String> badges;
  final int? impressions;
  final int? clicks;
  final List<String> audience;
  final List<String> interests;
  final String? duration;
  final String price;
  final String type;
  final String pricingModel;
  final int orders;
  final double revenue;

  Package({
    this.id,
    required this.title,
    required this.community,
    required this.badges,
    this.impressions,
    this.clicks,
    this.audience = const [],
    this.interests = const [],
    this.duration,
    required this.price,
    required this.type,
    required this.pricingModel,
    this.orders = 0,
    this.revenue = 0.0,
  });

  /// Parse from API JSON response.
  factory Package.fromJson(Map<String, dynamic> json) {
    // Badges: accept comma-separated string OR a JSON array
    List<String> parseBadges(dynamic raw) {
      if (raw == null) return [];
      if (raw is List) return raw.map((e) => e.toString()).toList();
      return raw.toString().split(',').map((e) => e.trim()).toList();
    }

    final priceVal = json['price'] ?? json['fixed_price'] ?? 0;
    
    // Capitalize pricing model for UI filtering match
    String rawPricing = json['pricing_type']?.toString() ?? json['pricingModel']?.toString() ?? 'Fixed';
    String formattedPricing = rawPricing.isNotEmpty 
        ? '${rawPricing[0].toUpperCase()}${rawPricing.substring(1).toLowerCase()}' 
        : 'Fixed';
    if (formattedPricing == 'Per_action') formattedPricing = 'Per Action';

    return Package(
      id: json['id'] is int ? json['id'] as int : (int.tryParse(json['id']?.toString() ?? '') ?? null),
      title: json['name']?.toString() ?? json['title']?.toString() ?? 'Unknown',
      community: json['community']?.toString() ?? json['community_name']?.toString() ?? 'General',
      badges: parseBadges(json['badges'] ?? json['tags']),
      impressions: json['impressions'] is int
          ? json['impressions'] as int
          : int.tryParse(json['impressions']?.toString() ?? ''),
      clicks: json['clicks'] is int ? json['clicks'] as int : int.tryParse(json['clicks']?.toString() ?? ''),
      audience: (json['audience'] is List) ? (json['audience'] as List).map((e) => e.toString()).toList() : [],
      interests: (json['interests'] is List) ? (json['interests'] as List).map((e) => e.toString()).toList() : [],
      duration: json['duration']?.toString(),
      price: '₹${priceVal.toString()}',
      type: json['type']?.toString() ?? 'Product', // API doesn't return type currently, fallback to Product
      pricingModel: formattedPricing,
      orders: json['orders'] is int ? json['orders'] as int : (int.tryParse(json['orders']?.toString() ?? '') ?? 0),
      revenue: json['revenue'] is num ? (json['revenue'] as num).toDouble() : (double.tryParse(json['revenue']?.toString() ?? '') ?? 0.0),
    );
  }
}

// ─── Promotion API Service ──────────────────────────────────────────────────
class PromotionApiService {
  static final Database _db = Database();

  static Future<Map<String, dynamic>> addPackage(Map<String, dynamic> packageData, {bool isDraft = false}) async {
    final payload = {
      'action': isDraft ? 'add_package_draft' : 'add_package',
      ...packageData,
    };
    return await _db.getData(payload);
  }

  static Future<Map<String, dynamic>> getPackages({int? status, String? search, int? communityId, String? duration, String? category, String? sort}) async {
    final payload = {
      'action': 'get_packages',
      if (status != null) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (communityId != null) 'community_id': communityId,
      if (duration != null && duration.isNotEmpty) 'duration': duration,
      if (category != null && category.isNotEmpty) 'category': category,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
    };
    return await _db.getData(payload);
  }

  static Future<Map<String, dynamic>> getPackageOrders({String? status, String? search, String? sort, int page = 1}) async {
    final payload = {
      'action': 'get_package_orders',
      if (status != null && status.isNotEmpty) 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      if (sort != null && sort.isNotEmpty) 'sort': sort,
      'page': page,
    };
    return await _db.getData(payload);
  }

  static Future<Map<String, dynamic>> getPackageDetails(int id) async {
    return await _db.getData({
      'action': 'get_package_details',
      'id': id,
    });
  }

  static Future<Map<String, dynamic>> saveSchedule({
    required int orderId,
    required String title,
    required String date,
    required String time,
    required String frequency,
    required int duration,
  }) async {
    return await _db.getData({
      'action': 'save_schedule',
      'order_id': orderId,
      'title': title,
      'date': date,
      'time': time,
      'frequency': frequency,
      'duration': duration,
    });
  }
}


class MarketplaceScreen2 extends StatefulWidget {
  const MarketplaceScreen2({super.key});

  @override
  State<MarketplaceScreen2> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen2> {
  // ─── API ───────────────────────────────────────────────────────────────────
  final Database _database = Database();

  bool _isLoading = true;
  String? _errorMessage;

  // ─── Controllers & Filters ────────────────────────────────────────────────
  final TextEditingController _searchController = TextEditingController();

  String _selectedType = 'All';
  String _selectedPricing = 'All';
  String _selectedCommunity = 'All Communities';
  String _selectedDuration = 'Any';

  // ─── Data ─────────────────────────────────────────────────────────────────
  List<Community> _topCommunities = [];
  List<Package> _allPackagesData = [];

  // ─── Lifecycle ────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fetchPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ─── API Call ─────────────────────────────────────────────────────────────
  Future<void> _fetchPackages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the newly created API service, requesting active packages (status: 1)
      final response = await PromotionApiService.getPackages(status: 1);

      if (response['status'] == 200 || response['success'] == true) {
        // ── Parse packages ──────────────────────────────────────────────────
        List<dynamic> rawPackages = [];
        if (response['data'] != null && response['data'] is List) {
          rawPackages = response['data'];
        } else if (response['packages'] != null) {
          rawPackages = response['packages'];
        } else if (response['promotion_packages'] != null) {
          rawPackages = response['promotion_packages'];
        }

        final packages = rawPackages
            .map((e) => Package.fromJson(e as Map<String, dynamic>))
            .toList();

        // ── Derive communities from package data ────────────────────────────
        final communityMap = <String, int>{};
        for (final pkg in packages) {
          communityMap[pkg.community] = (communityMap[pkg.community] ?? 0) + 1;
        }

        // Also try to parse explicit community list if provided by API
        List<Community> communities = [];
        if (response['communities'] != null) {
          for (final c in response['communities']) {
            communities.add(
              Community(
                name: c['name']?.toString() ?? '',
                members: c['members']?.toString() ?? '',
              ),
            );
          }
        } else {
          // Build community list from package data
          communities = communityMap.entries
              .map(
                (e) => Community(name: e.key, members: '${e.value} packages'),
              )
              .take(3)
              .toList();
        }

        setState(() {
          _allPackagesData = packages;
          _topCommunities = communities;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Server error: ${response['status']}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Network error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // ─── Filter Logic ─────────────────────────────────────────────────────────
  int get _activeFiltersCount {
    int count = 0;
    if (_selectedType != 'All') count++;
    if (_selectedPricing != 'All') count++;
    if (_selectedCommunity != 'All Communities') count++;
    if (_selectedDuration != 'Any') count++;
    return count;
  }

  List<Package> get _filteredPackages {
    return _allPackagesData.where((package) {
      if (_selectedType != 'All' && package.type != _selectedType) return false;
      if (_selectedPricing != 'All' && package.pricingModel != _selectedPricing)
        return false;
      if (_selectedCommunity != 'All Communities' &&
          package.community != _selectedCommunity) {
        return false;
      }
      if (_selectedDuration != 'Any') {
        if (package.duration == null) return false;
        if (_selectedDuration == '1–3 days' && package.duration != '1-3 days')
          return false;
        if (_selectedDuration == '7 days' && package.duration != '7 days')
          return false;
        if (_selectedDuration == '15+ days' && package.duration != '15+ days')
          return false;
      }
      if (_searchController.text.isNotEmpty) {
        final query = _searchController.text.toLowerCase();
        return package.title.toLowerCase().contains(query) ||
            package.community.toLowerCase().contains(query) ||
            package.badges.any((badge) => badge.toLowerCase().contains(query));
      }
      return true;
    }).toList();
  }

  List<Package> get _topPackages => _filteredPackages.take(2).toList();
  List<Package> get _remainingPackages => _filteredPackages.skip(2).toList();

  // ─── Filter Bottom Sheet ──────────────────────────────────────────────────
  void _showFilterBottomSheet() {
    String tempType = _selectedType;
    String tempPricing = _selectedPricing;
    String tempCommunity = _selectedCommunity;
    String tempDuration = _selectedDuration;

    // Build dynamic community list for filter
    final communityNames =
        ['All Communities'] +
        _allPackagesData.map((p) => p.community).toSet().toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  color: AppColors.accent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Filters',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                            color: AppColors.muted,
                          ),
                        ],
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
                        _buildFilterSection(
                          title: 'Package Type',
                          icon: Icons.category_rounded,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                ['All', 'Product', 'Job', 'Event', 'Training']
                                    .map(
                                      (type) => _buildChipOption(
                                        label: type,
                                        isSelected: tempType == type,
                                        onTap: () => setModalState(
                                          () => tempType = type,
                                        ),
                                        color: _getTypeColor(type),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFilterSection(
                          title: 'Pricing Model',
                          icon: Icons.payments_rounded,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children:
                                [
                                      'All',
                                      'Fixed',
                                      'Commission',
                                      'Per Action',
                                      'Hybrid',
                                    ]
                                    .map(
                                      (pricing) => _buildChipOption(
                                        label: pricing,
                                        isSelected: tempPricing == pricing,
                                        onTap: () => setModalState(
                                          () => tempPricing = pricing,
                                        ),
                                      ),
                                    )
                                    .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFilterSection(
                          title: 'Community',
                          icon: Icons.groups_rounded,
                          child: Column(
                            children: communityNames
                                .map(
                                  (community) => _buildRadioOption(
                                    label: community,
                                    sublabel: _topCommunities
                                        .where((c) => c.name == community)
                                        .map((c) => c.members)
                                        .firstOrNull,
                                    isSelected: tempCommunity == community,
                                    onTap: () => setModalState(
                                      () => tempCommunity = community,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildFilterSection(
                          title: 'Duration',
                          icon: Icons.schedule_rounded,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: ['Any', '1–3 days', '7 days', '15+ days']
                                .map(
                                  (duration) => _buildChipOption(
                                    label: duration,
                                    isSelected: tempDuration == duration,
                                    onTap: () => setModalState(
                                      () => tempDuration = duration,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),

                // Bottom Buttons
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => setModalState(() {
                              tempType = 'All';
                              tempPricing = 'All';
                              tempCommunity = 'All Communities';
                              tempDuration = 'Any';
                            }),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.accent,
                              side: const BorderSide(
                                color: AppColors.accent,
                                width: 2,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Reset',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _selectedType = tempType;
                                _selectedPricing = tempPricing;
                                _selectedCommunity = tempCommunity;
                                _selectedDuration = tempDuration;
                              });
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Apply Filters',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── Build Helpers ────────────────────────────────────────────────────────
  Widget _buildFilterSection({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.accent),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildChipOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? (color ?? AppColors.accent) : Colors.white,
          border: Border.all(
            color: isSelected ? (color ?? AppColors.accent) : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.text,
          ),
        ),
      ),
    );
  }

  Widget _buildRadioOption({
    required String label,
    String? sublabel,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.accent : AppColors.border,
                  width: 2,
                ),
                color: isSelected ? AppColors.accent : Colors.white,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: AppColors.text,
                    ),
                  ),
                  if (sublabel != null)
                    Text(
                      sublabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Main Build ───────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: const Text(
          'Promotion Marketplace',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          // Refresh button
          IconButton(
            onPressed: _fetchPackages,
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg, AppColors.bgGradient],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: AppColors.accent),
                      SizedBox(height: 16),
                      Text(
                        'Loading packages...',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                )
              : _errorMessage != null
              ? _buildErrorWidget()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Search + Filter Row
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: (value) => setState(() {}),
                              decoration: InputDecoration(
                                hintText: 'Search packages, communities...',
                                hintStyle: const TextStyle(
                                  fontSize: 14,
                                  color: AppColors.muted,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: AppColors.muted,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.border,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.accent,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.accent.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showFilterBottomSheet,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      padding: const EdgeInsets.all(14),
                                      child: const Icon(
                                        Icons.tune,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_activeFiltersCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$_activeFiltersCount',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      if (_activeFiltersCount > 0) _buildActiveFilters(),
                      if (_activeFiltersCount > 0) const SizedBox(height: 16),

                      _buildMainContent(),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ─── Error Widget ─────────────────────────────────────────────────────────
  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 56,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Failed to Load',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchPackages,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Filters',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted,
                ),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _selectedType = 'All';
                  _selectedPricing = 'All';
                  _selectedCommunity = 'All Communities';
                  _selectedDuration = 'Any';
                }),
                child: const Text(
                  'Clear All',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (_selectedType != 'All')
                _buildFilterChip(
                  'Type: $_selectedType',
                  () => setState(() => _selectedType = 'All'),
                ),
              if (_selectedPricing != 'All')
                _buildFilterChip(
                  'Pricing: $_selectedPricing',
                  () => setState(() => _selectedPricing = 'All'),
                ),
              if (_selectedCommunity != 'All Communities')
                _buildFilterChip(
                  'Community: $_selectedCommunity',
                  () => setState(() => _selectedCommunity = 'All Communities'),
                ),
              if (_selectedDuration != 'Any')
                _buildFilterChip(
                  'Duration: $_selectedDuration',
                  () => setState(() => _selectedDuration = 'Any'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 16, color: AppColors.accent),
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        // Results Count
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.confirmation_number,
                  size: 16,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_filteredPackages.length} packages available',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Top Communities
        if (_topCommunities.isNotEmpty)
          _buildCard(
            title: '🔥 Top Communities',
            child: Column(
              children: _topCommunities
                  .map((community) => _buildCommunityItem(community))
                  .toList(),
            ),
          ),

        if (_topCommunities.isNotEmpty) const SizedBox(height: 16),

        // Top Performing Packages
        if (_topPackages.isNotEmpty)
          _buildCard(
            title: '🚀 Top Performing Packages',
            child: _buildPackageGrid(_topPackages, showCompare: false),
          ),

        if (_topPackages.isNotEmpty) const SizedBox(height: 16),

        // All Packages
        if (_remainingPackages.isNotEmpty)
          _buildCard(
            title: 'All Packages',
            child: _buildPackageGrid(_remainingPackages, showCompare: true),
          ),

        // No results
        if (_filteredPackages.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: AppColors.card,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.search_off,
                    size: 48,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'No packages found',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Try adjusting your filters or search',
                  style: TextStyle(fontSize: 14, color: AppColors.muted),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {
                    _selectedType = 'All';
                    _selectedPricing = 'All';
                    _selectedCommunity = 'All Communities';
                    _selectedDuration = 'Any';
                    _searchController.clear();
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Reset All Filters'),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildCommunityItem(Community community) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
        color: Colors.white,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups,
                  size: 20,
                  color: AppColors.accent,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                community.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          Text(
            community.members,
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageGrid(
    List<Package> packages, {
    required bool showCompare,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 2 : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: packages.length,
          itemBuilder: (context, index) =>
              _buildPackageCard(packages[index], showCompare: showCompare),
        );
      },
    );
  }

  Widget _buildPackageCard(Package package, {required bool showCompare}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  package.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(package.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  package.type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _getTypeColor(package.type),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            package.community,
            style: const TextStyle(fontSize: 13, color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              border: Border.all(color: AppColors.accent.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getPricingIcon(package.pricingModel),
                  size: 13,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 5),
                Text(
                  package.pricingModel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: package.badges
                .map((badge) => _buildBadge(badge))
                .toList(),
          ),
          const SizedBox(height: 8),
          if (package.reach != null)
            Row(
              children: [
                const Icon(Icons.visibility, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  package.ctr != null
                      ? 'Reach: ${package.reach} • CTR: ${package.ctr}'
                      : 'Reach: ${package.reach}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          if (package.duration != null)
            Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  package.duration!,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Price',
                    style: TextStyle(fontSize: 11, color: AppColors.muted),
                  ),
                  Text(
                    package.price,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  ElevatedButton(
                    onPressed: () => _showPurchaseDialog(package),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      minimumSize: Size.zero,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Buy',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (showCompare) ...[
                    const SizedBox(width: 6),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.accent,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        side: const BorderSide(
                          color: AppColors.accent,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Compare',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFf3faf9),
        border: Border.all(color: const Color(0xFFe6f6f5)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'Product':
        return const Color(0xFF10b981);
      case 'Job':
        return const Color(0xFF3b82f6);
      case 'Event':
        return const Color(0xFFf59e0b);
      case 'Training':
        return const Color(0xFF8b5cf6);
      default:
        return AppColors.accent;
    }
  }

  IconData _getPricingIcon(String pricingModel) {
    switch (pricingModel) {
      case 'Fixed':
        return Icons.payments;
      case 'Commission':
        return Icons.percent;
      case 'Per Action':
        return Icons.touch_app;
      case 'Hybrid':
        return Icons.dashboard;
      default:
        return Icons.attach_money;
    }
  }

  void _showPurchaseDialog(Package package) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Purchase ${package.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogRow('Community', package.community),
            _buildDialogRow('Type', package.type),
            _buildDialogRow('Pricing', package.pricingModel),
            if (package.duration != null)
              _buildDialogRow('Duration', package.duration!),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Price',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  package.price,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.accent,
                  ),
                ),
              ],
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Purchase of ${package.title} initiated!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Confirm Purchase',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
