import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';
import 'package:commity_app1/screens/admin/admin_drawer.dart';

void main() {
  runApp(const MarketplaceApp());
}

class MarketplaceApp extends StatelessWidget {
  const MarketplaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Marketplace Partners',
      theme: AppTheme.theme,
      home: const MarketplacePartnersScreen(),
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

class MarketplacePartnersScreen extends StatefulWidget {
  const MarketplacePartnersScreen({super.key});

  @override
  State<MarketplacePartnersScreen> createState() =>
      _MarketplacePartnersScreenState();
}

class _MarketplacePartnersScreenState extends State<MarketplacePartnersScreen> {
  bool isGridView = false;
  String activeFilter = 'All';

  final List<Map<String, dynamic>> partners = [
    {
      'name': 'Alex Rivera',
      'type': 'Individual',
      'role': 'Senior UX Architect',
      'exp': '8+ Years Experience',
      'loc': 'San Francisco, CA',
      'rating': 4.9,
      'tags': ['UI/UX', 'Figma', 'Strategy'],
      'img':
          'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=200',
    },
    {
      'name': 'Stellar Supplies Co.',
      'type': 'Corporate',
      'role': 'Supply Chain & Manufacturing',
      'exp': 'Industry: Logistics',
      'loc': 'Global (HQ: London)',
      'rating': 4.8,
      'tags': ['Bulk Order', 'B2B', 'Fulfillment'],
      'icon': Icons.business,
    },
    {
      'name': 'Sarah Chen',
      'type': 'Individual',
      'role': 'Full Stack Developer',
      'exp': '6+ Years Experience',
      'loc': 'Berlin, Germany',
      'rating': 5.0,
      'tags': ['React', 'Node.js', 'Typescript'],
      'img':
          'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=200',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=100',
              ),
              backgroundColor: AppTheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildHeader(),
          _buildSearchAndFilters(),
          _buildCategoryTabs(),
          Expanded(child: isGridView ? _buildGrid() : _buildList()),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showInviteModal('All Partners'),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.person_add_alt_1, color: Colors.white),
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildHeaderText()),
          const SizedBox(width: 12),
          _buildViewToggle(),
        ],
      ),
    );
  }

  Widget _buildHeaderText() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Marketplace Partners',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          'Manage and invite professional service providers.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
        ),
      ],
    );
  }

  Widget _buildViewToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _toggleIcon(
            Icons.grid_view_rounded,
            isGridView,
            () => setState(() => isGridView = true),
          ),
          _toggleIcon(
            Icons.list_rounded,
            !isGridView,
            () => setState(() => isGridView = false),
          ),
        ],
      ),
    );
  }

  Widget _toggleIcon(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? AppTheme.primary : AppTheme.textMuted,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search by name, skills, or industry...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, color: AppTheme.textMuted),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _compactAction(Icons.tune, 'Filter', () => _showFilterModal()),
          const SizedBox(width: 8),
          _compactAction(Icons.sort, 'Sort', () => _showSortModal()),
        ],
      ),
    );
  }

  Widget _compactAction(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: AppTheme.textMain),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: AppTheme.textMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterAction(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textMain,
        side: const BorderSide(color: AppTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }

  Widget _buildCategoryTabs() {
    final categories = ['All', 'Individual', 'Corporate', 'Tech', 'Marketing', 'Logistics'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: categories.map((cat) {
          bool active = activeFilter == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(cat),
              selected: active,
              onSelected: (val) => setState(() => activeFilter = cat),
              selectedColor: AppTheme.primary,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: active ? Colors.white : AppTheme.textMuted,
                fontWeight: active ? FontWeight.bold : FontWeight.normal,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: active ? AppTheme.primary : AppTheme.border,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: partners.length + 1,
      itemBuilder: (context, index) {
        if (index == partners.length) return _buildJoinNetworkCard();
        return _buildPartnerCard(partners[index]);
      },
    );
  }

  Widget _buildGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      itemCount: partners.length + 1,
      itemBuilder: (context, index) {
        if (index == partners.length)
          return _buildJoinNetworkCard(isGrid: true);
        return _buildPartnerCard(partners[index], isGrid: true);
      },
    );
  }

  Widget _buildPartnerCard(
    Map<String, dynamic> partner, {
    bool isGrid = false,
  }) {
    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (partner['img'] != null)
                CircleAvatar(
                  radius: 24,
                  backgroundImage: NetworkImage(partner['img']),
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primarySoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(partner['icon'], color: AppTheme.primary),
                ),
              if (!isGrid) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        partner['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        partner['type'],
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.star, color: AppTheme.warning, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      partner['rating'].toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
          if (isGrid) ...[
            const SizedBox(height: 12),
            Text(
              partner['name'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              partner['type'],
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            partner['role'],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          _infoRow(Icons.work_outline, partner['exp']),
          _infoRow(Icons.location_on_outlined, partner['loc']),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: (partner['tags'] as List<String>)
                .map((t) => _badge(t))
                .toList(),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showInviteModal(partner['name']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Invite as Partner', style: TextStyle(fontSize: 12)),
            ),
          ),
          if (!isGrid) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showDetailsModal(partner['name']),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.textMain,
                  side: const BorderSide(color: AppTheme.border),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Ask for Details',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(icon, size: 14, color: AppTheme.textMuted),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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

  Widget _buildJoinNetworkCard({bool isGrid = false}) {
    return Container(
      margin: isGrid ? EdgeInsets.zero : const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, style: BorderStyle.none),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.handshake_outlined,
              color: AppTheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Join our Network',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Register your company as a service provider.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Get Started'),
          ),
        ],
      ),
    );
  }

  void _showInviteModal(String name) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 20),
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primarySoft, shape: BoxShape.circle), child: const Icon(Icons.outgoing_mail, color: AppTheme.primary)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Send Partnership Invitation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Inviting $name to join your network.', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ])),
        ]),
        const SizedBox(height: 20),
        const Text('Invitation Message', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(maxLines: 4, controller: TextEditingController(text: "Hi, we've reviewed your profile and would love to invite you to join our exclusive marketplace partners network. Looking forward to collaborating!"), decoration: InputDecoration(filled: true, fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        const SizedBox(height: 20),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Send Invite', style: TextStyle(fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(height: 12),
      ]),
    ));
  }

  void _showDetailsModal(String name) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 20),
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primarySoft, shape: BoxShape.circle), child: const Icon(Icons.info_outline, color: AppTheme.primary)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Request More Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Asking for professional info from $name.', style: const TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ])),
        ]),
        const SizedBox(height: 20),
        const Text('Which information would you like to request?', style: TextStyle(color: AppTheme.textMuted, fontSize: 14)),
        const SizedBox(height: 12),
        Wrap(spacing: 12, runSpacing: 12, children: ['Portfolio', 'Full Resume', 'References', 'Rates'].map((item) => Container(
          width: MediaQuery.of(ctx).size.width / 2 - 36, padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
          child: Row(children: [Icon(Icons.check_box_outlined, color: AppTheme.primary, size: 20), const SizedBox(width: 8), Text(item, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))]),
        )).toList()),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Back', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(width: 12),
          Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Request Details', style: TextStyle(fontWeight: FontWeight.bold)))),
        ]),
        const SizedBox(height: 12),
      ]),
    ));
  }

  void _showFilterModal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 20),
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primarySoft, shape: BoxShape.circle), child: const Icon(Icons.filter_list, color: AppTheme.primary)),
          const SizedBox(width: 16),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Filter Partners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Refine the list based on your criteria.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 20),
        ...['Individual Only', 'Corporate Only', 'Top Rated (4.5+)', 'Active Last 30 Days', 'Verified Only'].map((f) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(f, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)), Icon(Icons.check_box_outline_blank, color: AppTheme.textMuted, size: 22)]),
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
        const SizedBox(height: 8),
      ]),
    ));
  }

  void _showSortModal() {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, builder: (ctx) => Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(3)))),
        const SizedBox(height: 20),
        Row(children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primarySoft, shape: BoxShape.circle), child: const Icon(Icons.sort, color: AppTheme.primary)),
          const SizedBox(width: 16),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Sort Partners', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            Text('Order results to find what you need.', style: TextStyle(color: AppTheme.textMuted, fontSize: 13)),
          ]),
        ]),
        const SizedBox(height: 20),
        ...['Experience: High to Low', 'Rating: Highest First', 'Alphabetical (A-Z)', 'Recently Added', 'Location: Nearest'].asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(border: Border.all(color: e.key == 0 ? AppTheme.primary : AppTheme.border), borderRadius: BorderRadius.circular(12), color: e.key == 0 ? AppTheme.primarySoft : null),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(e.value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: e.key == 0 ? AppTheme.primary : AppTheme.textMain)), Icon(e.key == 0 ? Icons.radio_button_checked : Icons.radio_button_off, color: e.key == 0 ? AppTheme.primary : AppTheme.textMuted, size: 22)]),
        )),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Apply Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
        const SizedBox(height: 8),
      ]),
    ));
  }
}
