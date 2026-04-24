import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/screens/promotion/promotional_package_builder.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const PackageManagementApp());
}

class PackageManagementApp extends StatelessWidget {
  const PackageManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lavender Stitch Admin',
      theme: AppTheme.theme,
      home: const ManagePackagesScreen(),
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
  static const Color error = Color(0xFFEF4444);

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
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class PackageSummary {
  final String id;
  final String name;
  final String status;
  final String updatedAt;
  final List<String> badges;
  final Map<String, String> stats;
  final bool isDraft;
  final Map<String, dynamic> raw;

  PackageSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.updatedAt,
    required this.badges,
    required this.stats,
    required this.isDraft,
    required this.raw,
  });
}

class ManagePackagesScreen extends StatefulWidget {
  const ManagePackagesScreen({super.key});

  @override
  State<ManagePackagesScreen> createState() => _ManagePackagesScreenState();
}

class _ManagePackagesScreenState extends State<ManagePackagesScreen> {
  final _database = Database();
  final _searchController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';
  List<PackageSummary> _packages = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
    _loadPackages();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vendorId = await AuthService.getVendorIdString();
      final response = await _database.getData({
        'action': 'get_packages',
        if (vendorId != '0') 'vendor_id': vendorId,
      });

      if (response['success'] == true || response['status'] == 200) {
        final rawList =
            response['data'] ??
            response['packages'] ??
            response['promotion_packages'] ??
            [];

        final packages = <PackageSummary>[];
        if (rawList is List) {
          for (final item in rawList) {
            if (item is Map) {
              packages.add(_mapPackage(Map<String, dynamic>.from(item)));
            }
          }
        }

        if (!mounted) return;
        setState(() {
          _packages = packages;
          _isLoading = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _errorMessage =
              response['message']?.toString() ??
              response['error']?.toString() ??
              'Unable to load packages';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to load packages: $e';
        _isLoading = false;
      });
    }
  }

  PackageSummary _mapPackage(Map<String, dynamic> data) {
    final id = data['id']?.toString() ?? data['package_id']?.toString() ?? '';
    final rawStatus = (data['status']?.toString() ?? 'active').toLowerCase();
    final durationValue = data['duration_value']?.toString() ?? '';
    final durationType = data['duration_type']?.toString() ?? '';
    final packageName = data['name']?.toString() ?? 'Promotion Package';
    final pricingType =
        data['pricing_type']?.toString() ??
        data['pricing']?.toString() ??
        'Fixed Price';

    final badges = <String>[];
    final parsedBadges = data['badges'];
    if (parsedBadges is List) {
      badges.addAll(parsedBadges.map((e) => e.toString()));
    }

    final placements = data['placements'];
    if (placements is Map<String, dynamic>) {
      if (placements['homepage_banner'] == true) badges.add('Homepage');
      if (placements['search_top'] == true) badges.add('Search Boost');
      if (placements['feed_ads'] == true) badges.add('Feed Ads');
      if (placements['featured_section'] == true) badges.add('Featured');
    }

    final features = data['features'];
    if (features is Map<String, dynamic>) {
      if (features['featured_badge'] == true) badges.add('Featured Badge');
      if (features['ai_boost'] == true) badges.add('AI Boost');
      if (features['trending_tag'] == true) badges.add('Trending');
    }

    final audience =
        data['audience'] ??
        (data['targeting'] is Map ? data['targeting']['audience'] : null);
    final interests =
        data['interests'] ??
        (data['targeting'] is Map ? data['targeting']['interests'] : null);

    final audienceText = audience is List
        ? audience.map((e) => e.toString()).join(', ')
        : audience?.toString() ?? '';
    final interestsText = interests is List
        ? interests.map((e) => e.toString()).join(', ')
        : interests?.toString() ?? '';

    final price =
        data['fixed_price']?.toString() ??
        data['base_price']?.toString() ??
        data['price']?.toString() ??
        '0';

    return PackageSummary(
      id: id,
      name: packageName,
      status: _humanizeStatus(rawStatus),
      updatedAt:
          data['updated_at']?.toString() ??
          data['created_at']?.toString() ??
          'Recently updated',
      badges: badges.take(3).toList(),
      stats: {
        'Orders':
            data['orders']?.toString() ??
            data['orders_count']?.toString() ??
            '0',
        'Views': data['impressions']?.toString() ?? '0',
        'Revenue': '₹${data['revenue']?.toString() ?? price}',
        'CVR': data['cvr']?.toString() ?? '0%',
      },
      isDraft: rawStatus == 'draft' || rawStatus == 'inactive',
      raw: {
        ...data,
        'package_name': packageName,
        'pricing_type': pricingType,
        'duration': durationValue.isNotEmpty
            ? '$durationValue ${durationType.isNotEmpty ? durationType : ''}'
                  .trim()
            : data['duration']?.toString() ?? '',
        'audience_text': audienceText,
        'interests_text': interestsText,
      },
    );
  }

  String _humanizeStatus(String status) {
    switch (status) {
      case 'active':
      case 'live':
        return 'LIVE';
      case 'draft':
        return 'DRAFT';
      case 'inactive':
        return 'INACTIVE';
      case 'expired':
        return 'EXPIRED';
      default:
        return status.toUpperCase();
    }
  }

  List<PackageSummary> get _filteredPackages {
    if (_searchQuery.isEmpty) return _packages;
    return _packages.where((pkg) {
      final haystack = [
        pkg.name,
        pkg.status,
        pkg.badges.join(' '),
        pkg.stats['Orders'] ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(_searchQuery);
    }).toList();
  }

  Future<void> _openPackageDetails(PackageSummary package) async {
    if (package.id.isEmpty) {
      await _showPackageDetails(package, null);
      return;
    }

    try {
      final response = await _database.getData({
        'action': 'get_package_details',
        'id': package.id,
      });

      if (response['success'] == true || response['status'] == 200) {
        final data = response['data'];
        await _showPackageDetails(
          package,
          data is Map ? Map<String, dynamic>.from(data) : null,
        );
      } else {
        await _showPackageDetails(package, null);
      }
    } catch (_) {
      await _showPackageDetails(package, null);
    }
  }

  Future<void> _showPackageDetails(
    PackageSummary package,
    Map<String, dynamic>? details,
  ) async {
    if (!mounted) return;

    final map = details ?? package.raw;
    final title = map['name']?.toString() ?? package.name;
    final communityTitle = map['community'] is Map
        ? (map['community']['title']?.toString() ?? '')
        : map['community_title']?.toString() ??
              map['community_name']?.toString() ??
              map['community']?.toString() ??
              '';
    final duration =
        map['duration']?.toString() ??
        '${map['duration_value'] ?? ''} ${map['duration_type'] ?? ''}'.trim();
    final pricingType = map['pricing_type']?.toString() ?? 'Fixed Price';
    final status = map['status']?.toString() ?? package.status;
    final audience =
        map['audience_text']?.toString() ??
        (map['targeting'] is Map
            ? (map['targeting']['audience'] is List
                  ? (map['targeting']['audience'] as List).join(', ')
                  : map['targeting']['audience']?.toString() ?? '')
            : '');
    final interests =
        map['interests_text']?.toString() ??
        (map['targeting'] is Map
            ? (map['targeting']['interests'] is List
                  ? (map['targeting']['interests'] as List).join(', ')
                  : map['targeting']['interests']?.toString() ?? '')
            : '');

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.82,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppTheme.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    communityTitle.isNotEmpty
                        ? communityTitle
                        : 'Community package details',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _detailRow('Status', status),
                  _detailRow('Duration', duration.isEmpty ? '-' : duration),
                  _detailRow('Pricing Type', pricingType),
                  _detailRow('Audience', audience.isEmpty ? '-' : audience),
                  _detailRow('Interests', interests.isEmpty ? '-' : interests),
                  _detailRow('Orders', map['orders']?.toString() ?? '0'),
                  _detailRow('Views', map['impressions']?.toString() ?? '0'),
                  _detailRow(
                    'Revenue',
                    '₹${map['revenue']?.toString() ?? '0'}',
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Badges',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        (package.badges.isEmpty
                                ? ['No badges']
                                : package.badges)
                            .map(
                              (badge) => Chip(
                                label: Text(badge),
                                backgroundColor: AppTheme.primarySoft,
                                labelStyle: const TextStyle(
                                  color: AppTheme.primary,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textMain,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showActionMessage(String action) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action is not wired yet'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _openPackageBuilder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const PromotionalPackageBuilderScreen(),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: AppTheme.textMuted),
                  hintText: 'Search promotions...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(fontSize: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.tune, color: AppTheme.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: _openPackageBuilder,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create New Package',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildPackageCard({required PackageSummary package}) {
    final statusColor = _statusColor(package.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            package.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textMain,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _buildStatusBadge(package.status, statusColor),
                              const SizedBox(width: 8),
                              ...package.badges.map(
                                (badge) => Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: _buildSpecialBadge(badge),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '• ${package.updatedAt}',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      onSelected: (value) async {
                        switch (value) {
                          case 'view':
                            await _openPackageDetails(package);
                            break;
                          case 'edit':
                            await _showActionMessage('Edit');
                            break;
                          case 'duplicate':
                            await _showActionMessage('Duplicate');
                            break;
                          case 'pause':
                            await _showActionMessage('Pause');
                            break;
                          case 'report':
                            await _showActionMessage('Report');
                            break;
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'view',
                          child: Text('View details'),
                        ),
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(
                          value: 'duplicate',
                          child: Text('Duplicate'),
                        ),
                        PopupMenuItem(value: 'pause', child: Text('Pause')),
                        PopupMenuItem(value: 'report', child: Text('Report')),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildStatsGrid(package.stats),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: package.isDraft
                ? Row(
                    children: [
                      Expanded(
                        child: TextButton.icon(
                          onPressed: () => _showActionMessage('Complete Setup'),
                          icon: const Icon(Icons.edit_note, size: 20),
                          label: const Text('Complete Setup'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showActionMessage('Publish'),
                        icon: const Icon(Icons.publish, size: 18),
                        label: const Text('Publish'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primarySoft,
                          foregroundColor: AppTheme.primary,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        'View',
                        () => _openPackageDetails(package),
                      ),
                      _buildActionButton(
                        'Edit',
                        () => _showActionMessage('Edit'),
                      ),
                      _buildActionButton(
                        'Duplicate',
                        () => _showActionMessage('Duplicate'),
                      ),
                      _buildActionButton(
                        'Pause',
                        () => _showActionMessage('Pause'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'LIVE':
        return AppTheme.success;
      case 'DRAFT':
        return AppTheme.warning;
      case 'EXPIRED':
      case 'INACTIVE':
        return AppTheme.textMuted;
      default:
        return AppTheme.primary;
    }
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSpecialBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primary,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, String> stats) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: stats.entries
            .map((e) => _buildStatItem(e.key, e.value))
            .toList(),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    IconData icon;
    switch (label) {
      case 'Orders':
        icon = Icons.shopping_cart_outlined;
        break;
      case 'Views':
        icon = Icons.visibility_outlined;
        break;
      case 'Revenue':
        icon = Icons.payments_outlined;
        break;
      case 'CVR':
        icon = Icons.insights_outlined;
        break;
      default:
        icon = Icons.bar_chart;
    }
    return Column(
      children: [
        Icon(icon, size: 18, color: AppTheme.primary),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        Text(
          label,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 10),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap) {
    IconData icon;
    switch (label) {
      case 'View':
        icon = Icons.visibility_outlined;
        break;
      case 'Edit':
        icon = Icons.edit_outlined;
        break;
      case 'Duplicate':
        icon = Icons.copy_outlined;
        break;
      case 'Pause':
        icon = Icons.pause_circle_outline;
        break;
      default:
        icon = Icons.circle;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textMuted,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final packages = _filteredPackages;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.menu), onPressed: () {}),
        title: const Text('Package Management'),
        actions: [
          IconButton(
            onPressed: () {},
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
                color: Colors.white,
              ),
              child: const Icon(Icons.tune, color: AppTheme.primary, size: 20),
            ),
          ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.primary, width: 1.5),
              ),
              child: const CircleAvatar(
                radius: 14,
                backgroundImage: NetworkImage(
                  'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=100',
                ),
              ),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openPackageBuilder,
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildSearchAndFilter(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadPackages,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        if (_errorMessage != null) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.error.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: AppTheme.error),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const Text(
                          'Active Campaigns',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'You have ${packages.length} promotional packages running this month.',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildCreateButton(),
                        const SizedBox(height: 24),
                        if (packages.isEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 48),
                            alignment: Alignment.center,
                            child: const Column(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  size: 56,
                                  color: AppTheme.textMuted,
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'No promotional packages found',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textMain,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Create a package to see it here.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ...packages.map(
                            (package) => _buildPackageCard(package: package),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
