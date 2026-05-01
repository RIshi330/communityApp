import 'package:flutter/material.dart';
import 'package:commity_app1/Database/Database.dart';

// ════════════════════════════════════════════════════════════════════════════
// COLORS
// ════════════════════════════════════════════════════════════════════════════
class AppColors {
  static const accent = Color(0xFF7C83FD);
  static const accent2 = Color(0xFF9EA3FF);
  static const accentSoft = Color(0xFFEEEFFF);
  static const bg = Color(0xFFF5F5FF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E5FF);
  static const muted = Color(0xFF6B7280);
  static const text = Color(0xFF1A1A2E);
  static const success = Color(0xFF10B981);
  static const lavenderBg = Color(0xFFF3E8FF);
  static const textDark = Color(0xFF1F1F1F);
  static const textMuted = Color(0xFF6B7280);
}

// ════════════════════════════════════════════════════════════════════════════
// MODELS
// ════════════════════════════════════════════════════════════════════════════
class Community {
  final String name;
  final String members;
  const Community({required this.name, required this.members});
}

class Package {
  final int id;
  final String title;
  final String community;
  final List<String> badges;
  final String? reach;
  final String? ctr;
  final String? duration;
  final String price;
  final String type;
  final String pricingModel;
  final String description;
  final List<String> features;
  final List<String> targetAudience;
  final List<String> interests;
  final int aiMatchPercent;

  const Package({
    this.id = 0,
    required this.title,
    required this.community,
    required this.badges,
    this.reach,
    this.ctr,
    this.duration,
    required this.price,
    required this.type,
    required this.pricingModel,
    this.description =
        'Boost your opportunity to reach targeted users with AI-powered distribution. Get maximum visibility across the platform with smart placement.',
    this.features = const [
      'Homepage featured listing',
      'AI recommendation boost',
      'Search top ranking',
      'Targeted reach',
      'Analytics dashboard access',
    ],
    this.targetAudience = const ['Students', 'Entrepreneurs', 'Creators'],
    this.interests = const ['Marketing', 'Startups', 'Tech'],
    this.aiMatchPercent = 88,
  });

