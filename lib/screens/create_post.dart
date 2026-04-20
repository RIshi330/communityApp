import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:intl/intl.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/model/post_model.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a caption or at least one image'),
        ),
      );
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

  /// 👥 TAG PEOPLE MODAL
  void openTagModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _modalWrapper(
        title: "Tag People",
        child: Column(
          children: List.generate(10, (i) {
            return ListTile(
              leading: const CircleAvatar(child: Text("U")),
              title: Text("User $i"),
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
      builder: (_) => _modalWrapper(
        title: "Select Location",
        child: Column(
          children: ["Delhi", "Mumbai", "Remote"]
              .map(
                (e) => ListTile(
                  title: Text(e),
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
      builder: (_) => AlertDialog(
        title: const Text("Add Link"),
        content: TextField(controller: c),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => link = c.text);
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  /// 🎯 CTA MODAL
  void openCtaModal() {
    TextEditingController label = TextEditingController();
    TextEditingController url = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add CTA"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: label,
              decoration: const InputDecoration(hintText: "Label"),
            ),
            TextField(
              controller: url,
              decoration: const InputDecoration(hintText: "Link"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                ctaLabel = label.text;
                ctaLink = url.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
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
      backgroundColor: const Color(0xfff6f4ff),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.white,
        onPressed: _isPublishing ? null : _publishPost,
        label: _isPublishing
            ? const CircularProgressIndicator(color: Colors.deepPurple)
            : const Text(
                "Publish",
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade200, Colors.deepPurple.shade50],
              ),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Row(
              children: const [
                CircleAvatar(child: Text("R")),
                SizedBox(width: 10),
                Text(
                  "Create Post",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                /// TEXT INPUT
                _card(
                  child: TextField(
                    controller: content,
                    maxLines: null,
                    style: const TextStyle(fontSize: 18, color: Colors.black87),
                    minLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Share something...",
                      hintStyle: TextStyle(fontSize: 18, color: Colors.black38),
                      border: InputBorder.none,
                    ),
                  ),
                ),

                /// MEDIA
                _action("Add Photos / Videos", Icons.image, pickImages),

                if (images.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    children: images
                        .map(
                          (e) => ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              e.path,
                              width: 100,
                              height: 100,
                            ),
                          ),
                        )
                        .toList(),
                  ),

                /// TAG
                _action("Tag People", Icons.person_add, openTagModal),

                Wrap(
                  children: tagged.map((e) => Chip(label: Text(e))).toList(),
                ),

                /// LOCATION
                _action("Add Location", Icons.location_on, openLocationModal),
                if (location != null) Text(location!),

                /// LINK
                _action("Add Link", Icons.link, openLinkModal),
                if (link != null) AnyLinkPreview(link: link!),

                /// DOC
                _action("Upload Document", Icons.file_copy, pickDocs),
                ...docs.map((d) => ListTile(title: Text(d.name))),

                /// CTA
                _action("Add CTA", Icons.ads_click, openCtaModal),
                if (ctaLabel != null) Text("$ctaLabel → $ctaLink"),

                /// SCHEDULE
                _action("Schedule", Icons.schedule, pickSchedule),
                if (scheduled != null)
                  Text(DateFormat.yMMMd().format(scheduled!)),

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

  Widget _card({required Widget child}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  Widget _action(String t, IconData i, VoidCallback f) {
    return GestureDetector(
      onTap: f,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(i, color: Colors.deepPurple),
            const SizedBox(width: 10),
            Expanded(child: Text(t)),
            const Icon(Icons.arrow_forward_ios, size: 14),
          ],
        ),
      ),
    );
  }

  Widget _modalWrapper({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
