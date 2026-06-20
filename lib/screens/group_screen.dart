import 'package:commity_app1/screens/commity_Manage.dart';
import 'package:commity_app1/screens/create_community_screen.dart';
import 'package:commity_app1/screens/group_model.dart';
import 'package:commity_app1/screens/User_screens/CommunityProfile.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';

import '../Database/Database.dart';

// String extension for capitalize
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

class SuggestedGroup {
  final String id;
  final String name;
  final String category;
  final String coverUrl;
  final int memberCount;
  final String description;
  final String joiningRule;
  final String visibility;
  bool isJoined;
  bool isLoading;

  SuggestedGroup({
    required this.id,
    required this.name,
    required this.category,
    required this.coverUrl,
    required this.memberCount,
    required this.description,
    this.joiningRule = 'free',
    this.visibility = 'public',
    this.isJoined = false,
    this.isLoading = false,
  });
}

class GroupsScreen extends StatefulWidget {
  const GroupsScreen({super.key});

  @override
  State<GroupsScreen> createState() => _GroupsScreenState();
}

class _GroupsScreenState extends State<GroupsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = false;
  bool _isLoadingOwn = false;
  bool _isLoadingJoined = false;

  List<SuggestedGroup> _suggestedGroups = [];
  List<Map<String, dynamic>> _ownCommunities = [];
  List<Map<String, dynamic>> _joinedCommunities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
      if (_searchQuery.isNotEmpty) {
        _searchCommunities();
      }
    });
    _loadData();
  }

  String _vendorId = '0';

  Future<void> _loadData() async {
    _vendorId = await AuthService.getVendorIdString();
    await Future.wait([
      _fetchOwnCommunities(),
      _fetchJoinedCommunities(),
      _fetchSuggestedCommunities(),
    ]);
  }

  /// Check if the API response indicates success
  bool _isSuccessResponse(Map response) {
    if (response['success'] == true) return true;
    if (response['status'] == 200) return true;
    if (response['status'] == 'success') return true;
    if (response.containsKey('data') &&
        response['status'] != 300 &&
        response['error'] == null)
      return true;
    return false;
  }

  /// Navigate to create community screen and refresh on return
  Future<void> _navigateToCreateCommunity() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CreateCommunityScreen()),
    );
    // If community was created successfully, refresh all data
    if (result == true) {
      _loadData();
      // Switch to "Your Groups" tab to show the new community
      _tabController.animateTo(1);
    }
  }

  Future<void> _fetchOwnCommunities() async {
    setState(() => _isLoadingOwn = true);
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'fetch_own_communities',
        'vendor_id':
            _vendorId, // ✅ Dynamic vendor ID, // TODO: Get from shared preferences
      });

      print('📩 Own Communities Response: $response');

      if (_isSuccessResponse(response)) {
        setState(() {
          _ownCommunities = List<Map<String, dynamic>>.from(
            response['data'] ?? [],
          );
        });
        print('✅ Own communities loaded: ${_ownCommunities.length}');
      } else {
        print(
          '❌ fetch_own_communities failed: ${response['message'] ?? response['error']}',
        );
      }
    } catch (e) {
      print('❌ Error fetching own communities: $e');
    } finally {
      setState(() => _isLoadingOwn = false);
    }
  }

  Future<void> _fetchJoinedCommunities() async {
    setState(() => _isLoadingJoined = true);
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'fetch_joined_communities',
        'vendor_id':
            _vendorId, // ✅ Dynamic vendor ID, // TODO: Get from shared preferences
      });

      print('📩 Joined Communities Response: $response');

      if (_isSuccessResponse(response)) {
        setState(() {
          _joinedCommunities = List<Map<String, dynamic>>.from(
            response['data'] ?? [],
          );
        });
        print('✅ Joined communities loaded: ${_joinedCommunities.length}');
      } else {
        print(
          '❌ fetch_joined_communities failed: ${response['message'] ?? response['error']}',
        );
      }
    } catch (e) {
      print('❌ Error fetching joined communities: $e');
    } finally {
      setState(() => _isLoadingJoined = false);
    }
  }

  Future<void> _fetchSuggestedCommunities() async {
    setState(() => _isLoading = true);
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'search_communities',
        'vendor_id':
            _vendorId, // ✅ Dynamic vendor ID, // TODO: Get from shared preferences
        'search': '', // Empty search to get all communities
      });

      print('📩 Suggested Communities Response: $response');

      if (_isSuccessResponse(response)) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _suggestedGroups = data.map((community) {
            return SuggestedGroup(
              id: community['id']?.toString() ?? '',
              name: community['community_title'] ?? 'Unknown',
              category:
                  community['tags']?.toString().split(',')[0] ?? 'general',
              coverUrl:
                  community['cover_image'] ??
                  'https://picsum.photos/400/200?random=${community['id']}',
              memberCount:
                  int.tryParse(community['member_count']?.toString() ?? '0') ??
                  0,
              description:
                  community['description'] ?? 'No description available',
              joiningRule: community['joining_rule'] ?? 'free',
              visibility: community['visibility'] ?? 'public',
            );
          }).toList();
        });
      }
    } catch (e) {
      print('❌ Error fetching suggested communities: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _searchCommunities() async {
    if (_searchQuery.isEmpty) {
      _fetchSuggestedCommunities();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'search_communities',
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID,
        'search': _searchQuery,
      });

      if (_isSuccessResponse(response)) {
        final List<dynamic> data = response['data'] ?? [];
        setState(() {
          _suggestedGroups = data.map((community) {
            return SuggestedGroup(
              id: community['id']?.toString() ?? '',
              name: community['community_title'] ?? 'Unknown',
              category:
                  community['tags']?.toString().split(',')[0] ?? 'general',
              coverUrl:
                  community['cover_image'] ??
                  'https://picsum.photos/400/200?random=${community['id']}',
              memberCount:
                  int.tryParse(community['member_count']?.toString() ?? '0') ??
                  0,
              description:
                  community['description'] ?? 'No description available',
              joiningRule: community['joining_rule'] ?? 'free',
              visibility: community['visibility'] ?? 'public',
            );
          }).toList();
        });
      }
    } catch (e) {
      print('❌ Error searching communities: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinCommunity(SuggestedGroup group) async {
    setState(() => group.isLoading = true);
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'join_community',
        'group_id': group.id,
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID,
      });

      print('📩 Join Community Response: $response');

      if (_isSuccessResponse(response)) {
        setState(() {
          group.isJoined = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Joined successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Refresh joined communities
        _fetchJoinedCommunities();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Failed to join community'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Error joining community: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => group.isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }

  List<SuggestedGroup> get _filteredSuggested {
    if (_searchQuery.isEmpty) return _suggestedGroups;
    return _suggestedGroups
        .where(
          (g) =>
              g.name.toLowerCase().contains(_searchQuery) ||
              g.category.toLowerCase().contains(_searchQuery) ||
              g.description.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  List<Group> get _filteredUserGroups {
    if (_searchQuery.isEmpty) return userCreatedGroups;
    return userCreatedGroups
        .where(
          (g) =>
              g.name.toLowerCase().contains(_searchQuery) ||
              g.privacy.toLowerCase().contains(_searchQuery),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateCommunity,
        backgroundColor: const Color(0xff8F7CFF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ── Purple Header ──────────────────────────────────────────────
            Container(
              color: const Color(0xff8F7CFF),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Groups',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Search bar
                  Container(
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search groups...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 14,
                        ),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.white.withOpacity(0.8),
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: Icon(
                                  Icons.close,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 18,
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tab bar
                  TabBar(
                    controller: _tabController,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    indicatorColor: Colors.white,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      const Tab(text: 'For You'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Your Groups'),
                            if ((_ownCommunities.isNotEmpty) ||
                                (_joinedCommunities.isNotEmpty)) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_ownCommunities.length + _joinedCommunities.length}',
                                  style: const TextStyle(
                                    color: Color(0xff8F7CFF),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Tab(text: 'Discover'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildForYouTab(),
                  _buildYourGroupsTab(),
                  _buildDiscoverTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── For You Tab ────────────────────────────────────────────────────────────
  Widget _buildForYouTab() {
    final groups = _filteredSuggested;
    if (groups.isEmpty) {
      return Center(
        child: Text(
          'No groups found for "$_searchQuery"',
          style: const TextStyle(color: Color(0xFF6B7280), fontSize: 15),
        ),
      );
    }
    final Map<String, List<SuggestedGroup>> byCategory = {};
    for (final g in groups) {
      byCategory.putIfAbsent(g.category, () => []).add(g);
    }
    return ListView(
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      children: byCategory.entries.map((entry) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E5FF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '#${entry.key}',
                  style: const TextStyle(
                    color: Color(0xff8F7CFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            ...entry.value.map((g) => _buildSuggestedCard(g)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildSuggestedCard(SuggestedGroup group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              group.coverUrl,
              height: 120,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 120,
                color: const Color(0xFFE8E5FF),
                child: const Center(
                  child: Icon(Icons.group, color: Color(0xff8F7CFF), size: 40),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xff8F7CFF), Color(0xffB5ACFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.name,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        group.description,
                        style: const TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.people_outline,
                            size: 13,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_formatCount(group.memberCount)} members',
                            style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: group.isLoading ? null : () => _joinCommunity(group),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: group.isJoined
                          ? Colors.white
                          : const Color(0xff8F7CFF),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: const Color(0xff8F7CFF),
                        width: 1.5,
                      ),
                    ),
                    child: group.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xff8F7CFF),
                            ),
                          )
                        : Text(
                            group.isJoined ? 'Joined ✓' : 'Join',
                            style: TextStyle(
                              color: group.isJoined
                                  ? const Color(0xff8F7CFF)
                                  : Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Your Groups Tab ────────────────────────────────────────────────────────
  Widget _buildYourGroupsTab() {
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchOwnCommunities();
        await _fetchJoinedCommunities();
      },
      child: _buildYourGroupsContent(),
    );
  }

  Widget _buildYourGroupsContent() {
    if (_isLoadingOwn && _isLoadingJoined) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xff8F7CFF)),
      );
    }

    final allGroups = [..._ownCommunities, ..._joinedCommunities];

    if (allGroups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E5FF),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.group_add_outlined,
                  color: Color(0xff8F7CFF),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No communities yet',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "You haven't created or joined any communities yet.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _navigateToCreateCommunity,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff8F7CFF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Create Community',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: allGroups.length,
      itemBuilder: (context, index) {
        final community = allGroups[index];
        final isOwner = _ownCommunities.contains(community);
        final role = community['role']?.toString() ?? 'member';
        final joinStatus = community['join_status']?.toString() ?? 'approved';

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: CircleAvatar(
              radius: 28,
              backgroundImage: NetworkImage(
                community['cover_image'] ??
                    community['logo'] ??
                    'https://picsum.photos/200/200?random=${community['id']}',
              ),
              child:
                  community['cover_image'] == null && community['logo'] == null
                  ? const Icon(Icons.group, color: Color(0xff8F7CFF))
                  : null,
            ),
            title: Text(
              community['community_title'] ?? 'Unknown Community',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Colors.black,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Icon(
                    community['visibility'] == 'private'
                        ? Icons.lock_outline
                        : Icons.public,
                    size: 13,
                    color: const Color(0xFF6B7280),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${community['visibility']?.toString().capitalize() ?? 'Public'} • ${role.capitalize()}',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 12,
                    ),
                  ),
                  if (joinStatus == 'pending') ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Pending',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            trailing: isOwner || role == 'admin'
                ? ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CommunityPrivateAdminView(  //comment
                          groupName: community['community_title'] ?? '',
                          privacy: community['visibility'] ?? 'public',
                        ),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE8E5FF),
                      foregroundColor: const Color(0xff8F7CFF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'Manage',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  )
                : ElevatedButton(
                    onPressed: null, // TODO: Implement community details view
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.withOpacity(0.1),
                      foregroundColor: Colors.grey,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      'View',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ── Discover Tab ───────────────────────────────────────────────────────────
  String _discoverCategory = 'All';
  final List<String> _discoverCategories = [
    'All',
    'Development',
    'Design',
    'Artificial Intelligence',
    'Business',
  ];

  Widget _buildDiscoverTab() {
    final groups = _filteredSuggested;

    return Column(
      children: [
        // Category Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: Row(
            children: _discoverCategories.map((cat) {
              final active = _discoverCategory == cat;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(cat),
                  selected: active,
                  onSelected: (_) => setState(() => _discoverCategory = cat),
                  selectedColor: const Color(0xff8F7CFF),
                  backgroundColor: Colors.white,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : const Color(0xFF6B7280),
                    fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: active
                          ? const Color(0xff8F7CFF)
                          : const Color(0xFFE6E6F0),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Community Cards
        Expanded(
          child: _isLoading
              ? const Center(
                  child:
                      CircularProgressIndicator(color: Color(0xff8F7CFF)),
                )
              : groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8E5FF),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(Icons.explore_outlined,
                                color: Color(0xff8F7CFF), size: 36),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No communities found',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try a different search or category',
                            style: TextStyle(
                                color: Color(0xFF6B7280), fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSuggestedCommunities,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          return _buildDiscoverCommunityCard(groups[index]);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  /// Premium discover card – adapted from DiscoverCommunities design
  Widget _buildDiscoverCommunityCard(SuggestedGroup group) {
    // Derive display values from the model
    final String initials = group.name.isNotEmpty
        ? group.name
            .split(' ')
            .take(2)
            .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
            .join()
        : '?';
    final String memberText = _formatCount(group.memberCount);
    final String price =
        group.joiningRule == 'free' || group.joiningRule == 'Free'
            ? 'Free'
            : group.joiningRule;
    final String status = 'ONLINE';
    final List<String> tags = group.category
        .split(',')
        .take(3)
        .map((t) => '#${t.trim()}')
        .where((t) => t.length > 1)
        .toList();

    const Color primaryColor = Color(0xff8F7CFF);
    const Color primarySoft = Color(0xFFF1F2FF);
    const Color borderColor = Color(0xFFE6E6F0);
    const Color textMain = Color(0xFF1F2937);
    const Color textMuted = Color(0xFF6B7280);
    const Color successColor = Color(0xFF10B981);
    const Color warningColor = Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Banner + Badge + Logo ──
          Stack(
            clipBehavior: Clip.none,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(23)),
                child: Image.network(
                  group.coverUrl,
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 130,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff8F7CFF), Color(0xffB5ACFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(23)),
                    ),
                    child: const Center(
                      child: Icon(Icons.group, color: Colors.white, size: 44),
                    ),
                  ),
                ),
              ),

              // Visibility badge
              if (group.visibility == 'private')
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.lock, color: warningColor, size: 13),
                        SizedBox(width: 4),
                        Text(
                          'PRIVATE',
                          style: TextStyle(
                            color: warningColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Logo circle
              Positioned(
                bottom: -22,
                left: 18,
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // ── Info Section ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        group.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textMain,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primarySoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: successColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            status,
                            style: const TextStyle(
                              color: successColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // Members + Price
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '👥 $memberText Members',
                      style:
                          const TextStyle(color: textMuted, fontSize: 13),
                    ),
                    Text(
                      price,
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Tags
                if (tags.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primarySoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          tag,
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommunityProfileScreen(
                                groupId: group.id,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: primaryColor,
                          side: const BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('View',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: group.isLoading
                            ? null
                            : () => _joinCommunity(group),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: group.isJoined
                              ? Colors.white
                              : primaryColor,
                          foregroundColor: group.isJoined
                              ? primaryColor
                              : Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: group.isJoined
                                ? const BorderSide(color: primaryColor)
                                : BorderSide.none,
                          ),
                        ),
                        child: group.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor,
                                ),
                              )
                            : Text(
                                group.isJoined ? 'Joined ✓' : 'Join',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
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
