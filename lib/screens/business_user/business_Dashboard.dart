import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import 'AppDrawer.dart';
import 'Message.dart';
import 'business_bottom_navigation.dart';




class BusinessDashboardApp extends StatelessWidget {
  const BusinessDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Business Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'Manrope',
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.surface,
      ),
      home: const BusinessDashboard(),
    );
  }
}

/// Root screen — assembles Drawer, AppBar, Body sections, and BottomNavBar.
class BusinessDashboard extends StatefulWidget {
  const BusinessDashboard({super.key});

  @override
  State<BusinessDashboard> createState() => _BusinessDashboard();
}

class _BusinessDashboard extends State<BusinessDashboard> {
  int _navIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,

      // ── Left Drawer ──────────────────────────────────────────────────────
      drawer: const AppDrawer(activeIndex: 0),

      // ── Top App Bar ──────────────────────────────────────────────────────
      appBar: _DashboardAppBar(),

      // ── Body ─────────────────────────────────────────────────────────────
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // 1. Performance Stats
            const PerformanceStatsSection(),
            const SizedBox(height: 32),

            // 2. Quick Insights
            const QuickInsightsSection(),
            const SizedBox(height: 32),

            // 3. Recent Orders + Inquiries (side-by-side on wide screens)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth >= 680) {
                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: RecentOrdersSection()),
                        SizedBox(width: 24),
                        Expanded(child: InquiriesSection()),
                      ],
                    );
                  }
                  return const Column(
                    children: [
                      RecentOrdersSection(),
                      SizedBox(height: 32),
                      InquiriesSection(),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // 4. Insights & News
            const InsightsNewsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),

      // ── Bottom Nav Bar ───────────────────────────────────────────────────
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _navIndex,
        onTap: (i) => setState(() => _navIndex = i),
      ),
    );
  }

}

// ── Top App Bar ───────────────────────────────────────────────────────────────
class _DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.appBarBg,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 64,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [

                // Avatar opens drawer
                // Builder(
                //   builder: (ctx) => GestureDetector(
                //     onTap: () => Scaffold.of(ctx).openDrawer(),
                //     child: Container(
                //       decoration: BoxDecoration(
                //         shape: BoxShape.circle,
                //         border: Border.all(color: AppColors.border, width: 2),
                //       ),
                //       child: const CircleAvatar(
                //         radius: 19,
                //         backgroundImage: NetworkImage(
                //           'https://lh3.googleusercontent.com/aida/AP1WRLu6j9O1e9FCJY_jXqsxGSoR7hFh2XtwKjcp-_ZUj9Ok8NfcvTTqQlpIiAYjdGe8cox7O_M5GIqD1ldaVVRJ36bpQFj0clmUDEl1xiEaTAk-oMbvn0TXXFRpRnemh-Xa8LeeHAr0kLCDg9lLGMjK3GnCwiVdJVly2FZltnT8Gz5DMJvdyEHvmjwJVmTafeKgFeVxmmj1u2xk40vuOGat0YxnCYSs2bwMPWvTzttWM7bti1A_MgGYTkj6dMA',
                //         ),
                //       ),
                //     ),
                //   ),
                // ),
                IconButton(onPressed: (){
                  Scaffold.of(context).openDrawer();
                }, icon: Icon(Icons.menu)),
                const Text(
                  'Business Dashboard',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const Spacer(),
                _IconBtn(icon: Icons.message, onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen(),));
                }),
                const SizedBox(width: 2),
                _IconBtn(icon: Icons.notifications_rounded, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: AppColors.primary, size: 24),
      ),
    );
  }
}
class PerformanceStatsSection extends StatelessWidget {
  const PerformanceStatsSection({super.key});

