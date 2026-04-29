import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';
import 'package:commity_app1/screens/admin/admin_drawer.dart';
import 'package:commity_app1/screens/admin/Marketplace.dart' hide AppTheme;
import 'package:commity_app1/screens/admin/team_and_partner.dart' hide AppTheme;

void main() {
  runApp(const UserManagementApp());
}

class UserManagementApp extends StatelessWidget {
  const UserManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management',
      theme: AppTheme.theme,
      home: const UserManagementScreen(),
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
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool isListView = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _showAddMenu(BuildContext fabContext) async {
    final button = fabContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem<String>(
          value: 'marketplace_partner',
          child: Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
              SizedBox(width: 10),
              Text('Marketplace Partner'),
            ],
          ),
        ),
      ],
    );

    if (!mounted || selected != 'marketplace_partner') return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplacePartnersScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Text(
                    '5',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=100',
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Approval Queue
          _buildApprovalSlider(),
          const SizedBox(height: 8),

          // Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              controller: _tabController,
              labelColor: AppTheme.primary,
              unselectedLabelColor: AppTheme.textMuted,
              indicatorColor: AppTheme.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              tabs: const [
                Tab(text: 'General Users'),
                Tab(text: 'Business Users'),
                Tab(text: 'Sub Admins'),
              ],
            ),
          ),

          // Search and View Toggle
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: 'Search by name, email or location...',
                        border: InputBorder.none,
                        icon: Icon(Icons.search, color: AppTheme.textMuted),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                _buildFilterButton(),
                const SizedBox(width: 12),
                _buildViewToggle(),
              ],
            ),
          ),

          // Filter & Export Buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildActionButton(Icons.tune, 'Filter'),
                const SizedBox(width: 12),
                _buildActionButton(Icons.file_download_outlined, 'Export'),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // User List Header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'USER DETAILS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
                Text(
                  'LOCATION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 24, color: AppTheme.border),

          // User List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildUserItem(
                  'Elena Brooks',
                  'elena.b@example.com',
                  'New York, USA',
                  initials: 'EB',
                ),
                _buildUserItem(
                  'Marcus Reed',
                  'm.reed@agency.io',
                  'London, UK',
                  imageUrl:
                      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=100',
                ),
                _buildUserItem(
                  'Sarah Oh',
                  'sarah.oh@design.com',
                  'Seoul, KR',
                  initials: 'SO',
                ),
                _buildUserItem(
                  'David Chen',
                  'd.chen@tech.com',
                  'San Francisco, USA',
                  imageUrl:
                      'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=100',
                ),
              ],
            ),
          ),

          // Pagination
          _buildPagination(),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'market',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplacePartnersScreen())),
            backgroundColor: Colors.white,
            child: const Icon(Icons.storefront_outlined, color: AppTheme.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'team',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeamPartnerManagerScreen())),
            backgroundColor: AppTheme.primarySoft,
            child: const Icon(Icons.group_add_outlined, color: AppTheme.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddMenu(context),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.person_add_alt_1, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildApprovalSlider() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        const Text('Approval Queue', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
        Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(20)),
          child: const Text('4 Pending', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
      ])),
      const SizedBox(height: 12),
      SizedBox(height: 160, child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 16), physics: const BouncingScrollPhysics(), children: [
        _approvalCard('Stitch Studio', 'Business Request', 'Enterprise membership request for 15 users.', Icons.business),
        _approvalCard('Lumina Agency', 'Marketing Partner', 'New agency partnership application.', Icons.campaign),
        _approvalCard('Velvet Retail', 'Vendor Account', 'Priority access request for holiday sales.', Icons.shopping_bag),
        _approvalCard('Nebula Tech', 'Startup Tier', 'Beta program enrollment request.', Icons.rocket_launch),
      ])),
    ]);
  }

  Widget _approvalCard(String name, String type, String desc, IconData icon) {
    return Container(width: 280, margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: AppTheme.primary, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(type, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
          ])),
        ]),
        const SizedBox(height: 8),
        Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        const Spacer(),
        Row(children: [
          Expanded(child: ElevatedButton(onPressed: () {}, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Approve', style: TextStyle(fontSize: 12)))),
          const SizedBox(width: 8),
          Expanded(child: OutlinedButton(onPressed: () {}, style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primary, side: const BorderSide(color: AppTheme.border), padding: const EdgeInsets.symmetric(vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), child: const Text('Decline', style: TextStyle(fontSize: 12)))),
        ]),
      ]),
    );
  }



  Widget _buildFilterButton() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.tune, color: AppTheme.textMuted, size: 20),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => isListView = true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isListView ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Icon(
                Icons.list,
                color: isListView ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => isListView = false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: !isListView ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Icon(
                Icons.grid_view,
                color: !isListView ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textMain,
        side: const BorderSide(color: AppTheme.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildUserItem(
    String name,
    String email,
    String location, {
    String? initials,
    String? imageUrl,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          if (imageUrl != null)
            CircleAvatar(radius: 20, backgroundImage: NetworkImage(imageUrl))
          else
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primarySoft,
              child: Text(
                initials ?? '',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            location,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPageNav(Icons.chevron_left),
              const SizedBox(width: 8),
              _buildPageNumber('1', active: true),
              const SizedBox(width: 8),
              _buildPageNumber('2'),
              const SizedBox(width: 8),
              _buildPageNav(Icons.chevron_right),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Showing 1-10 of 1,248 Users',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNav(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: AppTheme.textMuted),
    );
  }

  Widget _buildPageNumber(String num, {bool active = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active ? AppTheme.primary : Colors.transparent,
        border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        num,
        style: TextStyle(
          color: active ? Colors.white : AppTheme.textMuted,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
