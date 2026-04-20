import 'package:flutter/material.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';

// ─── COLORS ───────────────────────────────────────────────────────────────────
class AppColors {
  static const lavender      = Color(0xFFB39DDB);
  static const lavenderDark  = Color(0xFF7E57C2);
  static const textPrimary   = Color(0xFF1A1A1A);
  static const textSub       = Color(0xFF888888);
  static const divider       = Color(0xFFF0F0F0);
  static const chatBg        = Color(0xFFF8F6FC);
}

// ─── CHAT USER MODEL ─────────────────────────────────────────────────────────
class ChatUser {
  final String id;
  final String name;
  final String lastMessage;
  final String time;
  final String avatarUrl;
  final bool isUnread;
  final bool isOnline;

  const ChatUser({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.time,
    required this.avatarUrl,
    this.isUnread = false,
    this.isOnline = false,
  });

  // Build ChatUser from FollowingModel or FollowerModel
  factory ChatUser.fromFollowing({
    required String id,
    required String name,
    required String avatarUrl,
    bool isOnline = false,
  }) {
    return ChatUser(
      id: id,
      name: name,
      lastMessage: 'Tap to start chatting',
      time: 'now',
      avatarUrl: avatarUrl,
      isOnline: isOnline,
    );
  }

  // Build ChatUser from API response (dm_senders_list)
  factory ChatUser.fromApi(Map<String, dynamic> data) {
    return ChatUser(
      id: data['id']?.toString() ?? '',
      name: data['name']?.toString() ?? 'Unknown User',
      lastMessage: data['message']?.toString() ?? 'No messages yet',
      time: _formatTimeAgo(data['created_date']?.toString()),
      avatarUrl: data['profile_pic']?.toString().isNotEmpty == true 
          ? data['profile_pic']!.toString()
          : 'https://i.pravatar.cc/150?img=${data['id'] ?? 1}',
      isUnread: false, // TODO: Add unread logic from API if needed
      isOnline: false, // TODO: Add online status from API if needed
    );
  }

  // Format time ago from timestamp
  static String _formatTimeAgo(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return 'now';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) return 'now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m';
      if (difference.inHours < 24) return '${difference.inHours}h';
      if (difference.inDays < 7) return '${difference.inDays}d';
      return '${difference.inDays ~/ 7}w';
    } catch (e) {
      return 'now';
    }
  }

  // Sample fallback chats
  static final List<ChatUser> sampleChats = [
    ChatUser(
      id: '1',
      name: 'Nishant Rathod',
      lastMessage: 'Sent a reel by vtc_janata · 18h',
      time: '18h',
      avatarUrl: 'https://i.pravatar.cc/150?img=11',
      isOnline: true,
    ),
    ChatUser(
      id: '2',
      name: 'VISHAL PATIL',
      lastMessage: 'Seen 19h ago',
      time: '19h',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
    ),
    ChatUser(
      id: '3',
      name: 'vivekpawar_24',
      lastMessage: 'Liked a message · 19h',
      time: '19h',
      avatarUrl: 'https://i.pravatar.cc/150?img=13',
      isOnline: true,
    ),
    ChatUser(
      id: '4',
      name: 'H Λ R S H Λ L | 🇮🇳',
      lastMessage: 'Seen 18h ago',
      time: '18h',
      avatarUrl: 'https://i.pravatar.cc/150?img=14',
    ),
    ChatUser(
      id: '5',
      name: 'Rohan',
      lastMessage: 'Seen 19h ago',
      time: '19h',
      avatarUrl: 'https://i.pravatar.cc/150?img=15',
      isOnline: true,
    ),
    ChatUser(
      id: '6',
      name: 'Ganesh Joshi',
      lastMessage: 'Liked a message · 22h',
      time: '22h',
      avatarUrl: 'https://i.pravatar.cc/150?img=16',
    ),
    ChatUser(
      id: '7',
      name: 'Priya Sharma',
      lastMessage: 'Hello! How are you?',
      time: '1d',
      avatarUrl: 'https://i.pravatar.cc/150?img=20',
      isUnread: true,
      isOnline: true,
    ),
    ChatUser(
      id: '8',
      name: 'Arjun Patil',
      lastMessage: 'Hi bro, what\'s up?',
      time: '2d',
      avatarUrl: 'https://i.pravatar.cc/150?img=21',
    ),
  ];
}


class ChatListScreen extends StatefulWidget {
  // Pass users from Following/Followers screen here
  final List<ChatUser>? extraUsers;