  static const _stats = [
    _StatData(label: 'CVR',        value: '4.2%', change: '+0.8%',  isUp: true),
    _StatData(label: 'Impressions',value: '250k',  change: '+12k',   isUp: true),
    _StatData(label: 'ROI',        value: '3.5x',  change: '+0.5x',  isUp: true),
    _StatData(label: 'Engagement', value: '8.4%', change: '+2.1%',  isUp: true),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Performance Stats',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.65,
            children: _stats.map((s) => _StatCard(data: s)).toList(),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});
  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.mutedText,
              letterSpacing: 0.5,
            ),
          ),
          Text(
            data.value,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          Row(
            children: [
              Icon(
                data.isUp ? Icons.trending_up_rounded : Icons.add_rounded,
                color: AppColors.tertiary,
                size: 14,
              ),
              const SizedBox(width: 3),
              Text(
                data.change,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.tertiary,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.label,
    required this.value,
    required this.change,
    required this.isUp,
  });
  final String label, value, change;
  final bool isUp;
}
class QuickInsightsSection extends StatelessWidget {
  const QuickInsightsSection({super.key});

  static const _cards = [
    _InsightData(
      imageUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLt7hmJMLfJb_1X_bBn38zXbubcn2Rpm1DRcVJaoxc2u7mArYD31Kt2x1UyUR04tDp5wl3Vc7psL2ZuSXQNLXQSPN7HhWg6Y0qZsm4Pr-sX_3SWk4yScJqqSzwbzfKTe76I1ynMZCjobSKMnC5jNn5u4Y4iyURqdngMldu8bqYPY6uMzk7BjBbk2x7soIDDa1cAkMkMhkfZ549-dAwlhT0FK9ysrHnXPQCdkiURo9y1aJhqQ-5C2EQSHHKc4',
      badge: 'Campaign Active',
      title: 'Instagram Growth Blast',
      showPulse: true,
    ),
    _InsightData(
      imageUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLuBKoEyPdl9zj2xUlBY8D9RvBNhH2MfEQJkbTfNWzvGNN2zzonoZo7lshksSqf_l1ZPxTfjFZcvvvF0pk4iH_ldDJ8rXHCe6veRbkNqwutdJKuWr1kinowp-VAnEJX4R0bFZ4rnO8pdQEzX-hjnlR2ZTQaMt3hLQy-9k1AoDMD2Yu5E-R1v8SNP-Hob0eoxmHf4riFE9_4R6oujqnrHoQve8NmVgmysGSvbY9YRg_2uzTGE0cWXhLJi2Oo',
      badge: 'Next Milestone',
      title: 'Target: 500k Impressions',
      showPulse: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Quick Insights',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 162,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _cards.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _InsightCard(data: _cards[i]),
          ),
        ),
      ],
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.data});
  final _InsightData data;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 300,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(data.imageUrl, fit: BoxFit.cover),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.4, 1.0],
                ),
              ),
            ),
            // Text content
            Positioned(
              bottom: 14,
              left: 14,
              right: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      if (data.showPulse)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: const BoxDecoration(
                            color: AppColors.tertiary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      Text(
                        data.badge.toUpperCase(),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          color: Colors.white70,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    data.title,
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InsightData {
  const _InsightData({
    required this.imageUrl,
    required this.badge,
    required this.title,
    required this.showPulse,
  });
  final String imageUrl, badge, title;
  final bool showPulse;
}
class RecentOrdersSection extends StatelessWidget {
  const RecentOrdersSection({super.key});

  static final _orders = [
    _OrderData(
      orderId: '#ORD-9921-X',
      productName: 'Mega Influencer Pack',
      status: 'Processing',
      badgeBg: AppColors.surfaceSoft,
      badgeText: AppColors.primary,
    ),
    _OrderData(
      orderId: '#ORD-9884-Z',
      productName: 'Local SEO Booster',
      status: 'Completed',
      badgeBg: const Color(0xFFF0FDF4),
      badgeText: const Color(0xFF16A34A),
    ),
    _OrderData(
      orderId: '#ORD-9870-A',
      productName: 'Video Content Suite',
      status: 'Active',
      badgeBg: AppColors.secondaryContainer,
      badgeText: AppColors.onSecondaryContainer,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Orders',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            Icon(Icons.filter_list_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: List.generate(_orders.length, (i) {
              final isLast = i == _orders.length - 1;
              return _OrderTile(data: _orders[i], isLast: isLast);
            }),
          ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.data, required this.isLast});
  final _OrderData data;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
            bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.orderId,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.productName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppColors.mutedText,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: data.badgeBg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              data.status,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: data.badgeText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderData {
  const _OrderData({
    required this.orderId,
    required this.productName,
    required this.status,
    required this.badgeBg,
    required this.badgeText,
  });
  final String orderId, productName, status;
  final Color badgeBg, badgeText;
}
class InquiriesSection extends StatelessWidget {
  const InquiriesSection({super.key});

  static const _inquiries = [
    _InquiryData(
      avatarUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLsdd68B4pOcYjAILc1_nQ55QJUPrcS9Bwz4mygwzo11d9_UFnb5IKa1LkDEpo7NymA2KQ9tvyWZZ95KTwfFGnZkHRuJKh7IoxI7cFbkLm_QhSTY1Tt5XytqPGecRxY7xHOcn_MOkydjObxmEGKt7bVGsFpErMWnkwDT20XCuic1dEjMiWWBFuFfPuC8aMDfetgwixUmysbsK7lYCdJJ3-mZWRNiACeT_NSnz7GVzQGbuhnBUi7Z8eIS3nmb',
      name: 'Urban Echo Media',
      message: 'Interested in the Q4 promo bundle for our...',
      time: '10m ago',
      hasUnread: true,
    ),
    _InquiryData(
      avatarUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLsXxoQReclaDLWY02JRpSfuULgTe8dzpD0l3rR_N1Mo3-HOtBzP6RM0nJ0xQza3xcGIBIWOvwWXHUrVEfT5fa0PBagF4gtRcIkmMLyvlkMJnyIaMDtCl4S9lWOnOr26slzo84tlsqdhtWasDMXUGRl3bfhGQBapaUcFBzWSijGCfebrDLA1c9AzxkekWPKfJ5W8KVDqhNiWYfX-MvDB_z6m6piZ_LE3UglJxe6MrscK5iSVlxOIIvXJvlU',
      name: 'Sarah Jenkins (Freelance)',
      message: 'Checking status on the engagement report...',
      time: '2h ago',
      hasUnread: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Inquiries',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
            Icon(Icons.edit_note_rounded,
                color: Colors.grey.shade400, size: 22),
          ],
        ),
        const SizedBox(height: 16),
        Column(
          children: _inquiries
              .map((i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _InquiryTile(data: i),
          ))
              .toList(),
        ),
      ],
    );
  }
}

