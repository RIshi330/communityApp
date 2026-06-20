import 'package:flutter/material.dart';
import 'package:flutter/services.dart';


class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedAccessType = 'All';
  bool _isGridView = false; // Default to list view (since original had list as default)
  int _selectedNavIndex = 0;

  final List<Community> _communities = [
    Community(
      name: 'Audio Engineers Collective',
      category: 'Music',
      accessType: 'Free',
      managedBy: 'Marcus Aurelius',
      timeAgo: '3m ago',
      logoInitials: 'AE',
      memberCount: '12.4k',
      packageCount: '8',
      eventCount: '24',
      engagement: '82%',
      postCount: '1.2k',
      activity: 'High',
      isPaid: false,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuCzqQSheRsAbIgJS3q7yvXOaKf0XSHeGUjgQt-B6_EgSKYLFTsW_VCgw41wYdI0XgqIHT_Jv7QrTe7E5RgUEbfBcICoe5wzUDVkTVTDcY7qjrrhpz6svP7-JW23E6MIoXsGJesuwX4MW2A2F-RthgdYW3j63xQrkzlDLFWZMI03S8aVwKVwmqN8jlUeDWTa_Q4rIgiPNGNHleb8ER3PHzOrWf01HbSlW4_iKn8LiKoEmhPj_f_LGwLiqJeLYxXJy_38D4OWbTjkvhde',
    ),
    Community(
      name: 'Study Buddies Pro',
      category: 'Education',
      accessType: 'Paid',
      managedBy: 'Elena Fisher',
      timeAgo: '1y ago',
      logoInitials: 'SB',
      memberCount: '3.8k',
      packageCount: '15',
      eventCount: '156',
      engagement: '64%',
      postCount: '8.4k',
      activity: 'Steady',
      isPaid: true,
      imageUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuBCC70Pr1_pvhYbxiIS01PWhDihRzR8NWy4hLDODZOZJMThlpRsHy9FT77LQcYcsSxybLaaqTBD5jvcdVF_lWnoP7WevaKTkxkD3-Xi7a4Er0DNNKAt8lfXomZItH8Uyq-3ssz8J9gMpJqwhYYe01E6cGa8np_8xbie-uWq0ge1gijRyIeOWHxwNRploa-kB_OCJ9DXVOy7VHMNo8_Jd1Q6bPJkfBxMR2Rf1DE-KKcYgIBJAa4oppYhFjWUFXABCieLZFNeAFWRRHkN',
    ),
  ];

  final List<PendingCommunity> _pendingCommunities = [
    PendingCommunity(
      name: 'Design Thinkers',
      requester: 'Alex Rivero',
      timeAgo: '2h ago',
      initials: 'DT',
    ),
    PendingCommunity(
      name: 'Vintage Collectors',
      requester: 'Sarah Chen',
      timeAgo: '5h ago',
      initials: 'VC',
    ),
  ];

  List<Community> get _filteredCommunities {
    return _communities.where((c) {
      final matchesSearch = _searchQuery.isEmpty ||
          c.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || c.category == _selectedCategory;
      final matchesAccess =
          _selectedAccessType == 'All' ||
              (_selectedAccessType == 'Free' && !c.isPaid) ||
              (_selectedAccessType == 'Paid' && c.isPaid);
      return matchesSearch && matchesCategory && matchesAccess;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Community Admin"),
        centerTitle: true,
      ),      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchFilterBar(),
                    _buildViewToggle(),
                    _buildPendingApprovalSection(),
                    _buildCommunitiesSection(),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // bottomNavigationBar: _buildBottomNavBar(),
    );
  }


  Widget _buildSearchFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search communities...',
                hintStyle: const TextStyle(color: Color(0xFF6B7280)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF6B7280), size: 20),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _showFilterModal(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: const Color(0xFFE6E6F0)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.filter_list, color: Color(0xFF7C83FD), size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Managed Communities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF151C27),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildToggleButton(
                  icon: Icons.grid_view,
                  isSelected: _isGridView,
                  onTap: () => setState(() => _isGridView = true),
                ),
                _buildToggleButton(
                  icon: Icons.view_list,
                  isSelected: !_isGridView,
                  onTap: () => setState(() => _isGridView = false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)] : [],
        ),
        child: Icon(
          icon,
          size: 20,
          color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildPendingApprovalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'PENDING APPROVAL (4)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Text(
                'View All',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF7C83FD),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _pendingCommunities.length,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final pending = _pendingCommunities[index];
              return _buildPendingCard(pending);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPendingCard(PendingCommunity pending) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6E6F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F3FF),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    pending.initials,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7C83FD),
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
                      pending.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${pending.requester} • ${pending.timeAgo}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Approve'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF7C83FD),
                    side: const BorderSide(color: Color(0xFFE6E6F0)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  child: const Text('Details'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _openChat(pending.requester),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F3FF),
                    border: Border.all(color: const Color(0xFFE6E6F0)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline,
                    size: 18,
                    color: Color(0xFF7C83FD),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommunitiesSection() {
    final communities = _filteredCommunities;

    if (communities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            'No communities found',
            style: TextStyle(color: Color(0xFF6B7280)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: _isGridView
          ? GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 1,
          childAspectRatio: 1.2,
          mainAxisSpacing: 16,
        ),
        itemCount: communities.length,
        itemBuilder: (context, index) => _buildCommunityCard(communities[index]),
      )
          : Column(
        children: communities
            .map((c) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildCommunityCard(c),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildCommunityCard(Community community) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE6E6F0)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        community.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: const Color(0xFFF0F3FF),
                          child: Center(
                            child: Text(
                              community.logoInitials,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            community.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildChip(
                                community.category,
                                backgroundColor: const Color(0xFFF0F3FF),
                                textColor: const Color(0xFF7C83FD),
                              ),
                              const SizedBox(width: 8),
                              _buildChip(
                                community.accessType,
                                backgroundColor: community.isPaid
                                    ? const Color(0xFF7C83FD).withOpacity(0.1)
                                    : const Color(0xFFE8F5E9),
                                textColor: community.isPaid
                                    ? const Color(0xFF7C83FD)
                                    : const Color(0xFF2E7D32),
                                borderColor: community.isPaid
                                    ? const Color(0xFF7C83FD).withOpacity(0.2)
                                    : const Color(0xFFA5D6A7),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildActionButtons(community),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Managed by ${community.managedBy} • ${community.timeAgo}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F9FF).withOpacity(0.2),
              border: Border(top: BorderSide(color: const Color(0xFFE6E6F0))),
            ),
            // child: _buildStatsGrid(community),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, {required Color backgroundColor, required Color textColor, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildActionButtons(Community community) {
    return Row(
      children: [
        _buildIconButton(
          icon: Icons.chat_bubble_outline,
          onTap: () => _openChat(community.managedBy.split(' ').first),
        ),
        const SizedBox(width: 4),
        _buildIconButton(
          icon: Icons.block,
          onTap: () {},
          color: const Color(0xFFBA1A1A),
        ),
        const SizedBox(width: 4),
        _buildDropdownButton(),
      ],
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 20, color: color ?? const Color(0xFF6B7280)),
      ),
    );
  }

  Widget _buildDropdownButton() {
    return PopupMenuButton<String>(
      offset: const Offset(0, 45),
      onSelected: (value) {},
      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF6B7280)),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'promote',
          child: Row(
            children: [
              Icon(Icons.campaign, size: 18, color: Color(0xFF6B7280)),
              SizedBox(width: 12),
              Text('Promote'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'sponsor',
          child: Row(
            children: [
              Icon(Icons.volunteer_activism, size: 18, color: Color(0xFF6B7280)),
              SizedBox(width: 12),
              Text('Sponsor'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'featured',
          child: Row(
            children: [
              Icon(Icons.grade, size: 18, color: Color(0xFF6B7280)),
              SizedBox(width: 12),
              Text('Featured'),
            ],
          ),
        ),
      ],
    );
  }

  // Widget _buildStatsGrid(Community community) {
  //   return GridView.count(
  //     shrinkWrap: true,
  //     physics: const NeverScrollableScrollPhysics(),
  //     crossAxisCount: 3,
  //     childAspectRatio: 2.5,
  //     mainAxisSpacing: 12,
  //     children: [
  //       _buildStatItem('Members', community.memberCount),
  //       _buildStatItem('Packages', community.packageCount),
  //       _buildStatItem('Events', community.eventCount),
  //       _buildStatItem('Engagement', community.engagement, isHighlighted: true),
  //       _buildStatItem('Posts', community.postCount),
  //       _buildStatItem('Activity', community.activity),
  //     ],
  //   );
  // }

  Widget _buildStatItem(String label, String value, {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isHighlighted ? const Color(0xFF7C83FD) : const Color(0xFF151C27),
          ),
        ),
      ],
    );
  }

  // Widget _buildBottomNavBar() {
  //   final navItems = [
  //     {'icon': Icons.group_work, 'label': 'Hub', 'filled': true},
  //     {'icon': Icons.group, 'label': 'Members', 'filled': false},
  //     {'icon': Icons.analytics, 'label': 'Reports', 'filled': false},
  //     {'icon': Icons.settings, 'label': 'Settings', 'filled': false},
  //   ];
  //
  //   return Container(
  //     decoration: const BoxDecoration(
  //       color: Colors.white,
  //       border: Border(top: BorderSide(color: Color(0xFFE6E6F0))),
  //     ),
  //     child: SafeArea(
  //       top: false,
  //       child: Padding(
  //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //         child: Row(
  //           mainAxisAlignment: MainAxisAlignment.spaceAround,
  //           children: navItems.asMap().entries.map((entry) {
  //             final index = entry.key;
  //             final item = entry.value;
  //             final isSelected = _selectedNavIndex == index;
  //             return GestureDetector(
  //               onTap: () => setState(() => _selectedNavIndex = index),
  //               child: Container(
  //                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  //                 decoration: BoxDecoration(
  //                   color: isSelected ? const Color(0xFFF0F3FF) : Colors.transparent,
  //                   borderRadius: BorderRadius.circular(8),
  //                 ),
  //                 child: Column(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(
  //                       item['icon'] as IconData,
  //                       color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFF6B7280),
  //                       size: 24,
  //                       fill: (item['filled'] as bool) ? 1 : 0,
  //                     ),
  //                     const SizedBox(height: 4),
  //                     Text(
  //                       item['label'] as String,
  //                       style: TextStyle(
  //                         fontSize: 10,
  //                         fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
  //                         color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFF6B7280),
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           }).toList(),
  //         ),
  //       ),
  //     ),
  //   );
  // }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterSheet(),
    );
  }

  Widget _buildFilterSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE6E6F0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Communities',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Color(0xFF6B7280)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'CATEGORY',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: ['All', 'Music', 'Education', 'Tech'].map((category) {
              final isSelected = _selectedCategory == category;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = category),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF7C83FD).withOpacity(0.1) : Colors.transparent,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFFE6E6F0),
                    ),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    category,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFF6B7280),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: const Text(
              'ACCESS TYPE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAccessTypeButton('All'),
              const SizedBox(width: 12),
              _buildAccessTypeButton('Free'),
              const SizedBox(width: 12),
              _buildAccessTypeButton('Paid'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply Filters',),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildAccessTypeButton(String type) {
    final isSelected = _selectedAccessType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAccessType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF7C83FD).withOpacity(0.05) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFFE6E6F0),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle,
                size: 20,
                color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Text(
                type,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? const Color(0xFF7C83FD) : const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openChat(String name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildChatSheet(name),
    );
  }

  Widget _buildChatSheet(String name) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF7C83FD),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      name.split(' ').map((n) => n[0]).join(''),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
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
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Community Admin',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.close, color: Colors.white),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    constraints: const BoxConstraints(maxWidth: 250),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          "Hello! I'm the administrator for this community. How can I help you today?",
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '09:41 AM',
                          style: TextStyle(
                            fontSize: 9,
                            color: const Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFE6E6F0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE6E6F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFE6E6F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF7C83FD)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF7C83FD),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.send, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Community {
  final String name;
  final String category;
  final String accessType;
  final String managedBy;
  final String timeAgo;
  final String logoInitials;
  final String memberCount;
  final String packageCount;
  final String eventCount;
  final String engagement;
  final String postCount;
  final String activity;
  final bool isPaid;
  final String imageUrl;

  Community({
    required this.name,
    required this.category,
    required this.accessType,
    required this.managedBy,
    required this.timeAgo,
    required this.logoInitials,
    required this.memberCount,
    required this.packageCount,
    required this.eventCount,
    required this.engagement,
    required this.postCount,
    required this.activity,
    required this.isPaid,
    required this.imageUrl,
  });
}

class PendingCommunity {
  final String name;
  final String requester;
  final String timeAgo;
  final String initials;

  PendingCommunity({
    required this.name,
    required this.requester,
    required this.timeAgo,
    required this.initials,
  });
}