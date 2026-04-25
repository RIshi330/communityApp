import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';

void main() {
  runApp(const AdminProfileApp());
}

class AdminProfileApp extends StatelessWidget {
  const AdminProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Profile',
      theme: AppTheme.theme,
      home: const AdminProfileScreen(),
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
        centerTitle: true,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Admin Profile'),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Section (Banner & Avatar)
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -50,
                  left: 20,
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.black12,
                          backgroundImage: const NetworkImage(
                            'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=200',
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 60),

            // Profile Intro
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Alex Johnson',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.verified,
                        color: AppTheme.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Super Admin',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Joined January 12, 2023',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'Save Changes',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primary,
                            side: const BorderSide(color: AppTheme.primarySoft),
                            backgroundColor: AppTheme.primarySoft.withOpacity(
                              0.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text('Log Out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Metrics Grid
            _buildMetricsGrid(),

            const SizedBox(height: 30),

            // Personal Information
            _buildSection(
              title: 'Personal Information',
              onEdit: () {},
              children: [
                _buildInfoField('Full Name', 'Alex Johnson'),
                _buildInfoField('Email Address', 'alex.j@comm-unity.app'),
                _buildInfoField('Phone Number', '+1 (555) 000-1234'),
                _buildInfoField(
                  'Bio',
                  'Dedicated community builder and strategic manager with over 8 years of experience in fostering inclusive digital spaces.',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Account Security
            _buildSection(
              title: 'Account Security',
              children: [
                _buildNavigationTile(
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  subtitle: 'Last updated 3 months ago',
                ),
                _buildToggleTile(
                  icon: Icons.security,
                  title: 'Two-Factor Authentication',
                  subtitle: 'Secure your account with 2FA',
                  value: true,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // App Settings
            _buildSection(
              title: 'App Settings',
              children: [
                _buildAppSettingTile(
                  icon: Icons.palette_outlined,
                  title: 'Theme',
                  subtitle: 'Currently Light Mode',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildModeIcon(Icons.wb_sunny_outlined, true),
                      const SizedBox(width: 8),
                      _buildModeIcon(Icons.nightlight_outlined, false),
                    ],
                  ),
                ),
                _buildNavigationTile(
                  icon: Icons.notifications_none,
                  title: 'Notification Settings',
                  subtitle: 'Push, Email, and SMS',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Danger Zone
            _buildDangerZone(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildMetricsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          _buildMetricCard(Icons.hub_outlined, 'Communities Managed', '24'),
          const SizedBox(height: 12),
          _buildMetricCard(Icons.people_outline, 'Active Users', '12.8k'),
          const SizedBox(height: 12),
          _buildMetricCard(Icons.speed, 'Moderation Score', '98.4%'),
        ],
      ),
    );
  }

  Widget _buildMetricCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primary),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    VoidCallback? onEdit,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 20,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textMuted),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textMuted),
      onTap: () {},
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textMuted),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      trailing: Switch(
        value: value,
        onChanged: (v) {},
        activeColor: AppTheme.primary,
      ),
    );
  }

  Widget _buildAppSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: AppTheme.textMuted),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
      ),
      trailing: trailing,
    );
  }

  Widget _buildModeIcon(IconData icon, bool active) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? AppTheme.primarySoft : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? AppTheme.primary : AppTheme.border),
      ),
      child: Icon(
        icon,
        size: 18,
        color: active ? AppTheme.primary : AppTheme.textMuted,
      ),
    );
  }

  Widget _buildDangerZone() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1F1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFFE4E4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppTheme.error, size: 24),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF991B1B),
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Permanently delete your admin account and data.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF991B1B)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.error,
              side: const BorderSide(color: AppTheme.error),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