class _InquiryTile extends StatelessWidget {
  const _InquiryTile({required this.data});
  final _InquiryData data;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: NetworkImage(data.avatarUrl),
                  ),
                  if (data.hasUnread)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.surfaceContainerLowest,
                              width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data.name,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: data.hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          data.time,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data.message,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: data.hasUnread
                            ? AppColors.onSurface
                            : AppColors.mutedText,
                        fontWeight: data.hasUnread
                            ? FontWeight.w500
                            : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

class _InquiryData {
  const _InquiryData({
    required this.avatarUrl,
    required this.name,
    required this.message,
    required this.time,
    required this.hasUnread,
  });
  final String avatarUrl, name, message, time;
  final bool hasUnread;
}
class InsightsNewsSection extends StatelessWidget {
  const InsightsNewsSection({super.key});

  static const _blogs = [
    _BlogData(
      imageUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLsHhzM10X1I2DbDbgKCW5DDRGSUHuicb7eY8HBYecWfRu1XdVGdYfib0n6T54maY508H5UPRle5-vw115hJl5nbbp1RTrvJyny5pSCQnIvIOCGU6mREJTY3chAo_WcsK0QgaL1T3C-DQrMgKabayh1beWTJWOS6hp7vANgyN5CtifJGPS8d6MzK_y-KEU5e1DTnfqQWwwfxiVPz_z-bJDRN96bMoeM9V3RY0fA6V7z0QclqTAodmDNItWf4',
      title: 'Maximize Your Q4 Engagement with These 5 Strategic Moves',
      authorName: 'Marco V.',
      authorRole: 'Strategic Lead',
      timeAgo: '3h ago',
      avatarUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLuBebHB9gaqBi3zcM9AtZxb3D0IrHuDincM48LI9UPW-U3SM1UWpvgqiGc4OIzI6EkJi9aw1KsjKnuhY9ar-Xodx1yoNsXxopboD-iClYbuahXBKIdlyzmZYe2giBy8x1HRElvtS4emHGr5llTbR_ktmbySAenOBHFPPjuUmUrSFQL0ztq1Ub1_ADJiUwuGwFMg86keweQCAQ3q8E4Re5_BaKbVXBonv0vvaej45MUS8Jn1zfX6FsDVqJ2Z',
      likes: 124,
      comments: 18,
    ),
    _BlogData(
      imageUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLvCCh5IaBGg5MtFaR6vB_SUpxHaxvK_FS5dKzCyxTbcInGXPJNYSeytHwSfPS8G7rakg6bAZ67zN0Lj9CfeMob6QovEfjOrCza_COkJNN-ZrIlL4GLaTmV313suUX0o0bKQd2plKT_QqvOwea1_dVh76-dAxGfv2aY_wyGVdp0Z12LtR8-c6mMmrF7FiaLXEuWDtcTzsgjp7ktmKneVdqUJ2AbWw673q0XW8minCE2yy7HBnF_rKwUK4LZV',
      title: 'The Future of AI in Influencer Marketing: Trends for 2024',
      authorName: 'Jessica Chen',
      authorRole: 'Tech Editor',
      timeAgo: '1d ago',
      avatarUrl:
      'https://lh3.googleusercontent.com/aida/AP1WRLu9w7HOB4PUKu41vH84VVf3fNn6ukSTMgFdqYRY_-Rzqk-d7CSBBA8UDwa1OWbn0zrlDsjOh_BilOwPuHBAidt7FnQ9utepwk2K_hi7P9-aXjvv3pF55Qeb65witesJWF-PTto3d1fJRg-h-9rzuBfT2-tmc19AUhnwaAeDD5UoSklupTVzntIfa1EqKmXihWvbS22GVK4U7R2A07DWDw66laP-D0rtUu9Ui-fJB7l9niMxpnuZEO-v8Lc',
      likes: 89,
      comments: 4,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Insights & News',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 340,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _blogs.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, i) => _BlogCard(data: _blogs[i]),
          ),
        ),
      ],
    );
  }
}

