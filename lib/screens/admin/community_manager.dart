import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';

void main() {
  runApp(const CommunityAdminApp());
}

class CommunityAdminApp extends StatelessWidget {
  const CommunityAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Community Admin',
      theme: AppTheme.theme,
      home: const CommunityManagementHub(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppTheme {
  static const Color lavender = Color(0xFF7C83FD);
  static const Color softLavender = Color(0xFFF1F2FF);
  static const Color border = Color(0xFFE6E6F0);
  static const Color muted = Color(0xFF6B7280);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color error = Color(0xFFEF4444);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: lavender,
        primary: lavender,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8F9FE),
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: lavender),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}

class CommunityManagementHub extends StatefulWidget {
  const CommunityManagementHub({super.key});

  @override
  State<CommunityManagementHub> createState() => _CommunityManagementHubState();
}

class _CommunityManagementHubState extends State<CommunityManagementHub> {
  bool isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Managed Communities'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.lavender.withOpacity(0.1),
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=100',
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and Filter Row
            Padding(
              padding: const EdgeInsets.all(16),
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
                          hintText: 'Search communities...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: AppTheme.muted),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.tune, color: AppTheme.lavender),
                      onPressed: () => _showFilterSheet(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.softLavender,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        _buildToggleButton(
                          Icons.grid_view_rounded,
                          isGridView,
                          () => setState(() => isGridView = true),
                        ),
                        _buildToggleButton(
                          Icons.list_rounded,
                          !isGridView,
                          () => setState(() => isGridView = false),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Pending Approval Section
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'PENDING APPROVAL (4)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.muted,
                      letterSpacing: 1,
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: AppTheme.lavender,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPendingCard(
                    'Design Thinkers',
                    'Alex Rivero',
                    '2h ago',
                    'DT',
                  ),
                  _buildPendingCard(
                    'Vintage Collect',
                    'Sarah Chen',
                    '5h ago',
                    'VC',
                  ),
                ],
              ),
            ),

