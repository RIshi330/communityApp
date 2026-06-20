// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:any_link_preview/any_link_preview.dart';
// import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
// import 'package:intl/intl.dart';
// import 'package:commity_app1/Database/Database.dart';
// import 'package:commity_app1/services/auth_service.dart';
// import 'package:commity_app1/model/post_model.dart';
//
// class CreatePostFinalScreen extends StatefulWidget {
//   const CreatePostFinalScreen({super.key});
//
//   @override
//   State<CreatePostFinalScreen> createState() => _CreatePostFinalScreenState();
// }
//
// class _CreatePostFinalScreenState extends State<CreatePostFinalScreen> {
//   final TextEditingController content = TextEditingController();
//
//   final ImagePicker picker = ImagePicker();
//
//   List<XFile> images = [];
//   List<PlatformFile> docs = [];
//   List<String> tagged = [];
//
//   String? location;
//   String? link;
//   String? ctaLabel;
//   String? ctaLink;
//
//   bool showEmoji = false;
//   DateTime? scheduled;
//   bool _isPublishing = false;
//   String _vendorId = '0';
//   String _userName = 'User';
//
//   @override
//   void initState() {
//     super.initState();
//     _initVendorId();
//   }
//
//   Future<void> _initVendorId() async {
//     _vendorId = await AuthService.getVendorIdString();
//     try {
//       final database = Database();
//       final response = await database.getData({
//         'action': 'profile',
//         'vendor_id': _vendorId,
//       });
//       if (response['success'] == true || response['status'] == 200) {
//         final profileData = response['data'];
//         if (profileData != null) {
//           final profile = profileData['profile'];
//           setState(() {
//             _userName = profile['name']?.toString() ?? 'User';
//           });
//         }
//       }
//     } catch (e) {
//       print("Error fetching user profile: $e");
//     }
//   }
//
//   /// 🚀 PUBLISH API
//   Future<void> _publishPost() async {
//     final caption = content.text.trim();
//
//     if (caption.isEmpty && images.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please add a caption or at least one image'),
//         ),
//       );
//       return;
//     }
//
//     setState(() => _isPublishing = true);
//
//     try {
//       final database = Database();
//       final Map<String, String> requestBody = {
//         'action': 'create_post',
//         'vendor_id': _vendorId,
//         'label': caption,
//       };
//
//       if (images.isNotEmpty) {
//         requestBody['images'] = images.map((img) => img.path).join(',');
//       }
//
//       final response = await database.getData(requestBody);
//
//       if (response['success'] == true || response['status'] == 200) {
//         final newPostId =
//             response['data']?['post_id']?.toString() ??
//             DateTime.now().millisecondsSinceEpoch.toString();
//
//         final List<String> imagePaths = images.isNotEmpty
//             ? images.map((img) => img.path).toList()
//             : ['https://picsum.photos/800/600?random=$newPostId'];
//
//         final newPost = Post(
//           id: newPostId,
//           username: _userName,
//           userImage: 'https://i.pravatar.cc/150?img=$_vendorId',
//           postImages: imagePaths,
//           likes: 0,
//           caption: caption,
//           timeAgo: 'Just now',
//           comments: 0,
//           shares: 0,
//         );
//
//         globalPosts.insert(0, newPost);
//
//         if (!mounted) return;
//         Navigator.pop(context, true);
//       } else {
//         // Fallback local injection
//         final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();
//         final List<String> imagePaths = images.isNotEmpty
//             ? images.map((img) => img.path).toList()
//             : ['https://picsum.photos/800/600?random=$fallbackId'];
//
//         globalPosts.insert(
//           0,
//           Post(
//             id: fallbackId,
//             username: _userName,
//             userImage: 'https://i.pravatar.cc/150?img=$_vendorId',
//             postImages: imagePaths,
//             likes: 0,
//             caption: caption,
//             timeAgo: 'Just now',
//             comments: 0,
//             shares: 0,
//           ),
//         );
//         if (!mounted) return;
//         Navigator.pop(context, true);
//       }
//     } catch (e) {
//       // Offline fallback
//       final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();
//       final List<String> imagePaths = images.isNotEmpty
//           ? images.map((img) => img.path).toList()
//           : ['https://picsum.photos/800/600?random=$fallbackId'];
//       globalPosts.insert(
//         0,
//         Post(
//           id: fallbackId,
//           username: _userName,
//           userImage: 'https://i.pravatar.cc/150?img=$_vendorId',
//           postImages: imagePaths,
//           likes: 0,
//           caption: caption,
//           timeAgo: 'Just now',
//           comments: 0,
//           shares: 0,
//         ),
//       );
//       if (!mounted) return;
//       Navigator.pop(context, true);
//     } finally {
//       if (mounted) setState(() => _isPublishing = false);
//     }
//   }
//
//   /// 📸 IMAGE PICKER
//   Future<void> pickImages() async {
//     final res = await picker.pickMultiImage();
//     if (res != null) {
//       setState(() => images.addAll(res));
//     }
//   }
//
//   /// 📄 DOC PICKER
//   Future<void> pickDocs() async {
//     final res = await FilePicker.pickFiles();
//     if (res != null) {
//       setState(() => docs.addAll(res.files));
//     }
//   }
//
//   /// 👥 TAG PEOPLE MODAL
//   void openTagModal() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (_) => _modalWrapper(
//         title: "Tag People",
//         child: Column(
//           children: List.generate(10, (i) {
//             return ListTile(
//               leading: const CircleAvatar(child: Text("U")),
//               title: Text("User $i"),
//               onTap: () {
//                 setState(() => tagged.add("User $i"));
//                 Navigator.pop(context);
//               },
//             );
//           }),
//         ),
//       ),
//     );
//   }
//
//   /// 📍 LOCATION MODAL
//   void openLocationModal() {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) => _modalWrapper(
//         title: "Select Location",
//         child: Column(
//           children: ["Delhi", "Mumbai", "Remote"]
//               .map(
//                 (e) => ListTile(
//                   title: Text(e),
//                   onTap: () {
//                     setState(() => location = e);
//                     Navigator.pop(context);
//                   },
//                 ),
//               )
//               .toList(),
//         ),
//       ),
//     );
//   }
//
//   /// 🔗 LINK MODAL
//   void openLinkModal() {
//     TextEditingController c = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Add Link"),
//         content: TextField(controller: c),
//         actions: [
//           TextButton(
//             onPressed: () {
//               setState(() => link = c.text);
//               Navigator.pop(context);
//             },
//             child: const Text("Add"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 🎯 CTA MODAL
//   void openCtaModal() {
//     TextEditingController label = TextEditingController();
//     TextEditingController url = TextEditingController();
//
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: const Text("Add CTA"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             TextField(
//               controller: label,
//               decoration: const InputDecoration(hintText: "Label"),
//             ),
//             TextField(
//               controller: url,
//               decoration: const InputDecoration(hintText: "Link"),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               setState(() {
//                 ctaLabel = label.text;
//                 ctaLink = url.text;
//               });
//               Navigator.pop(context);
//             },
//             child: const Text("Save"),
//           ),
//         ],
//       ),
//     );
//   }
//
//   /// 📅 SCHEDULE
//   Future<void> pickSchedule() async {
//     DateTime? date = await showDatePicker(
//       context: context,
//       firstDate: DateTime.now(),
//       lastDate: DateTime(2030),
//     );
//
//     if (date != null) {
//       setState(() => scheduled = date);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xfff6f4ff),
//
//       floatingActionButton: FloatingActionButton.extended(
//         backgroundColor: Colors.white,
//         onPressed: _isPublishing ? null : _publishPost,
//         label: _isPublishing
//             ? const CircularProgressIndicator(color: Colors.deepPurple)
//             : const Text(
//                 "Publish",
//                 style: TextStyle(
//                   color: Colors.deepPurple,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//       ),
//
//       body: Column(
//         children: [
//           /// HEADER
//           Container(
//             padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade50],
//               ),
//               borderRadius: const BorderRadius.vertical(
//                 bottom: Radius.circular(24),
//               ),
//             ),
//             child: Row(
//               children: const [
//                 CircleAvatar(child: Text("R")),
//                 SizedBox(width: 10),
//                 Text(
//                   "Create Post",
//                   style: TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               ],
//             ),
//           ),
//
//           Expanded(
//             child: ListView(
//               padding: const EdgeInsets.all(16),
//               children: [
//                 /// TEXT INPUT
//                 _card(
//                   child: TextField(
//                     controller: content,
//                     maxLines: null,
//                     style: const TextStyle(fontSize: 18, color: Colors.black87),
//                     minLines: 3,
//                     decoration: const InputDecoration(
//                       hintText: "Share something...",
//                       hintStyle: TextStyle(fontSize: 18, color: Colors.black38),
//                       border: InputBorder.none,
//                     ),
//                   ),
//                 ),
//
//                 /// MEDIA
//                 _action("Add Photos / Videos", Icons.image, pickImages),
//
//                 if (images.isNotEmpty)
//                   Wrap(
//                     spacing: 8,
//                     children: images
//                         .map(
//                           (e) => ClipRRect(
//                             borderRadius: BorderRadius.circular(12),
//                             child: Image.network(
//                               e.path,
//                               width: 100,
//                               height: 100,
//                             ),
//                           ),
//                         )
//                         .toList(),
//                   ),
//
//                 /// TAG
//                 _action("Tag People", Icons.person_add, openTagModal),
//
//                 Wrap(
//                   children: tagged.map((e) => Chip(label: Text(e))).toList(),
//                 ),
//
//                 /// LOCATION
//                 _action("Add Location", Icons.location_on, openLocationModal),
//                 if (location != null) Text(location!),
//
//                 /// LINK
//                 _action("Add Link", Icons.link, openLinkModal),
//                 if (link != null) AnyLinkPreview(link: link!),
//
//                 /// DOC
//                 _action("Upload Document", Icons.file_copy, pickDocs),
//                 ...docs.map((d) => ListTile(title: Text(d.name))),
//
//                 /// CTA
//                 _action("Add CTA", Icons.ads_click, openCtaModal),
//                 if (ctaLabel != null) Text("$ctaLabel → $ctaLink"),
//
//                 /// SCHEDULE
//                 _action("Schedule", Icons.schedule, pickSchedule),
//                 if (scheduled != null)
//                   Text(DateFormat.yMMMd().format(scheduled!)),
//
//                 const SizedBox(height: 80),
//               ],
//             ),
//           ),
//
//           /// EMOJI PICKER
//           if (showEmoji)
//             SizedBox(
//               height: 250,
//               child: EmojiPicker(
//                 onEmojiSelected: (c, e) {
//                   content.text += e.emoji;
//                 },
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _card({required Widget child}) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 14),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       child: child,
//     );
//   }
//
//   Widget _action(String t, IconData i, VoidCallback f) {
//     return GestureDetector(
//       onTap: f,
//       child: Container(
//         margin: const EdgeInsets.only(bottom: 10),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(14),
//         ),
//         child: Row(
//           children: [
//             Icon(i, color: Colors.deepPurple),
//             const SizedBox(width: 10),
//             Expanded(child: Text(t)),
//             const Icon(Icons.arrow_forward_ios, size: 14),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _modalWrapper({required String title, required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/model/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────
// Design tokens (consistent with CreateCommunityScreen)
// ─────────────────────────────────────────────────────────────────────────
class _Tokens {
  static const Color primary = Color(0xFFB9ACFF);
  static const Color primaryDark = Color(0xFF9C8CFF);
  static const Color primarySoft = Color(0xFFF6F3FF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color bg = Color(0xFFFAF9FE);
  static const Color border = Color(0xFFEFEDF7);
  static const Color textPrimary = Color(0xFF3A3850);
  static const Color textSecondary = Color(0xFF8F8DA3);
  static const Color textMuted = Color(0xFFBDBBCE);
  static const Color danger = Color(0xFFF4A6A6);

  static const double radiusLg = 18;
  static const double radiusMd = 14;
  static const double radiusSm = 10;
}

class CreatePostFinalScreen extends StatefulWidget {
  const CreatePostFinalScreen({super.key});

  @override
  State<CreatePostFinalScreen> createState() => _CreatePostFinalScreenState();
}

class _CreatePostFinalScreenState extends State<CreatePostFinalScreen> {
  final TextEditingController content = TextEditingController();

  final ImagePicker picker = ImagePicker();

  List<XFile> images = [];
  List<PlatformFile> docs = [];
  List<String> tagged = [];

  String? location;
  String? link;
  String? ctaLabel;
  String? ctaLink;

  bool showEmoji = false;
  DateTime? scheduled;
  bool _isPublishing = false;
  String _vendorId = '0';
  String _userName = 'User';

  @override
  void initState() {
    super.initState();
    _initVendorId();
  }

  Future<void> _initVendorId() async {
    _vendorId = await AuthService.getVendorIdString();
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'profile',
        'vendor_id': _vendorId,
      });
      if (response['success'] == true || response['status'] == 200) {
        final profileData = response['data'];
        if (profileData != null) {
          final profile = profileData['profile'];
          setState(() {
            _userName = profile['name']?.toString() ?? 'User';
          });
        }
      }
    } catch (e) {
      print("Error fetching user profile: $e");
    }
  }

  /// 🚀 PUBLISH API
  Future<void> _publishPost() async {
    final caption = content.text.trim();

    if (caption.isEmpty && images.isEmpty) {
      _showSnack('Please add a caption or at least one image');
      return;
    }

    setState(() => _isPublishing = true);

    try {
      final database = Database();
      final Map<String, String> requestBody = {
        'action': 'create_post',
        'vendor_id': _vendorId,
        'label': caption,
      };

      if (images.isNotEmpty) {
        requestBody['images'] = images.map((img) => img.path).join(',');
      }

      final response = await database.getData(requestBody);

      if (response['success'] == true || response['status'] == 200) {
        final newPostId =
            response['data']?['post_id']?.toString() ??
                DateTime.now().millisecondsSinceEpoch.toString();

        final List<String> imagePaths = images.isNotEmpty
            ? images.map((img) => img.path).toList()
            : ['https://picsum.photos/800/600?random=$newPostId'];

        final newPost = Post(
          id: newPostId,
          username: _userName,
          userImage: 'https://i.pravatar.cc/150?img=$_vendorId',
          postImages: imagePaths,
          likes: 0,
          caption: caption,
          timeAgo: 'Just now',
          comments: 0,
          shares: 0,
        );

        globalPosts.insert(0, newPost);

        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        // Fallback local injection
        final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();
        final List<String> imagePaths = images.isNotEmpty
            ? images.map((img) => img.path).toList()
            : ['https://picsum.photos/800/600?random=$fallbackId'];

        globalPosts.insert(
          0,
          Post(
            id: fallbackId,
            username: _userName,
            userImage: 'https://i.pravatar.cc/150?img=$_vendorId',
            postImages: imagePaths,
            likes: 0,
            caption: caption,
            timeAgo: 'Just now',
            comments: 0,
            shares: 0,
          ),
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      }
    } catch (e) {
      // Offline fallback
      final fallbackId = DateTime.now().millisecondsSinceEpoch.toString();
      final List<String> imagePaths = images.isNotEmpty
          ? images.map((img) => img.path).toList()
          : ['https://picsum.photos/800/600?random=$fallbackId'];
      globalPosts.insert(
        0,
        Post(
          id: fallbackId,
          username: _userName,
          userImage: 'https://i.pravatar.cc/150?img=$_vendorId',
          postImages: imagePaths,
          likes: 0,
          caption: caption,
          timeAgo: 'Just now',
          comments: 0,
          shares: 0,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isPublishing = false);
    }
  }

  /// 📸 IMAGE PICKER
  Future<void> pickImages() async {
    final res = await picker.pickMultiImage();
    if (res != null) {
      setState(() => images.addAll(res));
    }
  }

  /// 📄 DOC PICKER
  Future<void> pickDocs() async {
    final res = await FilePicker.pickFiles();
    if (res != null) {
      setState(() => docs.addAll(res.files));
    }
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _Tokens.textPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_Tokens.radiusSm),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// 👥 TAG PEOPLE MODAL
  void openTagModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _modalWrapper(
        title: "Tag people",
        child: Column(
          children: List.generate(10, (i) {
            return _modalListTile(
              leading: CircleAvatar(
                backgroundColor: _Tokens.primarySoft,
                child: Text(
                  "U",
                  style: const TextStyle(
                    color: _Tokens.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: "User $i",
              onTap: () {
                setState(() => tagged.add("User $i"));
                Navigator.pop(context);
              },
            );
          }),
        ),
      ),
    );
  }

  /// 📍 LOCATION MODAL
  void openLocationModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _modalWrapper(
        title: "Select location",
        child: Column(
          children: ["Delhi", "Mumbai", "Remote"]
              .map(
                (e) => _modalListTile(
              leading: const Icon(Icons.location_on_outlined,
                  color: _Tokens.primary),
              title: e,
              onTap: () {
                setState(() => location = e);
                Navigator.pop(context);
              },
            ),
          )
              .toList(),
        ),
      ),
    );
  }

  /// 🔗 LINK MODAL
  void openLinkModal() {
    TextEditingController c = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _dialogWrapper(
        title: "Add link",
        children: [
          _dialogTextField(controller: c, hint: "Paste a URL"),
        ],
        onConfirm: () {
          setState(() => link = c.text);
          Navigator.pop(context);
        },
        confirmLabel: "Add",
      ),
    );
  }

  /// 🎯 CTA MODAL
  void openCtaModal() {
    TextEditingController label = TextEditingController();
    TextEditingController url = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _dialogWrapper(
        title: "Add call to action",
        children: [
          _dialogTextField(controller: label, hint: "Button label"),
          const SizedBox(height: 10),
          _dialogTextField(controller: url, hint: "Destination link"),
        ],
        onConfirm: () {
          setState(() {
            ctaLabel = label.text;
            ctaLink = url.text;
          });
          Navigator.pop(context);
        },
        confirmLabel: "Save",
      ),
    );
  }

  /// 📅 SCHEDULE
  Future<void> pickSchedule() async {
    DateTime? date = await showDatePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(2030),
    );

    if (date != null) {
      setState(() => scheduled = date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Tokens.bg,

      floatingActionButton: SizedBox(
        height: 52,
        child: FloatingActionButton.extended(
          backgroundColor: _Tokens.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_Tokens.radiusMd),
          ),
          onPressed: _isPublishing ? null : _publishPost,
          label: _isPublishing
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
              : const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Publish",
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 18),
            ],
          ),
        ),
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(8, 48, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_Tokens.primary, _Tokens.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_rounded,
                      color: Colors.white),
                  // style: IconButton.styleFrom(
                  //   backgroundColor: Colors.white.withOpacity(0.15),
                  //   shape: const CircleBorder(),
                  //   padding: const EdgeInsets.all(8),
                  // ),
                ),
                //const SizedBox(width: 10),
                // Profile circle
                // CircleAvatar(
                //   radius: 19,
                //   backgroundColor: Colors.white.withOpacity(0.22),
                //   child: Text(
                //     _userName.isNotEmpty
                //         ? _userName[0].toUpperCase()
                //         : "U",
                //     style: const TextStyle(
                //       color: Colors.white,
                //       fontWeight: FontWeight.w700,
                //     ),
                //   ),
                // ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Create post",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 17,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Posting as $_userName",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                /// TEXT INPUT
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _Tokens.surface,
                    borderRadius: BorderRadius.circular(_Tokens.radiusLg),
                    border: Border.all(color: _Tokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: content,
                        maxLines: null,
                        minLines: 3,
                        style: const TextStyle(
                          fontSize: 16,
                          color: _Tokens.textPrimary,
                          height: 1.4,
                        ),
                        decoration: InputDecoration(
                          hintText: "Share something with your community…",
                          hintStyle: const TextStyle(
                            fontSize: 16,
                            color: _Tokens.textMuted,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: InkWell(
                          onTap: () =>
                              setState(() => showEmoji = !showEmoji),
                          borderRadius: BorderRadius.circular(50),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: showEmoji
                                  ? _Tokens.primarySoft
                                  : _Tokens.bg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.emoji_emotions_outlined,
                              size: 20,
                              color: showEmoji
                                  ? _Tokens.primary
                                  : _Tokens.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                /// MEDIA PREVIEW
                if (images.isNotEmpty) ...[
                  SizedBox(
                    height: 96,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius:
                              BorderRadius.circular(_Tokens.radiusMd),
                              child: Image.network(
                                images[i].path,
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => images.removeAt(i)),
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.close,
                                      size: 14, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                /// TAGGED PEOPLE CHIPS
                if (tagged.isNotEmpty) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: tagged
                        .map((e) => _infoChip(
                      icon: Icons.person_outline,
                      label: e,
                      onRemove: () =>
                          setState(() => tagged.remove(e)),
                    ))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                ],

                /// LOCATION / LINK / CTA / SCHEDULE SUMMARY CHIPS
                if (location != null ||
                    link != null ||
                    ctaLabel != null ||
                    scheduled != null) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (location != null)
                        _infoChip(
                          icon: Icons.location_on_outlined,
                          label: location!,
                          onRemove: () => setState(() => location = null),
                        ),
                      if (ctaLabel != null && ctaLabel!.isNotEmpty)
                        _infoChip(
                          icon: Icons.ads_click,
                          label: "${ctaLabel!} → ${ctaLink ?? ''}",
                          onRemove: () => setState(() {
                            ctaLabel = null;
                            ctaLink = null;
                          }),
                        ),
                      if (scheduled != null)
                        _infoChip(
                          icon: Icons.schedule,
                          label: DateFormat.yMMMd().format(scheduled!),
                          onRemove: () => setState(() => scheduled = null),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],

                if (link != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(_Tokens.radiusMd),
                    child: AnyLinkPreview(link: link!),
                  ),
                  const SizedBox(height: 14),
                ],

                if (docs.isNotEmpty) ...[
                  Column(
                    children: docs
                        .map((d) => _docTile(d.name))
                        .toList(),
                  ),
                  const SizedBox(height: 6),
                ],

                /// ACTION LIST
                _sectionLabel("Add to your post"),
                const SizedBox(height: 10),
                _action("Photos & videos", Icons.image_outlined, pickImages),
                _action("Tag people", Icons.person_add_alt_1_outlined,
                    openTagModal),
                _action("Location", Icons.location_on_outlined,
                    openLocationModal),
                _action("Link", Icons.link_rounded, openLinkModal),
                _action("Document", Icons.attach_file_rounded, pickDocs),
                _action("Call to action", Icons.ads_click_rounded,
                    openCtaModal),
                _action("Schedule", Icons.schedule_rounded, pickSchedule),

                const SizedBox(height: 80),
              ],
            ),
          ),

          /// EMOJI PICKER
          if (showEmoji)
            SizedBox(
              height: 250,
              child: EmojiPicker(
                onEmojiSelected: (c, e) {
                  content.text += e.emoji;
                },
              ),
            ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  // UI helpers
  // ───────────────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _Tokens.textMuted,
        letterSpacing: 1.1,
      ),
    );
  }

  Widget _action(String t, IconData i, VoidCallback f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: _Tokens.surface,
        borderRadius: BorderRadius.circular(_Tokens.radiusMd),
        child: InkWell(
          onTap: f,
          borderRadius: BorderRadius.circular(_Tokens.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_Tokens.radiusMd),
              border: Border.all(color: _Tokens.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _Tokens.primarySoft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(i, color: _Tokens.primary, size: 19),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    t,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                      color: _Tokens.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: _Tokens.textMuted, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required VoidCallback onRemove,
  }) {
    return Container(
      padding: const EdgeInsets.only(left: 10, right: 6, top: 8, bottom: 8),
      decoration: BoxDecoration(
        color: _Tokens.primarySoft,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: _Tokens.primaryDark),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 180),
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _Tokens.primaryDark,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: onRemove,
            borderRadius: BorderRadius.circular(50),
            child: const Padding(
              padding: EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: _Tokens.primaryDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _docTile(String name) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _Tokens.surface,
        borderRadius: BorderRadius.circular(_Tokens.radiusMd),
        border: Border.all(color: _Tokens.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _Tokens.primarySoft,
              borderRadius: BorderRadius.circular(9),
            ),
            child: const Icon(Icons.description_outlined,
                color: _Tokens.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
                color: _Tokens.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom sheet wrapper with grab handle and rounded top corners
  Widget _modalWrapper({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(
        color: _Tokens.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(_Tokens.radiusLg)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: _Tokens.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 17,
              color: _Tokens.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _modalListTile({
    required Widget leading,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_Tokens.radiusMd),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  color: _Tokens.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Modern dialog wrapper used for link & CTA forms
  Widget _dialogWrapper({
    required String title,
    required List<Widget> children,
    required VoidCallback onConfirm,
    required String confirmLabel,
  }) {
    return AlertDialog(
      backgroundColor: _Tokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_Tokens.radiusLg),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          color: _Tokens.textPrimary,
          fontSize: 17,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: _Tokens.textSecondary),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: onConfirm,
          style: ElevatedButton.styleFrom(
            backgroundColor: _Tokens.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_Tokens.radiusSm),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }

  Widget _dialogTextField({
    required TextEditingController controller,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      style: const TextStyle(fontSize: 14.5, color: _Tokens.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _Tokens.textMuted, fontSize: 14),
        filled: true,
        fillColor: _Tokens.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Tokens.radiusSm),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_Tokens.radiusSm),
          borderSide: const BorderSide(color: _Tokens.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}