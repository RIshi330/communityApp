import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';
import 'package:commity_app1/screens/admin/community_manager.dart';
import 'package:commity_app1/screens/admin/Community_Admin_Profile.dart';
import 'package:commity_app1/screens/admin/Community_Members.dart';
import 'package:commity_app1/screens/admin/Marketplace.dart' hide AppTheme;
import 'package:commity_app1/screens/admin/moderation.dart' hide AppTheme;
import 'package:commity_app1/screens/admin/team_and_partner.dart';
import 'package:commity_app1/screens/admin/wallet.dart' hide AppTheme;

void main() {
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'comm-Unity Admin',
      theme: AppTheme.theme,
      home: const AdminDashboardScreen(),
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

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('comm-Unity'),
        actions: [
          IconButton(
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.chat_bubble_outline),
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Badge(
              label: Text('5'),
              child: Icon(Icons.notifications_none),
            ),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminProfileScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=100',
                ),
                backgroundColor: AppTheme.primary.withOpacity(0.1),
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Row Slider
            const SizedBox(height: 16),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildMiniStatCard('Total Revenue', '₹1.2M', Icons.payments_outlined),
                  _buildMiniStatCard('Communities', '1.2K', Icons.groups_outlined),
                  _buildMiniStatCard('New Members', '+850', Icons.person_add_outlined),
                ],
              ),
            ),

            // Pending Approvals
            _buildSectionHeader('Pending Approvals', 'View All'),
            SizedBox(
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildApprovalCard('Artisans Hub', 'Community Request', 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=100'),
                  _buildApprovalCard('Dev Hub', 'Membership Request', 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=100'),
                ],
              ),
            ),

            // Pending Withdrawals
            _buildSectionHeader('Pending Withdrawals'),
            _buildWithdrawalItem('Rahul Mehta', 'Zen Garden Community', '₹12,500'),
            _buildWithdrawalItem('Sara Khan', 'Photography Pro', '₹8,900'),

            // Top Communities
            _buildSectionHeader('Top Communities'),
            _buildCommunityListItem('Creative Canvas', 'Managed by Alex Rivera', '12.4K', '₹2.4L', true),
            _buildCommunityListItem('Code Geeks', 'Managed by Priya S.', '8.9K', '₹1.8L', false),

            // Top Team Members
            _buildSectionHeader('Top Team Members'),
            _buildTeamMemberItem('David Miller', 'Support Lead', 'ELITE 9.8', Colors.green),
            _buildTeamMemberItem('Emma Wilson', 'Growth Analyst', 'PRO 9.2', AppTheme.primary),

            // Latest Messages
            _buildSectionHeader('Latest Messages'),
            _buildMessageItem('John Doe', 'Hey, I need help with the community payout...', '2m ago', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=100'),
            _buildMessageItem('Ananya Sharma', 'The new event guidelines look great. Thanks!', '45m ago', 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&q=80&w=100'),

            // Popular Packages
            _buildSectionHeader('Popular Packages'),
            _buildPackageItem('Premium Spotlight', '30-day banner promotion', '₹1.8L'),
            _buildPackageItem('Community Growth Pro', 'Member invite tools', '₹95K'),

            // Net Balance Card
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C83FD), Color(0xFF9EA4FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('NET BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    const SizedBox(height: 8),
                    const Text('₹8,45,200', style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 24),
                    // Mock Bar Chart
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(7, (index) {
                        double height = [20.0, 40.0, 30.0, 55.0, 25.0, 45.0, 65.0][index];
                        return Container(
                          width: 35,
                          height: height,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(index == 6 ? 1.0 : 0.4),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Last 7 Days', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Row(
                          children: [
                            Icon(Icons.trending_up, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text('+₹12,400', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'invite',
            onPressed: () => _showInviteModal(context),
            backgroundColor: Colors.white,
            child: const Icon(Icons.person_add_alt_1_outlined, color: AppTheme.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'create',
            onPressed: () => _showCreateCommunityModal(context),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 0),
    );
  }

  // ─── Drawer (Hamburger Menu) ─────────────────────────────────────────

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _buildDrawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _buildDrawerItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  isActive: true,
                ),
                _buildDrawerItem(
                  Icons.hub_outlined,
                  'Communities',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CommunityManagementHub(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.people_outline,
                  'Members',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UserManagementScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.badge_outlined,
                  'Marketplace Partners',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MarketplacePartnersScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.gavel_outlined,
                  'Moderation',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ModerationHubScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.payments_outlined,
                  'Wallet',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FinancialCenterScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(
                  Icons.loyalty_outlined,
                  'Team & Partners',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TeamPartnerManagerScreen(),
                      ),
                    );
                  },
                ),
                _buildDrawerItem(Icons.settings_outlined, 'Settings'),
              ],
            ),
          ),
          const Divider(height: 1),
          _buildDrawerItem(
            Icons.logout_rounded,
            'Logout',
            color: AppTheme.error,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.auto_awesome_mosaic,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Panel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                'comm-Unity',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String label, {
    bool isActive = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? AppTheme.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? AppTheme.primary : (color ?? AppTheme.textMuted),
          size: 22,
        ),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? AppTheme.primary : (color ?? AppTheme.textMain),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap ?? () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ─── Dashboard Content Widgets ───────────────────────────────────────

  Widget _buildSectionHeader(String title, [String? action]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          if (action != null)
            Text(action, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildMiniStatCard(String title, String value, IconData icon) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppTheme.primary),
          const Spacer(),
          Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildApprovalCard(String name, String type, String img) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(radius: 20, backgroundImage: NetworkImage(img)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(type, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(backgroundColor: AppTheme.primarySoft, foregroundColor: AppTheme.primary),
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalItem(String name, String community, String amount) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(community, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                ],
              ),
              Text(amount, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(backgroundColor: AppTheme.primarySoft, foregroundColor: AppTheme.primary),
                  child: const Text('Decline'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityListItem(String name, String manager, String members, String rev, bool isGrowth) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.hub_outlined, color: AppTheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text(manager, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.bar_chart, color: AppTheme.primary.withOpacity(0.5)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('MEMBERS', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text('$members ${isGrowth ? '↑ 24%' : '↑ 18%'}', style: TextStyle(fontWeight: FontWeight.bold, color: isGrowth ? Colors.green : Colors.blue)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('REVENUE', style: TextStyle(color: AppTheme.textMuted, fontSize: 10, fontWeight: FontWeight.bold)),
                  Text(rev, style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamMemberItem(String name, String role, String badge, Color badgeColor) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: const CircleAvatar(backgroundColor: Colors.black12),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      subtitle: Text(role, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: badgeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(badge, style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildMessageItem(String name, String msg, String time, String img) {
    return ListTile(
      leading: CircleAvatar(backgroundImage: NetworkImage(img)),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          Text(time, style: const TextStyle(color: AppTheme.textMuted, fontSize: 10)),
        ],
      ),
      subtitle: Text(msg, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildPackageItem(String name, String desc, String rev) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(desc, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(rev, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primary)),
              const Text('REVENUE', style: TextStyle(color: AppTheme.textMuted, fontSize: 9, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Bottom Sheet Modals ─────────────────────────────────────────────

  void _showInviteModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Invite Member', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField('Full Name', 'Enter name'),
            _buildField('Email Address', 'Enter email'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54)),
              child: const Text('Send Invitation'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showCreateCommunityModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Create Community', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            _buildField('Community Name', 'Enter name'),
            _buildField('Category', 'Select category'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 54)),
              child: const Text('Create Now'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppTheme.primarySoft.withOpacity(0.3), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
        ],
      ),
    );
  }
}
