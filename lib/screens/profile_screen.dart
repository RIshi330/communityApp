// import 'dart:async';
// import 'dart:io';
// import 'package:commity_app1/model/post_model.dart';
// import 'package:commity_app1/screens/setting_screen.dart';
// import 'package:commity_app1/theme.dart';
// import 'package:commity_app1/Database/Database.dart';
// import 'package:commity_app1/services/auth_service.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:share_plus/share_plus.dart';
//
// const _kPrimary = Color(0xFF7C83FD);
// const _kBorder = AppTheme.border;
// const _kMuted = AppTheme.muted;
// const _kGrad = [Color(0xFF7C83FD), Color(0xFF9B8FFF)];
//
// List<Post> _userPhotoPosts = [];
//
// final List<String> _userReels = [];
//
// List<Map<String, dynamic>> _followers = [];
//
// List<Map<String, dynamic>> _following = [];
//
// class ProfileScreen extends StatefulWidget {
//   const ProfileScreen({Key? key}) : super(key: key);
//   @override
//   State<ProfileScreen> createState() => _ProfileScreenState();
// }
//
// class _ProfileScreenState extends State<ProfileScreen>
//     with SingleTickerProviderStateMixin {
//   // ── API URL (no longer needed, using Database class) ──
//   // final String _profileApiUrl =
//   //     'http://192.168.40.76/SetupBackendCCBUL/SetupBackendCCBUL/android/community/get_vendor_details_API.php';
//
//   late TabController _tabCtrl;
//   final TextEditingController _commentCtrl = TextEditingController();
//
//   // ✅ ALL DATA FROM API
//   String _name = '';
//   String _location = '';
//   String _profileImage = 'https://i.pravatar.cc/150?img=12'; // Default
//   String _bio1 = '• Hare krishna';
//   String _bio2 = '• Karm||Dharm||moksha';
//   bool _isLoadingProfile = true;
//   String _errorMessage = '';
//
//   // ✅ API-based followers/following counts
//   int _followersCount = 0;
//   int _followingCount = 0;
//
//   List<Post> get _allPosts {
//     final list = [..._userPhotoPosts];
//     for (final p in globalPosts) {
//       if (!list.any((x) => x.id == p.id)) list.insert(0, p);
//     }
//     return list;
//   }
//
//   int _toInt(dynamic value) {
//     if (value is int) {
//       return value;
//     }
//     return int.tryParse(value?.toString() ?? '') ?? 0;
//   }
//
//   List<String> _extractImages(dynamic value) {
//     if (value is List) {
//       return value
//           .map((item) => item?.toString() ?? '')
//           .where((item) => item.isNotEmpty)
//           .toList();
//     }
//     if (value is String && value.isNotEmpty) {
//       return [value];
//     }
//     return [];
//   }
//
//   String _resolveCaption(Map<String, dynamic> post) {
//     final caption =
//         post['label'] ?? post['content'] ?? post['caption'] ?? post['tags'];
//     return caption?.toString().trim() ?? '';
//   }
//
//   String _resolveTimeAgo(dynamic value) {
//     final parsed = value is String ? DateTime.tryParse(value) : null;
//     if (parsed == null) {
//       return 'Just now';
//     }
//
//     final diff = DateTime.now().difference(parsed);
//     if (diff.inDays > 0) {
//       return '${diff.inDays}d';
//     }
//     if (diff.inHours > 0) {
//       return '${diff.inHours}h';
//     }
//     if (diff.inMinutes > 0) {
//       return '${diff.inMinutes}m';
//     }
//     return 'Just now';
//   }
//
//   Post _postFromApi(
//     Map<String, dynamic> post, {
//     required String fallbackName,
//     required String fallbackImage,
//   }) {
//     final images = _extractImages(post['images']);
//     final imageList = images.isNotEmpty ? images : [fallbackImage];
//
//     return Post(
//       id: post['id']?.toString() ?? post['post_id']?.toString() ?? '',
//       username: post['vendor_name']?.toString() ?? fallbackName,
//       userImage: post['profile_pic']?.toString() ?? fallbackImage,
//       postImages: imageList,
//       likes: _toInt(post['total_likes'] ?? post['likes']),
//       caption: _resolveCaption(post),
//       timeAgo: _resolveTimeAgo(post['created_date']),
//       comments: _toInt(post['total_comments'] ?? post['comments']),
//       shares: _toInt(post['shares']),
//       commentsList: [],
//     );
//   }
//
//   Map<String, dynamic> _personFromApi(Map<String, dynamic> person) {
//     return {
//       'name': person['name']?.toString() ?? '',
//       'image': person['image']?.toString() ?? '',
//       'mutual': person['mutual']?.toString() ?? '',
//       'isFollowing':
//           person['isFollowing'] == true || person['isFollowing'] == 1,
//     };
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     _tabCtrl = TabController(length: 2, vsync: this);
//     _initAndFetchProfile();
//   }
//
//   String _vendorId = '0';
//
//   Future<void> _initAndFetchProfile() async {
//     _vendorId = await AuthService.getVendorIdString();
//     _fetchProfile();
//   }
//
//   // ✅ UPDATED API CALL using Database class
//   Future<void> _fetchProfile() async {
//     setState(() {
//       _isLoadingProfile = true;
//       _errorMessage = '';
//     });
//
//     try {
//       final database = Database();
//
//       // Call Database.getData with profile action and vendor_id
//       final response = await database.getData({
//         'action': 'profile',
//         'vendor_id': _vendorId, // ✅ Dynamic vendor ID
//       });
//
//       if (!mounted) return;
//
//       print("✅ Profile API Response: $response");
//
//       if (response['success'] == true || response['status'] == 200) {
//         final profileData = response['data'];
//
//         if (profileData != null) {
//           final profile = profileData['profile'];
//           final totalPosts = profileData['total_posts'] ?? 0;
//           final followers = profileData['followers'] ?? 0;
//           final following = profileData['following'] ?? 0;
//           final postsData = profileData['posts'];
//           final followersData = profileData['followers_list'];
//           final followingData = profileData['following_list'];
//
//           final apiPosts = <Post>[];
//           final apiReels = <String>[];
//           if (postsData is List) {
//             for (final item in postsData) {
//               if (item is! Map<String, dynamic>) {
//                 continue;
//               }
//               final post = _postFromApi(
//                 item,
//                 fallbackName: profile['name']?.toString() ?? 'User',
//                 fallbackImage: profile['profile_pic']?.toString() ?? '',
//               );
//               apiPosts.add(post);
//
//               final contentType =
//                   item['content_type']?.toString().toLowerCase() ?? '';
//               if (contentType.contains('reel') ||
//                   contentType.contains('video')) {
//                 if (post.postImages.isNotEmpty) {
//                   apiReels.add(post.postImages.first);
//                 }
//               }
//             }
//           }
//
//           final apiFollowers = <Map<String, dynamic>>[];
//           if (followersData is List) {
//             for (final item in followersData) {
//               if (item is Map<String, dynamic>) {
//                 apiFollowers.add(_personFromApi(item));
//               }
//             }
//           }
//
//           final apiFollowing = <Map<String, dynamic>>[];
//           if (followingData is List) {
//             for (final item in followingData) {
//               if (item is Map<String, dynamic>) {
//                 apiFollowing.add(_personFromApi(item));
//               }
//             }
//           }
//
//           setState(() {
//             // Profile details
//             _name = profile['name']?.toString() ?? 'User';
//             _location =
//                 profile['city']?.toString() ??
//                 profile['address']?.toString() ??
//                 '';
//
//             // Profile image
//             if (profile['profile_pic'] != null &&
//                 profile['profile_pic'].toString().isNotEmpty &&
//                 profile['profile_pic'].toString() != 'null') {
//               _profileImage = profile['profile_pic'].toString();
//             }
//
//             // Bio (combine bio fields)
//             String bio = profile['bio']?.toString() ?? '';
//             if (bio.isEmpty) {
//               bio = '• Hare krishna\n• Karm||Dharm||moksha';
//             }
//             _bio1 = bio;
//             _bio2 = ''; // Can be extended for additional bio fields
//
//             // ✅ Set followers/following counts from API
//             _followersCount = followers is int
//                 ? followers
//                 : int.tryParse(followers.toString()) ?? 0;
//             _followingCount = following is int
//                 ? following
//                 : int.tryParse(following.toString()) ?? 0;
//
//             _userPhotoPosts = apiPosts;
//             _userReels
//               ..clear()
//               ..addAll(apiReels);
//             _followers = apiFollowers;
//             _following = apiFollowing;
//
//             _isLoadingProfile = false;
//           });
//
//           print("✅ Profile Loaded Successfully!");
//           print("Name: $_name");
//           print("Location: $_location");
//           print("Profile Image: $_profileImage");
//           print("Bio: $_bio1");
//           print("Total Posts: $totalPosts");
//           print("Followers: $followers");
//           print("Following: $following");
//         } else {
//           setState(() {
//             _errorMessage = 'No profile data received';
//             _isLoadingProfile = false;
//           });
//           print("❌ No profile data in response");
//         }
//       } else {
//         setState(() {
//           _errorMessage =
//               response['message']?.toString() ??
//               response['error']?.toString() ??
//               'Failed to load profile';
//           _isLoadingProfile = false;
//         });
//         print("❌ API Error: $_errorMessage");
//       }
//     } catch (e) {
//       if (!mounted) return;
//       setState(() {
//         _errorMessage = 'Error: ${e.toString()}';
//         _isLoadingProfile = false;
//       });
//       print("❌ Error: $e");
//     }
//   }
//
//   // ✅ UPDATE PROFILE using Database class
//   Future<void> _updateProfile({String? name, String? bio, String? city}) async {
//     try {
//       final database = Database();
//
//       // Create request body for update_profile
//       final requestBody = {
//         'action': 'update_profile',
//         'vendor_id': _vendorId, // ✅ Dynamic vendor ID
//         'name': name ?? _name,
//         'bio': bio ?? _bio1,
//         'city': city ?? _location,
//       };
//
//       print(
//         "🔍 Update Profile Request: $requestBody",
//       ); // Debug what we're sending
//
//       // Call Database.getData with update_profile action and vendor_id
//       final response = await database.getData(requestBody);
//
//       if (!mounted) return;
//
//       print("✅ Update Profile Response: $response");
//
//       if (response['success'] == true || response['status'] == 200) {
//         // Refresh profile data after update
//         _fetchProfile();
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Profile updated successfully!'),
//             backgroundColor: Colors.green,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(
//               response['message']?.toString() ?? 'Failed to update profile',
//             ),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
//
//   void _confirmDelete(Post post) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (ctx) => AlertDialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text(
//           'Delete Photo?',
//           textAlign: TextAlign.center,
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 17,
//           ),
//         ),
//         content: const Text(
//           'Are you sure you want to delete this photo?\nThis action cannot be undone.',
//           textAlign: TextAlign.center,
//           style: TextStyle(color: Colors.black54, fontSize: 14, height: 1.5),
//         ),
//         actionsPadding: EdgeInsets.zero,
//         actions: [
//           Divider(height: 1, color: Colors.grey.shade200),
//           Row(
//             children: [
//               Expanded(
//                 child: TextButton(
//                   onPressed: () => Navigator.pop(ctx),
//                   child: const Text(
//                     'Cancel',
//                     style: TextStyle(color: Colors.black54, fontSize: 16),
//                   ),
//                 ),
//               ),
//               Container(width: 1, height: 48, color: Colors.grey.shade200),
//               Expanded(
//                 child: TextButton(
//                   onPressed: () {
//                     Navigator.pop(ctx);
//                     setState(() {
//                       _userPhotoPosts.removeWhere((p) => p.id == post.id);
//                       globalPosts.removeWhere((p) => p.id == post.id);
//                     });
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Post deleted'),
//                         backgroundColor: Colors.red,
//                         duration: Duration(seconds: 2),
//                       ),
//                     );
//                   },
//                   child: const Text(
//                     'Delete',
//                     style: TextStyle(
//                       color: Colors.red,
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showPostOptions(Post post) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SafeArea(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 margin: const EdgeInsets.symmetric(vertical: 10),
//                 width: 36,
//                 height: 4,
//                 decoration: BoxDecoration(
//                   color: Colors.grey.shade300,
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               ListTile(
//                 leading: const Icon(Icons.delete_outline, color: Colors.red),
//                 title: const Text(
//                   'Delete Photo',
//                   style: TextStyle(
//                     color: Colors.red,
//                     fontWeight: FontWeight.w600,
//                     fontSize: 15,
//                   ),
//                 ),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _confirmDelete(post);
//                 },
//               ),
//               Divider(height: 1, color: Colors.grey.shade200),
//               ListTile(
//                 leading: const Icon(Icons.edit_outlined, color: Colors.black),
//                 title: const Text(
//                   'Edit Caption',
//                   style: TextStyle(color: Colors.black, fontSize: 15),
//                 ),
//                 onTap: () => Navigator.pop(context),
//               ),
//               Divider(height: 1, color: Colors.grey.shade200),
//               ListTile(
//                 leading: const Icon(Icons.close, color: Colors.black54),
//                 title: const Text(
//                   'Cancel',
//                   style: TextStyle(color: Colors.black54, fontSize: 15),
//                 ),
//                 onTap: () => Navigator.pop(context),
//               ),
//               const SizedBox(height: 8),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // ✅ LOADING STATE
//     if (_isLoadingProfile) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: const [
//               CircularProgressIndicator(color: _kPrimary),
//               SizedBox(height: 16),
//               Text(
//                 'Loading profile...',
//                 style: TextStyle(color: Colors.grey, fontSize: 14),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     // ✅ ERROR STATE
//     if (_errorMessage.isNotEmpty) {
//       return Scaffold(
//         backgroundColor: Colors.white,
//         body: Center(
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               const Icon(Icons.error_outline, color: Colors.red, size: 60),
//               const SizedBox(height: 16),
//               Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 32),
//                 child: Text(
//                   _errorMessage,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.black87, fontSize: 14),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               ElevatedButton.icon(
//                 onPressed: _fetchProfile,
//                 icon: const Icon(Icons.refresh),
//                 label: const Text('Retry'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: _kPrimary,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 24,
//                     vertical: 12,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       );
//     }
//
//     // SUCCESS STATE - PROFILE DISPLAY
//     return NestedScrollView(
//       headerSliverBuilder: (ctx, _) => [
//         SliverToBoxAdapter(child: _buildHeader()),
//         SliverToBoxAdapter(child: _buildBioButtons()),
//         SliverPersistentHeader(
//           pinned: true,
//           delegate: _TabDelegate(
//             TabBar(
//               controller: _tabCtrl,
//               indicatorColor: _kPrimary,
//               indicatorWeight: 2,
//               labelColor: _kPrimary,
//               unselectedLabelColor: Colors.grey,
//               dividerColor: _kBorder,
//               labelStyle: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//               ),
//               tabs: const [
//                 Tab(text: 'Photos'),
//                 Tab(text: 'Reels'),
//               ],
//             ),
//           ),
//         ),
//       ],
//       body: TabBarView(
//         controller: _tabCtrl,
//         children: [_buildPhotosTab(), _buildReelsTab()],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     final posts = _allPosts;
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         Container(
//           height: 195,
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: _kGrad,
//             ),
//           ),
//           padding: const EdgeInsets.only(top: 44, left: 12, right: 12),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 children: [
//                   const Spacer(),
//                   GestureDetector(
//                     onTap: () => Navigator.push(
//                       context,
//                       MaterialPageRoute(builder: (_) => SettingsScreen()),
//                     ),
//                     child: const Icon(Icons.settings, color: Colors.black),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 12),
//               Padding(
//                 padding: const EdgeInsets.only(left: 110),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       _name,
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 20,
//                       ),
//                     ),
//                     const SizedBox(height: 2),
//                     if (_location.isNotEmpty)
//                       Row(
//                         children: [
//                           const Icon(
//                             Icons.location_on,
//                             color: Colors.white70,
//                             size: 13,
//                           ),
//                           const SizedBox(width: 2),
//                           Text(
//                             _location,
//                             style: const TextStyle(
//                               color: Colors.white70,
//                               fontSize: 12,
//                             ),
//                           ),
//                         ],
//                       ),
//                     const SizedBox(height: 8),
//                     Row(
//                       children: [
//                         _stat('${posts.length}', 'Posts', null),
//                         const SizedBox(width: 20),
//                         _stat('$_followersCount', 'Followers', _openFollowers),
//                         const SizedBox(width: 20),
//                         _stat('$_followingCount', 'Following', _openFollowing),
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//         Positioned(
//           bottom: -44,
//           left: 16,
//           child: GestureDetector(
//             onTap: _viewProfilePhoto,
//             child: Container(
//               decoration: BoxDecoration(
//                 shape: BoxShape.circle,
//                 border: Border.all(color: Colors.white, width: 3),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.15),
//                     blurRadius: 8,
//                   ),
//                 ],
//               ),
//               child: CircleAvatar(
//                 radius: 46,
//                 backgroundImage: NetworkImage(_profileImage),
//                 backgroundColor: Colors.grey.shade200,
//                 // ✅ Error handling for image
//                 onBackgroundImageError: (_, __) {
//                   print("❌ Failed to load profile image: $_profileImage");
//                 },
//               ),
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Widget _stat(String count, String label, VoidCallback? tap) {
//     final w = Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           count,
//           style: const TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         Text(
//           label,
//           style: const TextStyle(color: Colors.white70, fontSize: 11),
//         ),
//       ],
//     );
//     return tap != null ? GestureDetector(onTap: tap, child: w) : w;
//   }
//
//   Widget _buildBioButtons() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(16, 52, 16, 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           if (_bio1.isNotEmpty)
//             Text(
//               _bio1,
//               style: const TextStyle(color: Colors.black87, fontSize: 13),
//             ),
//           if (_bio2.isNotEmpty)
//             Text(
//               _bio2,
//               style: const TextStyle(color: Colors.black87, fontSize: 13),
//             ),
//           const SizedBox(height: 10),
//           Row(
//             children: [
//               Expanded(
//                 child: GestureDetector(
//                   onTap: _openEditProfile,
//                   child: Container(
//                     height: 34,
//                     decoration: BoxDecoration(
//                       borderRadius: BorderRadius.circular(20),
//                       gradient: const LinearGradient(colors: _kGrad),
//                     ),
//                     alignment: Alignment.center,
//                     child: const Text(
//                       'Edit Profile',
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.w600,
//                         fontSize: 13,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//               const SizedBox(width: 8),
//               Container(
//                 height: 34,
//                 width: 34,
//                 decoration: BoxDecoration(
//                   borderRadius: BorderRadius.circular(20),
//                   border: Border.all(color: Colors.grey.shade300),
//                 ),
//                 child: const Icon(
//                   Icons.person_add_alt_1_outlined,
//                   size: 18,
//                   color: Colors.black,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildPhotosTab() {
//     final posts = _allPosts;
//     return SingleChildScrollView(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 const Text(
//                   'Photos',
//                   style: TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 16,
//                   ),
//                 ),
//                 GestureDetector(
//                   onTap: () => _showAllPhotos(
//                     posts.map((p) => p.postImages.first).toList(),
//                   ),
//                   child: const Text(
//                     'Show All',
//                     style: TextStyle(
//                       color: _kPrimary,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 8),
//             child: GridView.builder(
//               physics: const NeverScrollableScrollPhysics(),
//               shrinkWrap: true,
//               gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                 crossAxisCount: 3,
//                 crossAxisSpacing: 4,
//                 mainAxisSpacing: 4,
//               ),
//               itemCount: posts.length,
//               itemBuilder: (ctx, i) {
//                 final p = posts[i];
//                 return GestureDetector(
//                   onTap: () => _viewPhoto(p.postImages.first),
//                   child: ClipRRect(
//                     borderRadius: BorderRadius.circular(6),
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         Image.network(
//                           p.postImages.first,
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) =>
//                               Container(color: Colors.grey.shade200),
//                         ),
//                         Positioned(
//                           bottom: 4,
//                           left: 4,
//                           child: Row(
//                             children: [
//                               Icon(
//                                 Icons.favorite,
//                                 size: 11,
//                                 color: p.isLiked ? _kPrimary : Colors.white70,
//                               ),
//                               const SizedBox(width: 2),
//                               Text(
//                                 '${p.likes}',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w600,
//                                   shadows: [
//                                     Shadow(
//                                       color: Colors.black54,
//                                       blurRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                               const SizedBox(width: 5),
//                               const Icon(
//                                 Icons.chat_bubble,
//                                 size: 10,
//                                 color: Colors.white70,
//                               ),
//                               const SizedBox(width: 2),
//                               Text(
//                                 '${p.comments}',
//                                 style: const TextStyle(
//                                   color: Colors.white,
//                                   fontSize: 9,
//                                   fontWeight: FontWeight.w600,
//                                   shadows: [
//                                     Shadow(
//                                       color: Colors.black54,
//                                       blurRadius: 2,
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//           const SizedBox(height: 4),
//           Divider(height: 1, color: _kBorder),
//           ...posts.map((p) => _buildPostCard(p)),
//           const SizedBox(height: 24),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildReelsTab() {
//     final reels = [
//       ..._userReels,
//       ...globalPosts
//           .where((p) => p.postImages.isNotEmpty)
//           .map((p) => p.postImages.first),
//     ];
//     if (reels.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.play_circle_outline,
//               size: 60,
//               color: Colors.grey.shade300,
//             ),
//             const SizedBox(height: 12),
//             const Text(
//               'No reels yet',
//               style: TextStyle(color: Colors.grey, fontSize: 14),
//             ),
//           ],
//         ),
//       );
//     }
//     return GridView.builder(
//       padding: const EdgeInsets.all(8),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 4,
//         mainAxisSpacing: 4,
//         childAspectRatio: 0.6,
//       ),
//       itemCount: reels.length,
//       itemBuilder: (ctx, i) => GestureDetector(
//         onTap: () => _viewPhoto(reels[i]),
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             ClipRRect(
//               borderRadius: BorderRadius.circular(6),
//               child: Image.network(
//                 reels[i],
//                 fit: BoxFit.cover,
//                 errorBuilder: (_, __, ___) =>
//                     Container(color: Colors.grey.shade200),
//               ),
//             ),
//             const Center(
//               child: Icon(
//                 Icons.play_circle_filled,
//                 color: Colors.white70,
//                 size: 28,
//               ),
//             ),
//             Positioned(
//               bottom: 6,
//               left: 6,
//               child: Row(
//                 children: [
//                   const Icon(Icons.play_arrow, color: Colors.white, size: 12),
//                   Text(
//                     '${(i + 1) * 1200}',
//                     style: const TextStyle(
//                       color: Colors.white,
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPostCard(Post post) {
//     return StatefulBuilder(
//       builder: (ctx, setCard) {
//         return Container(
//           margin: const EdgeInsets.symmetric(vertical: 6),
//           color: Colors.white,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 12,
//                   vertical: 10,
//                 ),
//                 child: Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 18,
//                       backgroundImage: NetworkImage(post.userImage),
//                       backgroundColor: Colors.grey.shade200,
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             post.username,
//                             style: const TextStyle(
//                               color: Colors.black,
//                               fontWeight: FontWeight.bold,
//                               fontSize: 13,
//                             ),
//                           ),
//                           Text(
//                             post.timeAgo,
//                             style: const TextStyle(
//                               color: Colors.grey,
//                               fontSize: 11,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     GestureDetector(
//                       onTap: () => _showPostOptions(post),
//                       child: const Icon(Icons.more_vert, color: Colors.black54),
//                     ),
//                   ],
//                 ),
//               ),
//               post.postImages.length == 1
//                   ? GestureDetector(
//                       onDoubleTap: () => setCard(() {
//                         if (!post.isLiked) {
//                           post.isLiked = true;
//                           post.likes++;
//                           setState(() {});
//                         }
//                       }),
//                       child: Image.network(
//                         post.postImages.first,
//                         width: double.infinity,
//                         height: 280,
//                         fit: BoxFit.cover,
//                         errorBuilder: (_, __, ___) =>
//                             Container(height: 280, color: Colors.grey.shade200),
//                       ),
//                     )
//                   : SizedBox(
//                       height: 280,
//                       child: PageView.builder(
//                         itemCount: post.postImages.length,
//                         itemBuilder: (_, i) => Image.network(
//                           post.postImages[i],
//                           fit: BoxFit.cover,
//                           errorBuilder: (_, __, ___) =>
//                               Container(color: Colors.grey.shade200),
//                         ),
//                       ),
//                     ),
//               Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 10,
//                   vertical: 8,
//                 ),
//                 child: Row(
//                   children: [
//                     GestureDetector(
//                       onTap: () => setCard(() {
//                         post.isLiked = !post.isLiked;
//                         post.likes += post.isLiked ? 1 : -1;
//                         setState(() {});
//                       }),
//                       child: Row(
//                         children: [
//                           Icon(
//                             post.isLiked
//                                 ? Icons.favorite
//                                 : Icons.favorite_border,
//                             color: post.isLiked ? _kPrimary : Colors.black54,
//                             size: 24,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${post.likes}',
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     GestureDetector(
//                       onTap: () => _openComments(post, setCard),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.chat_bubble_outline,
//                             color: Colors.black54,
//                             size: 22,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${post.comments}',
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     GestureDetector(
//                       onTap: () => _openShareSheet(post),
//                       child: Row(
//                         children: [
//                           const Icon(
//                             Icons.send_outlined,
//                             color: Colors.black54,
//                             size: 22,
//                           ),
//                           const SizedBox(width: 4),
//                           Text(
//                             '${post.shares}',
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Colors.black54,
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     const Spacer(),
//                     GestureDetector(
//                       onTap: () =>
//                           setCard(() => post.isBookmarked = !post.isBookmarked),
//                       child: Icon(
//                         post.isBookmarked
//                             ? Icons.bookmark
//                             : Icons.bookmark_border,
//                         color: post.isBookmarked ? _kPrimary : Colors.black54,
//                         size: 22,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.only(left: 12, bottom: 4),
//                 child: Text(
//                   '${post.likes} likes',
//                   style: const TextStyle(
//                     color: Colors.black,
//                     fontWeight: FontWeight.bold,
//                     fontSize: 12,
//                   ),
//                 ),
//               ),
//               if (post.caption.isNotEmpty)
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
//                   child: RichText(
//                     text: TextSpan(
//                       children: [
//                         TextSpan(
//                           text: '${post.username} ',
//                           style: const TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 13,
//                           ),
//                         ),
//                         TextSpan(
//                           text: post.caption,
//                           style: const TextStyle(
//                             color: Colors.black87,
//                             fontSize: 13,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               Divider(height: 1, color: _kBorder),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   void _openComments(Post post, StateSetter parentSet) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (ctx) => StatefulBuilder(
//         builder: (ctx, setModal) {
//           return Container(
//             height: MediaQuery.of(context).size.height * 0.75,
//             decoration: const BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//             ),
//             child: Column(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(14),
//                   decoration: BoxDecoration(
//                     border: Border(
//                       bottom: BorderSide(color: _kBorder, width: 0.5),
//                     ),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const SizedBox(width: 40),
//                       const Text(
//                         'Comments',
//                         style: TextStyle(
//                           color: Colors.black,
//                           fontSize: 16,
//                           fontWeight: FontWeight.w600,
//                         ),
//                       ),
//                       IconButton(
//                         icon: const Icon(Icons.close, color: Colors.black),
//                         onPressed: () => Navigator.pop(ctx),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: post.commentsList.isEmpty
//                       ? const Center(
//                           child: Text(
//                             'No comments yet.\nBe the first! 💬',
//                             textAlign: TextAlign.center,
//                             style: TextStyle(color: _kMuted, fontSize: 14),
//                           ),
//                         )
//                       : ListView.builder(
//                           padding: const EdgeInsets.symmetric(vertical: 8),
//                           itemCount: post.commentsList.length,
//                           itemBuilder: (_, i) {
//                             final c = post.commentsList[i];
//                             return Padding(
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 14,
//                                 vertical: 10,
//                               ),
//                               child: Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   CircleAvatar(
//                                     radius: 17,
//                                     backgroundImage: NetworkImage(c.userImage),
//                                     backgroundColor: Colors.grey.shade200,
//                                   ),
//                                   const SizedBox(width: 10),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment:
//                                           CrossAxisAlignment.start,
//                                       children: [
//                                         RichText(
//                                           text: TextSpan(
//                                             children: [
//                                               TextSpan(
//                                                 text: '${c.username} ',
//                                                 style: const TextStyle(
//                                                   color: Colors.black,
//                                                   fontWeight: FontWeight.w600,
//                                                   fontSize: 13,
//                                                 ),
//                                               ),
//                                               TextSpan(
//                                                 text: c.text,
//                                                 style: const TextStyle(
//                                                   color: Colors.black87,
//                                                   fontSize: 13,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                         ),
//                                         const SizedBox(height: 5),
//                                         Row(
//                                           children: [
//                                             Text(
//                                               c.timeAgo,
//                                               style: const TextStyle(
//                                                 color: _kMuted,
//                                                 fontSize: 11,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 12),
//                                             Text(
//                                               '${c.likes} likes',
//                                               style: const TextStyle(
//                                                 color: _kMuted,
//                                                 fontSize: 11,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                             const SizedBox(width: 12),
//                                             const Text(
//                                               'Reply',
//                                               style: TextStyle(
//                                                 color: _kMuted,
//                                                 fontSize: 11,
//                                                 fontWeight: FontWeight.w600,
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       ],
//                                     ),
//                                   ),
//                                   GestureDetector(
//                                     onTap: () => setModal(() => c.likes++),
//                                     child: const Icon(
//                                       Icons.favorite_border,
//                                       size: 14,
//                                       color: _kMuted,
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             );
//                           },
//                         ),
//                 ),
//                 Container(
//                   padding: EdgeInsets.only(
//                     bottom: MediaQuery.of(ctx).viewInsets.bottom,
//                   ),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     border: Border(
//                       top: BorderSide(color: _kBorder, width: 0.5),
//                     ),
//                   ),
//                   child: SafeArea(
//                     child: Padding(
//                       padding: const EdgeInsets.all(10),
//                       child: Row(
//                         children: [
//                           CircleAvatar(
//                             radius: 17,
//                             backgroundImage: NetworkImage(_profileImage),
//                             backgroundColor: Colors.grey.shade200,
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: TextField(
//                               controller: _commentCtrl,
//                               style: const TextStyle(
//                                 color: Colors.black,
//                                 fontSize: 14,
//                               ),
//                               decoration: const InputDecoration(
//                                 hintText: 'Add a comment...',
//                                 hintStyle: TextStyle(color: _kMuted),
//                                 border: InputBorder.none,
//                               ),
//                             ),
//                           ),
//                           TextButton(
//                             onPressed: () {
//                               final txt = _commentCtrl.text.trim();
//                               if (txt.isEmpty) return;
//                               post.addComment(
//                                 Comment(
//                                   username: _name,
//                                   userImage: _profileImage,
//                                   text: txt,
//                                   timeAgo: 'Just now',
//                                   likes: 0,
//                                 ),
//                               );
//                               _commentCtrl.clear();
//                               setModal(() {});
//                               parentSet(() {});
//                               setState(() {});
//                             },
//                             child: const Text(
//                               'Post',
//                               style: TextStyle(
//                                 color: _kPrimary,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           );
//         },
//       ),
//     );
//   }
//
//   void _openShareSheet(Post post) {
//     showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (_) => Container(
//         decoration: const BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               margin: const EdgeInsets.symmetric(vertical: 8),
//               width: 36,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: Colors.grey.shade300,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const Padding(
//               padding: EdgeInsets.all(14),
//               child: Text(
//                 'Share',
//                 style: TextStyle(
//                   color: Colors.black,
//                   fontSize: 16,
//                   fontWeight: FontWeight.w600,
//                 ),
//               ),
//             ),
//             InkWell(
//               onTap: () async {
//                 Navigator.pop(context);
//                 await Share.share(
//                   '${post.username}: ${post.caption}\n${post.postImages.isNotEmpty ? post.postImages[0] : ''}',
//                 );
//               },
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(
//                   horizontal: 16,
//                   vertical: 14,
//                 ),
//                 child: Row(
//                   children: [
//                     Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: const Color(0xFF25D366),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: const Icon(
//                         Icons.chat,
//                         color: Colors.white,
//                         size: 22,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     const Text(
//                       'Share on WhatsApp',
//                       style: TextStyle(color: Colors.black, fontSize: 15),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             _shareRow(Icons.send_outlined, 'Send in Direct'),
//             _shareRow(Icons.link, 'Copy link'),
//             _shareRow(Icons.share_outlined, 'Share to...'),
//             _shareRow(Icons.bookmark_border, 'Add to favorites'),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _shareRow(IconData icon, String label) {
//     return InkWell(
//       onTap: () {
//         Navigator.pop(context);
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text('$label clicked'),
//             duration: const Duration(seconds: 1),
//             backgroundColor: _kPrimary,
//           ),
//         );
//       },
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         child: Row(
//           children: [
//             Icon(icon, color: Colors.black),
//             const SizedBox(width: 16),
//             Text(
//               label,
//               style: const TextStyle(color: Colors.black, fontSize: 15),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   void _openFollowers() => Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => FriendsScreen(
//         username: _name,
//         initialTab: 0,
//         followers: _followers,
//         following: _following,
//       ),
//     ),
//   );
//   void _openFollowing() => Navigator.push(
//     context,
//     MaterialPageRoute(
//       builder: (_) => FriendsScreen(
//         username: _name,
//         initialTab: 1,
//         followers: _followers,
//         following: _following,
//       ),
//     ),
//   );
//   void _viewProfilePhoto() => Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: _profileImage)),
//   );
//   void _viewPhoto(String url) => Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: url)),
//   );
//   void _showAllPhotos(List<String> photos) => Navigator.push(
//     context,
//     MaterialPageRoute(builder: (_) => _AllPhotosScreen(photos: photos)),
//   );
//
//   void _openEditProfile() async {
//     final r = await Navigator.push<Map<String, String>>(
//       context,
//       MaterialPageRoute(
//         builder: (_) => _EditProfileScreen(
//           name: _name,
//           location: _location,
//           bio1: _bio1,
//           bio2: _bio2,
//           profileImage: _profileImage,
//         ),
//       ),
//     );
//     if (r != null) {
//       // Check if API update is requested
//       if (r['shouldUpdate'] == 'true') {
//         // Call the API to update profile
//         await _updateProfile(
//           name: r['name'],
//           bio: r['bio1'],
//           city: r['location'],
//         );
//       } else {
//         // Just update local state (for cancel or non-API updates)
//         setState(() {
//           _name = r['name'] ?? _name;
//           _location = r['location'] ?? _location;
//           _bio1 = r['bio1'] ?? _bio1;
//           _bio2 = r['bio2'] ?? _bio2;
//           _profileImage = r['profileImage'] ?? _profileImage;
//         });
//       }
//     }
//   }
//
//   @override
//   void dispose() {
//     _tabCtrl.dispose();
//     _commentCtrl.dispose();
//     super.dispose();
//   }
// } // Added missing closing brace for _ProfileScreenState class
//
// // ─── FRIENDS SCREEN ───────────────────────────────────────────────────────────
// class FriendsScreen extends StatefulWidget {
//   final String username;
//   final int initialTab;
//   final List<Map<String, dynamic>> followers;
//   final List<Map<String, dynamic>> following;
//   const FriendsScreen({
//     Key? key,
//     required this.username,
//     required this.initialTab,
//     required this.followers,
//     required this.following,
//   }) : super(key: key);
//   @override
//   State<FriendsScreen> createState() => _FriendsScreenState();
// }
//
// class _FriendsScreenState extends State<FriendsScreen>
//     with SingleTickerProviderStateMixin {
//   late TabController _tabCtrl;
//   @override
//   void initState() {
//     super.initState();
//     _tabCtrl = TabController(
//       length: 2,
//       vsync: this,
//       initialIndex: widget.initialTab,
//     );
//   }
//
//   @override
//   void dispose() {
//     _tabCtrl.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF6F7FB),
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: Colors.black),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: const Text(
//           'Friends',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 17,
//           ),
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.notifications_outlined, color: Colors.black),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.add, color: Colors.black),
//             onPressed: () {},
//           ),
//           IconButton(
//             icon: const Icon(Icons.more_vert, color: Colors.black),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Container(
//             color: Colors.white,
//             child: TabBar(
//               controller: _tabCtrl,
//               indicatorColor: _kPrimary,
//               labelColor: Colors.black,
//               unselectedLabelColor: Colors.grey,
//               dividerColor: _kBorder,
//               labelStyle: const TextStyle(
//                 fontWeight: FontWeight.w600,
//                 fontSize: 13,
//               ),
//               tabs: [
//                 Tab(text: 'Following (${widget.following.length})'),
//                 Tab(text: 'Followers (${widget.followers.length})'),
//               ],
//             ),
//           ),
//           Expanded(
//             child: TabBarView(
//               controller: _tabCtrl,
//               children: [
//                 _buildList(widget.following, isFollowingTab: true),
//                 _buildList(widget.followers, isFollowingTab: false),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildList(
//     List<Map<String, dynamic>> list, {
//     required bool isFollowingTab,
//   }) {
//     return ListView.separated(
//       padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
//       itemCount: list.length,
//       separatorBuilder: (_, __) => const SizedBox(height: 8),
//       itemBuilder: (ctx, i) {
//         final f = list[i];
//         return StatefulBuilder(
//           builder: (ctx, setRow) {
//             final isOn = f['isFollowing'] as bool? ?? false;
//             return Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.04),
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   CircleAvatar(
//                     radius: 26,
//                     backgroundImage: NetworkImage(f['image'] as String),
//                     backgroundColor: Colors.grey.shade200,
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           f['name'] as String,
//                           style: const TextStyle(
//                             color: Colors.black,
//                             fontWeight: FontWeight.w600,
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 2),
//                         Text(
//                           f['mutual'] as String,
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 12,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   GestureDetector(
//                     onTap: () => setRow(() => f['isFollowing'] = !isOn),
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 18,
//                         vertical: 8,
//                       ),
//                       decoration: BoxDecoration(
//                         gradient: !isOn
//                             ? const LinearGradient(colors: _kGrad)
//                             : null,
//                         color: isOn ? Colors.grey.shade200 : null,
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         isFollowingTab
//                             ? (isOn ? 'Follow' : 'Following')
//                             : (isOn ? 'Follower' : 'Follow'),
//                         style: TextStyle(
//                           color: isOn ? Colors.black54 : Colors.white,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 13,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
// }
//
// // ─── PHOTO VIEWER ─────────────────────────────────────────────────────────────
// class _PhotoViewer extends StatelessWidget {
//   final String imageUrl;
//   const _PhotoViewer({required this.imageUrl});
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: Colors.black,
//     appBar: AppBar(
//       backgroundColor: Colors.black,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.white),
//         onPressed: () => Navigator.pop(context),
//       ),
//     ),
//     body: Center(
//       child: InteractiveViewer(
//         child: Image.network(
//           imageUrl,
//           fit: BoxFit.contain,
//           errorBuilder: (_, __, ___) =>
//               const Icon(Icons.broken_image, color: Colors.white54, size: 80),
//         ),
//       ),
//     ),
//   );
// }
//
// // ─── ALL PHOTOS SCREEN ────────────────────────────────────────────────────────
// class _AllPhotosScreen extends StatelessWidget {
//   final List<String> photos;
//   const _AllPhotosScreen({required this.photos});
//   @override
//   Widget build(BuildContext context) => Scaffold(
//     backgroundColor: Colors.white,
//     appBar: AppBar(
//       backgroundColor: Colors.white,
//       elevation: 0.5,
//       leading: IconButton(
//         icon: const Icon(Icons.arrow_back, color: Colors.black),
//         onPressed: () => Navigator.pop(context),
//       ),
//       title: const Text(
//         'All Photos',
//         style: TextStyle(
//           color: Colors.black,
//           fontWeight: FontWeight.bold,
//           fontSize: 16,
//         ),
//       ),
//     ),
//     body: GridView.builder(
//       padding: const EdgeInsets.all(4),
//       gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: 3,
//         crossAxisSpacing: 3,
//         mainAxisSpacing: 3,
//       ),
//       itemCount: photos.length,
//       itemBuilder: (ctx, i) => GestureDetector(
//         onTap: () => Navigator.push(
//           ctx,
//           MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: photos[i])),
//         ),
//         child: Image.network(
//           photos[i],
//           fit: BoxFit.cover,
//           errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
//         ),
//       ),
//     ),
//   );
// }
//
// // ─── EDIT PROFILE SCREEN ──────────────────────────────────────────────────────
// class _EditProfileScreen extends StatefulWidget {
//   final String name, location, bio1, bio2, profileImage;
//   const _EditProfileScreen({
//     required this.name,
//     required this.location,
//     required this.bio1,
//     required this.bio2,
//     required this.profileImage,
//   });
//   @override
//   State<_EditProfileScreen> createState() => _EditProfileScreenState();
// }
// class _EditProfileScreenState extends State<_EditProfileScreen> {
//   late TextEditingController _nameCtrl, _locCtrl, _bio1Ctrl, _bio2Ctrl;
//   String _networkImg = '';
//   File? _localImg;
//   String? _focusedField;
//   final _picker = ImagePicker();
//
//   @override
//   void initState() {
//     super.initState();
//     _nameCtrl = TextEditingController(text: widget.name);
//     _locCtrl = TextEditingController(text: widget.location);
//     _bio1Ctrl = TextEditingController(text: widget.bio1);
//     _bio2Ctrl = TextEditingController(text: widget.bio2);
//     _networkImg = widget.profileImage;
//   }
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _locCtrl.dispose();
//     _bio1Ctrl.dispose();
//     _bio2Ctrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickFromGallery() async {
//     final XFile? picked = await _picker.pickImage(
//       source: ImageSource.gallery,
//       imageQuality: 85,
//     );
//     if (picked != null) setState(() => _localImg = File(picked.path));
//   }
//
//   ImageProvider get _currentImage => _localImg != null
//       ? FileImage(_localImg!)
//       : NetworkImage(_networkImg) as ImageProvider;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0.5,
//         leading: TextButton(
//           onPressed: () => Navigator.pop(context),
//           child: const Text(
//             'Cancel',
//             style: TextStyle(color: Colors.black, fontSize: 15),
//           ),
//         ),
//         leadingWidth: 80,
//         title: const Text(
//           'Edit profile',
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 16,
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               // Return data with API update flag
//               Navigator.pop(context, {
//                 'name': _nameCtrl.text.trim(),
//                 'location': _locCtrl.text.trim(),
//                 'bio1': _bio1Ctrl.text.trim(),
//                 'bio2': _bio2Ctrl.text.trim(),
//                 'profileImage': _localImg?.path ?? _networkImg,
//                 'shouldUpdate': 'true', // Flag to trigger API call
//               });
//             },
//             child: const Text(
//               'Done',
//               style: TextStyle(
//                 color: _kPrimary,
//                 fontWeight: FontWeight.bold,
//                 fontSize: 15,
//               ),
//             ),
//           ),
//         ],
//       ),
//       body: ListView(
//         children: [
//           Center(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(vertical: 20),
//               child: Column(
//                 children: [
//                   GestureDetector(
//                     onTap: _pickFromGallery,
//                     child: Stack(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             border: Border.all(color: _kPrimary, width: 2),
//                           ),
//                           child: CircleAvatar(
//                             radius: 46,
//                             backgroundImage: _currentImage,
//                             backgroundColor: Colors.grey.shade200,
//                           ),
//                         ),
//                         Positioned(
//                           bottom: 2,
//                           right: 2,
//                           child: Container(
//                             width: 26,
//                             height: 26,
//                             decoration: BoxDecoration(
//                               color: _kPrimary,
//                               shape: BoxShape.circle,
//                               border: Border.all(color: Colors.white, width: 2),
//                             ),
//                             child: const Icon(
//                               Icons.camera_alt,
//                               color: Colors.white,
//                               size: 13,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                   const SizedBox(height: 6),
//                   const Text(
//                     'Tap to change photo',
//                     style: TextStyle(
//                       color: _kPrimary,
//                       fontSize: 13,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           _field('Name', _nameCtrl, 'name'),
//           _field('Location', _locCtrl, 'location'),
//           _field('Bio line 1', _bio1Ctrl, 'bio1'),
//           _field('Bio line 2', _bio2Ctrl, 'bio2'),
//           const SizedBox(height: 32),
//         ],
//       ),
//     );
//   }
//
//   Widget _field(String label, TextEditingController ctrl, String fieldKey) {
//     final isFocused = _focusedField == fieldKey;
//     return Focus(
//       onFocusChange: (hasFocus) =>
//           setState(() => _focusedField = hasFocus ? fieldKey : null),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
//         decoration: BoxDecoration(
//           border: Border(
//             bottom: BorderSide(
//               color: isFocused ? _kPrimary : Colors.grey.shade200,
//               width: isFocused ? 2.0 : 0.8,
//             ),
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: const EdgeInsets.only(top: 10, bottom: 2),
//               child: Text(
//                 label,
//                 style: TextStyle(
//                   color: isFocused ? _kPrimary : Colors.grey.shade500,
//                   fontSize: 12,
//                   fontWeight: isFocused ? FontWeight.w600 : FontWeight.normal,
//                 ),
//               ),
//             ),
//             TextField(
//               controller: ctrl,
//               style: const TextStyle(color: Colors.black, fontSize: 15),
//               cursorColor: _kPrimary,
//               decoration: const InputDecoration(
//                 border: InputBorder.none,
//                 isDense: true,
//                 contentPadding: EdgeInsets.only(bottom: 10),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ─── SLIVER TAB DELEGATE ──────────────────────────────────────────────────────
// class _TabDelegate extends SliverPersistentHeaderDelegate {
//   final TabBar tabBar;
//   _TabDelegate(this.tabBar);
//   @override
//   double get minExtent => tabBar.preferredSize.height;
//   @override
//   double get maxExtent => tabBar.preferredSize.height;
//   @override
//   Widget build(BuildContext ctx, double offset, bool _) =>
//       Container(color: Colors.white, child: tabBar);
//   @override
//   bool shouldRebuild(covariant _TabDelegate old) => false;
// }
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

// ── Constants ──────────────────────────────────────────────────────────────────
const _kPrimary = Color(0xFF7C83FD);
const _kSecondary = Color(0xFF9B8FFF);
const _kBorder = AppTheme.border;
const _kMuted = AppTheme.muted;
const _kGrad = [Color(0xFF7C83FD), Color(0xFF9B8FFF)];
const _kBg = Color(0xFFF8F8FC);

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final TextEditingController _commentCtrl = TextEditingController();

  // ── Profile data ─────────────────────────────────────────────────────────
  String _name = '';
  String _location = '';
  String _profileImage = 'https://i.pravatar.cc/150?img=12';
  String _bio1 = '• Hare krishna';
  String _bio2 = '• Karm||Dharm||moksha';
  bool _isLoadingProfile = true;
  String _errorMessage = '';
  int _followersCount = 0;
  int _followingCount = 0;

  // ── FIXED: Instance-level lists instead of module-level globals ───────────
  List<Post> _userPhotoPosts = [];
  List<String> _userReels = [];
  List<Map<String, dynamic>> _followers = [];
  List<Map<String, dynamic>> _following = [];

  String _vendorId = '0';

  List<Post> get _allPosts {
    final list = [..._userPhotoPosts];
    for (final p in globalPosts) {
      if (!list.any((x) => x.id == p.id)) list.insert(0, p);
    }
    return list;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  List<String> _extractImages(dynamic value) {
    if (value is List) {
      return value
          .map((item) => item?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }
    if (value is String && value.isNotEmpty) return [value];
    return [];
  }

  String _resolveCaption(Map<String, dynamic> post) {
    final caption =
        post['label'] ?? post['content'] ?? post['caption'] ?? post['tags'];
    return caption?.toString().trim() ?? '';
  }

  String _resolveTimeAgo(dynamic value) {
    final parsed = value is String ? DateTime.tryParse(value) : null;
    if (parsed == null) return 'Just now';
    final diff = DateTime.now().difference(parsed);
    if (diff.inDays > 0) return '${diff.inDays}d';
    if (diff.inHours > 0) return '${diff.inHours}h';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m';
    return 'Just now';
  }

  Post _postFromApi(Map<String, dynamic> post,
      {required String fallbackName, required String fallbackImage}) {
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

  Future<void> _initAndFetchProfile() async {
    _vendorId = await AuthService.getVendorIdString();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _errorMessage = '';
    });

    try {
      final database = Database();
      final response = await database.getData({
        'action': 'profile',
        'vendor_id': _vendorId,
      });

      if (!mounted) return;

      if (response['success'] == true || response['status'] == 200) {
        final profileData = response['data'];
        if (profileData != null) {
          final profile = profileData['profile'];
          final followers = profileData['followers'] ?? 0;
          final following = profileData['following'] ?? 0;
          final postsData = profileData['posts'];
          final followersData = profileData['followers_list'];
          final followingData = profileData['following_list'];

          final apiPosts = <Post>[];
          final apiReels = <String>[];

          if (postsData is List) {
            for (final item in postsData) {
              if (item is! Map<String, dynamic>) continue;
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
            _name = profile['name']?.toString() ?? 'User';
            _location = profile['city']?.toString() ??
                profile['address']?.toString() ??
                '';

            if (profile['profile_pic'] != null &&
                profile['profile_pic'].toString().isNotEmpty &&
                profile['profile_pic'].toString() != 'null') {
              _profileImage = profile['profile_pic'].toString();
            }

            String bio = profile['bio']?.toString() ?? '';
            if (bio.isEmpty) bio = '• Hare krishna\n• Karm||Dharm||moksha';
            _bio1 = bio;
            _bio2 = '';

            _followersCount = followers is int
                ? followers
                : int.tryParse(followers.toString()) ?? 0;
            _followingCount = following is int
                ? following
                : int.tryParse(following.toString()) ?? 0;

            _userPhotoPosts = apiPosts;
            _userReels = apiReels;
            _followers = apiFollowers;
            _following = apiFollowing;
            _isLoadingProfile = false;
          });
        } else {
          setState(() {
            _errorMessage = 'No profile data received';
            _isLoadingProfile = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response['message']?.toString() ??
              response['error']?.toString() ??
              'Failed to load profile';
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _updateProfile(
      {String? name, String? bio, String? city}) async {
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'update_profile',
        'vendor_id': _vendorId,
        'name': name ?? _name,
        'bio': bio ?? _bio1,
        'city': city ?? _location,
      });

      if (!mounted) return;

      if (response['success'] == true || response['status'] == 200) {
        _fetchProfile();
        _showSnack('Profile updated successfully!', Colors.green);
      } else {
        _showSnack(
            response['message']?.toString() ?? 'Failed to update profile',
            Colors.red);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: ${e.toString()}', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _confirmDelete(Post post) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post?',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        content: const Text(
            'Are you sure you want to delete this post?\nThis action cannot be undone.',
            textAlign: TextAlign.center,
            style:
            TextStyle(color: Colors.black54, fontSize: 14, height: 1.5)),
        actionsPadding: EdgeInsets.zero,
        actions: [
          Divider(height: 1, color: Colors.grey.shade100),
          Row(children: [
            Expanded(
              child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.black54, fontSize: 16))),
            ),
            Container(width: 1, height: 48, color: Colors.grey.shade100),
            Expanded(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    _userPhotoPosts.removeWhere((p) => p.id == post.id);
                    globalPosts.removeWhere((p) => p.id == post.id);
                  });
                  _showSnack('Post deleted', Colors.red);
                },
                child: const Text('Delete',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ]),
        ],
      ),
    );
  }

  void _showPostOptions(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(children: [
        _BottomSheetTile(
          icon: Icons.delete_outline_rounded,
          label: 'Delete Post',
          color: Colors.red,
          onTap: () {
            Navigator.pop(context);
            _confirmDelete(post);
          },
        ),
        _BottomSheetTile(
          icon: Icons.edit_rounded,
          label: 'Edit Caption',
          onTap: () => Navigator.pop(context),
        ),
        _BottomSheetTile(
          icon: Icons.share_outlined,
          label: 'Share Post',
          onTap: () {
            Navigator.pop(context);
            _openShareSheet(post);
          },
        ),
      ]),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                  color: _kPrimary, strokeWidth: 2.5),
              SizedBox(height: 16),
              Text('Loading profile...',
                  style: TextStyle(color: _kMuted, fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      color: Colors.red, size: 44),
                ),
                const SizedBox(height: 20),
                const Text('Something went wrong',
                    style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 17)),
                const SizedBox(height: 8),
                Text(_errorMessage,
                    textAlign: TextAlign.center,
                    style:
                    const TextStyle(color: Colors.black54, fontSize: 13)),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  onPressed: _fetchProfile,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 13),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // ── FIXED: Wrapped in Scaffold ─────────────────────────────────────────
    return Scaffold(
      backgroundColor: _kBg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildBioSection()),
          SliverPersistentHeader(
            pinned: true,
            delegate: _TabDelegate(
              TabBar(
                controller: _tabCtrl,
                indicatorColor: _kPrimary,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                labelColor: _kPrimary,
                unselectedLabelColor: _kMuted,
                dividerColor: _kBorder,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 13, letterSpacing: 0.2),
                unselectedLabelStyle:
                const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
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
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final posts = _allPosts;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Cover gradient
        Container(
          height: 180,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _kGrad,
            ),
          ),
          child: Stack(
            children: [
              // Subtle pattern overlay
              Positioned.fill(
                child: Opacity(
                  opacity: 0.06,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 8),
                    itemCount: 64,
                    itemBuilder: (_, __) => const DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: Colors.white, width: 0.5),
                          bottom: BorderSide(color: Colors.white, width: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Top bar
              // Positioned(
              //   top: 44,
              //   right: 14,
              //   child: Row(children: [
              //     // _iconBtn(Icons.notifications_outlined, () {}),
              //     // const SizedBox(width: 6),
              //     _iconBtn(Icons.settings_outlined, () {
              //       Navigator.push(context,
              //           MaterialPageRoute(builder: (_) => SettingsScreen()));
              //     }),
              //   ]),
              // ),
              // Name & location (right of avatar space)
              Positioned(
                bottom: 50,
                left: 125,
                right: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 21,
                          letterSpacing: -0.3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_location.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Row(children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.white70, size: 12),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _location,
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),

        // Stats card — floats below header
        Positioned(
          bottom: -32,
          left: 120,
          right: 0,
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.10),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _stat('${posts.length}', 'Posts', null),
                  _vertDivider(),
                  _stat('$_followersCount', 'Followers', _openFollowers),
                  _vertDivider(),
                  _stat('$_followingCount', 'Following', _openFollowing),
                ],
              ),
            ),
          ),
        ),

        // Avatar
        Positioned(
          bottom: 25,
          left: 16,
          child: GestureDetector(
            onTap: _viewProfilePhoto,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3.5),
                boxShadow: [
                  BoxShadow(
                    color: _kPrimary.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: CircleAvatar(
                radius: 46,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: Image.network(
                    _profileImage,
                    width: 92,
                    height: 92,
                    fit: BoxFit.cover,
                    // FIXED: errorBuilder cannot call setState
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.person_rounded,
                          size: 48, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _vertDivider() => Container(
      width: 1, height: 28, color: Colors.grey.shade200);

  Widget _stat(String count, String label, VoidCallback? tap) {
    final col = Column(
      children: [
        Text(count,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        const SizedBox(height: 2),
        Text(label,
            style:
            TextStyle(color: Colors.grey.shade500, fontSize: 11)),
      ],
    );
    return tap != null
        ? GestureDetector(onTap: tap, child: col)
        : col;
  }

  // ── BIO SECTION ────────────────────────────────────────────────────────────
  Widget _buildBioSection() {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(top: 58),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_bio1.isNotEmpty)
            Text(_bio1,
                style: const TextStyle(color: Colors.black87, fontSize: 13.5, height: 1.5)),
          if (_bio2.isNotEmpty)
            Text(_bio2,
                style: const TextStyle(color: Colors.black87, fontSize: 13.5, height: 1.5)),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: GestureDetector(
                onTap: _openEditProfile,
                child: Container(
                  height: 38,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(colors: _kGrad),
                    boxShadow: [
                      BoxShadow(
                        color: _kPrimary.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text('Edit Profile',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                          letterSpacing: 0.2)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 38,
              width: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Icon(Icons.person_add_alt_1_outlined,
                  size: 18, color: Colors.black87),
            ),
          ]),
        ],
      ),
    );
  }

  // ── PHOTOS TAB ────────────────────────────────────────────────────────────
  Widget _buildPhotosTab() {
    final posts = _allPosts;
    return posts.isEmpty
        ? _buildEmptyState(
        Icons.photo_library_outlined, 'No photos yet', 'Share your first moment')
        : CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Photos',
                    style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                GestureDetector(
                  onTap: () => _showAllPhotos(
                      posts.map((p) => p.postImages.first).toList()),
                  child: const Text('See All',
                      style: TextStyle(
                          color: _kPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ),
        // Grid preview
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
                final p = posts[i];
                return GestureDetector(
                  onTap: () => _viewPhoto(p.postImages.first),
                  onLongPress: () => _showPostOptions(p),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.network(
                        p.postImages.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image_rounded,
                                    color: Colors.grey)),
                      ),
                      // Gradient overlay
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.50),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        left: 5,
                        child: Row(children: [
                          Icon(Icons.favorite_rounded,
                              size: 11,
                              color: p.isLiked
                                  ? _kPrimary
                                  : Colors.white70),
                          const SizedBox(width: 2),
                          Text('${p.likes}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black54,
                                        blurRadius: 2)
                                  ])),
                          const SizedBox(width: 6),
                          const Icon(Icons.chat_bubble_rounded,
                              size: 10, color: Colors.white70),
                          const SizedBox(width: 2),
                          Text('${p.comments}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  shadows: [
                                    Shadow(
                                        color: Colors.black54,
                                        blurRadius: 2)
                                  ])),
                        ]),
                      ),
                      if (p.postImages.length > 1)
                        const Positioned(
                            top: 6,
                            right: 6,
                            child: Icon(Icons.copy_rounded,
                                color: Colors.white, size: 14)),
                    ]),
                  ),
                );
              },
              childCount: posts.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        SliverToBoxAdapter(
            child: Divider(height: 1, color: _kBorder)),
        // Full post cards
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (ctx, i) => _buildPostCard(posts[i]),
            childCount: posts.length,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  // ── REELS TAB ─────────────────────────────────────────────────────────────
  Widget _buildReelsTab() {
    final reels = [
      ..._userReels,
      ...globalPosts
          .where((p) => p.postImages.isNotEmpty)
          .map((p) => p.postImages.first),
    ];

    if (reels.isEmpty) {
      return _buildEmptyState(
          Icons.play_circle_outline_rounded, 'No reels yet', 'Your videos will appear here');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
        childAspectRatio: 0.6,
      ),
      itemCount: reels.length,
      itemBuilder: (ctx, i) => GestureDetector(
        onTap: () => _viewPhoto(reels[i]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(fit: StackFit.expand, children: [
            Image.network(
              reels[i],
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: Colors.grey.shade200),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                ),
              ),
            ),
            const Center(
              child: Icon(Icons.play_circle_fill_rounded,
                  color: Colors.white, size: 30),
            ),
            Positioned(
              bottom: 7,
              left: 7,
              child: Row(children: [
                const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 12),
                Text('${(i + 1) * 1200}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        shadows: [
                          Shadow(color: Colors.black54, blurRadius: 2)
                        ])),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String sub) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: _kPrimary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 44, color: _kPrimary.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const SizedBox(height: 5),
          Text(sub,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
        ],
      ),
    );
  }

  // ── POST CARD ─────────────────────────────────────────────────────────────
  Widget _buildPostCard(Post post) {
    return StatefulBuilder(builder: (ctx, setCard) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
              child: Row(children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: Image.network(
                      post.userImage,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person_rounded, size: 22, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.username,
                          style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5)),
                      Text(post.timeAgo,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 11.5)),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => _showPostOptions(post),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.more_horiz_rounded,
                        color: Colors.grey.shade600, size: 22),
                  ),
                ),
              ]),
            ),

            // Image(s)
            ClipRRect(
              child: post.postImages.length == 1
                  ? GestureDetector(
                onDoubleTap: () {
                  if (!post.isLiked) {
                    setCard(() {
                      post.isLiked = true;
                      post.likes++;
                    });
                    setState(() {});
                  }
                },
                child: Image.network(
                  post.postImages.first,
                  width: double.infinity,
                  height: 280,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 280, color: Colors.grey.shade100,
                          child: const Icon(Icons.broken_image_rounded,
                              size: 48, color: Colors.grey)),
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
                        Container(color: Colors.grey.shade100),
                  ),
                ),
              ),
            ),

            // Action row
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
              child: Row(children: [
                _actionBtn(
                  icon: post.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: post.isLiked ? _kPrimary : Colors.black54,
                  label: '${post.likes}',
                  onTap: () => setCard(() {
                    post.isLiked = !post.isLiked;
                    post.likes += post.isLiked ? 1 : -1;
                    setState(() {});
                  }),
                ),
                const SizedBox(width: 18),
                _actionBtn(
                  icon: Icons.chat_bubble_outline_rounded,
                  color: Colors.black54,
                  label: '${post.comments}',
                  onTap: () => _openComments(post, setCard),
                ),
                const SizedBox(width: 18),
                _actionBtn(
                  icon: Icons.send_rounded,
                  color: Colors.black54,
                  label: '${post.shares}',
                  onTap: () => _openShareSheet(post),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () =>
                      setCard(() => post.isBookmarked = !post.isBookmarked),
                  child: Icon(
                      post.isBookmarked
                          ? Icons.bookmark_rounded
                          : Icons.bookmark_border_rounded,
                      color: post.isBookmarked ? _kPrimary : Colors.black54,
                      size: 22),
                ),
              ]),
            ),

            Padding(
              padding: const EdgeInsets.only(left: 14, bottom: 4),
              child: Text('${post.likes} likes',
                  style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5)),
            ),

            if (post.caption.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                child: RichText(
                  text: TextSpan(children: [
                    TextSpan(
                      text: '${post.username} ',
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                    TextSpan(
                      text: post.caption,
                      style: const TextStyle(
                          color: Colors.black87, fontSize: 13),
                    ),
                  ]),
                ),
              ),

            Divider(height: 1, color: _kBorder),
          ],
        ),
      );
    });
  }

  Widget _actionBtn({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: color, size: 23),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ── COMMENTS SHEET ────────────────────────────────────────────────────────
  void _openComments(Post post, StateSetter parentSet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setModal) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle + title
            Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 4),
              child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2))),
            ),
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 32),
                    const Text('Comments',
                        style: TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.black),
                      ),
                    )
                  ]),
            ),
            Divider(height: 1, color: Colors.grey.shade100),

            // Comments list
            Expanded(
              child: post.commentsList.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 44,
                        color: Colors.grey.shade300),
                    const SizedBox(height: 12),
                    const Text('No comments yet.',
                        style: TextStyle(
                            color: _kMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    const SizedBox(height: 4),
                    const Text('Be the first to comment! 💬',
                        style:
                        TextStyle(color: _kMuted, fontSize: 13)),
                  ],
                ),
              )
                  : ListView.separated(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                itemCount: post.commentsList.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 2),
                itemBuilder: (_, i) {
                  final c = post.commentsList[i];
                  return Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 17,
                            backgroundColor: Colors.grey.shade200,
                            child: ClipOval(
                              child: Image.network(c.userImage,
                                  width: 34,
                                  height: 34,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.person_rounded,
                                      size: 18,
                                      color: Colors.grey)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(children: [
                                      TextSpan(
                                        text: '${c.username} ',
                                        style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight:
                                            FontWeight.w600,
                                            fontSize: 13),
                                      ),
                                      TextSpan(
                                        text: c.text,
                                        style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 13),
                                      ),
                                    ]),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(children: [
                                    Text(c.timeAgo,
                                        style: const TextStyle(
                                            color: _kMuted,
                                            fontSize: 11)),
                                    const SizedBox(width: 14),
                                    Text('${c.likes} likes',
                                        style: const TextStyle(
                                            color: _kMuted,
                                            fontSize: 11,
                                            fontWeight:
                                            FontWeight.w600)),
                                    const SizedBox(width: 14),
                                    const Text('Reply',
                                        style: TextStyle(
                                            color: _kMuted,
                                            fontSize: 11,
                                            fontWeight:
                                            FontWeight.w600)),
                                  ]),
                                ]),
                          ),
                          GestureDetector(
                            onTap: () =>
                                setModal(() => c.likes++),
                            child: const Icon(
                                Icons.favorite_border_rounded,
                                size: 14,
                                color: _kMuted),
                          ),
                        ]),
                  );
                },
              ),
            ),

            // Input bar
            Container(
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                    top: BorderSide(
                        color: Colors.grey.shade100, width: 0.8)),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: Colors.grey.shade200,
                      child: ClipOval(
                        child: Image.network(_profileImage,
                            width: 34,
                            height: 34,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                            const Icon(Icons.person_rounded,
                                size: 18, color: Colors.grey)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextField(
                          controller: _commentCtrl,
                          style: const TextStyle(
                              color: Colors.black, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle:
                            TextStyle(color: _kMuted, fontSize: 14),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        final txt = _commentCtrl.text.trim();
                        if (txt.isEmpty) return;
                        post.addComment(Comment(
                          username: _name,
                          userImage: _profileImage,
                          text: txt,
                          timeAgo: 'Just now',
                          likes: 0,
                        ));
                        _commentCtrl.clear();
                        setModal(() {});
                        parentSet(() {});
                        setState(() {});
                      },
                      child: Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: _kGrad),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _kPrimary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        child: const Icon(Icons.send_rounded,
                            color: Colors.white, size: 16),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        );
      }),
    );
  }

  // ── SHARE SHEET ────────────────────────────────────────────────────────────
  void _openShareSheet(Post post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _BottomSheet(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Share',
              style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
        ),
        _ShareTile(
          color: const Color(0xFF25D366),
          icon: Icons.chat_rounded,
          label: 'WhatsApp',
          onTap: () async {
            Navigator.pop(context);
            await Share.share(
                '${post.username}: ${post.caption}\n${post.postImages.isNotEmpty ? post.postImages[0] : ''}');
          },
        ),
        _ShareTile(
            color: _kPrimary,
            icon: Icons.send_rounded,
            label: 'Direct Message',
            onTap: () => Navigator.pop(context)),
        _ShareTile(
            color: Colors.orange,
            icon: Icons.link_rounded,
            label: 'Copy Link',
            onTap: () => Navigator.pop(context)),
        _ShareTile(
            color: Colors.blue,
            icon: Icons.share_rounded,
            label: 'Share to...',
            onTap: () => Navigator.pop(context)),
        _ShareTile(
            color: Colors.purple,
            icon: Icons.bookmark_rounded,
            label: 'Add to Favorites',
            onTap: () => Navigator.pop(context)),
        const SizedBox(height: 8),
      ]),
    );
  }

  // ── NAVIGATION HELPERS ────────────────────────────────────────────────────
  void _openFollowers() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FriendsScreen(
              username: _name,
              initialTab: 0,
              followers: _followers,
              following: _following)));

  void _openFollowing() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => FriendsScreen(
              username: _name,
              initialTab: 1,
              followers: _followers,
              following: _following)));

  void _viewProfilePhoto() => Navigator.push(context,
      MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: _profileImage)));

  void _viewPhoto(String url) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => _PhotoViewer(imageUrl: url)));

  void _showAllPhotos(List<String> photos) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => _AllPhotosScreen(photos: photos)));

  void _openEditProfile() async {
    final r = await Navigator.push<Map<String, String>>(
        context,
        MaterialPageRoute(
            builder: (_) => _EditProfileScreen(
                name: _name,
                location: _location,
                bio1: _bio1,
                bio2: _bio2,
                profileImage: _profileImage)));

    if (r != null) {
      if (r['shouldUpdate'] == 'true') {
        await _updateProfile(name: r['name'], bio: r['bio1'], city: r['location']);
      } else {
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
}

// ─── REUSABLE BOTTOM SHEET WRAPPER ─────────────────────────────────────────────
class _BottomSheet extends StatelessWidget {
  final List<Widget> children;
  const _BottomSheet({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BottomSheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _BottomSheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: TextStyle(
                  color: color, fontSize: 15, fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }
}

class _ShareTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(color: Colors.black87, fontSize: 15)),
        ]),
      ),
    );
  }
}

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
    // FIXED: initialTab 0 = Followers, 1 = Following (matches the tabs order)
    _tabCtrl = TabController(
        length: 2, vsync: this, initialIndex: widget.initialTab);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.username,
            style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1_outlined,
                color: Colors.black),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: TabBar(
            controller: _tabCtrl,
            indicatorColor: _kPrimary,
            indicatorWeight: 2.5,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: _kPrimary,
            unselectedLabelColor: _kMuted,
            dividerColor: _kBorder,
            labelStyle: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 13),
            // FIXED: Tab order matches initialTab assignment
            tabs: [
              Tab(text: 'Followers (${widget.followers.length})'),
              Tab(text: 'Following (${widget.following.length})'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildList(widget.followers, isFollowersTab: true),
          _buildList(widget.following, isFollowersTab: false),
        ],
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> list,
      {required bool isFollowersTab}) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded,
                size: 44, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(
              isFollowersTab
                  ? 'No followers yet'
                  : 'Not following anyone yet',
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                  fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) {
        final f = list[i];
        return StatefulBuilder(builder: (ctx, setRow) {
          // FIXED: isFollowing logic — for followers tab, toggle means "Follow back"
          final isFollowing = f['isFollowing'] as bool? ?? false;

          return Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.grey.shade200,
                child: ClipOval(
                  child: Image.network(
                    f['image'] as String? ?? '',
                    width: 52,
                    height: 52,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.person_rounded,
                        size: 28,
                        color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f['name'] as String? ?? '',
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    if ((f['mutual'] as String? ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(f['mutual'] as String,
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 12)),
                    ]
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setRow(() => f['isFollowing'] = !isFollowing),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: !isFollowing
                        ? const LinearGradient(colors: _kGrad)
                        : null,
                    color: isFollowing ? Colors.grey.shade100 : null,
                    borderRadius: BorderRadius.circular(20),
                    border: isFollowing
                        ? Border.all(color: Colors.grey.shade300)
                        : null,
                  ),
                  child: Text(
                    isFollowersTab
                        ? (isFollowing ? 'Following' : 'Follow Back')
                        : (isFollowing ? 'Following' : 'Follow'),
                    style: TextStyle(
                        color:
                        isFollowing ? Colors.black54 : Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 12.5),
                  ),
                ),
              ),
            ]),
          );
        });
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
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.download_rounded, color: Colors.white),
          onPressed: () {},
        )
      ],
    ),
    extendBodyBehindAppBar: true,
    body: Center(
      child: InteractiveViewer(
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.broken_image_rounded,
                  color: Colors.white54, size: 64),
              SizedBox(height: 12),
              Text('Failed to load image',
                  style: TextStyle(color: Colors.white54, fontSize: 14)),
            ],
          ),
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
      elevation: 0,
      surfaceTintColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text('All Photos',
          style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 17)),
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
        onTap: () => Navigator.push(ctx,
            MaterialPageRoute(
                builder: (_) => _PhotoViewer(imageUrl: photos[i]))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: Image.network(
            photos[i],
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) =>
                Container(color: Colors.grey.shade200),
          ),
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
  late TextEditingController _nameCtrl,
      _locCtrl,
      _bio1Ctrl,
      _bio2Ctrl;
  String _networkImg = '';
  File? _localImg;
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
    final XFile? picked =
    await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (picked != null) setState(() => _localImg = File(picked.path));
  }

  ImageProvider get _currentImage => _localImg != null
      ? FileImage(_localImg!) as ImageProvider
      : NetworkImage(_networkImg);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ),
        leadingWidth: 80,
        title: const Text('Edit Profile',
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'name': _nameCtrl.text.trim(),
              'location': _locCtrl.text.trim(),
              'bio1': _bio1Ctrl.text.trim(),
              'bio2': _bio2Ctrl.text.trim(),
              'profileImage': _localImg?.path ?? _networkImg,
              'shouldUpdate': 'true',
            }),
            child: const Text('Done',
                style: TextStyle(
                    color: _kPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
          ),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Divider(height: 0.5, color: Colors.grey.shade200)),
      ),
      body: ListView(
        children: [
          // Avatar picker
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: GestureDetector(
                onTap: _pickFromGallery,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: _kGrad,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundImage: _currentImage,
                        backgroundColor: Colors.grey.shade200,
                      ),
                    ),
                    Positioned(
                      bottom: 2,
                      right: 2,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: _kGrad),
                          shape: BoxShape.circle,
                          border:
                          Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.camera_alt_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Fields
          const _SectionLabel('Personal Info'),
          _EditField(
            label: 'Name',
            controller: _nameCtrl,
            icon: Icons.person_outline_rounded,
          ),
          _EditField(
            label: 'Location',
            controller: _locCtrl,
            icon: Icons.location_on_outlined,
          ),
          const SizedBox(height: 12),
          const _SectionLabel('About'),
          _EditField(
            label: 'Bio',
            controller: _bio1Ctrl,
            icon: Icons.info_outline_rounded,
            maxLines: 3,
          ),
          _EditField(
            label: 'Bio line 2',
            controller: _bio2Ctrl,
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(text,
          style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5)),
    );
  }
}

class _EditField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData icon;
  final int maxLines;

  const _EditField({
    required this.label,
    required this.controller,
    required this.icon,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 0, 12),
                  child: Icon(icon, size: 18, color: _kPrimary),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    maxLines: maxLines,
                    style: const TextStyle(
                        color: Colors.black, fontSize: 14.5),
                    cursorColor: _kPrimary,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.fromLTRB(10, 11, 12, 11),
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
  bool shouldRebuild(covariant _TabDelegate old) =>
      old.tabBar != tabBar;
}