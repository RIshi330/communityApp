import 'package:commity_app1/model/user_model.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';

class FollowersScreen extends StatefulWidget {
  final UserModel user;
  final int initialTab;

  const FollowersScreen({
    super.key,
    required this.user,
    this.initialTab = 0,
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<FollowerModel> _followers = [];
  List<FollowingModel> _following = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTab,
    );
    _loadFollowersAndFollowing();
  }

  Future<void> _loadFollowersAndFollowing() async {
    try {
      final database = Database();
      final vendorId = await AuthService.getVendorIdString();
      
      // Fetch followers
      final followersResponse = await database.getData({
        'action': 'followers_list',
        'vendor_id': vendorId,
      });
      
      // Fetch following
      final followingResponse = await database.getData({
        'action': 'following_list',
        'vendor_id': vendorId,
      });
      
      List<FollowerModel> followersList = [];
      List<FollowingModel> followingList = [];
      
      if (followersResponse['success'] == true || followersResponse['status'] == 200) {
        final List<dynamic> followersData = followersResponse['data']['followers'] ?? [];
        followersList = followersData.map((vendorJson) {
          final vendor = vendorJson as Map<String, dynamic>;
          return FollowerModel(
            uid: vendor['id']?.toString() ?? '',
            username: vendor['username'] ?? vendor['name'] ?? '',
            displayName: vendor['name'] ?? '',
            profileImageUrl: vendor['image'] ?? vendor['profile_image'] ?? 'https://i.pravatar.cc/150?img=1',
            isFollowingBack: false,
          );
        }).toList();
      }
      
      if (followingResponse['success'] == true || followingResponse['status'] == 200) {
        final List<dynamic> followingData = followingResponse['data']['following'] ?? [];
        followingList = followingData.map((vendorJson) {
          final vendor = vendorJson as Map<String, dynamic>;
          return FollowingModel(
            uid: vendor['id']?.toString() ?? '',
            username: vendor['username'] ?? vendor['name'] ?? '',
            displayName: vendor['name'] ?? '',
            profileImageUrl: vendor['image'] ?? vendor['profile_image'] ?? 'https://i.pravatar.cc/150?img=1',
          );
        }).toList();
      }
      
      setState(() {
        _followers = followersList.isNotEmpty ? followersList : FollowerModel.sampleFollowers;
        _following = followingList.isNotEmpty ? followingList : FollowingModel.sampleFollowing;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading followers/following: $e');
      _loadSampleData();
    }
  }

  void _loadSampleData() {
    setState(() {
      _followers = FollowerModel.sampleFollowers;
      _following = FollowingModel.sampleFollowing;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<FollowerModel> get _filteredFollowers {
    if (_searchQuery.isEmpty) return _followers;
    return _followers.where((f) {
      return f.username
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          f.displayName
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.user.username,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: [
            Tab(text: 'Followers (${widget.user.followersCount})'),
            Tab(text: 'Following (${widget.user.followingCount})'),
            const Tab(text: 'Subscriptions'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildFollowersList(),
                _FollowingTabContent(following: _following),
                _buildEmptySubscriptions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 SEARCH BAR
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Search",
            hintStyle: TextStyle(color: Colors.grey),
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  // 👥 FOLLOWERS LIST
  Widget _buildFollowersList() {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_filteredFollowers.isEmpty) {
      return const Center(
        child: Text("No followers found",
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _filteredFollowers.length,
      itemBuilder: (context, index) =>
          _buildFollowerTile(_filteredFollowers[index]),
    );
  }

  Widget _buildFollowerTile(FollowerModel follower) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage:
                NetworkImage(follower.profileImageUrl),
            backgroundColor: Colors.grey.shade800,
          ),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  follower.username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  follower.displayName,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          _ActionButton(
            label: 'Message',
            onTap: () => _showActionSnackBar('Message ${follower.username}'),
          ),

          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEmptySubscriptions() {
    return const Center(
      child: Text(
        "No subscriptions",
        style: TextStyle(color: Colors.grey),
      ),
    );
  }

  void _showActionSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF7C83FD),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// 💬 FOLLOWING TAB CONTENT
class _FollowingTabContent extends StatelessWidget {
  final List<FollowingModel> following;

  const _FollowingTabContent({required this.following});

  @override
  Widget build(BuildContext context) {
    if (following.isEmpty) {
      return const Center(
        child: Text("No following", style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: following.length,
      itemBuilder: (context, index) {
        final f = following[index];

        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage:
                    NetworkImage(f.profileImageUrl),
                backgroundColor: Colors.grey.shade800,
              ),
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.username,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600),
                    ),
                    Text(
                      f.displayName,
                      style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              _ActionButton(
                label: 'Message',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Message ${f.username}'),
                      backgroundColor: const Color(0xFF7C83FD),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              const SizedBox(width: 8),

              _ActionButton(
                label: 'Subscribe',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Subscribed to ${f.username}'),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                filled: false,
              ),

              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool filled;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.filled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: filled ? const Color(0xFFB39DDB) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
          border: filled ? null : Border.all(color: Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: filled ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
