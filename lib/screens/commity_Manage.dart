// lib/screens/commity_Manage.dart

import 'package:commity_app1/screens/admin_commity_manger.dart';
import 'package:flutter/material.dart';

class CommunityPrivateAdminView extends StatefulWidget {
  final String groupName;
  final String privacy;

  const CommunityPrivateAdminView({
    super.key,
    required this.groupName,
    required this.privacy,
  });

  @override
  State<CommunityPrivateAdminView> createState() =>
      _CommunityPrivateAdminViewState();
}

class _CommunityPrivateAdminViewState
    extends State<CommunityPrivateAdminView> {
  // ---- Modern palette: deep indigo + warm coral accent + soft neutrals ----
  static const Color bgColor = Color(0xFFF8F9FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF14152B);          // near-black navy
  static const Color inkSoft = Color(0xFF6E7191);      // muted slate
  static const Color primary = Color(0xFF8F7CFF);      // light purple
  static const Color primaryDeep = Color(0xFFB8ACFF);  // lighter purple
  static const Color accent = Color(0xFFFF6F5E);       // warm coral
  static const Color mint = Color(0xFF1FC494);         // success green
  static const Color amber = Color(0xFFFFB23E);        // pending amber
  static const Color sky = Color(0xFF3D9BFF);          // info blue
  static const Color borderGrey = Color(0xFFEAEAF2);

  // ---- Data ----
  final int totalMembers = 12540;
  final int pendingRequests = 24;
  final int livePromotions = 3;
  final double monthlyRevenue = 54000;

  bool get isPrivate => widget.privacy == 'Private';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildActionRow(),
                  const SizedBox(height: 28),
                  _buildSectionHeader("Overview"),
                  const SizedBox(height: 14),
                  _buildStatsGrid(),
                  const SizedBox(height: 28),
                  _buildSectionHeader("Activity"),
                  const SizedBox(height: 14),
                  _buildActivityCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================== APP BAR =====================
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: ink,
      foregroundColor: Colors.white,
      iconTheme: const IconThemeData(color: Colors.white),

      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Solid deep ink base — modern, not gradient-default
            Container(color: Colors.deepPurpleAccent.shade100),

            // Abstract geometric accent shapes
            Positioned(
              top: -60,
              right: -30,
              child: _blob(180, primary.withValues(alpha: 0.35)),
            ),
            Positioned(
              bottom: -40,
              right: 80,
              child: _blob(100, accent.withValues(alpha: 0.25)),
            ),
            Positioned(
              top: 30,
              left: -50,
              child: _blob(120, primaryDeep.withValues(alpha: 0.3)),
            ),

            // Content
            Positioned(
              bottom: 22,
              left: 20,
              right: 64,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.groups_rounded,
                        size: 28, color: primary),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    widget.groupName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPrivacyBadge(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          isPrivate
                              ? 'Only followers see members & posts'
                              : 'Anyone can find and view this group',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          maxLines: 1,
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
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.tune_rounded, color: Colors.white, size: 22),
            tooltip: 'Manage community',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminCommunityManagerScreen(
                    groupName: widget.groupName,
                    privacy: widget.privacy,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }

  Widget _buildPrivacyBadge() {
    final Color tint = isPrivate ? Colors.green.shade900 : Colors.blue.shade900
    ;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isPrivate ? Icons.lock_rounded : Icons.public_rounded,
              color: tint, size: 12),
          const SizedBox(width: 4),
          Text(
            isPrivate ? 'Private' : 'Public',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ===================== ACTION ROW =====================
  Widget _buildActionRow() {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: "Create Post",
            icon: Icons.add_rounded,
            isPrimary: true,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ActionButton(
            label: "Invite Members",
            icon: Icons.person_add_alt_rounded,
            isPrimary: false,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  // ===================== SECTION HEADER =====================
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: inkSoft,
        letterSpacing: 1.1,
      ),
    );
  }

  // ===================== STATS GRID (2x2) =====================
  Widget _buildStatsGrid() {
    final stats = [
      _StatData(
        title: "Total Members",
        value: _formatNumber(totalMembers),
        icon: Icons.people_alt_rounded,
        color: primary,
      ),
      _StatData(
        title: "Pending Requests",
        value: pendingRequests.toString(),
        icon: Icons.hourglass_top_rounded,
        color: amber,
      ),
      _StatData(
        title: "Live Promotions",
        value: livePromotions.toString(),
        icon: Icons.campaign_rounded,
        color: mint,
      ),
      _StatData(
        title: "Monthly Revenue",
        value: "₹${_formatNumber(monthlyRevenue.toInt())}",
        icon: Icons.payments_rounded,
        color: sky,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: stats.map((s) => _StatCard(data: s)).toList(),
    );
  }

  // ===================== ACTIVITY CARD =====================
  Widget _buildActivityCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderGrey),
      ),
      child: Column(
        children: [
          _activityRow(
            icon: Icons.person_add_alt_1_rounded,
            color: primary,
            title: "8 new members joined",
            subtitle: "Last 24 hours",
          ),
          const Divider(height: 24, color: borderGrey),
          _activityRow(
            icon: Icons.campaign_rounded,
            color: mint,
            title: "Spring Sale promotion is live",
            subtitle: "Ends in 3 days",
          ),
          const Divider(height: 24, color: borderGrey),
          _activityRow(
            icon: Icons.report_gmailerrorred_rounded,
            color: accent,
            title: "2 posts flagged for review",
            subtitle: "Needs attention",
          ),
        ],
      ),
    );
  }

  Widget _activityRow({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 12, color: inkSoft),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: inkSoft, size: 20),
      ],
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
  }
}

// ===================== ACTION BUTTON =====================
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary
          ? _CommunityPrivateAdminViewState.primary
          : _CommunityPrivateAdminViewState.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isPrimary
                ? null
                : Border.all(
                color: _CommunityPrivateAdminViewState.borderGrey),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isPrimary
                    ? Colors.white
                    : _CommunityPrivateAdminViewState.ink,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPrimary
                      ? Colors.white
                      : _CommunityPrivateAdminViewState.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== STAT DATA MODEL =====================
class _StatData {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  _StatData({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });
}

// ===================== STAT CARD =====================
class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _CommunityPrivateAdminViewState.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _CommunityPrivateAdminViewState.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(data.icon, color: data.color, size: 19),
          ),
          const Spacer(),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _CommunityPrivateAdminViewState.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 12,
              color: _CommunityPrivateAdminViewState.inkSoft,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}