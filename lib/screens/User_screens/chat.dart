import 'dart:convert';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── COLORS ───────────────────────────────────────────────────────────────────
class AppColors {
  static const lavender = Color(0xFFB39DDB);
  static const lavenderDark = Color(0xFF7E57C2);
  static const textPrimary = Color(0xFF1A1A1A);
  static const textSub = Color(0xFF888888);
  static const divider = Color(0xFFF0F0F0);
  static const chatBg = Color(0xFFF8F6FC);
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
  List<ChatUser> _fetchedChats = [];

  Future<void> fetchChatList() async {
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'dm_chat_list',
      }, endpointUrl: '${baseUrl}new_apis/admin/manage_user_api.php');

      print('Chat list response: $response');

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> chatsData = response['data'] ?? [];
        final parsedChats = <ChatUser>[];

        for (final chatData in chatsData) {
          try {
            parsedChats.add(
              ChatUser(
                id: chatData['user_id'].toString(),
                name: chatData['name'] ?? 'Unknown',
                lastMessage: 'Tap to start chatting',
                time: _formatTime(chatData['last_msg_time'] ?? ''),
                avatarUrl: chatData['profile_pic'] ?? '',
                isUnread: false,
                isOnline: false,
              ),
            );
          } catch (e) {
            print('Error parsing chat: $e');
          }
        }

        setState(() {
          _fetchedChats = parsedChats;
          print('Fetched ${parsedChats.length} chats');
        });
      } else {
        print('Error: ${response['error']}');
      }
    } catch (e) {
      debugPrint('Error fetching chat list: $e');
    }
  }

  // Format timestamp to relative time (e.g., "1h ago", "2d ago")
  String _formatTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return 'now';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return dateTime.toString().split(' ')[0]; // Return date
      }
    } catch (e) {
      return 'now';
    }
  }

  List<ChatUser> get _allChats {
    // Use fetched chats, fallback to sample chats if empty
    final base = List<ChatUser>.from(_fetchedChats);

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
        .where((u) => u.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void initState() {
    super.initState();
    fetchChatList();
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
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search messages...',
                    hintStyle: const TextStyle(
                      color: AppColors.textSub,
                      fontSize: 14,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textSub,
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),
            ),

            // ── Chat List ─────────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  indent: 82,
                  color: AppColors.divider,
                ),
                itemBuilder: (ctx, i) => _ChatTile(user: _filtered[i]),
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
                        child: const Icon(
                          Icons.person,
                          color: AppColors.lavenderDark,
                        ),
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
                        border: Border.all(color: Colors.white, width: 2),
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
                Text(
                  user.time,
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 12,
                  ),
                ),
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
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  List<_ChatMessage> _messages = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchChatMessages();
  }

  Future<void> fetchChatMessages() async {
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'dm_chat',
        'receiver_id': widget.user.id,
      }, endpointUrl: '${baseUrl}new_apis/admin/manage_user_api.php');

      print('Chat messages response: $response');

      if (response.containsKey('data') && response['data'] is List) {
        final List<dynamic> messagesData = response['data'] ?? [];
        final parsedMessages = <_ChatMessage>[];

        for (final msgData in messagesData) {
          try {
            // Convert sender and receiver to int safely
            final sender = int.tryParse(msgData['sender'].toString()) ?? 0;
            final receiver = int.tryParse(msgData['receiver'].toString()) ?? 0;

            // Determine if message is from current user
            final isSenderMe = sender != receiver;

            parsedMessages.add(
              _ChatMessage(
                id: msgData['id'].toString(),
                text: msgData['message'] ?? '',
                isMe: isSenderMe,
                time: _formatMessageTime(msgData['created_date'] ?? ''),
                senderName: msgData['name'] ?? 'Unknown',
                senderAvatar: msgData['profile_pic'] ?? '',
                status: int.tryParse(msgData['status'].toString()) ?? 1,
              ),
            );
          } catch (e) {
            print('Error parsing message: $e');
          }
        }

        setState(() {
          _messages = parsedMessages;
          _isLoading = false;
          print('Fetched ${parsedMessages.length} messages');
        });

        // Scroll to bottom after loading messages
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } else {
        print('Error: ${response['error']}');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching chat messages: $e');
      setState(() => _isLoading = false);
    }
  }

  // Format message time to human-readable format (e.g., "10:30 AM")
  String _formatMessageTime(String dateTimeStr) {
    if (dateTimeStr.isEmpty) return 'now';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final h = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
      final m = dateTime.minute.toString().padLeft(2, '0');
      return '$h:$m ${dateTime.hour < 12 ? 'AM' : 'PM'}';
    } catch (e) {
      return 'now';
    }
  }

  void _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;

    // Clear input field immediately
    _msgController.clear();

    // Add message to UI optimistically
    final tempMessage = _ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      isMe: true,
      time: _formatMessageTime(DateTime.now().toString()),
      senderName: 'You',
      senderAvatar: '',
      status: 1,
    );

    setState(() {
      _messages.add(tempMessage);
    });

    // Scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    // Send to API
    try {
      final database = Database();
      final response = await database.getData({
        'action': 'send_dm',
        'receiver_id': widget.user.id,
        'message': text,
      }, endpointUrl: '${baseUrl}new_apis/admin/manage_user_api.php');

      print('Send message response: $response');

      if (response.containsKey('success') && response['success'] == true) {
        print('Message sent successfully');
        // Message was already added optimistically, no need to update
      } else {
        // Remove the message if sending failed
        setState(() {
          _messages.removeWhere((m) => m.id == tempMessage.id);
        });
        _showErrorSnackbar(
          'Failed to send message: ${response['error'] ?? 'Unknown error'}',
        );
      }
    } catch (e) {
      print('Error sending message: $e');
      // Remove the message if sending failed
      setState(() {
        _messages.removeWhere((m) => m.id == tempMessage.id);
      });
      _showErrorSnackbar('Error sending message: $e');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
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
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 18,
          ),
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
                        child: const Icon(
                          Icons.person,
                          color: AppColors.lavenderDark,
                          size: 20,
                        ),
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
                        border: Border.all(color: Colors.white, width: 2),
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
            icon: const Icon(
              Icons.call_outlined,
              color: AppColors.lavenderDark,
            ),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(
              Icons.videocam_outlined,
              color: AppColors.lavenderDark,
            ),
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
                    child: CircularProgressIndicator(
                      color: AppColors.lavenderDark,
                    ),
                  )
                : _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(color: AppColors.textSub, fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) => _BubbleWidget(
                      msg: _messages[i],
                      avatarUrl: widget.user.avatarUrl,
                    ),
                  ),
          ),

          // ── Input bar ─────────────────────────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Text input
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _msgController,
                        focusNode: _focusNode,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(
                            color: AppColors.textSub,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Send button — lavender
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: AppColors.lavender,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
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
  final String id;
  final String text;
  final bool isMe;
  final String time;
  final String senderName;
  final String senderAvatar;
  final int status; // 0 = unread, 1 = read

  const _ChatMessage({
    required this.id,
    required this.text,
    required this.isMe,
    required this.time,
    required this.senderName,
    required this.senderAvatar,
    this.status = 1,
  });
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
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Other user avatar on left
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.grey.shade200,
              child: ClipOval(
                child: msg.senderAvatar.isNotEmpty
                    ? Image.network(
                        msg.senderAvatar,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: AppColors.lavender.withOpacity(0.2),
                          child: const Icon(
                            Icons.person,
                            color: AppColors.lavenderDark,
                            size: 16,
                          ),
                        ),
                      )
                    : Container(
                        color: AppColors.lavender.withOpacity(0.2),
                        child: const Icon(
                          Icons.person,
                          color: AppColors.lavenderDark,
                          size: 16,
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
                  maxWidth: MediaQuery.of(context).size.width * 0.68,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
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
                    color: isMe ? Colors.white : AppColors.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                msg.time,
                style: const TextStyle(color: AppColors.textSub, fontSize: 10),
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