  /// Parse from API response (handles get_home_feed & get_package_details)
  factory Package.fromJson(Map<String, dynamic> json) {
    final id = int.tryParse(
          json['id']?.toString() ?? json['item_id']?.toString() ?? '0',
        ) ?? 0;

    final title = json['name']?.toString() ??
        json['title']?.toString() ??
        json['package_name']?.toString() ??
        'Untitled';

    String community = '';
    if (json['community'] is Map) {
      community = (json['community'] as Map)['title']?.toString() ?? '';
    } else {
      community = json['community']?.toString() ?? '';
    }

    final description =
        json['description']?.toString() ?? 'No description available';

    final type =
        json['item_type']?.toString() ?? json['type']?.toString() ?? 'Product';

    // Pricing
    String price = '₹0';
    String pricingModel = 'Fixed';
    if (json['pricing'] is Map) {
      final pr = json['pricing'] as Map;
      price = '₹${pr['amount'] ?? pr['price'] ?? pr['base_price'] ?? 0}';
      pricingModel = pr['model']?.toString() ?? 'Fixed';
    } else if (json['amount'] != null) {
      price = '₹${json['amount']}';
    }

    // Duration
    String? duration;
    if (json['duration_value'] != null && json['duration_type'] != null) {
      duration = '${json['duration_value']} ${json['duration_type']}';
    } else if (json['duration'] != null) {
      duration = json['duration'].toString();
    }

    // Features
    List<String> features = [];
    if (json['features'] is List) {
      features = (json['features'] as List).map((e) => e.toString()).toList();
    } else if (json['features'] is Map) {
      features =
          (json['features'] as Map).values.map((e) => e.toString()).toList();
    }

    // Placements → badges
    List<String> badges = [];
    if (json['placements'] is Map) {
      badges =
          (json['placements'] as Map).keys.map((e) => e.toString()).toList();
    } else if (json['placements'] is List) {
      badges =
          (json['placements'] as List).map((e) => e.toString()).toList();
    } else if (json['badges'] is List) {
      badges = (json['badges'] as List).map((e) => e.toString()).toList();
    }

    // Reach
    String? reach;
    if (json['reach'] is Map) {
      final r = json['reach'] as Map;
      reach = r['total']?.toString() ?? r['estimated']?.toString();
    } else if (json['impressions'] != null) {
      final imp = int.tryParse(json['impressions'].toString()) ?? 0;
      reach = imp >= 1000
          ? '${(imp / 1000).toStringAsFixed(imp >= 10000 ? 0 : 1)}K'
          : imp.toString();
    } else if (json['reach'] != null) {
      reach = json['reach'].toString();
    }

    // Targeting → targetAudience
    List<String> targetAudience = [];
    if (json['targeting'] is Map) {
      final t = json['targeting'] as Map;
      if (t['audience'] is List) {
        targetAudience =
            (t['audience'] as List).map((e) => e.toString()).toList();
      } else if (t['demographics'] is List) {
        targetAudience =
            (t['demographics'] as List).map((e) => e.toString()).toList();
      }
    }
    if (targetAudience.isEmpty) targetAudience = const ['General'];

    // applicable_to → interests
    List<String> interests = [];
    if (json['applicable_to'] is List) {
      interests =
          (json['applicable_to'] as List).map((e) => e.toString()).toList();
    } else if (json['interests'] is List) {
      interests =
          (json['interests'] as List).map((e) => e.toString()).toList();
    }
    if (interests.isEmpty) interests = const ['General'];

    return Package(
      id: id,
      title: title,
      community: community,
      badges: badges,
      reach: reach,
      duration: duration,
      price: price,
      type: type,
      pricingModel: pricingModel,
      description: description,
      features: features,
      targetAudience: targetAudience,
      interests: interests,
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SAMPLE DATA
// ════════════════════════════════════════════════════════════════════════════
const List<Community> topCommunities = [
  Community(name: 'Startup Hub', members: '120K members'),
  Community(name: 'Student Network', members: '95K members'),
  Community(name: 'Creator Club', members: '80K members'),
];

final List<Package> allPackages = [
  const Package(
    title: 'Growth Boost',
    community: 'Startup Hub',
    badges: ['Featured', 'AI Boost'],
    reach: '25K',
    ctr: '4.5%',
    price: '₹999',
    type: 'Product',
    pricingModel: 'Fixed',
    duration: '7 days',
    description:
        'Boost your opportunity with AI-powered distribution. Get maximum visibility across the platform with smart placement and real-time analytics.',
    features: [
      'Homepage featured listing',
      'AI recommendation boost',
      'Search top ranking',
      '25K+ targeted reach',
      'Analytics dashboard',
    ],
    targetAudience: ['Students', 'Entrepreneurs', 'Creators'],
    interests: ['Marketing', 'Startups', 'Tech'],
    aiMatchPercent: 92,
  ),
  const Package(
    title: 'Premium Investor Boost',
    community: 'Investor Circle',
    badges: ['Trending', 'Homepage'],
    reach: '100K',
    price: '₹2999',
    type: 'Event',
    pricingModel: 'Commission',
    duration: '15+ days',
    description:
        'Reach top investors and decision makers with premium homepage placement and trending visibility.',
    features: [
      'Homepage banner slot',
      'Investor feed priority',
      'Email blast to 10K investors',
      '100K reach',
      'ROI tracking',
    ],
    targetAudience: ['Investors', 'Founders', 'VCs'],
    interests: ['Investment', 'Finance', 'Startups'],
    aiMatchPercent: 85,
  ),
  const Package(
    title: 'Starter Boost',
    community: 'Student Network',
    badges: ['Search Boost', 'Feed Ads'],
    reach: '5K',
    price: '₹199',
    type: 'Product',
    pricingModel: 'Fixed',
    duration: '1-3 days',
    description:
        'Perfect entry-level boost for student-focused opportunities. Affordable and effective for short campaigns.',
    features: [
      'Search boost listing',
      'Feed ad placement',
      '5K student reach',
      'Basic analytics',
    ],
    targetAudience: ['Students', 'Freshers'],
    interests: ['Internships', 'Learning', 'Campus'],
    aiMatchPercent: 78,
  ),
  const Package(
    title: 'Business Expansion Pack',
    community: 'Startup Hub',
    badges: ['Featured', 'Priority'],
    reach: '40K',
    price: '₹1499',
    type: 'Product',
    pricingModel: 'Hybrid',
    duration: '7 days',
    description:
        'Scale your business reach with priority placement and featured listings across the Startup Hub community.',
    features: [
      'Priority listing',
      'Featured placement',
      '40K reach',
      'A/B testing',
      'Dedicated support',
    ],
    targetAudience: ['Entrepreneurs', 'SMBs', 'Founders'],
    interests: ['Business', 'Growth', 'Marketing'],
    aiMatchPercent: 89,
  ),
  const Package(
    title: 'Campus Recruitment Drive',
    community: 'Student Network',
    badges: ['Job Portal', 'Featured'],
    reach: '15K',
    ctr: '3.2%',
    price: '₹799',
    type: 'Job',
    pricingModel: 'Per Action',
    duration: '7 days',
    description:
        'Drive quality applications from top students with campus-targeted job promotion and featured portal listing.',
    features: [
      'Job portal feature',
      'Campus targeting',
      '15K student reach',
      'Application tracking',
      'Resume filter access',
    ],
    targetAudience: ['Final Year Students', 'Freshers', 'Interns'],
    interests: ['Jobs', 'Placements', 'Career'],
    aiMatchPercent: 91,
  ),
  const Package(
    title: 'Tech Conference Promo',
    community: 'Startup Hub',
    badges: ['Event Highlight', 'Trending'],
    reach: '50K',
    ctr: '5.1%',
    price: '₹1999',
    type: 'Event',
    pricingModel: 'Fixed',
    duration: '15+ days',
    description:
        'Promote your tech conference to 50K+ startup enthusiasts with trending event placement.',
    features: [
      'Event highlight banner',
      'Trending section',
      '50K reach',
      'Early bird promo',
      'Social share boost',
    ],
    targetAudience: ['Developers', 'Entrepreneurs', 'Tech Enthusiasts'],
    interests: ['Technology', 'Conferences', 'Networking'],
    aiMatchPercent: 87,
  ),
  const Package(
    title: 'AI/ML Training Program',
    community: 'Creator Club',
    badges: ['Training', 'Certificate'],
    reach: '8K',
    price: '₹599',
    type: 'Training',
    pricingModel: 'Commission',
    duration: '15+ days',
    description:
        'Showcase your AI/ML course to tech-savvy creators with certificate-linked promotion.',
    features: [
      'Course listing',
      'Certificate badge',
      '8K reach',
      'Commission-based',
      'Creator community feature',
    ],
    targetAudience: ['Developers', 'Data Scientists', 'Students'],
    interests: ['AI', 'Machine Learning', 'Technology'],
    aiMatchPercent: 83,
  ),
  const Package(
    title: 'Freelance Job Board',
    community: 'Creator Club',
    badges: ['Remote Jobs', 'Verified'],
    reach: '20K',
    ctr: '4.0%',
    price: '₹499',
    type: 'Job',
    pricingModel: 'Commission',
    duration: '7 days',
    description:
        'Post your freelance opportunity to verified creators and remote workers.',
    features: [
      'Verified badge',
      'Remote job listing',
      '20K reach',
      'Creator targeting',
      'Application alerts',
    ],
    targetAudience: ['Freelancers', 'Creators', 'Remote Workers'],
    interests: ['Freelancing', 'Remote Work', 'Design'],
    aiMatchPercent: 80,
  ),
  const Package(
    title: 'Product Launch Kit',
    community: 'Startup Hub',
    badges: ['Featured', 'Launch Special'],
    reach: '35K',
    ctr: '6.2%',
    price: '₹1299',
    type: 'Product',
    pricingModel: 'Fixed',
    duration: '1-3 days',
    description:
        'Launch your product with a bang using our special launch kit with maximum initial visibility.',
    features: [
      'Launch day feature',
      'Homepage banner',
      '35K reach',
      'Launch countdown',
      'Press kit support',
    ],
    targetAudience: ['Product Enthusiasts', 'Early Adopters', 'Startups'],
    interests: ['Product Launches', 'Innovation', 'Tech'],
    aiMatchPercent: 94,
  ),
  const Package(
    title: 'Web Dev Bootcamp',
    community: 'Student Network',
    badges: ['Training', 'Placement Support'],
    reach: '12K',
    price: '₹899',
    type: 'Training',
    pricingModel: 'Hybrid',
    duration: '15+ days',
    description:
        'Promote your web development bootcamp with placement-focused student targeting.',
    features: [
      'Bootcamp listing',
      'Placement badge',
      '12K reach',
      'Student targeting',
      'Hybrid pricing',
    ],
    targetAudience: ['Students', 'Career Changers', 'Beginners'],
    interests: ['Web Dev', 'Coding', 'Career'],
    aiMatchPercent: 82,
  ),
  const Package(
    title: 'Startup Meetup Series',
    community: 'Startup Hub',
    badges: ['Event', 'Networking'],
    reach: '18K',
    ctr: '3.8%',
    price: '₹399',
    type: 'Event',
    pricingModel: 'Per Action',
    duration: '7 days',
    description:
        'Grow attendance at your startup meetup with community-driven event promotion.',
    features: [
      'Event listing',
      'Networking badge',
      '18K reach',
      'RSVP tracking',
      'Community newsletter',
    ],
    targetAudience: ['Founders', 'Entrepreneurs', 'Investors'],
    interests: ['Networking', 'Startups', 'Events'],
    aiMatchPercent: 76,
  ),
  const Package(
    title: 'Design Internship',
    community: 'Student Network',
    badges: ['Job', 'Entry Level'],
    reach: '10K',
    price: '₹299',
    type: 'Job',
    pricingModel: 'Fixed',
    duration: '1-3 days',
    description:
        'Find talented design interns from the student network with targeted job placement.',
    features: [
      'Job listing',
      'Entry level badge',
      '10K reach',
      'Portfolio filter',
      'Quick apply',
    ],
    targetAudience: ['Design Students', 'Freshers', 'Interns'],
    interests: ['Design', 'UI/UX', 'Internships'],
    aiMatchPercent: 79,
  ),
  const Package(
    title: 'Digital Marketing Course',
    community: 'Creator Club',
    badges: ['Training', 'Expert Led'],
    reach: '22K',
    ctr: '4.7%',
    price: '₹1099',
    type: 'Training',
    pricingModel: 'Per Action',
    duration: '15+ days',
    description:
        'Promote your expert-led digital marketing course to creators and marketers.',
    features: [
      'Expert badge',
      'Course feature',
      '22K reach',
      'Expert-led tag',
      'Course analytics',
    ],
    targetAudience: ['Marketers', 'Creators', 'Entrepreneurs'],
    interests: ['Digital Marketing', 'Social Media', 'Growth'],
    aiMatchPercent: 86,
  ),
  const Package(
    title: 'Product Manager Opening',
    community: 'Startup Hub',
    badges: ['Job', 'High Salary'],
    reach: '30K',
    ctr: '5.5%',
    price: '₹1499',
    type: 'Job',
    pricingModel: 'Hybrid',
    duration: '7 days',
    description:
        'Attract top product talent with high-visibility job promotion across the startup community.',
    features: [
      'High salary badge',
      'Featured job',
      '30K reach',
      'PM community target',
      'Application boost',
    ],
    targetAudience: ['Product Managers', 'Entrepreneurs', 'MBAs'],
    interests: ['Product', 'Strategy', 'Tech'],
    aiMatchPercent: 90,
  ),
];

// ════════════════════════════════════════════════════════════════════════════
// HELPER
// ════════════════════════════════════════════════════════════════════════════
String communityMembers(String name) {
  try {
    return topCommunities.firstWhere((c) => c.name == name).members;
  } catch (_) {
    return 'Community';
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SCREEN 1 — MARKETPLACE
// ════════════════════════════════════════════════════════════════════════════
class MarketplaceScreen2 extends StatefulWidget {
  const MarketplaceScreen2({super.key});
  @override
  State<MarketplaceScreen2> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen2> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selType = 'All';
  String _selPricing = 'All';
  String _selCommunity = 'All Communities';
  String _selDuration = 'Any';

  final Database _database = Database();
  bool _loading = true;
  String? _error;
  List<Package> _packages = [];
  List<Community> _communities = [];

  int get _activeCount {
    int c = 0;
    if (_selType != 'All') c++;
    if (_selPricing != 'All') c++;
    if (_selCommunity != 'All Communities') c++;
    if (_selDuration != 'Any') c++;
    return c;
  }

  List<Package> get _filtered => _packages.where((p) {
    if (_selType != 'All' && p.type != _selType) return false;
    if (_selPricing != 'All' && p.pricingModel != _selPricing) return false;
    if (_selCommunity != 'All Communities' && p.community != _selCommunity)
      return false;
    if (_selDuration != 'Any') {
      if (p.duration == null) return false;
      if (_selDuration == '1–3 days' && p.duration != '1-3 days') return false;
      if (_selDuration == '7 days' && p.duration != '7 days') return false;
      if (_selDuration == '15+ days' && p.duration != '15+ days') return false;
    }
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      return p.title.toLowerCase().contains(q) ||
          p.community.toLowerCase().contains(q) ||
          p.badges.any((b) => b.toLowerCase().contains(q));
    }
    return true;
  }).toList();

  List<Package> get _topPkgs => _filtered.take(2).toList();
  List<Package> get _restPkgs => _filtered.skip(2).toList();

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _database.getData({
        'action': 'get_packages',
        'status': 1,
      });

      if (response['success'] == true || response['status'] == 200) {
        final dynamic payload = response['data'];
        final List<dynamic> items = payload is List
            ? payload
            : (payload is Map
                ? (payload['packages'] as List<dynamic>? ??
                    payload['feed'] as List<dynamic>? ??
                    const [])
                : const []);

        final packages = items
            .whereType<Map>()
            .map((item) => Package.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (packages.isNotEmpty) {
          _applyPackagesAndCommunities(packages);
        } else {
          _useFallbackData();
        }
      } else {
        _useFallbackData();
      }
    } catch (error) {
      debugPrint('Error loading packages: $error');
      _useFallbackData();
    }
  }

  void _applyPackagesAndCommunities(List<Package> packages) {
    final communityCounts = <String, int>{};
    for (final package in packages) {
      if (package.community.trim().isEmpty) continue;
      communityCounts[package.community] =
          (communityCounts[package.community] ?? 0) + 1;
    }

    final communities = communityCounts.entries
        .map((entry) => Community(
              name: entry.key,
              members: '${entry.value} packages',
            ))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (mounted) {
      setState(() {
        _packages = packages;
        _communities = communities;
        _loading = false;
      });
    }
  }

  void _useFallbackData() {
    _applyPackagesAndCommunities(List<Package>.from(allPackages));
  }

  Widget _errorState() => Container(
    padding: const EdgeInsets.all(32),
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      children: [
        const Icon(Icons.cloud_off_rounded, size: 44, color: AppColors.accent),
        const SizedBox(height: 12),
        const Text(
          'Unable to load packages',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Text(
          _error ?? 'Unknown error',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _loadPackages,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Retry'),
        ),
      ],
    ),
  );

  void _goBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  // card tap → Detail Screen
  void _goDetail(Package pkg) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => PackageDetailScreen(package: pkg)),
  );

  // ── "Buy" button → BuyModelScreen (full screen) ──────────────────────────
  void _openBuyModel(Package pkg) => Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => BuyModelScreen(package: pkg),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _goBack,
        ),
        title: const Text(
          'Promotion Marketplace',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg, Color(0xFFEEF8F9)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSearchRow(),
                const SizedBox(height: 16),
                if (_activeCount > 0) ...[
                  _buildActiveFilters(),
                  const SizedBox(height: 16),
                ],
                _buildBody(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchRow() => Row(
    children: [
      Expanded(
        child: TextField(
          controller: _searchCtrl,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search packages, communities...',
            hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(Icons.search, color: AppColors.muted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
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
                onTap: _showFilterSheet,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(14),
                  child: const Icon(Icons.tune, color: Colors.white, size: 24),
                ),
              ),
            ),
          ),
          if (_activeCount > 0)
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
                  '$_activeCount',
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
  );

  Widget _buildBody() => Column(
    children: [
      if (_loading)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 72),
          child: Center(child: CircularProgressIndicator()),
        )
      else if (_error != null)
        _errorState()
      else ...[
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
                '${_filtered.length} packages available',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _section(
          '🔥 Top Communities',
          Column(children: _communities.map(_communityTile).toList()),
        ),
        const SizedBox(height: 16),
        if (_topPkgs.isNotEmpty) ...[
          _section(
            '🚀 Top Performing Packages',
            _grid(_topPkgs, compare: false),
          ),
          const SizedBox(height: 16),
        ],
        if (_restPkgs.isNotEmpty)
          _section('All Packages', _grid(_restPkgs, compare: true)),
        if (_filtered.isEmpty) _emptyState(),
      ],
    ],
  );

