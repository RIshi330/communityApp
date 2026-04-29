import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/Community_Admin_Dashboard.dart';
import 'package:commity_app1/screens/admin/community_manager.dart';
// import 'package:commity_app1/screens/admin/UserManagementScreen.dart'; // Add actual import if needed
// import 'package:commity_app1/screens/admin/MarketplacePartnersScreen.dart';
// import 'package:commity_app1/screens/admin/ModerationHubScreen.dart';
// import 'package:commity_app1/screens/admin/FinancialCenterScreen.dart';
// import 'package:commity_app1/screens/admin/TeamPartnerManagerScreen.dart';
import 'package:commity_app1/screens/admin/Platform_Settings.dart';
import 'package:commity_app1/screens/auth_screen.dart';
import 'package:commity_app1/services/auth_service.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        children: [
          _drawerHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _drawerItem(
                  Icons.dashboard_rounded,
                  'Dashboard',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminDashboardScreen()));
                  },
                ),
                _drawerItem(
                  Icons.hub_outlined,
                  'Communities',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const CommunityManagementHub()));
                  },
                ),
                _drawerItem(Icons.people_outline, 'Members', onTap: () {}),
                _drawerItem(Icons.badge_outlined, 'Marketplace Partners', onTap: () {}),
                _drawerItem(Icons.gavel_outlined, 'Moderation', onTap: () {}),
                _drawerItem(Icons.payments_outlined, 'Wallet', onTap: () {}),
                _drawerItem(Icons.loyalty_outlined, 'Team & Partners', onTap: () {}),
                _drawerItem(
                  Icons.settings_outlined,
                  'Settings',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PlatformSettingsScreen()));
                  },
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _drawerItem(
              Icons.logout_rounded,
              'Logout',
              color: const Color(0xFFEF4444), // AppTheme.error
              onTap: () => _handleAdminLogout(context),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _drawerHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF7C83FD), // AppTheme.primary
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.auto_awesome_mosaic, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Admin Panel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text('comm-Unity', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))), // AppTheme.textMuted
            ],
          ),
        ],
      ),
    );
  }

  Widget _drawerItem(
    IconData icon,
    String label, {
    bool isActive = false,
    Color? color,
    VoidCallback? onTap,
  }) {
    final primary = const Color(0xFF7C83FD);
    final primarySoft = const Color(0xFFF1F2FF);
    final textMuted = const Color(0xFF6B7280);
    final textMain = const Color(0xFF1F2937);

    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: isActive ? primary : (color ?? textMuted), size: 22),
        title: Text(
          label,
          style: TextStyle(
            color: isActive ? primary : (color ?? textMain),
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 14,
          ),
        ),
        onTap: onTap ?? () {},
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<void> _handleAdminLogout(BuildContext context) async {
    Navigator.pop(context); // Close the drawer
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to logout from the admin panel?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.clearSession();
      if (!context.mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthProduction()),
        (route) => false,
      );
    }
  }
}
