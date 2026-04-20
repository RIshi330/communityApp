// lib/screens/feed_screen.dart

import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/screens/create_community_screen.dart';
import 'package:commity_app1/screens/group_screen.dart'; // fixed: groups_screen (with s)
import 'package:commity_app1/screens/loginscreen.dart';
import 'package:commity_app1/screens/setting_screen.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:commity_app1/screens/post_item.dart';
import 'package:commity_app1/model/post_model.dart';
import 'package:commity_app1/screens/story_item.dart';
import 'package:commity_app1/model/story_model.dart';
import 'package:commity_app1/screens/create_post.dart';
import 'package:commity_app1/screens/notification_screen.dart';
import 'package:commity_app1/screens/profile_screen.dart';
import 'package:commity_app1/screens/product_shop/productshop_btc.dart';
import 'package:commity_app1/screens/promotion_marketplace_screen.dart';
import 'package:share_plus/share_plus.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({Key? key}) : super(key: key);

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final TextEditingController _commentController = TextEditingController();
  bool _isLoadingPosts = false;

  // ✅ User data from API (like profile screen)
  String _userName = "User";
  String _userHandle = "@user";
  String _vendorId = '0'; // ✅ Dynamic vendor ID from session

  final List<Story> stories = [
    Story(
      username: 'Your story',
      imageUrl: 'https://picsum.photos/200/300?random=1',
      isYourStory: true,
    ),
    Story(
      username: 'abhi_amup_108',
      imageUrl: 'https://picsum.photos/200/300?random=2',
      hasStory: true,
    ),
    Story(
      username: 'nikita_w_21',
      imageUrl: 'https://picsum.photos/200/300?random=3',
      hasStory: true,
    ),
    Story(
      username: '_shivkumar',
      imageUrl: 'https://picsum.photos/200/300?random=4',
      hasStory: true,
    ),
    Story(
      username: 'rahul_dev',
      imageUrl: 'https://picsum.photos/200/300?random=5',
      hasStory: true,
    ),
  ];

  List<Post> posts = [];

  @override
  void initState() {
    super.initState();
    _initVendorId(); // ✅ Load vendor ID first
    _loadPosts();
  }

  // ✅ Initialize vendor ID from session
  Future<void> _initVendorId() async {
    _vendorId = await AuthService.getVendorIdString();
    _fetchUserProfile();
  }

  // ✅ Fetch user profile data (like profile screen)
  Future<void> _fetchUserProfile() async {
    try {
      final database = Database();
      
      final response = await database.getData({
        'action': 'profile',
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID
      });

      if (response['success'] == true || response['status'] == 200) {
        final profileData = response['data'];
        
        if (profileData != null) {
          final profile = profileData['profile'];
          
          setState(() {
            // ✅ Update user data from API (like profile screen)
            _userName = profile['name']?.toString() ?? 'User';
            _userHandle = '@${profile['name']?.toString().toLowerCase().replaceAll(' ', '_') ?? 'user'}';
          });
          
          print("✅ User profile loaded: $_userName, $_userHandle");
        }
      }
    } catch (e) {
      print("❌ Error loading user profile: $e");
      // Keep default values if API fails
    }
  }

  // Load posts from API
  Future<void> _loadPosts() async {
    setState(() => _isLoadingPosts = true);
    
    try {
      final database = Database();
      
      // ✅ Fetch user's saved interests
      final savedInterests = await AuthService.getSavedInterests();
      final interestsFilter = savedInterests?.join(',') ?? '';
      
      // Call view_all_posts API
      final response = await database.getData({
        'action': 'view_all_posts',
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID
        if (interestsFilter.isNotEmpty) 'interests': interestsFilter, // ✅ Pass interests to backend
      });
      
      print(" View All Posts Request: action=view_all_posts, vendor_id=$_vendorId, interests=$interestsFilter");
      print(" View All Posts Response: $response");

      if (response['success'] == true || response['status'] == 200) {
        final List<dynamic> postsData = response['data'] ?? [];
        
        // Convert API data to Post objects
        List<Post> apiPosts = postsData.map((postJson) {
          final post = postJson as Map<String, dynamic>;
          final List<String> images = (post['images'] as List<dynamic>?)
              ?.map((img) => img.toString())
              .toList() ?? [];
          
          return Post(
            id: post['id']?.toString() ?? '',
            username: post['vendor_name']?.toString() ?? 'Unknown User',
            userImage: 'https://i.pravatar.cc/150?img=${post['vendor_id'] ?? 1}',
            postImages: images.isNotEmpty ? images : ['https://picsum.photos/800/600?random=${post['id']}'],
            likes: 0, // TODO: Add likes count to API
            caption: post['label']?.toString() ?? '',
            timeAgo: _formatTimeAgo(post['created_date']?.toString() ?? ''),
            comments: 0, // TODO: Add comments count to API
            shares: 0, // TODO: Add shares count to API
            isVerified: post['vendor_name']?.toString().toLowerCase().contains('virat') ?? false,
          );
        }).toList();

        setState(() {
          posts = apiPosts;
          _addUserPosts(); // Add local posts
        });
        
      } else {
        // Fallback to dummy data if API fails
        _loadDummyPosts();
        print(" API failed, using dummy data: ${response['message']}");
      }
    } catch (e) {
      // Fallback to dummy data on error
      _loadDummyPosts();
      print(" Error loading posts: $e");
    } finally {
      setState(() => _isLoadingPosts = false);
    }
  }

  // Format time ago from created_date
  String _formatTimeAgo(String? createdDate) {
    if (createdDate == null || createdDate.isEmpty) return 'Just now';
    
    try {
      final dateTime = DateTime.parse(createdDate);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      if (difference.inDays < 7) return '${difference.inDays}d ago';
      return '${difference.inDays ~/ 7}w ago';
    } catch (e) {
      return 'Just now';
    }
  }

  // Fallback dummy posts
  void _loadDummyPosts() {
    posts = [
      Post(
        id: '1',
        username: 'virat.kohli',
        userImage:
            'https://images.unsplash.com/photo-1546519638-68e109498ffc?w=150',
        isVerified: true,
        postImages: [
          'https://images.unsplash.com/photo-1531415074968-036ba1b575da?w=800',
          'https://images.unsplash.com/photo-1624526267942-ab0ff8a3e972?w=800',
          'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
        ],
        likes: 1200,
        caption: 'Practice makes perfect! ',
        timeAgo: '2h',
        comments: 150,
        shares: 890,
      ),
      Post(
        id: '2',
        username: 'rohitsharma45',
        userImage:
            'https://images.unsplash.com/photo-1552374196-1ab2a1c593e8?w=150',
        isVerified: true,
        postImages: [
          'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?w=800',
        ],
        likes: 950,
        caption: 'New day, new goals! Cricket is life ',
        timeAgo: '5h',
        comments: 80,
        shares: 567,
      ),
    ];
    _addUserPosts();
  }

  void _addUserPosts() {
    try {
      if (globalPosts.isNotEmpty) {
        for (var post in globalPosts.reversed) {
          if (!posts.any((p) => p.id == post.id)) {
            posts.insert(0, post);
          }
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  Future<void> _refreshFeed() async {
    await _loadPosts();
  }

  void _deletePost(String postId) {
    setState(() {
      posts.removeWhere((post) => post.id == postId);
      globalPosts.removeWhere((post) => post.id == postId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post deleted'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _openCreateBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Create',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E5FF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: Color(0xff8F7CFF),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Create a post',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                subtitle: const Text(
                  'Share a post on your timeline.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreatePostFinalScreen()),
                  ).then((result) {
                    // Always refresh when returning from create post
                    _loadPosts();
                  });
                },
              ),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8E5FF),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.group_add_outlined,
                    color: Color(0xff8F7CFF),
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Create a group',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.black,
                  ),
                ),
                subtitle: const Text(
                  'Create a public or private group.',
                  style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateCommunityScreen()),
                  ).then((result) {
                    if (result == true) {
                      _loadPosts(); // Refresh feed after community creation
                    }
                  });
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  void _openDrawerMenu() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const SizedBox(),
      transitionBuilder: (context, animation, _, __) {
        final slide = Tween<Offset>(
          begin: const Offset(-1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

        return SlideTransition(
          position: slide,
          child: Align(
            alignment: Alignment.centerLeft,
            child: _buildSideMenu(context),
          ),
        );
      },
    );
  }

  Widget _buildSideMenu(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.72,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xff8F7CFF),
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xff7B68EE),
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        'https://picsum.photos/100/100?random=99',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _userHandle,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _buildDrawerItem(
                icon: Icons.groups_outlined,
                label: 'Groups',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const GroupsScreen()), // ✅ fixed
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.group_add_outlined,
                label: 'Create Community',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateCommunityScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.person_outline,
                label: 'Profile',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ProfileScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => NotificationsScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SettingsScreen()),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.storefront_outlined,
                label: 'Market Place',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BtcProductShopScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(
                icon: Icons.auto_awesome_outlined,
                label: 'Promotional Packages',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MarketplaceScreen2(),
                    ),
                  );
                },
              ),
              const Spacer(),
              _buildDrawerItem(
                icon: Icons.logout,
                label: 'Logout',
                color: Colors.red.shade100,
                onTap: () {
                  Navigator.pop(context); // close the drawer
                  showDialog(
                    context: this.context, // explicitly use the StatefulWidget's context
                    builder: (dialogCtx) => AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      title: const Text(
                        'Logout',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black,
                        ),
                      ),
                      content: const Text(
                        'Are you sure you want to logout?',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogCtx),
                          child: const Text(
                            'No',
                            style: TextStyle(
                              color: Color(0xff8F7CFF),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8F7CFF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.pop(dialogCtx);
                            print("🔄 Starting logout process...");
                            try {
                              // ✅ Clear 30-day session
                              await AuthService.logout();
                              print("✅ Session cleared - navigating to login");
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                this.context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            } catch (e) {
                              print("❌ Error during logout: $e");
                              if (!mounted) return;
                              ScaffoldMessenger.of(this.context).showSnackBar(
                                const SnackBar(
                                  content: Text('Logout completed with error'),
                                  backgroundColor: Colors.orange,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                              Navigator.pushAndRemoveUntil(
                                this.context,
                                MaterialPageRoute(builder: (_) => const LoginScreen()),
                                (route) => false,
                              );
                            }
                          },
                          child: const Text(
                            'Yes',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color, size: 24),
      title: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      horizontalTitleGap: 8,
    );
  }

  @override
  Widget build(BuildContext context) {
    const int adInterval = 5;
    final int totalItems = posts.length + (posts.length ~/ adInterval);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              color: const Color(0xff8F7CFF),
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 12,
                left: 16,
                right: 16,
                bottom: 12,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openDrawerMenu,
                    child: const Icon(
                      Icons.menu,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Commity',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _userName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => NotificationsScreen()),
                    ),
                    child: Stack(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoadingPosts
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: Color(0xff8F7CFF)),
                          SizedBox(height: 16),
                          Text(
                            'Loading posts...',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refreshFeed,
                      child: CustomScrollView(
                        slivers: [
                          SliverToBoxAdapter(
                            child: SizedBox(
                              height: 100, // Increased from 90 to prevent overflow
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                itemCount: stories.length,
                                itemBuilder: (context, index) =>
                                    StoryItem(story: stories[index]),
                              ),
                            ),
                          ),
                          const SliverToBoxAdapter(
                            child: Divider(
                              color: Color(0xFFE6E6F0),
                              thickness: 0.5,
                              height: 0.5,
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                if ((index + 1) % (adInterval + 1) == 0) {
                                  return _buildAdCard();
                                }
                                final postIndex =
                                    index - (index ~/ (adInterval + 1));
                                if (postIndex >= posts.length) return null;
                                final post = posts[postIndex];
                                return PostItem(
                                  key: ValueKey(post.id),
                                  post: post,
                                  onLike: () => _handleLike(post.id),
                                  onComment: () => _handleComment(post),
                                  onShare: () => _handleShare(post),
                                  onDelete: () => _deletePost(post.id),
                                  onReaction: () => _handleReaction(post.id),
                                  onRepost: () => _handleRepost(post.id),
                                );
                              },
                              childCount: totalItems,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateBottomSheet,
        backgroundColor: const Color(0xff8F7CFF),
        elevation: 4,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildAdCard() => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F2FF),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Sponsored",
              style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "https://picsum.photos/800/400?random=999",
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Grow your business with us ",
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ],
        ),
      );

  // NOTIFICATION INTEGRATION START
  Future<void> _addNotification({
    required String type,
    required String title,
  }) async {
    try {
      final database = Database();
      
      final response = await database.getData({
        'action': 'add_notification',
        'notification_type': type,
        'notification_title': title,
        'sender_id': _vendorId, // ✅ Dynamic vendor ID
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID
      });
      
      print("Notification added: $response");
    } catch (e) {
      print("Notification error: $e");
    }
  }
  // NOTIFICATION INTEGRATION END

  Future<void> _handleLike(String postId) async {
    // Find the post and get current state
    final postIndex = posts.indexWhere((post) => post.id == postId);
    if (postIndex == -1) return;

    final post = posts[postIndex];
    final wasLiked = post.isLiked;

    // Optimistic UI update
    setState(() {
      if (wasLiked) {
        posts[postIndex] = Post(
          id: post.id,
          username: post.username,
          userImage: post.userImage,
          isVerified: post.isVerified,
          postImages: post.postImages,
          likes: post.likes - 1,
          caption: post.caption,
          timeAgo: post.timeAgo,
          comments: post.comments,
          shares: post.shares,
          isLiked: false,
          isBookmarked: post.isBookmarked,
          commentsList: post.commentsList,
        );
      } else {
        posts[postIndex] = Post(
          id: post.id,
          username: post.username,
          userImage: post.userImage,
          isVerified: post.isVerified,
          postImages: post.postImages,
          likes: post.likes + 1,
          caption: post.caption,
          timeAgo: post.timeAgo,
          comments: post.comments,
          shares: post.shares,
          isLiked: true,
          isBookmarked: post.isBookmarked,
          commentsList: post.commentsList,
        );
      }
    });

    try {
      final database = Database();

      final response = await database.getData({
        'action': 'post_engagement',
        'post_id': postId,
        'engagement_type': 'like',
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID
      });

      if (response['success'] != true && response['status'] != 200) {
        // Revert optimistic update on failure
        setState(() {
          posts[postIndex] = post;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        _addNotification(
          type: "like",
          title: "$_userName liked ${post.username}'s post",
        );
      }
    } catch (e) {
      print('Error toggling like: $e');
      // Revert optimistic update on error
      setState(() {
        posts[postIndex] = post;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error updating like'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleReaction(String postId) async {
    // Show emoji picker bottom sheet
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF6B7280),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Add Reaction',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildEmojiButton('❤️', postId),
                  _buildEmojiButton('😂', postId),
                  _buildEmojiButton('😮', postId),
                  _buildEmojiButton('😢', postId),
                  _buildEmojiButton('😡', postId),
                  _buildEmojiButton('👏', postId),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiButton(String emoji, String postId) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        
        try {
          final database = Database();
          
          final response = await database.getData({
            'action': 'post_engagement',
            'post_id': postId,
            'engagement_type': 'reaction',
            'reaction_value': emoji,
                        'vendor_id': _vendorId, // ✅ Dynamic vendor ID
          });
          
          if (response['success'] == true || response['status'] == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Reaction added: $emoji'),
                duration: const Duration(seconds: 1),
                backgroundColor: const Color(0xFF7C83FD),
              ),
            );
            final postIndex = posts.indexWhere((p) => p.id == postId);
            if (postIndex != -1) {
              final post = posts[postIndex];
              _addNotification(
                type: "reaction",
                title: "$_userName reacted to ${post.username}'s post",
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Failed to add reaction'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 2),
              ),
            );
          }
        } catch (e) {
          print('Error adding reaction: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error adding reaction'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  Future<void> _handleRepost(String postId) async {
    try {
      final database = Database();
      
      final response = await database.getData({
        'action': 'post_engagement',
        'post_id': postId,
        'engagement_type': 'repost',
                    'vendor_id': _vendorId, // ✅ Dynamic vendor ID
      });
      
      if (response['success'] == true || response['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post reposted!'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF7C83FD),
          ),
        );
        final postIndex = posts.indexWhere((p) => p.id == postId);
        if (postIndex != -1) {
          final post = posts[postIndex];
          _addNotification(
            type: "repost",
            title: "$_userName reposted ${post.username}'s post",
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to repost'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error reposting: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error reposting'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleComment(Post post) => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => StatefulBuilder(
          builder: (context, setModalState) =>
              _buildCommentSheet(post, setModalState),
        ),
      );

  Widget _buildCommentSheet(Post post, StateSetter setModalState) =>
      Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE6E6F0), width: 0.5),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40),
                  const Text(
                    'Comments',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: post.commentsList.isEmpty
                  ? const Center(
                      child: Text(
                        'No comments yet.\nBe the first to comment!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF6B7280), fontSize: 14),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: post.commentsList.length,
                      itemBuilder: (context, index) {
                        final comment = post.commentsList[index];
                        return _buildCommentItem(
                          username: comment.username,
                          comment: comment.text,
                          timeAgo: comment.timeAgo,
                          likes: comment.likes,
                        );
                      },
                    ),
            ),
            Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Color(0xFFE6E6F0), width: 0.5),
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const CircleAvatar(
                        radius: 18,
                        backgroundImage: NetworkImage(
                          'https://picsum.photos/100/100?random=99',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          style: const TextStyle(color: Colors.black),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle:
                                TextStyle(color: Color(0xFF6B7280)),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final text = _commentController.text.trim();
                          if (text.isEmpty) return;
                          
                          final postIndex = posts.indexWhere(
                            (p) => p.id == post.id,
                          );
                          if (postIndex == -1) return;
                          
                          // Optimistic UI update
                          final newComment = Comment(
                            username: 'current_user',
                            userImage:
                                'https://picsum.photos/100/100?random=99',
                            text: text,
                            timeAgo: 'Just now',
                            likes: 0,
                          );
                          
                          setState(() {
                            posts[postIndex].addComment(newComment);
                          });
                          _commentController.clear();
                          setModalState(() {});
                          
                          try {
                            final database = Database();
                            
                            final response = await database.getData({
                              'action': 'add_comment',
                              'post_id': post.id,
                              'message': text,
                                          'vendor_id': _vendorId, // ✅ Dynamic vendor ID
                            });
                            
                            if (response['success'] != true && response['status'] != 200) {
                              // Revert optimistic update on failure
                              setState(() {
                                posts[postIndex].commentsList.remove(newComment);
                                posts[postIndex] = Post(
                                  id: posts[postIndex].id,
                                  username: posts[postIndex].username,
                                  userImage: posts[postIndex].userImage,
                                  isVerified: posts[postIndex].isVerified,
                                  postImages: posts[postIndex].postImages,
                                  likes: posts[postIndex].likes,
                                  caption: posts[postIndex].caption,
                                  timeAgo: posts[postIndex].timeAgo,
                                  comments: posts[postIndex].comments - 1,
                                  shares: posts[postIndex].shares,
                                  isLiked: posts[postIndex].isLiked,
                                  isBookmarked: posts[postIndex].isBookmarked,
                                  commentsList: posts[postIndex].commentsList,
                                );
                              });
                              setModalState(() {});
                              
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Failed to post comment'),
                                  backgroundColor: Colors.red,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            } else {
                              _addNotification(
                                type: "comment",
                                title: "$_userName commented on ${post.username}'s post",
                              );
                            }
                          } catch (e) {
                            print('Error adding comment: $e');
                            // Revert optimistic update on error
                            setState(() {
                              posts[postIndex].commentsList.remove(newComment);
                              posts[postIndex] = Post(
                                id: posts[postIndex].id,
                                username: posts[postIndex].username,
                                userImage: posts[postIndex].userImage,
                                isVerified: posts[postIndex].isVerified,
                                postImages: posts[postIndex].postImages,
                                likes: posts[postIndex].likes,
                                caption: posts[postIndex].caption,
                                timeAgo: posts[postIndex].timeAgo,
                                comments: posts[postIndex].comments - 1,
                                shares: posts[postIndex].shares,
                                isLiked: posts[postIndex].isLiked,
                                isBookmarked: posts[postIndex].isBookmarked,
                                commentsList: posts[postIndex].commentsList,
                              );
                            });
                            setModalState(() {});
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error posting comment'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: const Text("Post"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _buildCommentItem({
    required String username,
    required String comment,
    required String timeAgo,
    required int likes,
  }) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(
                'https://picsum.photos/100/100?random=${username.hashCode}',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: username,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const TextSpan(text: ' '),
                        TextSpan(
                          text: comment,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(timeAgo,
                          style: const TextStyle(
                              color: Color(0xFF6B7280), fontSize: 12)),
                      const SizedBox(width: 16),
                      Text('$likes likes',
                          style: const TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 16),
                      const Text('Reply',
                          style: TextStyle(
                              color: Color(0xFF6B7280),
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.favorite_border,
                  size: 14, color: Color(0xFF6B7280)),
              onPressed: () {},
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );

  void _handleShare(Post post) => showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Share',
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ),
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  
                  try {
                    final database = Database();
                    
                    final response = await database.getData({
                      'action': 'post_engagement',
                      'post_id': post.id,
                      'engagement_type': 'share',
                                  'vendor_id': _vendorId, // ✅ Dynamic vendor ID
                    });
                    
                    if (response['success'] == true || response['status'] == 200) {
                      // Update share count optimistically
                      final postIndex = posts.indexWhere((p) => p.id == post.id);
                      if (postIndex != -1) {
                        setState(() {
                          posts[postIndex] = Post(
                            id: posts[postIndex].id,
                            username: posts[postIndex].username,
                            userImage: posts[postIndex].userImage,
                            isVerified: posts[postIndex].isVerified,
                            postImages: posts[postIndex].postImages,
                            likes: posts[postIndex].likes,
                            caption: posts[postIndex].caption,
                            timeAgo: posts[postIndex].timeAgo,
                            comments: posts[postIndex].comments,
                            shares: posts[postIndex].shares + 1,
                            isLiked: posts[postIndex].isLiked,
                            isBookmarked: posts[postIndex].isBookmarked,
                            commentsList: posts[postIndex].commentsList,
                          );
                        });
                      }
                      _addNotification(
                        type: "share",
                        title: "$_userName shared ${post.username}'s post",
                      );
                    }
                  } catch (e) {
                    print('Error sharing post: $e');
                  }
                  
                  final text =
                      '${post.username}: ${post.caption}\n${post.postImages.isNotEmpty ? post.postImages[0] : ''}';
                  await Share.share(text);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF25D366),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.chat,
                            color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 16),
                      const Text('Share on WhatsApp',
                          style:
                              TextStyle(color: Colors.black, fontSize: 15)),
                    ],
                  ),
                ),
              ),
              _buildShareOption(Icons.send_outlined, 'Send in Direct'),
              _buildShareOption(Icons.link, 'Copy link'),
              _buildShareOption(Icons.share_outlined, 'Share to...'),
              _buildShareOption(Icons.bookmark_border, 'Add to favorites'),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );

  Widget _buildShareOption(IconData icon, String label) => InkWell(
        onTap: () {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label clicked'),
              duration: const Duration(seconds: 1),
              backgroundColor: const Color(0xFF7C83FD),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 16),
              Text(label,
                  style:
                      const TextStyle(color: Colors.black, fontSize: 15)),
            ],
          ),
        ),
      );
}