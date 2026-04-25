import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/Community_Admin_Dashboard.dart';
import 'package:commity_app1/screens/admin/community_manager.dart';
import 'package:commity_app1/screens/admin/wallet.dart';
import 'package:commity_app1/screens/admin/Platform_Settings.dart';

class AdminBottomNavigation extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavigation({super.key, required this.currentIndex});

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget destination;
    switch (index) {
      case 0:
        destination = const AdminDashboardScreen();
        break;
      case 1:
        destination = const CommunityManagementHub();
        break;
      case 2:
        destination = const FinancialCenterScreen();
        break;
      default:
        destination = const PlatformSettingsScreen();
        break;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => destination),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: currentIndex,
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Colors.grey.shade600,
      onTap: (index) => _onTap(context, index),
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.hub_outlined),
          label: 'Communities',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          label: 'Financial',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Setting',
        ),
      ],
    );
  }
}