  const ChatListScreen({super.key, this.extraUsers});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<ChatUser> _chatUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChatUsers();
  }

  Future<void> _loadChatUsers() async {
    setState(() => _isLoading = true);
    
    try {
      final database = Database();
      final vendorId = await AuthService.getVendorIdString();
      
      final response = await database.getData({
        'action': 'dm_senders_list',
        'vendor_id': vendorId, // ✅ Dynamic vendor ID
      });
      
      if (response['success'] == true || response['status'] == 200) {
        final List<dynamic> chatData = response['data'] ?? [];
        
        List<ChatUser> apiChats = chatData.map((chatJson) {
          return ChatUser.fromApi(chatJson as Map<String, dynamic>);
        }).toList();
        
        setState(() {
          _chatUsers = apiChats;
          _isLoading = false;
        });
      } else {
        _loadSampleChats();
      }
    } catch (e) {
      print('Error loading chat users: $e');
      _loadSampleChats();
    }
  }

  void _loadSampleChats() {
    setState(() {
      _chatUsers = ChatUser.sampleChats;
      _isLoading = false;
    });
  }

  List<ChatUser> get _allChats {
    final base = List<ChatUser>.from(_chatUsers);
    if (widget.extraUsers != null) {
      for (final u in widget.extraUsers!) {
        if (!base.any((b) => b.id == u.id)) {
          base.insert(0, u); // add following/followers users at top
        }
      }
    }
    return base;
  }

  List<ChatUser> get _filtered {
    if (_searchQuery.isEmpty) return _allChats;
    return _allChats
        .where((u) =>
            u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: const [
                  Text(
                    'Messages',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  // ❌ Requests removed
                  // ❌ Camera removed
                ],
              ),
            ),

            // ── Search Bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: const TextStyle(
                        color: AppColors.textSub, fontSize: 14),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSub, size: 20),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),

            // ── Chat List ─────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(color: AppColors.lavender),
                          SizedBox(height: 16),
                          Text(
                            'Loading chats...',
                            style: TextStyle(color: AppColors.textSub, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  : _filtered.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, 
                                   size: 64, color: AppColors.textSub),
                              SizedBox(height: 16),
                              Text(
                                'No chats yet',
                                style: TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Start a conversation to see it here',
                                style: TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadChatUsers,
                          color: AppColors.lavender,
                          child: ListView.separated(
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                                height: 1, indent: 82, color: AppColors.divider),
                            itemBuilder: (ctx, i) =>
                                _ChatTile(user: _filtered[i]),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── CHAT TILE ────────────────────────────────────────────────────────────────
class _ChatTile extends StatelessWidget {
  final ChatUser user;
  const _ChatTile({required this.user});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChatScreen(user: user)),
      ),
      splashColor: AppColors.lavender.withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [

            // ── Avatar + online dot ──────────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: Image.network(
                      user.avatarUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.lavender.withOpacity(0.2),
                        child: const Icon(Icons.person,
                            color: AppColors.lavenderDark),
                      ),
                    ),
                  ),
                ),
                if (user.isOnline)
                  Positioned(
                    bottom: 1,
                    right: 1,
                    child: Container(
                      width: 13,
                      height: 13,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 14),

            // ── Name + last message ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: user.isUnread
                          ? FontWeight.w800
                          : FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user.lastMessage,
                    style: TextStyle(
                      color: user.isUnread
                          ? AppColors.textPrimary
                          : AppColors.textSub,
                      fontSize: 13,
                      fontWeight: user.isUnread
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // ── Time + unread dot ────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(user.time,
                    style: const TextStyle(
                        color: AppColors.textSub, fontSize: 12)),
                if (user.isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.lavenderDark,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            // ❌ Camera icon removed
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  CHAT SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class ChatScreen extends StatefulWidget {
  final ChatUser user;
  final String? initialMessage;

  const ChatScreen({super.key, required this.user, this.initialMessage});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<_ChatMessage> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.trim().isNotEmpty) {
      _msgController.text = widget.initialMessage!.trim();
    }
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _isLoading = true);
    
    try {
      final database = Database();
      final vendorId = await AuthService.getVendorIdString();
      
      final response = await database.getData({
        'action': 'dm_chat',
        'sender_id': widget.user.id,
        'vendor_id': vendorId, // ✅ Dynamic vendor ID
      });
      
      if (response['success'] == true || response['status'] == 200) {
        final List<dynamic> messagesData = response['data'] ?? [];
        
        List<_ChatMessage> apiMessages = messagesData.map((msgJson) {
          final message = msgJson as Map<String, dynamic>;
          return _ChatMessage(
            text: message['message']?.toString() ?? '',
            isMe: message['sender']?.toString() == vendorId, // ✅ Dynamic vendor ID
            time: _formatMessageTime(message['created_date']?.toString()),
          );
        }).toList();
        
        setState(() {
          _messages = apiMessages;
          _isLoading = false;
        });
        
        // Scroll to bottom after loading
        Future.delayed(const Duration(milliseconds: 100), () {
          _scrollToBottom();
        });
      } else {
        _loadSampleMessages();
      }
    } catch (e) {
      print('Error loading messages: $e');
      _loadSampleMessages();
    }
  }

  void _loadSampleMessages() {
    setState(() {
      _messages = [
        const _ChatMessage(text: 'Hey! How are you?',         isMe: false, time: '10:00 AM'),
        const _ChatMessage(text: 'Hello! I\'m good 😊',        isMe: true,  time: '10:01 AM'),
        const _ChatMessage(text: 'What\'s up?',                isMe: false, time: '10:02 AM'),
        const _ChatMessage(text: 'Hi! Nothing much, chilling', isMe: true,  time: '10:03 AM'),
        const _ChatMessage(text: 'Cool! Did you see the match?', isMe: false, time: '10:05 AM'),
        const _ChatMessage(text: 'Yes! It was amazing 🔥',    isMe: true,  time: '10:06 AM'),
        const _ChatMessage(text: 'Hello, free today evening?', isMe: false, time: '10:10 AM'),
        const _ChatMessage(text: 'Hi! Yes, free after 6pm 👍', isMe: true,  time: '10:11 AM'),
      ];
      _isLoading = false;
    });
  }

  String _formatMessageTime(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return _now();
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inDays > 0) {
        // Show date for older messages
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        // Show time for today's messages
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return _now();
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    
    // Add message locally for immediate feedback
    final tempMessage = _ChatMessage(
      text: text,
      isMe: true,
      time: _now(),
    );
    
    setState(() {
      _messages.add(tempMessage);
    });
    
    _msgController.clear();
    _scrollToBottom();

    try {
      final database = Database();
      
      final vendorId = await AuthService.getVendorIdString();
      
      final response = await database.getData({
        'action': 'send_dm',
        'receiver_id': widget.user.id,
        'message': text,
        'vendor_id': vendorId, // ✅ Dynamic vendor ID
      });
      
      if (response['success'] == true || response['status'] == 200) {
        // Message sent successfully - keep the local message
        print('Message sent successfully');
      } else {
        // Failed to send - remove the temporary message
        setState(() {
          _messages.remove(tempMessage);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to send message'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      
      // Remove the temporary message on error
      setState(() {
        _messages.remove(tempMessage);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error sending message'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  String _now() {
    final t = DateTime.now();
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.chatBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.8,
        shadowColor: Colors.grey.shade200,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Row(
          children: [

            // ── User avatar in app bar ─────────────────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.grey.shade200,
                  child: ClipOval(
                    child: Image.network(
                      widget.user.avatarUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.lavender.withOpacity(0.2),
                        child: const Icon(Icons.person,
                            color: AppColors.lavenderDark, size: 20),
                      ),
                    ),
                  ),
                ),
                if (widget.user.isOnline)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 11,
                      height: 11,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 10),

            // ── User name + status ────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.user.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    widget.user.isOnline
                        ? 'Online'
                        : 'Last seen ${widget.user.time} ago',
                    style: TextStyle(
                      color: widget.user.isOnline
                          ? Colors.green
                          : AppColors.textSub,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined,
                color: AppColors.lavenderDark),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.videocam_outlined,
                color: AppColors.lavenderDark),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [

          // ── Messages list ─────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.lavender),
                        SizedBox(height: 16),
                        Text(
                          'Loading messages...',
                          style: TextStyle(color: AppColors.textSub, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline, 
                                 size: 64, color: AppColors.textSub),
                            SizedBox(height: 16),
                            Text(
                              'No messages yet',
                              style: TextStyle(
                                color: AppColors.textSub,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Start the conversation!',
                              style: TextStyle(
                                color: AppColors.textSub,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadMessages,
                        color: AppColors.lavender,
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          itemCount: _messages.length,
                          itemBuilder: (_, i) => _BubbleWidget(
                            msg: _messages[i],
                            avatarUrl: widget.user.avatarUrl,
                          ),
                        ),
                      ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                              color: AppColors.textSub, fontSize: 14),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: null,
                        textCapitalization:
                            TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button — lavender
                  GestureDetector(
                    onTap: _isSending ? null : _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _isSending 
                            ? AppColors.lavender.withOpacity(0.5)
                            : AppColors.lavender,
                        shape: BoxShape.circle,
                      ),
                      child: _isSending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── MESSAGE MODEL ────────────────────────────────────────────────────────────
class _ChatMessage {
  final String text;
  final bool isMe;
  final String time;
  const _ChatMessage(
      {required this.text, required this.isMe, required this.time});
}

// ─── BUBBLE WIDGET ────────────────────────────────────────────────────────────
class _BubbleWidget extends StatelessWidget {
  final _ChatMessage msg;
  final String avatarUrl;
  const _BubbleWidget({required this.msg, required this.avatarUrl});

  @override
  Widget build(BuildContext context) {
    final isMe = msg.isMe;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [

          // Other user avatar on left
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: Image.network(
                  avatarUrl,
                  width: 32,
                  height: 32,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.lavender.withOpacity(0.2),
                    child: const Icon(Icons.person,
                        color: AppColors.lavenderDark, size: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message bubble
          Column(
            crossAxisAlignment: isMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth:
                      MediaQuery.of(context).size.width * 0.68,
                ),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  // My messages → lavender
                  // Their messages → white
                  color: isMe ? AppColors.lavender : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  msg.text,
                  style: TextStyle(
                    // My text → white, their text → dark
                    color: isMe
                        ? Colors.white
                        : AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                msg.time,
                style: const TextStyle(
                    color: AppColors.textSub, fontSize: 10),
              ),
            ],
          ),

          // My avatar on right
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }
}