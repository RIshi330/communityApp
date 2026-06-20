import 'package:commity_app1/screens/business_user/promotional_package.dart';
import 'package:commity_app1/screens/business_user/setting.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../services/auth_service.dart';
import '../auth_screen.dart';

/// App-wide left navigation drawer.
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, this.activeIndex = 0});

  /// 0 = Dashboard, 1 = Promotional Packages, 2 = My Orders,
  /// 3 = Wallet, 4 = Settings
  final int activeIndex;

  static const _menuItems = [
    _DrawerMenuItem(
      icon: Icons.dashboard_rounded,
      label: 'Dashboard',
      route: '/dashboard',
    ),
    _DrawerMenuItem(
      icon: Icons.local_offer_rounded,
      label: 'Promo Market',
      route: '/PromoMarketScreen',
    ),
    _DrawerMenuItem(
      icon: Icons.shopping_bag_rounded,
      label: 'My Orders',
      route: '/orders',
    ),
    _DrawerMenuItem(
      icon: Icons.account_balance_wallet_rounded,
      label: 'Wallet',
      route: '/wallet',
    ),
    _DrawerMenuItem(
      icon: Icons.settings_rounded,
      label: 'Settings',
      route: '/SettingsPage',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surfaceContainerLowest,
      width: 285,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) => _DrawerTile(
                  item: _menuItems[index],
                  isActive: index == activeIndex,
                  onTap: () {
                    switch (index) {
                      case 0:
                        Navigator.pop(context);
                        break;
                      case 1:
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PromoMarketScreen(),
                          ),
                        );
                        break;
                      case 4: Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsPage(),
                          ),
                      );
                      break;
                      default:
                        Navigator.pop(context);
                        break;
                    }
                  },
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(color: AppColors.border, thickness: 1),
            ),
            _LogoutTile(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF474DC5), Color(0xFF6067DF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white38, width: 2),
            ),
            child: const CircleAvatar(
              radius: 32,
              backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida/AP1WRLu6j9O1e9FCJY_jXqsxGSoR7hFh2XtwKjcp-_ZUj9Ok8NfcvTTqQlpIiAYjdGe8cox7O_M5GIqD1ldaVVRJ36bpQFj0clmUDEl1xiEaTAk-oMbvn0TXXFRpRnemh-Xa8LeeHAr0kLCDg9lLGMjK3GnCwiVdJVly2FZltnT8Gz5DMJvdyEHvmjwJVmTafeKgFeVxmmj1u2xk40vuOGat0YxnCYSs2bwMPWvTzttWM7bti1A_MgGYTkj6dMA',
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Business User',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'business@example.com',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, size: 13, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Pro Account',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Menu Tile ──────────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  const _DrawerTile({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final _DrawerMenuItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: isActive
          ? BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      )
          : null,
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.12)
                : AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            item.icon,
            size: 20,
            color: isActive ? AppColors.primary : AppColors.secondary,
          ),
        ),
        title: Text(
          item.label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? AppColors.primary : AppColors.onSurface,
          ),
        ),
        trailing: isActive
            ? Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        )
            : null,
        onTap: onTap,
      ),
    );
  }
}

// ── Logout Tile ────────────────────────────────────────────────────────────────
class _LogoutTile extends StatelessWidget {
  const _LogoutTile();

  Future<void> _handleLogout(BuildContext context) async {
    // Capture the navigator/scaffold context BEFORE closing the drawer,
    // so it stays valid for showDialog and pushAndRemoveUntil.
    final pageContext = Navigator.of(context, rootNavigator: false).context;

    // Close the drawer
    Navigator.pop(context);

    final confirmed = await showDialog<bool>(
      context: pageContext,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Logout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.clearSession();
      if (!pageContext.mounted) return;
      Navigator.pushAndRemoveUntil(
        pageContext,
        MaterialPageRoute(builder: (_) => const AuthProduction()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ListTile(
        dense: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: AppColors.error.withOpacity(0.06),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.error.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.logout_rounded,
              size: 20, color: AppColors.error),
        ),
        title: const Text(
          'Logout',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.error,
          ),
        ),
        onTap: () => _handleLogout(context),
      ),
    );
  }
}

// ── Data Model ────────────────────────────────────────────────────────────────
class _DrawerMenuItem {
  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });
  final IconData icon;
  final String label;
  final String route;
}