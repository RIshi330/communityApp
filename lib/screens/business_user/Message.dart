import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

import '../../app_constants.dart';

// ==================== API SERVICE ====================

class ChatApiService {
  // ⚠️ REPLACE WITH YOUR ACTUAL API URL
  static const String Url = '${baseUrl}new_apis/chat_manager_api.php';

  static int currentVendorId = 2; // TODO: set from login response

  static Future<Map<String, dynamic>> postRequest(String action, Map<String, dynamic> data) async {
    try {
      // final response = await http.post(
      //   Uri.parse(Url),
      //   body: {
      //     'action': action,
      //     ...data.map((key, value) => MapEntry(key, value.toString())),
      //   },
      // );
      print("Chat URL = $Url");
      final response = await http.post(
        Uri.parse(Url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': action,
          ...data,
        }),
      );
      print('Action: $action');
      print('Status: ${response.statusCode}');
      print('Body: ${response.body}');      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
      return {'success': false, 'message': 'Server error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<List<dynamic>> getConversations({String search = ''}) async {
    final result = await postRequest('dm_senders_list', {'search': search});
    if (result['success'] == true) {
      return result['data'] ?? [];
    }
    return [];
  }

  static Future<List<dynamic>> getChatMessages(int senderId) async {
    final result = await postRequest('dm_chat', {'sender_id': senderId});
    if (result['success'] == true) {
      return result['data'] ?? [];
    }
    return [];
  }

  static Future<bool> sendMessage(int receiverId, String message) async {
    final result = await postRequest('send_dm', {
      'receiver_id': receiverId,
      'message': message,
    });
    return result['success'] == true;
  }

  static Future<bool> shareProduct(int receiverId, int productId, int siteId) async {
    final result = await postRequest('share_product', {
      'sender': currentVendorId,
      'receiver': receiverId,
      'site_id': siteId,
      'product_id': productId,
    });
    return result['success'] == true;
  }
}

// ==================== MODELS ====================

class Conversation {
  final int userId;
  final String name;
  final String lastMessage;
  final String lastMessageTime;
  final int unreadCount;
  final String? profilePic;

  Conversation({
    required this.userId,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.unreadCount,
    this.profilePic,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      lastMessage: json['message'] ?? '',
      lastMessageTime: _formatTime(json['created_date']),
      unreadCount: json['unread_count'] ?? 0,
      profilePic: json['profile_pic'],
    );
  }

  static String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      final now = DateTime.now();
      final diff = now.difference(dateTime);

      if (diff.inDays == 0) {
        return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return days[dateTime.weekday - 1];
      } else {
        return '${dateTime.day}/${dateTime.month}';
      }
    } catch (e) {
      return '';
    }
  }

  String getInitials() {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color getAvatarColor() {
    final colors = [
      const Color(0xFF474DC5), const Color(0xFF5C5E69), const Color(0xFF805200),
      const Color(0xFFE91E63), const Color(0xFF00BCD4), const Color(0xFF4CAF50),
      const Color(0xFFFF9800), const Color(0xFF9C27B0),
    ];
    return colors[userId % colors.length];
  }
}

class ChatMessage {
  final int id;
  final String text;
  final bool isUser;
  final String time;
  final bool isRead;
  final String? msgType;
  final Map<String, dynamic>? sharedProduct;
  final String? attachment;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.time,
    this.isRead = false,
    this.msgType,
    this.sharedProduct,
    this.attachment,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json, int currentUserId) {
    final sender = json['sender'] ?? 0;
    final isUser = sender == currentUserId;
    final msgType = json['msg_type'] ?? 'direct_message';

    String displayText = json['message'] ?? '';

    if (msgType == 'PRODUCT_SHARE' && json['shared_product'] != null) {
      displayText = '📦 Shared a product';
    } else if (msgType == 'CATALOGUE_SHARE') {
      displayText = '📁 Shared a catalogue';
    }

    return ChatMessage(
      id: json['id'] ?? 0,
      text: displayText,
      isUser: isUser,
      time: _formatTime(json['created_date']),
      isRead: (json['is_read'] ?? '0') == '1',
      msgType: msgType,
      sharedProduct: json['shared_product'],
      attachment: json['attachment'],
    );
  }

  static String _formatTime(String? dateTimeStr) {
    if (dateTimeStr == null) return '';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  bool get hasProductCard => msgType == 'PRODUCT_SHARE' && sharedProduct != null;
  bool get hasFileAttachment => msgType == 'CATALOGUE_SHARE' && attachment != null && attachment!.isNotEmpty;
}