  Widget _section(String title, Widget child) => Container(
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

  Widget _communityTile(Community c) => Container(
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
              c.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        Text(
          c.members,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
      ],
    ),
  );

  Widget _grid(List<Package> pkgs, {required bool compare}) => LayoutBuilder(
    builder: (ctx, cons) {
      final cols = cons.maxWidth > 600 ? 2 : 1;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
        ),
        itemCount: pkgs.length,
        itemBuilder: (_, i) => _card(pkgs[i], compare: compare),
      );
    },
  );

  Widget _card(Package p, {required bool compare}) => GestureDetector(
    onTap: () => _goDetail(p),
    child: Container(
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
                  p.title,
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
                  color: _typeColor(p.type).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.type,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _typeColor(p.type),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            p.community,
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
                  _pricingIcon(p.pricingModel),
                  size: 13,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 5),
                Text(
                  p.pricingModel,
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
            children: p.badges.map(_badge).toList(),
          ),
          const SizedBox(height: 8),
          if (p.reach != null)
            Row(
              children: [
                const Icon(Icons.visibility, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  p.ctr != null
                      ? 'Reach: ${p.reach} • CTR: ${p.ctr}'
                      : 'Reach: ${p.reach}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
          if (p.duration != null)
            Row(
              children: [
                const Icon(Icons.schedule, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  p.duration!,
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
                    p.price,
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
                  // "Buy" button → opens BuyModelScreen (full screen)
                  ElevatedButton(
                    onPressed: () => _openBuyModel(p),
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
                  if (compare) ...[
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
    ),
  );

  Widget _badge(String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
    ),
  );

  Widget _emptyState() => Container(
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
            _selType = 'All';
            _selPricing = 'All';
            _selCommunity = 'All Communities';
            _selDuration = 'Any';
            _searchCtrl.clear();
          }),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Reset All Filters'),
        ),
      ],
    ),
  );

  Widget _buildActiveFilters() => Container(
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
                _selType = 'All';
                _selPricing = 'All';
                _selCommunity = 'All Communities';
                _selDuration = 'Any';
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
            if (_selType != 'All')
              _chip('Type: $_selType', () => setState(() => _selType = 'All')),
            if (_selPricing != 'All')
              _chip(
                'Pricing: $_selPricing',
                () => setState(() => _selPricing = 'All'),
              ),
            if (_selCommunity != 'All Communities')
              _chip(
                'Community: $_selCommunity',
                () => setState(() => _selCommunity = 'All Communities'),
              ),
            if (_selDuration != 'Any')
              _chip(
                'Duration: $_selDuration',
                () => setState(() => _selDuration = 'Any'),
              ),
          ],
        ),
      ],
    ),
  );

  Widget _chip(String label, VoidCallback onRemove) => Container(
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

  void _showFilterSheet() {
    String tType = _selType,
        tPricing = _selPricing,
        tCom = _selCommunity,
        tDur = _selDuration;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
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
                          onPressed: () => Navigator.pop(ctx),
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
                      _fSection(
                        'Package Type',
                        Icons.category_rounded,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              ['All', 'Product', 'Job', 'Event', 'Training']
                                  .map(
                                    (t) => _fChip(
                                      t,
                                      tType == t,
                                      () => setModal(() => tType = t),
                                      _typeColor(t),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _fSection(
                        'Pricing Model',
                        Icons.payments_rounded,
                        Wrap(
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
                                    (p) => _fChip(
                                      p,
                                      tPricing == p,
                                      () => setModal(() => tPricing = p),
                                      null,
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _fSection(
                        'Community',
                        Icons.groups_rounded,
                        Column(
                          children:
                              [
                                    'All Communities',
                                    'Startup Hub',
                                    'Student Network',
                                    'Creator Club',
                                    'Investor Circle',
                                  ]
                                  .map(
                                    (c) => _fRadio(
                                      c,
                                      c == 'Startup Hub'
                                          ? '120K members'
                                          : c == 'Student Network'
                                          ? '95K members'
                                          : c == 'Creator Club'
                                          ? '80K members'
                                          : null,
                                      tCom == c,
                                      () => setModal(() => tCom = c),
                                    ),
                                  )
                                  .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _fSection(
                        'Duration',
                        Icons.schedule_rounded,
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: ['Any', '1–3 days', '7 days', '15+ days']
                              .map(
                                (d) => _fChip(
                                  d,
                                  tDur == d,
                                  () => setModal(() => tDur = d),
                                  null,
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
                          onPressed: () => setModal(() {
                            tType = 'All';
                            tPricing = 'All';
                            tCom = 'All Communities';
                            tDur = 'Any';
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
                              _selType = tType;
                              _selPricing = tPricing;
                              _selCommunity = tCom;
                              _selDuration = tDur;
                            });
                            Navigator.pop(ctx);
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
        ),
      ),
    );
  }

  Widget _fSection(String title, IconData icon, Widget child) => Column(
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

  Widget _fChip(String label, bool sel, VoidCallback onTap, Color? color) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: sel ? (color ?? AppColors.accent) : Colors.white,
            border: Border.all(
              color: sel ? (color ?? AppColors.accent) : AppColors.border,
              width: sel ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
              color: sel ? Colors.white : AppColors.text,
            ),
          ),
        ),
      );

  Widget _fRadio(String label, String? sub, bool sel, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? AppColors.accent.withOpacity(0.1) : Colors.white,
            border: Border.all(
              color: sel ? AppColors.accent : AppColors.border,
              width: sel ? 2 : 1,
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
                    color: sel ? AppColors.accent : AppColors.border,
                    width: 2,
                  ),
                  color: sel ? AppColors.accent : Colors.white,
                ),
                child: sel
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
                        fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                        color: AppColors.text,
                      ),
                    ),
                    if (sub != null)
                      Text(
                        sub,
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

  Color _typeColor(String t) {
    switch (t) {
      case 'Product':
        return const Color(0xFF10B981);
      case 'Job':
        return const Color(0xFF3B82F6);
      case 'Event':
        return const Color(0xFFF59E0B);
      case 'Training':
        return const Color(0xFF8B5CF6);
      default:
        return AppColors.accent;
    }
  }

  IconData _pricingIcon(String m) {
    switch (m) {
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

}

// ════════════════════════════════════════════════════════════════════════════
// SCREEN 2 — PACKAGE DETAIL
// ════════════════════════════════════════════════════════════════════════════
class PackageDetailScreen extends StatefulWidget {
  final Package package;
  const PackageDetailScreen({super.key, required this.package});
  @override
  State<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends State<PackageDetailScreen> {
  bool _push = false;
  bool _infl = false;
  String _opportunity = 'Select Opportunity';

  final Database _database = Database();
  late Package _pkg;
  bool _detailLoading = false;

  @override
  void initState() {
    super.initState();
    _pkg = widget.package;
    _fetchPackageDetails();
    _trackEngagement('views');
  }

  Package get pkg => _pkg;
  int get _base =>
      int.tryParse(pkg.price.replaceAll('₹', '').replaceAll(',', '')) ?? 0;
  int get _addon => (_push ? 199 : 0) + (_infl ? 499 : 0);
  int get _total => _base + _addon;

  /// Fetch full package details from API
  Future<void> _fetchPackageDetails() async {
    if (_pkg.id <= 0) return;
    setState(() => _detailLoading = true);
    try {
      final response = await _database.getData({
        'action': 'get_package_details',
        'id': _pkg.id.toString(),
      });
      if (response['success'] == true || response['status'] == 200) {
        final data = response['data'];
        if (data is Map) {
          if (mounted) {
            setState(() {
              _pkg = Package.fromJson(Map<String, dynamic>.from(data));
              _detailLoading = false;
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching package details: $e');
    }
    if (mounted) setState(() => _detailLoading = false);
  }

  /// Track engagement (views, likes, share)
  Future<void> _trackEngagement(String type) async {
    if (_pkg.id <= 0) return;
    try {
      await _database.getData({
        'action': 'track_engagement',
        'package_id': _pkg.id.toString(),
        'type': type,
      });
    } catch (_) {}
  }

  // "Proceed to Payment" → BuyModelScreen
  void _openPayment() => Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) =>
          BuyModelScreen(package: pkg, pushAddon: _push, inflAddon: _infl),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.accent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Package Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () => _trackEngagement('share'),
          ),
          IconButton(
            icon: const Icon(
              Icons.bookmark_border_rounded,
              color: Colors.white,
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          if (_detailLoading)
            const LinearProgressIndicator(
              color: AppColors.accent,
              backgroundColor: AppColors.accentSoft,
              minHeight: 3,
            ),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (ctx, cons) {
            if (cons.maxWidth > 700) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _left()),
                  const SizedBox(width: 14),
                  SizedBox(width: 320, child: _right()),
                ],
              );
            }
            return Column(
              children: [_left(), const SizedBox(height: 14), _right()],
            );
          },
        ),
      ),
          ),
        ],
      ),
    );
  }

  Widget _left() => Column(
    children: [
      _hero(),
      const SizedBox(height: 12),
      _features(),
      const SizedBox(height: 12),
      _targeting(),
      const SizedBox(height: 12),
      _ai(),
    ],
  );

  Widget _hero() => _DCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accent2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_pkgIcon(), color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        size: 14,
                        color: AppColors.muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${pkg.community} • ${communityMembers(pkg.community)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: pkg.badges.map((b) => _DBadge(b)).toList(),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            pkg.description,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.text,
              height: 1.6,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (pkg.reach != null)
              _StatChip(
                icon: Icons.visibility_rounded,
                label: '${pkg.reach} Reach',
              ),
            if (pkg.ctr != null)
              _StatChip(
                icon: Icons.trending_up_rounded,
                label: '${pkg.ctr} CTR',
              ),
            if (pkg.duration != null)
              _StatChip(icon: Icons.schedule_rounded, label: pkg.duration!),
          ],
        ),
      ],
    ),
  );

  Widget _features() => _DCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DSectionTitle(
          icon: Icons.star_rounded,
          title: 'Package Features',
        ),
        const SizedBox(height: 12),
        ...pkg.features.map(
          (f) => _FeatureRow(icon: _featureIcon(f), label: f),
        ),
      ],
    ),
  );

  Widget _targeting() => _DCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _DSectionTitle(
          icon: Icons.gps_fixed_rounded,
          title: 'Target Audience',
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: pkg.targetAudience.map((b) => _DBadge(b)).toList(),
        ),
        const SizedBox(height: 14),
        const _DSectionTitle(icon: Icons.interests_rounded, title: 'Interests'),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: pkg.interests.map((b) => _DBadge(b)).toList(),
        ),
      ],
    ),
  );

  Widget _ai() => _DCard(
    gradient: const LinearGradient(
      colors: [Color(0xFFF0F0FF), Color(0xFFE8F4FF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.psychology,
                size: 20,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'AI Recommendation',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'Based on your activity:',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...[
          'You posted a ${pkg.type} opportunity',
          'Your audience matches ${pkg.targetAudience.first}',
          '${pkg.interests.first} category detected',
        ].map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.accent,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(fontSize: 13, color: AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accent2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommended: ${pkg.title}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${pkg.aiMatchPercent}% match',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _right() =>
      Column(children: [_buyCard(), const SizedBox(height: 12), _similar()]);

  Widget _buyCard() => _DCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              pkg.price,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${pkg.duration ?? ''} • ${pkg.pricingModel}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const _DDivider(),
        const _DSectionTitle(
          icon: Icons.add_circle_outline_rounded,
          title: 'Add-ons',
        ),
        const SizedBox(height: 10),
        _AddonCheckbox(
          label: 'Push Notification',
          price: '+₹199',
          value: _push,
          onChanged: (v) => setState(() => _push = v ?? false),
        ),
        const SizedBox(height: 8),
        _AddonCheckbox(
          label: 'Influencer Boost',
          price: '+₹499',
          value: _infl,
          onChanged: (v) => setState(() => _infl = v ?? false),
        ),
        const SizedBox(height: 14),
        const _DDivider(),
        const _DSectionTitle(
          icon: Icons.receipt_long_rounded,
          title: 'Price Breakdown',
        ),
        const SizedBox(height: 10),
        _PriceRow(label: 'Base Package', value: pkg.price),
        if (_push) const _PriceRow(label: 'Push Notification', value: '+₹199'),
        if (_infl) const _PriceRow(label: 'Influencer Boost', value: '+₹499'),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: AppColors.text,
                ),
              ),
              Text(
                '₹$_total',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.accent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const _DDivider(),
        const _DSectionTitle(
          icon: Icons.campaign_rounded,
          title: 'Campaign Setup',
        ),
        const SizedBox(height: 10),
        const _InputField(hint: 'Campaign Title', icon: Icons.edit_outlined),
        const SizedBox(height: 8),
        _DropdownField(
          value: _opportunity,
          items: const [
            'Select Opportunity',
            'Campus Ambassador Job',
            'Product Launch',
          ],
          onChanged: (v) => setState(() => _opportunity = v ?? _opportunity),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _openPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline_rounded, size: 16),
                SizedBox(width: 8),
                Text(
                  'Proceed to Payment',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            '🔒 Secure checkout • Instant activation',
            style: TextStyle(fontSize: 11, color: AppColors.muted),
          ),
        ),
      ],
    ),
  );

  Widget _similar() {
    final others = allPackages
        .where((p) => p.title != pkg.title && p.type == pkg.type)
        .take(3)
        .toList();
    if (others.isEmpty) return const SizedBox.shrink();
    return _DCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _DSectionTitle(
            icon: Icons.grid_view_rounded,
            title: 'Similar Packages',
          ),
          const SizedBox(height: 10),
          ...others.map(
            (p) => GestureDetector(
              onTap: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => PackageDetailScreen(package: p),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.local_offer_rounded,
                            size: 14,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          p.title,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          p.price,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accent,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentSoft,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'View',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _pkgIcon() {
    switch (pkg.type) {
      case 'Job':
        return Icons.work;
      case 'Event':
        return Icons.event;
      case 'Training':
        return Icons.school;
      default:
        return Icons.rocket_launch_rounded;
    }
  }

  IconData _featureIcon(String f) {
    if (f.contains('Homepage')) return Icons.home_rounded;
    if (f.contains('AI')) return Icons.auto_awesome_rounded;
    if (f.contains('Search')) return Icons.search_rounded;
    if (f.contains('each')) return Icons.radar_rounded;
    if (f.contains('Analytics')) return Icons.bar_chart_rounded;
    if (f.contains('Email')) return Icons.email_rounded;
    if (f.contains('ROI')) return Icons.track_changes_rounded;
    if (f.contains('Certificate')) return Icons.verified_rounded;
    if (f.contains('Placement')) return Icons.work_rounded;
    if (f.contains('Application')) return Icons.description_rounded;
    return Icons.check_circle_outline_rounded;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SCREEN 3 — BUY MODEL SCREEN (full screen, replaces bottom sheet on Buy tap)
// ════════════════════════════════════════════════════════════════════════════
class BuyModelScreen extends StatefulWidget {
  final Package package;
  final bool pushAddon;
  final bool inflAddon;
  const BuyModelScreen({
    super.key,
    required this.package,
    this.pushAddon = false,
    this.inflAddon = false,
  });
  @override
  State<BuyModelScreen> createState() => _BuyModelScreenState();
}

class _BuyModelScreenState extends State<BuyModelScreen> {
  final _ecashCtrl = TextEditingController();
  final _ebankCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();
  final _campaignTitleCtrl = TextEditingController();

  final int ecashBal = 500;
  final int ebankBal = 1200;
  int discount = 0;
  String couponMsg = '';
  bool couponApplied = false;

  late bool _push;
  late bool _infl;
  String _opportunity = 'Select Opportunity';
  DateTime? _scheduleDate;
  TimeOfDay? _scheduleTime;
  String _scheduleFrequency = 'one-time';

  Package get pkg => widget.package;

  @override
  void initState() {
    super.initState();
    _push = widget.pushAddon;
    _infl = widget.inflAddon;
  }

  int get _base =>
      int.tryParse(pkg.price.replaceAll('₹', '').replaceAll(',', '')) ?? 0;
  int get _addon => (_push ? 199 : 0) + (_infl ? 499 : 0);
  int get _packageTotal => _base + _addon;

  int get _walletUsed {
    final eu = (int.tryParse(_ecashCtrl.text) ?? 0).clamp(0, ecashBal);
    final bu = (int.tryParse(_ebankCtrl.text) ?? 0).clamp(0, ebankBal);
    return (eu + bu).clamp(0, _packageTotal - discount);
  }

  int get _finalPrice =>
      (_packageTotal - discount - _walletUsed).clamp(0, _packageTotal);

  void _applyCoupon() {
    final code = _couponCtrl.text.trim().toUpperCase();
    setState(() {
      if (code == 'SAVE100') {
        discount = 100;
        couponMsg = 'Coupon Applied — ₹100 off!';
        couponApplied = true;
      } else if (code == 'WELCOME50') {
        discount = 50;
        couponMsg = 'Coupon Applied — ₹50 off!';
        couponApplied = true;
      } else {
        discount = 0;
        couponMsg = 'Invalid coupon code';
        couponApplied = false;
      }
    });
  }

  @override
  void dispose() {
    _ecashCtrl.dispose();
    _ebankCtrl.dispose();
    _couponCtrl.dispose();
    _campaignTitleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.accent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Complete Purchase',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                const Text(
                  'Secure',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.bg, Color(0xFFEEF8F9)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Package Summary Card ──────────────────────────────────────
              _packageSummaryCard(),
              const SizedBox(height: 14),

              // ── Add-ons Card ──────────────────────────────────────────────
              _addonsCard(),
              const SizedBox(height: 14),

              // ── Campaign Setup Card ───────────────────────────────────────
              _campaignCard(),
              const SizedBox(height: 14),

              // ── Campaign Schedule Card ────────────────────────────────────
              _campaignScheduleCard(),
              const SizedBox(height: 14),

              // ── Wallet Card ───────────────────────────────────────────────
              _walletCard(),
              const SizedBox(height: 14),

              // ── Coupon Card ───────────────────────────────────────────────
              _couponCard(),
              const SizedBox(height: 14),

              // ── Price Summary Card ────────────────────────────────────────
              _priceSummaryCard(),
              const SizedBox(height: 20),

              // ── Pay Button ───────────────────────────────────────────────
              _payButton(),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  '🔒 Secured by 256-bit encryption • Instant activation',
                  style: TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ── Package Summary Card ──────────────────────────────────────────────────
  Widget _packageSummaryCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecor(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.accent, AppColors.accent2],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_pkgIcon(), color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pkg.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${pkg.community} • ${communityMembers(pkg.community)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  pkg.price,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.accent,
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  '${pkg.duration ?? ''} • ${pkg.pricingModel}',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: pkg.badges
              .map(
                (b) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    b,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 12),
        // AI match strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.accent, AppColors.accent2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.psychology, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Match: ${pkg.aiMatchPercent}% — Great fit for your profile!',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (pkg.reach != null) ...[
          const SizedBox(height: 10),
          Row(
            children: [
              _statPill(Icons.visibility_rounded, '${pkg.reach} Reach'),
              if (pkg.ctr != null) ...[
                const SizedBox(width: 8),
                _statPill(Icons.trending_up_rounded, '${pkg.ctr} CTR'),
              ],
              if (pkg.duration != null) ...[
                const SizedBox(width: 8),
                _statPill(Icons.schedule_rounded, pkg.duration!),
              ],
            ],
          ),
        ],
      ],
    ),
  );

  Widget _statPill(IconData icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: AppColors.accent),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
      ],
    ),
  );

  // ── Add-ons Card ──────────────────────────────────────────────────────────
  Widget _addonsCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecor(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.add_circle_outline_rounded, 'Boost Add-ons'),
        const SizedBox(height: 12),
        _addonTile(
          icon: Icons.notifications_active_rounded,
          label: 'Push Notification',
          subtitle: 'Instant alerts to 10K+ users',
          price: '+₹199',
          value: _push,
          onChanged: (v) => setState(() => _push = v ?? false),
        ),
        const SizedBox(height: 10),
        _addonTile(
          icon: Icons.campaign_rounded,
          label: 'Influencer Boost',
          subtitle: 'Featured on top creator profiles',
          price: '+₹499',
          value: _infl,
          onChanged: (v) => setState(() => _infl = v ?? false),
        ),
        if (_addon > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  size: 14,
                  color: AppColors.success,
                ),
                const SizedBox(width: 6),
                Text(
                  'Add-ons total: +₹$_addon',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _addonTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required String price,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: value ? AppColors.accentSoft : AppColors.card,
        border: Border.all(
          color: value ? AppColors.accent : AppColors.border,
          width: value ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value ? AppColors.accent : AppColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? Colors.white : AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: value ? FontWeight.w700 : FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: value ? AppColors.accent : AppColors.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              price,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: value ? Colors.white : AppColors.accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.accent : Colors.white,
              border: Border.all(
                color: value ? AppColors.accent : AppColors.border,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : null,
          ),
        ],
      ),
    ),
  );

  // ── Campaign Setup Card ───────────────────────────────────────────────────
  Widget _campaignCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecor(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.campaign_rounded, 'Campaign Setup'),
        const SizedBox(height: 12),
        _InputField(hint: 'Campaign Title', icon: Icons.edit_outlined, controller: _campaignTitleCtrl),
        const SizedBox(height: 10),
        _DropdownField(
          value: _opportunity,
          items: const [
            'Select Opportunity',
            'Campus Ambassador Job',
            'Product Launch',
            'Internship Drive',
            'Event Promotion',
          ],
          onChanged: (v) => setState(() => _opportunity = v ?? _opportunity),
        ),
      ],
    ),
  );

  Widget _campaignScheduleCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecor(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.calendar_month_rounded, 'Campaign Schedule'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _scheduleDate = date);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.date_range, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        _scheduleDate == null
                            ? 'Select Date'
                            : '${_scheduleDate!.day}/${_scheduleDate!.month}/${_scheduleDate!.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: _scheduleDate == null ? AppColors.muted : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) setState(() => _scheduleTime = time);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time, size: 16, color: AppColors.accent),
                      const SizedBox(width: 8),
                      Text(
                        _scheduleTime == null
                            ? 'Select Time'
                            : _scheduleTime!.format(context),
                        style: TextStyle(
                          fontSize: 13,
                          color: _scheduleTime == null ? AppColors.muted : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _DropdownField(
          value: _scheduleFrequency,
          items: const ['one-time', 'daily', 'weekly', 'monthly'],
          onChanged: (v) => setState(() => _scheduleFrequency = v ?? _scheduleFrequency),
        ),
      ],
    ),
  );

  // ── Wallet Card ───────────────────────────────────────────────────────────
  Widget _walletCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecor(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          Icons.account_balance_wallet_rounded,
          'Use Wallet Balance',
        ),
        const SizedBox(height: 12),
        _walletTile(
          'eCash Balance',
          '₹$ecashBal',
          Icons.account_balance_wallet,
          _ecashCtrl,
        ),
        const SizedBox(height: 10),
        _walletTile(
          'eBank Balance',
          '₹$ebankBal',
          Icons.account_balance,
          _ebankCtrl,
        ),
        if (_walletUsed > 0) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.success.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.savings_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text(
                  'Saving ₹$_walletUsed using wallet',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  Widget _walletTile(
    String title,
    String bal,
    IconData icon,
    TextEditingController ctrl,
  ) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.lavenderBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
              Text(
                bal,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          width: 100,
          child: TextField(
            controller: ctrl,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Use',
              hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
              filled: true,
              fillColor: AppColors.lavenderBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    ),
  );

  // ── Coupon Card ───────────────────────────────────────────────────────────
  Widget _couponCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: _cardDecor(),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(Icons.local_offer_rounded, 'Coupon Code'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _couponCtrl,
                decoration: InputDecoration(
                  hintText: 'Enter coupon (e.g. SAVE100)',
                  hintStyle: TextStyle(
                    color: AppColors.textMuted.withOpacity(0.5),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: AppColors.lavenderBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _applyCoupon,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Apply',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        if (couponMsg.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: couponApplied
                  ? AppColors.success.withOpacity(0.08)
                  : const Color(0xFFDC2626).withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: couponApplied
                    ? AppColors.success.withOpacity(0.3)
                    : const Color(0xFFDC2626).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  couponApplied
                      ? Icons.check_circle_rounded
                      : Icons.error_rounded,
                  size: 16,
                  color: couponApplied
                      ? AppColors.success
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Text(
                  couponMsg,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: couponApplied
                        ? AppColors.success
                        : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    ),
  );

  // ── Price Summary Card ────────────────────────────────────────────────────
  Widget _priceSummaryCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.card,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppColors.accent.withOpacity(0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: AppColors.accent.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        _sectionHeader(Icons.receipt_long_rounded, 'Order Summary'),
        const SizedBox(height: 14),
        _priceRow('Base Package', pkg.price),
        if (_push) ...[
          const SizedBox(height: 8),
          _priceRow('Push Notification', '+₹199'),
        ],
        if (_infl) ...[
          const SizedBox(height: 8),
          _priceRow('Influencer Boost', '+₹499'),
        ],
        if (discount > 0) ...[
          const SizedBox(height: 8),
          _priceRow('Coupon Discount', '-₹$discount', green: true),
        ],
        if (_walletUsed > 0) ...[
          const SizedBox(height: 8),
          _priceRow('Wallet Used', '-₹$_walletUsed', green: true),
        ],
        const SizedBox(height: 12),
        Container(height: 1, color: AppColors.border),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Payable',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            Text(
              '₹$_finalPrice',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: AppColors.accent,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
        if (_finalPrice < _packageTotal) ...[
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'You save ₹${_packageTotal - _finalPrice}!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    ),
  );

  Widget _priceRow(String label, String value, {bool green = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: green ? AppColors.success : AppColors.textDark,
        ),
      ),
    ],
  );

  // ── Pay Button ────────────────────────────────────────────────────────────
  Widget _payButton() => SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: () async {
        if (_campaignTitleCtrl.text.isEmpty || _scheduleDate == null || _scheduleTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a Campaign Title and select a Schedule Date & Time.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // Since we don't have a create_order API yet, we simulate an order_id
        final mockOrderId = DateTime.now().millisecondsSinceEpoch % 1000000;

        // Parse package duration safely (default to 7 if parsing fails)
        int durationValue = 7;
        if (pkg.duration != null) {
          final digits = pkg.duration!.replaceAll(RegExp(r'[^0-9]'), '');
          if (digits.isNotEmpty) durationValue = int.parse(digits);
        }

        final scheduleDateStr = '${_scheduleDate!.year}-${_scheduleDate!.month.toString().padLeft(2, '0')}-${_scheduleDate!.day.toString().padLeft(2, '0')}';
        final scheduleTimeStr = '${_scheduleTime!.hour.toString().padLeft(2, '0')}:${_scheduleTime!.minute.toString().padLeft(2, '0')}:00';

        final response = await Database().getData({
          'action': 'save_schedule',
          'order_id': mockOrderId.toString(),
          'title': _campaignTitleCtrl.text,
          'date': scheduleDateStr,
          'time': scheduleTimeStr,
          'frequency': _scheduleFrequency,
          'duration': durationValue.toString(),
        });

        if (!mounted) return;
        Navigator.pop(context);

        if (response['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🎉 ${pkg.title} — Payment of ₹$_finalPrice successful! Schedule saved.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Payment simulated, but scheduling failed.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 18),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_rounded, size: 18),
          const SizedBox(width: 10),
          Text(
            'Pay ₹$_finalPrice Now',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    ),
  );

  // ── Helpers ───────────────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String title) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: AppColors.accent),
      ),
      const SizedBox(width: 8),
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
    ],
  );

  BoxDecoration _cardDecor() => BoxDecoration(
    color: AppColors.card,
    borderRadius: BorderRadius.circular(14),
    border: Border.all(color: AppColors.border),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.03),
        blurRadius: 10,
        offset: const Offset(0, 2),
      ),
    ],
  );

  IconData _pkgIcon() {
    switch (pkg.type) {
      case 'Job':
        return Icons.work;
      case 'Event':
        return Icons.event;
      case 'Training':
        return Icons.school;
      default:
        return Icons.rocket_launch_rounded;
    }
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS (used by Detail Screen)
// ════════════════════════════════════════════════════════════════════════════
class _DCard extends StatelessWidget {
  final Widget child;
  final Gradient? gradient;
  const _DCard({required this.child, this.gradient});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: gradient == null ? AppColors.card : null,
      gradient: gradient,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: AppColors.accent.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: child,
  );
}