            // Communities List/Grid
            const SizedBox(height: 24),
            isGridView ? _buildGridView() : _buildListView(),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildToggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? AppTheme.lavender : AppTheme.muted,
        ),
      ),
    );
  }

  Widget _buildPendingCard(
    String title,
    String manager,
    String time,
    String initials,
  ) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 16),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.softLavender,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppTheme.lavender,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$manager • $time',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showChatModal(manager),
                icon: const Icon(
                  Icons.chat_bubble_outline,
                  size: 18,
                  color: AppTheme.lavender,
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
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.lavender,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Approve', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.lavender,
                    side: const BorderSide(color: AppTheme.softLavender),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Details', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return Column(
      children: [
        _buildCommunityCard(
          'Audio Engineers Collective',
          'Marcus Aurelius',
          '3m ago',
          'MUSIC',
          'FREE',
          '12.4k',
          '8',
          '24',
          '82%',
          '1.2k',
          'High',
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&q=80&w=200',
        ),
        _buildCommunityCard(
          'Study Buddies Pro',
          'Elena Fisher',
          '1y ago',
          'EDUCATION',
          'PAID',
          '3.8k',
          '15',
          '156',
          '64%',
          '8.4k',
          'Steady',
          'https://images.unsplash.com/photo-1523240715630-991e2e746e0c?auto=format&fit=crop&q=80&w=200',
        ),
      ],
    );
  }

  Widget _buildGridView() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 0.6,
      children: [
        _buildCommunityCardGrid('Audio Engineers', '12.4k', 'MUSIC'),
        _buildCommunityCardGrid('Study Buddies', '3.8k', 'EDUCATION'),
      ],
    );
  }

  Widget _buildCommunityCard(
    String name,
    String manager,
    String time,
    String category,
    String pricing,
    String members,
    String packages,
    String events,
    String engagement,
    String posts,
    String activity,
    String imageUrl,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildBadge(
                                category,
                                AppTheme.softLavender,
                                AppTheme.lavender,
                              ),
                              const SizedBox(width: 6),
                              _buildBadge(
                                pricing,
                                Colors.green.withOpacity(0.1),
                                Colors.green,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(onPressed: () => _showChatModal(manager), icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.muted, size: 20)),
                        IconButton(onPressed: () {}, icon: const Icon(Icons.block, color: AppTheme.error, size: 20)),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppTheme.muted, size: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (_) {},
                          itemBuilder: (_) => [
                            const PopupMenuItem(value: 'promote', child: Row(children: [Icon(Icons.campaign, color: AppTheme.lavender, size: 18), SizedBox(width: 12), Text('Promote')])),
                            const PopupMenuItem(value: 'sponsor', child: Row(children: [Icon(Icons.volunteer_activism, color: AppTheme.lavender, size: 18), SizedBox(width: 12), Text('Sponsor')])),
                            const PopupMenuItem(value: 'feature', child: Row(children: [Icon(Icons.grade, color: AppTheme.lavender, size: 18), SizedBox(width: 12), Text('Featured')])),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Managed by $manager • $time',
                    style: const TextStyle(color: AppTheme.muted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 2,
              children: [
                _buildStat('MEMBERS', members),
                _buildStat('PACKAGES', packages),
                _buildStat('EVENTS', events),
                _buildStat('ENGAGEMENT', engagement, isColored: true),
                _buildStat('POSTS', posts),
                _buildStat('ACTIVITY', activity),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCardGrid(String name, String members, String cat) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Expanded(child: Container(color: AppTheme.softLavender)),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  '$members members',
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
                const SizedBox(height: 8),
                _buildBadge(cat, AppTheme.softLavender, AppTheme.lavender),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textCol,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStat(String label, String value, {bool isColored = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 9,
            color: AppTheme.muted,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isColored ? AppTheme.lavender : Colors.black,
          ),
        ),
      ],
    );
  }

  void _showChatModal(String name) {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        height: MediaQuery.of(context).size.height * 0.65,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.lavender, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                CircleAvatar(radius: 16, backgroundColor: Colors.white24, child: Text(name.split(' ').map((n) => n[0]).join(''), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const Text('Community Admin', style: TextStyle(color: Colors.white70, fontSize: 10)),
                ]),
              ]),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          Expanded(child: Container(color: AppTheme.surface, padding: const EdgeInsets.all(16), child: Align(alignment: Alignment.topLeft,
            child: Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("Hello! I'm the administrator for this community. How can I help you today?", style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                Text('09:41 AM', style: TextStyle(fontSize: 9, color: AppTheme.muted), textAlign: TextAlign.right),
              ]),
            ),
          ))),
          Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.border))),
            child: Row(children: [
              Expanded(child: TextField(decoration: InputDecoration(hintText: 'Type a message...', filled: true, fillColor: AppTheme.surface, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)))),
              const SizedBox(width: 8),
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppTheme.lavender, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.send, color: Colors.white, size: 20)),
            ]),
          ),
        ]),
      ),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 48, height: 5, decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(3)))),
          const SizedBox(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Filter Communities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close, color: AppTheme.muted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 20),
          const Text('CATEGORY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: ['All', 'Music', 'Education', 'Tech'].map((c) => ChoiceChip(label: Text(c), selected: c == 'All', selectedColor: AppTheme.softLavender, labelStyle: TextStyle(color: c == 'All' ? AppTheme.lavender : AppTheme.muted, fontWeight: FontWeight.bold, fontSize: 13), side: BorderSide(color: c == 'All' ? AppTheme.lavender : AppTheme.border), onSelected: (_) {})).toList()),
          const SizedBox(height: 24),
          const Text('ACCESS TYPE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted, letterSpacing: 1)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.check_circle_outline, size: 18), label: const Text('Free'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton.icon(onPressed: () {}, icon: const Icon(Icons.check_circle, size: 18), label: const Text('Paid'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.softLavender, foregroundColor: AppTheme.lavender, elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: AppTheme.lavender))))),
          ]),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.lavender, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