// ==================== MAIN CHAT SCREEN ====================

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  bool _isLoading = true;
  bool _isLoadingMessages = false;
  List<Conversation> _conversations = [];
  List<ChatMessage> _messages = [];

  Conversation? _selectedConversation;
  Timer? _typingTimer;
  bool _otherUserTyping = false;

  // For responsive design
  bool _isDesktop = true;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadConversations() async {
    setState(() => _isLoading = true);
    final data = await ChatApiService.getConversations(search: _searchQuery);
    setState(() {
      _conversations = data.map((item) => Conversation.fromJson(item)).toList();
      _isLoading = false;
    });
  }

  Future<void> _loadMessages(Conversation conversation) async {
    setState(() {
      _selectedConversation = conversation;
      _isLoadingMessages = true;
    });

    final data = await ChatApiService.getChatMessages(conversation.userId);

    setState(() {
      _messages = data.map((item) => ChatMessage.fromJson(item, ChatApiService.currentVendorId)).toList();
      _isLoadingMessages = false;
    });

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty || _selectedConversation == null) return;

    final messageText = _messageController.text.trim();
    final tempId = DateTime.now().millisecondsSinceEpoch;

    // Optimistic update
    setState(() {
      _messages.add(ChatMessage(
        id: tempId,
        text: messageText,
        isUser: true,
        time: _getCurrentTime(),
        isRead: false,
      ));
      _messageController.clear();
    });
    _scrollToBottom();

    // Send to API
    final success = await ChatApiService.sendMessage(_selectedConversation!.userId, messageText);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send message')),
      );
    }
  }

  String _getCurrentTime() {
    final now = DateTime.now();
    return '${now.hour}:${now.minute.toString().padLeft(2, '0')}';
  }

  void _showProductShareDialog() {
    final TextEditingController productIdController = TextEditingController();
    final TextEditingController siteIdController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Share Product', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: productIdController,
              decoration: InputDecoration(
                hintText: 'Product ID',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.shopping_bag, color: Color(0xFF474DC5)),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: siteIdController,
              decoration: InputDecoration(
                hintText: 'Site ID (5 = B2C, 6 = B2B)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.store, color: Color(0xFF474DC5)),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () async {
              final productId = int.tryParse(productIdController.text);
              final siteId = int.tryParse(siteIdController.text);

              if (productId != null && siteId != null && _selectedConversation != null) {
                Navigator.pop(context);

                final success = await ChatApiService.shareProduct(
                  _selectedConversation!.userId,
                  productId,
                  siteId,
                );

                if (success) {
                  setState(() {
                    _messages.add(ChatMessage(
                      id: DateTime.now().millisecondsSinceEpoch,
                      text: '📦 Shared a product',
                      isUser: true,
                      time: _getCurrentTime(),
                      msgType: 'PRODUCT_SHARE',
                    ));
                  });
                  _scrollToBottom();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product shared successfully!'), backgroundColor: Colors.green),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to share product'), backgroundColor: Colors.red),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter valid Product ID and Site ID')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF474DC5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Share'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    _isDesktop = screenWidth > 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FF),
      appBar: _isDesktop ? null : _buildMobileAppBar(),
      body: SafeArea(
        child: _isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  PreferredSizeWidget _buildMobileAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Messages',
        style: TextStyle(color: Color(0xFF151C27), fontWeight: FontWeight.bold),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: _buildSearchBar(),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Conversations List (Left Panel)
        Container(
          width: 320,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(right: BorderSide(color: Color(0xFFE6E6F0))),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Row(
                      children: [
                        Text(
                          'Messages',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF151C27)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildSearchBar(),
                  ],
                ),
              ),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF474DC5)))
                    : _conversations.isEmpty
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFE6E6F0)),
                      SizedBox(height: 12),
                      Text('No conversations yet', style: TextStyle(color: Color(0xFF6B7280))),
                    ],
                  ),
                )
                    : ListView.builder(
                  itemCount: _conversations.length,
                  itemBuilder: (context, index) => _buildConversationItem(_conversations[index]),
                ),
              ),
            ],
          ),
        ),

        // Chat Area (Right Panel)
        Expanded(
          child: _selectedConversation == null
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFF474DC5)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Select a conversation',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a chat to start messaging',
                  style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                ),
              ],
            ),
          )
              : Column(
            children: [
              _buildChatHeader(),
              Expanded(
                child: _isLoadingMessages
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF474DC5)))
                    : Stack(
                  children: [
                    ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                    ),
                    if (_otherUserTyping) _buildTypingIndicator(),
                  ],
                ),
              ),
              _buildMessageInput(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    if (_selectedConversation == null) {
      // Show conversations list
      return Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF474DC5)))
                : _conversations.isEmpty
                ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 48, color: Color(0xFFE6E6F0)),
                  SizedBox(height: 12),
                  Text('No conversations yet', style: TextStyle(color: Color(0xFF6B7280))),
                ],
              ),
            )
                : ListView.builder(
              itemCount: _conversations.length,
              itemBuilder: (context, index) => _buildConversationItem(_conversations[index]),
            ),
          ),
        ],
      );
    } else {
      // Show chat screen
      return Column(
        children: [
          _buildMobileChatHeader(),
          Expanded(
            child: _isLoadingMessages
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF474DC5)))
                : Stack(
              children: [
                ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                ),
                if (_otherUserTyping) _buildTypingIndicator(),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
      );
    }
  }

  Widget _buildMobileChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E6F0))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF474DC5)),
            onPressed: () => setState(() => _selectedConversation = null),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedConversation?.getAvatarColor(),
            ),
            child: Center(
              child: Text(
                _selectedConversation?.getInitials() ?? '?',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedConversation?.name ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const Text('Online', style: TextStyle(fontSize: 11, color: Colors.green)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share, color: Color(0xFF474DC5)),
            onPressed: _showProductShareDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6F0)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() => _searchQuery = value);
          _loadConversations();
        },
        decoration: InputDecoration(
          hintText: 'Search conversations...',
          hintStyle: const TextStyle(fontSize: 14, color: Color(0xFF767685)),
          prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF767685)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 20),
            onPressed: () {
              setState(() => _searchQuery = '');
              _searchController.clear();
              _loadConversations();
            },
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildConversationItem(Conversation conv) {
    final isSelected = _selectedConversation?.userId == conv.userId;

    return GestureDetector(
      onTap: () => _loadMessages(conv),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F3FF) : Colors.white,
          border: Border(bottom: BorderSide(color: const Color(0xFFE6E6F0))),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: conv.getAvatarColor(),
                  ),
                  child: Center(
                    child: Text(
                      conv.getInitials(),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conv.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: conv.unreadCount > 0 ? FontWeight.w700 : FontWeight.w500,
                      color: const Color(0xFF151C27),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conv.lastMessage,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                      color: conv.unreadCount > 0 ? const Color(0xFF151C27) : const Color(0xFF6B7280),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  conv.lastMessageTime,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                ),
                if (conv.unreadCount > 0) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF474DC5),
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                    ),
                    child: Text(
                      conv.unreadCount.toString(),
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatHeader() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE6E6F0))),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _selectedConversation?.getAvatarColor(),
            ),
            child: Center(
              child: Text(
                _selectedConversation?.getInitials() ?? '?',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedConversation?.name ?? '',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF151C27)),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 13, color: Colors.green),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.shopping_bag, color: Color(0xFF474DC5), size: 22),
              onPressed: _showProductShareDialog,
              tooltip: 'Share Product',
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F3FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF474DC5), size: 22),
              onPressed: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * (message.isUser ? 0.7 : 0.75)),
        child: Column(
          crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser ? const Color(0xFF474DC5) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                  bottomRight: Radius.circular(message.isUser ? 4 : 16),
                ),
                border: message.isUser ? null : Border.all(color: const Color(0xFFE6E6F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: message.isUser ? Colors.white : const Color(0xFF151C27),
                    ),
                  ),
                  if (message.hasProductCard && message.sharedProduct != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () {
                          // Navigate to product detail
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('View product: ${message.sharedProduct!['name'] ?? 'Product'}')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE6E6F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: message.sharedProduct!['image'] != null &&
                                    message.sharedProduct!['image'].toString().isNotEmpty
                                    ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    message.sharedProduct!['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 24, color: Color(0xFF474DC5)),
                                  ),
                                )
                                    : const Icon(Icons.shopping_bag, size: 24, color: Color(0xFF474DC5)),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      message.sharedProduct!['name'] ?? 'Product',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF151C27)),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap to view details →',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF474DC5)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (message.hasFileAttachment && message.attachment != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Downloading catalogue...')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFE6E6F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFDAD6).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.description, color: Color(0xFFBA1A1A), size: 28),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Catalogue', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                    Text('Tap to download', style: TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                                  ],
                                ),
                              ),
                              const Icon(Icons.download, color: Color(0xFF474DC5), size: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(message.time, style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280))),
                if (message.isUser && message.isRead)
                  const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.done_all, size: 12, color: Color(0xFF6B7280)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE6E6F0))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showProductShareDialog,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_bag, color: Color(0xFF474DC5), size: 22),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F3FF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF474DC5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Positioned(
      bottom: 20,
      left: 20,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6E6F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 30,
              child: Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF474DC5)),
                  SizedBox(width: 4),
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF474DC5)),
                  SizedBox(width: 4),
                  CircleAvatar(radius: 4, backgroundColor: Color(0xFF474DC5)),
                ],
              ),
            ),
            SizedBox(width: 8),
            Text('Typing...', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}