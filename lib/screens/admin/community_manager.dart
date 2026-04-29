import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/screens/admin/admin_drawer.dart';

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
  final _db = Database();
  bool isGridView = false;
  
  List<dynamic> _communities = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchCommunities();
  }

  Future<void> _fetchCommunities() async {
    setState(() => _isLoading = true);
    try {
      final response = await _db.postJsonData({
        'action': 'admin_fetch_communities',
        'search': _searchQuery,
      });

      if (response['success'] == true) {
        setState(() {
          _communities = response['data'] ?? [];
        });
      } else {
        _showSnackBar(response['message']?.toString() ?? 'Failed to load communities');
      }
    } catch (e) {
      _showSnackBar('Error loading communities: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateCommunityStatus(int communityId, int status) async {
    try {
      final response = await _db.postJsonData({
        'action': 'admin_update_community_status',
        'community_id': communityId.toString(),
        'status': status.toString(),
      });

      if (response['success'] == true) {
        _showSnackBar('Status updated successfully');
        _fetchCommunities(); // Refresh list
      } else {
        _showSnackBar(response['message']?.toString() ?? 'Failed to update status');
      }
    } catch (e) {
      _showSnackBar('Error updating status: $e');
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final pendingCommunities = _communities.where((c) => c['status'].toString() == '0').toList();
    final activeCommunities = _communities.where((c) => c['status'].toString() != '0').toList();

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
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
      body: Column(
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
                    child: TextField(
                      onChanged: (val) {
                        _searchQuery = val;
                        // Debounce could be added here
                      },
                      onSubmitted: (_) => _fetchCommunities(),
                      decoration: InputDecoration(
                        hintText: 'Search communities...',
                        border: InputBorder.none,
                        icon: const Icon(Icons.search, color: AppTheme.muted),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.arrow_forward_ios, size: 14),
                          onPressed: _fetchCommunities,
                        ),
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

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _fetchCommunities,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (pendingCommunities.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'PENDING APPROVAL (${pendingCommunities.length})',
                                    style: const TextStyle(
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
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: pendingCommunities.length,
                                itemBuilder: (ctx, i) {
                                  final c = pendingCommunities[i];
                                  return _buildPendingCard(c);
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],

                          if (activeCommunities.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(32),
                              child: Center(
                                child: Text('No active communities found.', style: TextStyle(color: AppTheme.muted)),
                              ),
                            )
                          else
                            isGridView ? _buildGridView(activeCommunities) : _buildListView(activeCommunities),
                            
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
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

  Widget _buildPendingCard(dynamic c) {
    final title = c['community_title']?.toString() ?? 'Unknown';
    final manager = c['owner_name']?.toString() ?? 'Unknown';
    final initials = title.isNotEmpty ? title[0].toUpperCase() : '?';
    final id = int.tryParse(c['id']?.toString() ?? '0') ?? 0;

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
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      manager,
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 11,
                      ),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
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
                  onPressed: () => _updateCommunityStatus(id, 1), // 1 = approved
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
                  onPressed: () => _updateCommunityStatus(id, 2), // 2 = suspended
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.error,
                    side: const BorderSide(color: AppTheme.error),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Reject', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<dynamic> activeCommunities) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: activeCommunities.length,
      itemBuilder: (ctx, i) {
        final c = activeCommunities[i];
        return _buildCommunityCard(c);
      },
    );
  }

  Widget _buildGridView(List<dynamic> activeCommunities) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.65,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: activeCommunities.length,
      itemBuilder: (ctx, i) {
        final c = activeCommunities[i];
        return _buildCommunityCardGrid(c);
      },
    );
  }

  Widget _buildCommunityCard(dynamic c) {
    final name = c['community_title']?.toString() ?? 'Unknown';
    final manager = c['owner_name']?.toString() ?? 'Unknown';
    final catId = c['cat_id']?.toString() ?? '1';
    final members = c['total_members']?.toString() ?? '0';
    final packages = c['total_packages']?.toString() ?? '0';
    final orders = c['total_orders']?.toString() ?? '0';
    final statusText = c['status_text']?.toString() ?? '';
    final isApproved = c['status']?.toString() == '1';
    final privacy = c['group_privacy']?.toString() ?? 'Public';
    final id = int.tryParse(c['id']?.toString() ?? '0') ?? 0;

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
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.softLavender,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.groups, color: AppTheme.lavender, size: 30),
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
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _buildBadge(
                                'CAT $catId',
                                AppTheme.softLavender,
                                AppTheme.lavender,
                              ),
                              const SizedBox(width: 6),
                              _buildBadge(
                                privacy.toUpperCase(),
                                Colors.green.withOpacity(0.1),
                                Colors.green,
                              ),
                              const SizedBox(width: 6),
                              _buildBadge(
                                statusText.toUpperCase(),
                                isApproved ? Colors.blue.withOpacity(0.1) : AppTheme.error.withOpacity(0.1),
                                isApproved ? Colors.blue : AppTheme.error,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            onPressed: () => _showChatModal(manager),
                            icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.muted, size: 20)),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: AppTheme.muted, size: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          onSelected: (val) {
                            if (val == 'suspend') {
                              _updateCommunityStatus(id, 2);
                            } else if (val == 'approve') {
                              _updateCommunityStatus(id, 1);
                            }
                          },
                          itemBuilder: (_) => [
                            if (isApproved)
                              const PopupMenuItem(value: 'suspend', child: Row(children: [Icon(Icons.block, color: AppTheme.error, size: 18), SizedBox(width: 12), Text('Suspend')]))
                            else
                              const PopupMenuItem(value: 'approve', child: Row(children: [Icon(Icons.check_circle, color: Colors.green, size: 18), SizedBox(width: 12), Text('Approve')])),
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
                    'Managed by $manager',
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
                _buildStat('ORDERS', orders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommunityCardGrid(dynamic c) {
    final name = c['community_title']?.toString() ?? 'Unknown';
    final members = c['total_members']?.toString() ?? '0';
    final catId = c['cat_id']?.toString() ?? '1';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          Expanded(child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.softLavender,
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: const Center(child: Icon(Icons.groups, color: AppTheme.lavender, size: 40)),
          )),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis,),
                Text(
                  '$members members',
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
                const SizedBox(height: 8),
                _buildBadge('CAT $catId', AppTheme.softLavender, AppTheme.lavender),
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
          fontSize: 8,
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
          Container(padding: const EdgeInsets.all(16), decoration: const BoxDecoration(color: AppTheme.lavender, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: [
                CircleAvatar(radius: 16, backgroundColor: Colors.white24, child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
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
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                const Text("Hello! I'm the administrator for this community. How can I help you today?", style: TextStyle(fontSize: 12)),
                const SizedBox(height: 4),
                const Text('09:41 AM', style: TextStyle(fontSize: 9, color: AppTheme.muted), textAlign: TextAlign.right),
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
          const Text('STATUS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.muted, letterSpacing: 1)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: ['All', 'Approved', 'Pending', 'Suspended'].map((c) => ChoiceChip(label: Text(c), selected: c == 'All', selectedColor: AppTheme.softLavender, labelStyle: TextStyle(color: c == 'All' ? AppTheme.lavender : AppTheme.muted, fontWeight: FontWeight.bold, fontSize: 13), side: BorderSide(color: c == 'All' ? AppTheme.lavender : AppTheme.border), onSelected: (_) {})).toList()),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity, height: 54, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.lavender, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }
}
