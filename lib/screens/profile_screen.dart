import 'dart:async';
import 'dart:io';
import 'package:commity_app1/model/post_model.dart';
import 'package:commity_app1/screens/setting_screen.dart';
import 'package:commity_app1/theme.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';

const _kPrimary = Color(0xFF7C83FD);
const _kBorder = AppTheme.border;
const _kMuted = AppTheme.muted;
const _kGrad = [Color(0xFF7C83FD), Color(0xFF9B8FFF)];

List<Post> _userPhotoPosts = [];

final List<String> _userReels = [];

List<Map<String, dynamic>> _followers = [];

List<Map<String, dynamic>> _following = [];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  // ── API URL (no longer needed, using Database class) ──
  // final String _profileApiUrl =
  //     'http://192.168.40.76/SetupBackendCCBUL/SetupBackendCCBUL/android/community/get_vendor_details_API.php';

  late TabController _tabCtrl;
  final TextEditingController _commentCtrl = TextEditingController();

  // ✅ ALL DATA FROM API
  String _name = '';
  String _location = '';
  String _profileImage = 'https://i.pravatar.cc/150?img=12'; // Default
  String _bio1 = '• Hare krishna';
  String _bio2 = '• Karm||Dharm||moksha';
  bool _isLoadingProfile = true;
  String _errorMessage = '';

  // ✅ API-based followers/following counts
  int _followersCount = 0;
  int _followingCount = 0;

  List<Post> get _allPosts {
    final list = [..._userPhotoPosts];
    for (final p in globalPosts) {
      if (!list.any((x) => x.id == p.id)) list.insert(0, p);
    }
    return list;
  }

  int _toInt(dynamic value) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _extractImages(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) {
      return [value];
    }
    return [];
  }

  String _resolveCaption(Map<String, dynamic> post) {
    final caption =
        post['label'] ?? post['content'] ?? post['caption'] ?? post['tags'];
    return caption?.toString().trim() ?? '';
  }

  String _resolveTimeAgo(dynamic value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) {
      return 'Just now';
    }

    final diff = DateTime.now().difference(parsed);
    if (diff.inDays > 0) {
      return '${diff.inDays}d';
    }
    if (diff.inHours > 0) {
      return '${diff.inHours}h';
    }
    if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m';
    }
    return 'Just now';
  }

  Post _postFromApi(
    Map<String, dynamic> post, {
    required String fallbackName,
    required String fallbackImage,
  }) {
    final images = _extractImages(post['images']);
    final imageList = images.isNotEmpty ? images : [fallbackImage];

    return Post(
      id: post['id']?.toString() ?? post['post_id']?.toString() ?? '',
      username: post['vendor_name']?.toString() ?? fallbackName,
      userImage: post['profile_pic']?.toString() ?? fallbackImage,
      postImages: imageList,
      likes: _toInt(post['total_likes'] ?? post['likes']),
      caption: _resolveCaption(post),
      timeAgo: _resolveTimeAgo(post['created_date']),
      comments: _toInt(post['total_comments'] ?? post['comments']),
      shares: _toInt(post['shares']),
      commentsList: [],
    );
  }

  Map<String, dynamic> _personFromApi(Map<String, dynamic> person) {
    return {
      'name': person['name']?.toString() ?? '',
      'image': person['image']?.toString() ?? '',
      'mutual': person['mutual']?.toString() ?? '',
      'isFollowing':
          person['isFollowing'] == true || person['isFollowing'] == 1,
    };
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _initAndFetchProfile();
  }

  String _vendorId = '0';

  Future<void> _initAndFetchProfile() async {
    _vendorId = await AuthService.getVendorIdString();
    _fetchProfile();
  }

  // ✅ UPDATED API CALL using Database class
  Future<void> _fetchProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = '';
    });

    try {
      final database = Database();

      // Call Database.getData with profile action and vendor_id
      final response = await database.getData({
        'action': 'profile',
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID
      });

      if (!mounted) return;

      print("✅ Profile API Response: $response");

      if (response['success'] == true || response['status'] == 200) {
        final profileData = response['data'];

        if (profileData != null) {
          final profile = profileData['profile'];
          final totalPosts = profileData['total_posts'] ?? 0;
          final followers = profileData['followers'] ?? 0;
          final following = profileData['following'] ?? 0;
          final postsData = profileData['posts'];
          final followersData = profileData['followers_list'];
          final followingData = profileData['following_list'];

          final apiPosts = <Post>[];
          final apiReels = <String>[];
          if (postsData is List) {
            for (final item in postsData) {
              if (item is! Map<String, dynamic>) {
                continue;
              }
              final post = _postFromApi(
                item,
                fallbackName: profile['name']?.toString() ?? 'User',
                fallbackImage: profile['profile_pic']?.toString() ?? '',
              );
              apiPosts.add(post);

              final contentType =
                  item['content_type']?.toString().toLowerCase() ?? '';
              if (contentType.contains('reel') ||
                  contentType.contains('video')) {
                if (post.postImages.isNotEmpty) {
                  apiReels.add(post.postImages.first);
                }
              }
            }
          }

          final apiFollowers = <Map<String, dynamic>>[];
          if (followersData is List) {
            for (final item in followersData) {
              if (item is Map<String, dynamic>) {
                apiFollowers.add(_personFromApi(item));
              }
            }
          }

          final apiFollowing = <Map<String, dynamic>>[];
          if (followingData is List) {
            for (final item in followingData) {
              if (item is Map<String, dynamic>) {
                apiFollowing.add(_personFromApi(item));
              }
            }
          }

          setState(() {
            // Profile details
            _name = profile['name']?.toString() ?? 'User';
            _location =
                profile['city']?.toString() ??
                profile['address']?.toString() ??
                '';

            // Profile image
            if (profile['profile_pic'] != null &&
                profile['profile_pic'].toString().isNotEmpty &&
                profile['profile_pic'].toString() != 'null') {
              _profileImage = profile['profile_pic'].toString();
            }

            // Bio (combine bio fields)
            String bio = profile['bio']?.toString() ?? '';
            if (bio.isEmpty) {
              bio = '• Hare krishna\n• Karm||Dharm||moksha';
            }
            _bio1 = bio;
            _bio2 = ''; // Can be extended for additional bio fields

            // ✅ Set followers/following counts from API
            _followersCount = followers is int
                ? followers
                : int.tryParse(followers.toString()) ?? 0;
            _followingCount = following is int
                ? following
                : int.tryParse(following.toString()) ?? 0;

            _userPhotoPosts = apiPosts;
            _userReels
              ..clear()
              ..addAll(apiReels);
            _followers = apiFollowers;
            _following = apiFollowing;

            _isLoadingProfile = false;
          });

          print("✅ Profile Loaded Successfully!");
          print("Name: $_name");
          print("Location: $_location");
          print("Profile Image: $_profileImage");
          print("Bio: $_bio1");
          print("Total Posts: $totalPosts");
          print("Followers: $followers");
          print("Following: $following");
        } else {
          setState(() {
            _errorMessage = 'No profile data received';
            _isLoadingProfile = false;
          });
          print("❌ No profile data in response");
        }
      } else {
        setState(() {
          _errorMessage =
              response['message']?.toString() ??
              response['error']?.toString() ??
              'Failed to load profile';
          _isLoadingProfile = false;
        });
        print("❌ API Error: $_errorMessage");
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoadingProfile = false;
      });
      print("❌ Error: $e");
    }
  }

  // ✅ UPDATE PROFILE using Database class
  Future<void> _updateProfile({String? name, String? bio, String? city}) async {
    try {
      final database = Database();

      // Create request body for update_profile
      final requestBody = {
        'action': 'update_profile',
        'vendor_id': _vendorId, // ✅ Dynamic vendor ID
        'name': name ?? _name,
        'bio': bio ?? _bio1,
        'city': city ?? _location,
      };

      print(
        "🔍 Update Profile Request: $requestBody",
      ); // Debug what we're sending

      // Call Database.getData with update_profile action and vendor_id
      final response = await database.getData(requestBody);

      if (!mounted) return;

      print("✅ Update Profile Response: $response");

      if (response['success'] == true || response['status'] == 200) {
        // Refresh profile data after update
        _fetchProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message']?.toString() ?? 'Failed to update profile',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _confirmDelete(Post post) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Photo?',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete this photo?\nThis action cannot be undone.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
        ),
        actionsPadding: EdgeInsets.zero,
        actions: [
          Divider(height: 1, color: Colors.grey.shade200),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ),
              ),
              Container(width: 1, height: 48, color: Colors.grey.shade200),
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() {
                      _userPhotoPosts.removeWhere((p) => p.id == post.id);
                      globalPosts.removeWhere((p) => p.id == post.id);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post deleted'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Delete',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text(
                  'Delete Photo',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(post);
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                leading: const Icon(Icons.edit_outlined, color: Colors.black),
                title: const Text(
                  'Edit Caption',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                onTap: () => Navigator.pop(context),
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                leading: const Icon(Icons.close, color: Colors.black54),
                title: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ LOADING STATE
    if (_isLoadingProfile) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              CircularProgressIndicator(color: _kPrimary),
              SizedBox(height: 16),
              Text(
                'Loading profile...',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ ERROR STATE
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _errorMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _fetchProfile,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // SUCCESS STATE - PROFILE DISPLAY
    return NestedScrollView(
      headerSliverBuilder: (ctx, _) => [
        SliverToBoxAdapter(child: _buildHeader()),
        SliverToBoxAdapter(child: _buildBioButtons()),
        SliverPersistentHeader(
          pinned: true,
          delegate: _TabDelegate(
            TabBar(
              controller: _tabCtrl,
              indicatorColor: _kPrimary,
              indicatorWeight: 2,
              labelColor: _kPrimary,
              unselectedLabelColor: Colors.grey,
              dividerColor: _kBorder,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'Photos'),
                Tab(text: 'Reels'),
              ],
            ),
          ),
        ),
      ],
      body: TabBarView(
        controller: _tabCtrl,
        children: [_buildPhotosTab(), _buildReelsTab()],
      ),
    );
  }

  Widget _buildHeader() {
    final posts = _allPosts;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 195,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _kGrad,
            ),
          ),
          padding: const EdgeInsets.only(top: 44, left: 12, right: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SettingsScreen()),
                    ),
                    child: const Icon(Icons.settings, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (_location.isNotEmpty)
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.white70,
                            size: 13,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            _location,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _stat('${posts.length}', 'Posts', null),
                        const SizedBox(width: 20),
                        _stat('$_followersCount', 'Followers', _openFollowers),
                        const SizedBox(width: 20),
                        _stat('$_followingCount', 'Following', _openFollowing),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: -44,
          left: 16,
          child: GestureDetector(
            onTap: _viewProfilePhoto,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundImage: NetworkImage(_profileImage),
                backgroundColor: Colors.grey.shade200,
                // ✅ Error handling for image
                onBackgroundImageError: (_, __) {
                  print("❌ Failed to load profile image: $_profileImage");
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _stat(String count, String label, VoidCallback? tap) {
    final w = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 11),
        ),
      ],
    );
    return tap != null ? GestureDetector(onTap: tap, child: w) : w;
  }

  Widget _buildBioButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_bio1.isNotEmpty)
            Text(
              _bio1,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          if (_bio2.isNotEmpty)
            Text(
              _bio2,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _openEditProfile,
                  child: Container(
                    height: 34,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(colors: _kGrad),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_outlined,
                  size: 18,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhotosTab() {
    final posts = _allPosts;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Photos',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                GestureDetector(
                  onTap: () => _showAllPhotos(
                    posts.map((p) => p.postImages.first).toList(),
                  ),
                  child: const Text(
                    'Show All',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: posts.length,
              itemBuilder: (ctx, i) {
                final p = posts[i];
                return GestureDetector(
                  onTap: () => _viewPhoto(p.postImages.first),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          p.postImages.first,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200),
                        ),
                        Positioned(
                          bottom: 4,
                          left: 4,
                          child: Row(
                            children: [
                              Icon(
                                Icons.favorite,
                                size: 11,
                                color: p.isLiked ? _kPrimary : Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${p.likes}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 5),
                              const Icon(
                                Icons.chat_bubble,
                                size: 10,
                                color: Colors.white70,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${p.comments}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          Divider(height: 1, color: _kBorder),
          ...posts.map((p) => _buildPostCard(p)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildReelsTab() {
    final reels = [
      ..._userReels,
      ...globalPosts
          .where((p) => p.postImages.isNotEmpty)
          .map((p) => p.postImages.first),
    ];
    if (reels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_circle_outline,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            const Text(
              'No reels yet',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.6,
      ),
      itemCount: reels.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => _viewPhoto(reels[i]),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                reels[i],
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey.shade200),
              ),
            ),
            const Center(
              child: Icon(
                Icons.play_circle_filled,
                color: Colors.white70,
                size: 28,
              ),
            ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Row(
                children: [
                  const Icon(Icons.play_arrow, color: Colors.white, size: 12),
                  Text(
                    '${(i + 1) * 1200}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
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

  Widget _buildPostCard(Post post) {
    return StatefulBuilder(
      builder: (ctx, setCard) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(post.userImage),
                      backgroundColor: Colors.grey.shade200,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.username,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            post.timeAgo,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showPostOptions(post),
                      child: const Icon(Icons.more_vert, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              post.postImages.length == 1
                  ? GestureDetector(
                      onDoubleTap: () => setCard(() {
                        if (!post.isLiked) {
                          post.isLiked = true;
                          post.likes++;
                          setState(() {});
                        }
                      }),
                      child: Image.network(
                        post.postImages.first,
                        width: double.infinity,
                        height: 280,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(height: 280, color: Colors.grey.shade200),
                      ),
                    )
                  : SizedBox(
                      height: 280,
                      child: PageView.builder(
                        itemCount: post.postImages.length,
                        itemBuilder: (_, i) => Image.network(
                          post.postImages[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade200),
                        ),
                      ),
                    ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setCard(() {
                        post.isLiked = !post.isLiked;
                        post.likes += post.isLiked ? 1 : -1;
                        setState(() {});
                      }),
                      child: Row(
                        children: [
                          Icon(
                            post.isLiked
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: post.isLiked ? _kPrimary : Colors.black54,
                            size: 24,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.likes}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _openComments(post, setCard),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.black54,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.comments}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _openShareSheet(post),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.send_outlined,
                            color: Colors.black54,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${post.shares}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () =>
                          setCard(() => post.isBookmarked = !post.isBookmarked),
                      child: Icon(
                        post.isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: post.isBookmarked ? _kPrimary : Colors.black54,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                  '${post.likes} likes',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (post.caption.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${post.username} ',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        TextSpan(
                          text: post.caption,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Divider(height: 1, color: _kBorder),
            ],
          ),
        );
      },
    );
  }

  void _openComments(Post post, StateSetter parentSet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: _kBorder, width: 0.5),
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
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: post.commentsList.isEmpty
                      ? const Center(
                          child: Text(
                            'No comments yet.\nBe the first! 💬',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: _kMuted, fontSize: 14),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: post.commentsList.length,
                          itemBuilder: (_, i) {
                            final c = post.commentsList[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 17,
                                    backgroundImage: NetworkImage(c.userImage),
                                    backgroundColor: Colors.grey.shade200,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(
                                            children: [
                                              TextSpan(
                                                text: '${c.username} ',
                                                style: const TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              TextSpan(
                                                text: c.text,
                                                style: const TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 5),
                                        Row(
                                          children: [
                                            Text(
                                              c.timeAgo,
                                              style: const TextStyle(
                                                color: _kMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              '${c.likes} likes',
                                              style: const TextStyle(
                                                color: _kMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Reply',
                                              style: TextStyle(
                                                color: _kMuted,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => setModal(() => c.likes++),
                                    child: const Icon(
                                      Icons.favorite_border,
                                      size: 14,
                                      color: _kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Container(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(ctx).viewInsets.bottom,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(color: _kBorder, width: 0.5),
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundImage: NetworkImage(_profileImage),
                            backgroundColor: Colors.grey.shade200,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _commentCtrl,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 14,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Add a comment...',
                                hintStyle: TextStyle(color: _kMuted),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final txt = _commentCtrl.text.trim();
                              if (txt.isEmpty) return;
                              post.addComment(
                                Comment(
                                  username: _name,
                                  userImage: _profileImage,
                                  text: txt,
                                  timeAgo: 'Just now',
                                  likes: 0,
                                ),
                              );
                              _commentCtrl.clear();
                              setModal(() {});
                              parentSet(() {});
                              setState(() {});
                            },
                            child: const Text(
                              'Post',
                              style: TextStyle(
                                color: _kPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openShareSheet(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Share',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            InkWell(
              onTap: () async {
                Navigator.pop(context);
                await Share.share(
                  '${post.username}: ${post.caption}\n${post.postImages.isNotEmpty ? post.postImages[0] : ''}',
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF25D366),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.chat,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'Share on WhatsApp',
                      style: TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            _shareRow(Icons.send_outlined, 'Send in Direct'),
            _shareRow(Icons.link, 'Copy link'),
            _shareRow(Icons.share_outlined, 'Share to...'),
            _shareRow(Icons.bookmark_border, 'Add to favorites'),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _shareRow(IconData icon, String label) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$label clicked'),
            duration: const Duration(seconds: 1),
            backgroundColor: _kPrimary,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: Colors.black),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(color: Colors.black, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  void _openFollowers() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FriendsScreen(
        username: _name,
        initialTab: 0,
        followers: _followers,
        following: _following,
      ),
    ),
  );
  void _openFollowing() => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => FriendsScreen(
        username: _name,
        initialTab: 1,
        followers: _followers,
        following: _following,
      ),
    ),
  );
  void _viewProfilePhoto() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: _profileImage)),
  );
  void _viewPhoto(String url) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: url)),
  );
  void _showAllPhotos(List<String> photos) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => _AllPhotosScreen(photos: photos)),
  );

  void _openEditProfile() async {
    final r = await Navigator.push<Map<String, String>>(
      context,
      MaterialPageRoute(
        builder: (_) => _EditProfileScreen(
          name: _name,
          location: _location,
          bio1: _bio1,
          bio2: _bio2,
          profileImage: _profileImage,
        ),
      ),
    );
    if (r != null) {
      // Check if API update is requested
      if (r['shouldUpdate'] == 'true') {
        // Call the API to update profile
        await _updateProfile(
          name: r['name'],
          bio: r['bio1'],
          city: r['location'],
        );
      } else {
        // Just update local state (for cancel or non-API updates)
        setState(() {
          _name = r['name'] ?? _name;
          _location = r['location'] ?? _location;
          _bio1 = r['bio1'] ?? _bio1;
          _bio2 = r['bio2'] ?? _bio2;
          _profileImage = r['profileImage'] ?? _profileImage;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }
} // Added missing closing brace for _ProfileScreenState class

// ─── FRIENDS SCREEN ───────────────────────────────────────────────────────────
class FriendsScreen extends StatefulWidget {
  final String username;
  final int initialTab;
  final List<Map<String, dynamic>> followers;
  final List<Map<String, dynamic>> following;
  const FriendsScreen({
    Key? key,
    required this.username,
    required this.initialTab,
    required this.followers,
    required this.following,
  }) : super(key: key);
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab,
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Friends',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 17,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabCtrl,
              indicatorColor: _kPrimary,
              labelColor: Colors.black,
              unselectedLabelColor: Colors.grey,
              dividerColor: _kBorder,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: [
                Tab(text: 'Following (${widget.following.length})'),
                Tab(text: 'Followers (${widget.followers.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(widget.following, isFollowingTab: true),
                _buildList(widget.followers, isFollowingTab: false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    List<Map<String, dynamic>> list, {
    required bool isFollowingTab,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final f = list[i];
        return StatefulBuilder(
          builder: (ctx, setRow) {
            final isOn = f['isFollowing'] as bool? ?? false;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundImage: NetworkImage(f['image'] as String),
                    backgroundColor: Colors.grey.shade200,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f['name'] as String,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          f['mutual'] as String,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setRow(() => f['isFollowing'] = !isOn),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: !isOn
                            ? const LinearGradient(colors: _kGrad)
                            : null,
                        color: isOn ? Colors.grey.shade200 : null,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isFollowingTab
                            ? (isOn ? 'Follow' : 'Following')
                            : (isOn ? 'Follower' : 'Follow'),
                        style: TextStyle(
                          color: isOn ? Colors.black54 : Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// ─── PHOTO VIEWER ─────────────────────────────────────────────────────────────
class _PhotoViewer extends StatelessWidget {
  final String imageUrl;
  const _PhotoViewer({required this.imageUrl});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    body: Center(
      child: InteractiveViewer(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.broken_image, color: Colors.white54, size: 80),
        ),
      ),
    ),
  );
}

// ─── ALL PHOTOS SCREEN ────────────────────────────────────────────────────────
class _AllPhotosScreen extends StatelessWidget {
  final List<String> photos;
  const _AllPhotosScreen({required this.photos});
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    appBar: AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.black),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        'All Photos',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    ),
    body: GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: photos.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => Navigator.push(
          ctx,
          MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: photos[i])),
        ),
        child: Image.network(
          photos[i],
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
        ),
      ),
    ),
  );
}

// ─── EDIT PROFILE SCREEN ──────────────────────────────────────────────────────
class _EditProfileScreen extends StatefulWidget {
  final String name, location, bio1, bio2, profileImage;
  const _EditProfileScreen({
    required this.name,
    required this.location,
    required this.bio1,
    required this.bio2,
    required this.profileImage,
  });
  @override
  State<_EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<_EditProfileScreen> {
  late TextEditingController _nameCtrl, _locCtrl, _bio1Ctrl, _bio2Ctrl;
  String _networkImg = '';
  File? _localImg;
  String? _focusedField;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.name);
    _locCtrl = TextEditingController(text: widget.location);
    _bio1Ctrl = TextEditingController(text: widget.bio1);
    _bio2Ctrl = TextEditingController(text: widget.bio2);
    _networkImg = widget.profileImage;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _locCtrl.dispose();
    _bio1Ctrl.dispose();
    _bio2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _localImg = File(picked.path));
  }

  ImageProvider get _currentImage => _localImg != null
      ? FileImage(_localImg!)
      : NetworkImage(_networkImg) as ImageProvider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.black, fontSize: 15),
          ),
        ),
        leadingWidth: 80,
        title: const Text(
          'Edit profile',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // Return data with API update flag
              Navigator.pop(context, {
                'name': _nameCtrl.text.trim(),
                'location': _locCtrl.text.trim(),
                'bio1': _bio1Ctrl.text.trim(),
                'bio2': _bio2Ctrl.text.trim(),
                'profileImage': _localImg?.path ?? _networkImg,
                'shouldUpdate': 'true', // Flag to trigger API call
              });
            },
            child: const Text(
              'Done',
              style: TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _kPrimary, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 46,
                            backgroundImage: _currentImage,
                            backgroundColor: Colors.grey.shade200,
                          ),
                        ),
                        Positioned(
                          bottom: 2,
                          right: 2,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: _kPrimary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap to change photo',
                    style: TextStyle(
                      color: _kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          _field('Name', _nameCtrl, 'name'),
          _field('Location', _locCtrl, 'location'),
          _field('Bio line 1', _bio1Ctrl, 'bio1'),
          _field('Bio line 2', _bio2Ctrl, 'bio2'),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, String fieldKey) {
    final isFocused = _focusedField == fieldKey;
    return Focus(
      onFocusChange: (hasFocus) =>
          setState(() => _focusedField = hasFocus ? fieldKey : null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isFocused ? _kPrimary : Colors.grey.shade200,
              width: isFocused ? 2.0 : 0.8,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 2),
              child: Text(
                label,
                style: TextStyle(
                  color: isFocused ? _kPrimary : Colors.grey.shade500,
                  fontSize: 12,
                  fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.black, fontSize: 15),
              cursorColor: _kPrimary,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.only(bottom: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── SLIVER TAB DELEGATE ──────────────────────────────────────────────────────
class _TabDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  _TabDelegate(this.tabBar);
  @override
  double get minExtent => tabBar.preferredSize.height;
  @override
  double get maxExtent => tabBar.preferredSize.height;
  @override
  Widget build(BuildContext ctx, double offset, bool _) =>
      Container(color: Colors.white, child: tabBar);
  @override
  bool shouldRebuild(covariant _TabDelegate old) => false;
}
