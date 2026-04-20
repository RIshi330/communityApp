import 'package:commity_app1/model/user_model.dart';
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
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _followers = FollowerModel.sampleFollowers;
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
            Tab(text: '${widget.user.followersCount} Message'), //
            Tab(text: '${widget.user.followingCount} Message'),  //
            const Tab(text: '0 Subscriptions'),
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
                const _FollowingTabContent(),
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

          // 💜 MESSAGE BUTTON
        //  _MessageButton(onTap: () {}),

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
}

// 💬 FOLLOWING TAB CONTENT
class _FollowingTabContent extends StatelessWidget {
  const _FollowingTabContent();

  @override
  Widget build(BuildContext context) {
    final following = FollowingModel.sampleFollowing;

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

              //_MessageButton(onTap: () {}),

              const SizedBox(width: 8),
            ],
          ),
        );
      },
    );
  }
}

// 💜 LAVENDER MESSAGE BUTTON
// class _MessageButton extends StatelessWidget {
//   final VoidCallback onTap;

//   const _MessageButton({required this.onTap});

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         padding: const EdgeInsets.symmetric(
//             horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: const Color(0xFFB39DDB),
//           borderRadius: BorderRadius.circular(20),
//         ),
//         child: const Text(
//           "Message",
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.w700,
//             fontSize: 13,
//           ),
//         ),
//       ),
//     );
//   }
// }
