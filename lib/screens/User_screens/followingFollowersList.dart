import 'package:commity_app1/model/user_model.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';

// ─── UNIFIED RECIPIENTS LIST FOR DIRECT MESSAGES ───────────────────
class SendDirectScreen extends StatefulWidget {
  final String? postId; // Optional: for tracking which post this DM is for
  final String? postCaption; // Optional: post caption to include in message
  final List<String>? postImages; // Optional: post images to include in message

  const SendDirectScreen({
    super.key,
    this.postId,
    this.postCaption,
    this.postImages,
  });

  @override
  State<SendDirectScreen> createState() => _SendDirectScreenState();
}

class _SendDirectScreenState extends State<SendDirectScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  List<Map<String, dynamic>> _recipients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipientsFromAPI();
  }

  Future<void> _loadRecipientsFromAPI() async {
    try {
      final database = Database();
      final vendorId = await AuthService.getVendorIdString();
      
      // Fetch both followers and following
      final followersResponse = await database.getData({
        'action': 'followers_list',
        'vendor_id': vendorId,
      });
      
      final followingResponse = await database.getData({
        'action': 'following_list',
        'vendor_id': vendorId,
      });
      
      List<Map<String, dynamic>> allRecipients = [];
      
      // Add followers
      if (followersResponse['success'] == true || followersResponse['status'] == 200) {
        final List<dynamic> followersData = followersResponse['data']['followers'] ?? [];
        for (var vendor in followersData) {
          allRecipients.add({
            'id': vendor['id']?.toString() ?? '',
            'username': vendor['username'] ?? vendor['name'] ?? '',
            'name': vendor['name'] ?? '',
            'profileImageUrl': vendor['image'] ?? vendor['profile_image'] ?? 'https://i.pravatar.cc/150?img=1',
          });
        }
      }
      
      // Add following
      if (followingResponse['success'] == true || followingResponse['status'] == 200) {
        final List<dynamic> followingData = followingResponse['data']['following'] ?? [];
        for (var vendor in followingData) {
          // Avoid duplicates
          if (!allRecipients.any((r) => r['id'] == vendor['id']?.toString())) {
            allRecipients.add({
              'id': vendor['id']?.toString() ?? '',
              'username': vendor['username'] ?? vendor['name'] ?? '',
              'name': vendor['name'] ?? '',
              'profileImageUrl': vendor['image'] ?? vendor['profile_image'] ?? 'https://i.pravatar.cc/150?img=1',
            });
          }
        }
      }
      
      setState(() {
        _recipients = allRecipients;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading recipients: $e');
      _loadSampleRecipients();
    }
  }

  void _loadSampleRecipients() {
    final sampleFollowers = FollowerModel.sampleFollowers;
    final sampleFollowing = FollowingModel.sampleFollowing;
    
    List<Map<String, dynamic>> allRecipients = [];
    
    // Add sample followers
    for (var f in sampleFollowers) {
      allRecipients.add({
        'id': f.uid,
        'username': f.username,
        'name': f.displayName,
        'profileImageUrl': f.profileImageUrl,
      });
    }
    
    // Add sample following (avoid duplicates)
    for (var f in sampleFollowing) {
      if (!allRecipients.any((r) => r['id'] == f.uid)) {
        allRecipients.add({
          'id': f.uid,
          'username': f.username,
          'name': f.displayName,
          'profileImageUrl': f.profileImageUrl,
        });
      }
    }
    
    setState(() {
      _recipients = allRecipients;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _filteredRecipients {
    if (_searchQuery.isEmpty) return _recipients;
    return _recipients.where((r) {
      return (r['username'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
             (r['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        title: const Text(
          'Send Direct Message',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : _buildRecipientsList(),
          ),
        ],
      ),
    );
  }

  // 🔍 SEARCH BAR
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search people...',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon: Icon(Icons.search, color: Colors.grey.shade500, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  // 👥 RECIPIENTS LIST (No Partitions)
  Widget _buildRecipientsList() {
    if (_filteredRecipients.isEmpty) {
      return Center(
        child: Text(
          _searchQuery.isEmpty ? 'No recipients found' : 'No match found',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _filteredRecipients.length,
      itemBuilder: (context, index) {
        final recipient = _filteredRecipients[index];
        return _buildRecipientTile(recipient);
      },
    );
  }

  Widget _buildRecipientTile(Map<String, dynamic> recipient) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 28,
            backgroundImage: NetworkImage(recipient['profileImageUrl'] as String),
            backgroundColor: Colors.grey.shade800,
          ),
          const SizedBox(width: 12),

          // Username & Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipient['username'] as String,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  recipient['name'] as String,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Send Button
          GestureDetector(
            onTap: () => _showSendMessageDialog(context, recipient),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFB39DDB), // Lavender
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'Send',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // 💬 SEND MESSAGE DIALOG
  void _showSendMessageDialog(BuildContext context, Map<String, dynamic> recipient) {
    final messageController = TextEditingController();
    
    // Pre-fill with post link if this is a post share
    if (widget.postId != null) {
      messageController.text = 'Check this out: ${widget.postCaption ?? 'Interesting post'}\n\n';
      if (widget.postImages != null && widget.postImages!.isNotEmpty) {
        messageController.text += 'Images: ${widget.postImages!.join(', ')}';
      }
    }
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.grey.shade900,
        title: Text(
          'Message ${recipient['username']}',
          style: const TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: messageController,
          maxLines: 6,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: widget.postId != null ? 'Post content ready to share' : 'Type your message...',
            hintStyle: const TextStyle(color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade800,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              if (messageController.text.isNotEmpty) {
                final messageText = messageController.text;
                final recipientId = recipient['id'] as String;
                final recipientName = recipient['username'] as String;
                
                print('Sending message to $recipientName (ID: $recipientId): $messageText');
                
                Navigator.pop(ctx);
                _sendDirectMessage(recipientId, messageText, context, recipientName);
              }
            },
            child: const Text('Send', style: TextStyle(color: Color(0xFFB39DDB))),
          ),
        ],
      ),
    );
  }

  // 📤 SEND MESSAGE VIA API
  Future<void> _sendDirectMessage(
    String recipientId,
    String messageText,
    BuildContext context,
    String recipientName,
  ) async {
    try {
      final database = Database();
      final senderId = await AuthService.getVendorIdString();
      
      final response = await database.getData({
        'action': 'send_direct_message',
        'sender_id': senderId,
        'recipient_id': recipientId,
        'message': messageText,
        'post_id': widget.postId, // Include post ID if sharing
      });
      
      if (response['success'] == true || response['status'] == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Message sent to $recipientName ✓'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send: ${response['message'] ?? "Unknown error"}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error sending message'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

// ─── LAVENDER MESSAGE BUTTON ────────────────────────────────
class _MessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MessageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB39DDB), // Lavender
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Message',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