class _BlogCard extends StatelessWidget {
  const _BlogCard({required this.data});
  final _BlogData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover image
          Image.network(
            data.imageUrl,
            height: 160,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  data.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                // Author row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundImage: NetworkImage(data.avatarUrl),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.authorName,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          '${data.authorRole} · ${data.timeAgo}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(color: AppColors.border, height: 1),
                const SizedBox(height: 10),
                // Interaction bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        _ReactionChip(
                          icon: Icons.favorite_border_rounded,
                          count: data.likes,
                        ),
                        const SizedBox(width: 16),
                        _ReactionChip(
                          icon: Icons.chat_bubble_outline_rounded,
                          count: data.comments,
                        ),
                      ],
                    ),
                    const Icon(
                      Icons.share_rounded,
                      size: 18,
                      color: AppColors.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionChip extends StatelessWidget {
  const _ReactionChip({required this.icon, required this.count});
  final IconData icon;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.secondary),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.secondary,
          ),
        ),
      ],
    );
  }
}

class _BlogData {
  const _BlogData({
    required this.imageUrl,
    required this.title,
    required this.authorName,
    required this.authorRole,
    required this.timeAgo,
    required this.avatarUrl,
    required this.likes,
    required this.comments,
  });
  final String imageUrl, title, authorName, authorRole, timeAgo, avatarUrl;
  final int likes, comments;
}