class _DBadge extends StatelessWidget {
  final String label;
  const _DBadge(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: AppColors.accent,
      ),
    ),
  );
}

class _DSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const _DSectionTitle({required this.icon, required this.title});
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, size: 16, color: AppColors.accent),
      const SizedBox(width: 6),
      Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.text,
        ),
      ),
    ],
  );
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppColors.accentSoft,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.accent),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.accent,
          ),
        ),
      ],
    ),
  );
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureRow({required this.icon, required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.accentSoft,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: AppColors.accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.text),
          ),
        ),
      ],
    ),
  );
}

class _AddonCheckbox extends StatelessWidget {
  final String label, price;
  final bool value;
  final ValueChanged<bool?> onChanged;
  const _AddonCheckbox({
    required this.label,
    required this.price,
    required this.value,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => onChanged(!value),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: value ? AppColors.accentSoft : AppColors.card,
        border: Border.all(
          color: value ? AppColors.accent : AppColors.border,
          width: value ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AppColors.accent : AppColors.card,
              border: Border.all(
                color: value ? AppColors.accent : AppColors.border,
                width: 2,
              ),
            ),
            child: value
                ? const Icon(Icons.check_rounded, size: 12, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: value ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.text,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: value ? AppColors.accent : AppColors.accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              price,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: value ? Colors.white : AppColors.accent,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
          ),
        ),
      ],
    ),
  );
}

class _InputField extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController? controller;
  const _InputField({required this.hint, required this.icon, this.controller});
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    style: const TextStyle(fontSize: 13, color: AppColors.text),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AppColors.muted),
      prefixIcon: Icon(icon, size: 16, color: AppColors.accent),
      filled: true,
      fillColor: AppColors.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
      ),
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: AppColors.card,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(10),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        icon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.accent,
        ),
        style: const TextStyle(fontSize: 13, color: AppColors.text),
        onChanged: onChanged,
        items: items
            .map((i) => DropdownMenuItem(value: i, child: Text(i)))
            .toList(),
      ),
    ),
  );
}

class _DDivider extends StatelessWidget {
  const _DDivider();
  @override
  Widget build(BuildContext context) => Container(
    height: 1,
    margin: const EdgeInsets.symmetric(vertical: 12),
    color: AppColors.border,
  );
}
