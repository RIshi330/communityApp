import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/app_constants.dart' as app_constants;
import 'package:commity_app1/screens/admin/Marketplace.dart' hide AppTheme;
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';
import 'package:commity_app1/screens/admin/admin_drawer.dart';
import 'package:commity_app1/screens/admin/team_and_partner.dart' hide AppTheme;
import 'package:flutter/material.dart';

void main() {
  runApp(const UserManagementApp());
}

class UserManagementApp extends StatelessWidget {
  const UserManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'User Management',
      theme: AppTheme.theme,
      home: const UserManagementScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF7C83FD);
  static const Color primarySoft = Color(0xFFF1F2FF);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color border = Color(0xFFE6E6F0);
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);
  static const Color danger = Color(0xFFEF4444);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primary),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 20,
        ),
      ),
    );
  }
}

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  State<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen>
    with SingleTickerProviderStateMixin {
  final Database _db = Database();
  final TextEditingController _searchController = TextEditingController();

  late TabController _tabController;
  bool isListView = true;
  bool _isLoading = false;

  List<Map<String, dynamic>> _generalUsers = [];
  List<Map<String, dynamic>> _businessUsers = [];
  List<Map<String, dynamic>> _subAdmins = [];
  List<Map<String, dynamic>> _pendingApprovals = [];
  List<Map<String, dynamic>> _vendorCommunities = [];
  List<Map<String, dynamic>> _dmList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted || _tabController.indexIsChanging) return;
      setState(() {});
    });
    _loadInitialData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _callMembersApi(
    String action,
    Map<String, dynamic> payload,
  ) async {
    final requestBody = <String, dynamic>{'action': action, ...payload};
    final androidBase = app_constants.baseUrl;

    final indexCandidates = <String>[
      ...{app_constants.apiUrl},
    ];

    final membersCandidates = <String>[
      ...{
        '${androidBase}new_api/admin/members.php',
        '${androidBase}new_apis/admin/members.php',
      },
    ];

    String lastError = 'Request failed';

    for (final endpoint in indexCandidates) {
      try {
        final raw = await _db.getData(requestBody, endpointUrl: endpoint);
        final mapped = Map<String, dynamic>.from(raw);
        if (mapped['success'] == true) {
          return mapped;
        }

        lastError =
            mapped['message']?.toString() ??
            mapped['error']?.toString() ??
            lastError;
      } catch (e) {
        lastError = e.toString();
      }
    }

    for (final endpoint in membersCandidates) {
      try {
        final raw = await _db.postJsonData(requestBody, endpointUrl: endpoint);
        final mapped = Map<String, dynamic>.from(raw);
        if (mapped['success'] == true) {
          return mapped;
        }

        lastError =
            mapped['message']?.toString() ??
            mapped['error']?.toString() ??
            lastError;
      } catch (e) {
        lastError = e.toString();
      }
    }

    return {'success': false, 'message': lastError, 'data': []};
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchUsersList(),
      _fetchPendingApprovals(),
      _fetchVendorCommunities(),
      _fetchDmChatList(),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchUsersList() async {
    final res = await _callMembersApi('get_users_list', {});
    if (res['success'] == true) {
      final data = Map<String, dynamic>.from(res['data'] ?? {});
      if (!mounted) return;
      setState(() {
        _generalUsers = _safeMapList(data['general_users']);
        _businessUsers = _safeMapList(data['business_users']);
        _subAdmins = [];
      });
      return;
    }

    _showSnack(res['message']?.toString() ?? 'Failed to fetch users');
  }

  Future<void> _fetchPendingApprovals() async {
    final res = await _callMembersApi('get_pending_community_approvals', {});
    if (res['success'] == true) {
      if (!mounted) return;
      setState(() {
        _pendingApprovals = _safeMapList(res['data']);
      });
      return;
    }

    _showSnack(
      res['message']?.toString() ?? 'Failed to fetch pending approvals',
    );
  }

  Future<void> _fetchVendorCommunities() async {
    final res = await _callMembersApi('get_vendor_communities', {});
    if (res['success'] == true) {
      if (!mounted) return;
      setState(() {
        _vendorCommunities = _safeMapList(res['data']);
      });
      return;
    }

    _showSnack(res['message']?.toString() ?? 'Failed to fetch communities');
  }

  Future<void> _fetchDmChatList() async {
    final res = await _callMembersApi('dm_chat_list', {});
    if (res['success'] == true) {
      if (!mounted) return;
      setState(() {
        _dmList = _safeMapList(res['data']);
      });
      return;
    }

    _showSnack(res['message']?.toString() ?? 'Failed to fetch chats');
  }

  List<Map<String, dynamic>> _safeMapList(dynamic data) {
    if (data is! List) return [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _handleManageUser({
    required int vendorId,
    required String type,
    int? communityId,
    String role = 'member',
  }) async {
    final payload = <String, dynamic>{
      'vendor_id': vendorId,
      'type': type,
      if (communityId != null) 'community_id': communityId,
      if (type == 'add_to_community') 'role': role,
    };

    final res = await _callMembersApi('manage_user', payload);
    _showSnack(
      res['message']?.toString() ??
          (res['success'] == true ? 'Updated' : 'Failed'),
    );
    if (res['success'] == true) {
      await _loadInitialData();
    }
  }

  Future<void> _sendDirectMessage({
    required int receiverId,
    required String message,
  }) async {
    final res = await _callMembersApi('send_dm', {
      'receiver_id': receiverId,
      'message': message,
    });

    _showSnack(
      res['message']?.toString() ??
          (res['success'] == true ? 'Message sent' : 'Failed to send'),
    );
    if (res['success'] == true) {
      await _fetchDmChatList();
    }
  }

  Future<List<Map<String, dynamic>>> _fetchDmChat(int receiverId) async {
    final res = await _callMembersApi('dm_chat', {'receiver_id': receiverId});
    if (res['success'] == true) {
      return _safeMapList(res['data']);
    }

    _showSnack(res['message']?.toString() ?? 'Failed to load chat');
    return [];
  }

  Future<void> _showAddMenu(BuildContext fabContext) async {
    final button = fabContext.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(
          button.size.bottomRight(Offset.zero),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: const [
        PopupMenuItem<String>(
          value: 'marketplace_partner',
          child: Row(
            children: [
              Icon(
                Icons.storefront_outlined,
                color: AppTheme.primary,
                size: 20,
              ),
              SizedBox(width: 10),
              Text('Marketplace Partner'),
            ],
          ),
        ),
      ],
    );

    if (!mounted || selected != 'marketplace_partner') return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MarketplacePartnersScreen()),
    );
  }

  List<Map<String, dynamic>> get _activeTabUsers {
    switch (_tabController.index) {
      case 0:
        return _generalUsers;
      case 1:
        return _businessUsers;
      case 2:
      default:
        return _subAdmins;
    }
  }

  List<Map<String, dynamic>> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _activeTabUsers;

    return _activeTabUsers.where((u) {
      final name = (u['name'] ?? '').toString().toLowerCase();
      final email = (u['email'] ?? '').toString().toLowerCase();
      final mobile = (u['mobile'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          email.contains(query) ||
          mobile.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _filteredUsers;

    return Scaffold(
      drawer: const AdminDrawer(),
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          _buildDmIcon(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInitialData,
            tooltip: 'Refresh',
          ),
          const Padding(
            padding: EdgeInsets.only(right: 16, left: 8),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=100',
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadInitialData,
              child: Column(
                children: [
                  _buildApprovalSlider(),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textMuted,
                      indicatorColor: AppTheme.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: 'General Users'),
                        Tab(text: 'Business Users'),
                        Tab(text: 'Sub Admins'),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: TextField(
                              controller: _searchController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                hintText: 'Search by name, email or mobile...',
                                border: InputBorder.none,
                                icon: Icon(
                                  Icons.search,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildViewToggle(),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'USER DETAILS (${filteredUsers.length})',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                          ),
                        ),
                        const Text(
                          'COMMUNITIES',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 24, color: AppTheme.border),
                  Expanded(
                    child: filteredUsers.isEmpty
                        ? const Center(
                            child: Text(
                              'No users found',
                              style: TextStyle(color: AppTheme.textMuted),
                            ),
                          )
                        : (isListView
                              ? ListView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return _buildUserItem(user);
                                  },
                                )
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 1.4,
                                        crossAxisSpacing: 12,
                                        mainAxisSpacing: 12,
                                      ),
                                  itemCount: filteredUsers.length,
                                  itemBuilder: (context, index) {
                                    final user = filteredUsers[index];
                                    return _buildUserGridCard(user);
                                  },
                                )),
                  ),
                ],
              ),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'market',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const MarketplacePartnersScreen(),
              ),
            ),
            backgroundColor: Colors.white,
            child: const Icon(
              Icons.storefront_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'team',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const TeamPartnerManagerScreen(),
              ),
            ),
            backgroundColor: AppTheme.primarySoft,
            child: const Icon(
              Icons.group_add_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showAddMenu(context),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.person_add_alt_1, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildDmIcon() {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline),
          onPressed: _showDmListSheet,
        ),
        if (_dmList.isNotEmpty)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                _dmList.length > 99 ? '99+' : _dmList.length.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildApprovalSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Approval Queue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_pendingApprovals.length} Pending',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: _pendingApprovals.isEmpty
              ? const Center(
                  child: Text(
                    'No pending approvals',
                    style: TextStyle(color: AppTheme.textMuted),
                  ),
                )
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _pendingApprovals.length,
                  itemBuilder: (context, index) {
                    final item = _pendingApprovals[index];
                    return _approvalCard(item);
                  },
                ),
        ),
      ],
    );
  }

  Widget _approvalCard(Map<String, dynamic> request) {
    final title = (request['title'] ?? 'Community Request').toString();
    final description = (request['description'] ?? 'Pending request')
        .toString();
    final joinDate = (request['joined_at'] ?? request['created_at'] ?? '')
        .toString();

    return Container(
      width: 300,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.hourglass_top,
                  color: AppTheme.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      joinDate.isEmpty ? 'Pending' : 'Joined $joinDate',
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    final receiverId =
                        int.tryParse(request['vendor_id'].toString()) ?? 0;
                    if (receiverId > 0) {
                      _openSendDmDialog(receiverId);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primary,
                    side: const BorderSide(color: AppTheme.border),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Message', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => isListView = true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isListView ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Icon(
                Icons.list,
                color: isListView ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => isListView = false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: !isListView ? AppTheme.primary : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Icon(
                Icons.grid_view,
                color: !isListView ? Colors.white : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItem(Map<String, dynamic> user) {
    final id = int.tryParse(user['id'].toString()) ?? 0;
    final name = (user['name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final mobile = (user['mobile'] ?? '').toString();
    final approved =
        int.tryParse(user['total_approved_communities'].toString()) ?? 0;
    final pending =
        int.tryParse(user['total_pending_communities'].toString()) ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primarySoft,
            child: Text(
              _initials(name),
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  email.isEmpty ? mobile : '$email • $mobile',
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '$approved A / $pending P',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          IconButton(
            onPressed: id > 0 ? () => _openUserActions(user) : null,
            icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildUserGridCard(Map<String, dynamic> user) {
    final id = int.tryParse(user['id'].toString()) ?? 0;
    final name = (user['name'] ?? 'Unknown').toString();
    final email = (user['email'] ?? '').toString();
    final approved =
        int.tryParse(user['total_approved_communities'].toString()) ?? 0;
    final pending =
        int.tryParse(user['total_pending_communities'].toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primarySoft,
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: id > 0 ? () => _openUserActions(user) : null,
                icon: const Icon(Icons.more_horiz, size: 18),
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(
            email,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const Spacer(),
          Text(
            '$approved approved • $pending pending',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  String _initials(String text) {
    final words = text
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (words.isEmpty) return 'U';
    if (words.length == 1) return words.first[0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  Future<void> _openUserActions(Map<String, dynamic> user) async {
    final vendorId = int.tryParse(user['id'].toString()) ?? 0;
    if (vendorId <= 0) return;

    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.message_outlined),
                title: Text('Send direct message'),
                onTap: () => Navigator.pop(context, 'send_dm'),
              ),
              ListTile(
                leading: Icon(Icons.chat_outlined),
                title: Text('View chat history'),
                onTap: () => Navigator.pop(context, 'chat_history'),
              ),
              ListTile(
                leading: Icon(
                  Icons.person_off_outlined,
                  color: AppTheme.danger,
                ),
                title: Text('Suspend user'),
                onTap: () => Navigator.pop(context, 'suspend'),
              ),
              ListTile(
                leading: Icon(
                  Icons.verified_user_outlined,
                  color: AppTheme.success,
                ),
                title: Text('Activate user'),
                onTap: () => Navigator.pop(context, 'activate'),
              ),
              ListTile(
                leading: Icon(Icons.group_add_outlined),
                title: Text('Add to community'),
                onTap: () => Navigator.pop(context, 'add_to_community'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    switch (selected) {
      case 'send_dm':
        _openSendDmDialog(vendorId);
        break;
      case 'chat_history':
        _openDmChatSheet(vendorId, user['name']?.toString() ?? 'Chat');
        break;
      case 'suspend':
        _handleManageUser(vendorId: vendorId, type: 'suspend');
        break;
      case 'activate':
        _handleManageUser(vendorId: vendorId, type: 'activate');
        break;
      case 'add_to_community':
        _openAddToCommunityDialog(vendorId);
        break;
    }
  }

  Future<void> _openSendDmDialog(int receiverId) async {
    final controller = TextEditingController();
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Send Direct Message'),
          content: TextField(
            controller: controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Write your message',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (shouldSend != true) return;

    final text = controller.text.trim();
    if (text.isEmpty) {
      _showSnack('Message is required');
      return;
    }

    await _sendDirectMessage(receiverId: receiverId, message: text);
  }

  Future<void> _openAddToCommunityDialog(int vendorId) async {
    if (_vendorCommunities.isEmpty) {
      await _fetchVendorCommunities();
    }

    if (!mounted) return;

    int? selectedCommunityId;
    String selectedRole = 'member';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setLocalState) {
            return AlertDialog(
              title: const Text('Add User To Community'),
              content: SizedBox(
                width: 420,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<int>(
                      value: selectedCommunityId,
                      isExpanded: true,
                      items: _vendorCommunities.map((c) {
                        final id = int.tryParse(c['id'].toString()) ?? 0;
                        final title = (c['title'] ?? 'Community').toString();
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(title, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          setLocalState(() => selectedCommunityId = val),
                      decoration: const InputDecoration(
                        labelText: 'Community',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      items: const [
                        DropdownMenuItem(
                          value: 'member',
                          child: Text('member'),
                        ),
                        DropdownMenuItem(
                          value: 'moderator',
                          child: Text('moderator'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('admin')),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setLocalState(() => selectedRole = val);
                      },
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedCommunityId == null ||
                        selectedCommunityId! <= 0) {
                      _showSnack('Select a community');
                      return;
                    }
                    Navigator.pop(context, true);
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || selectedCommunityId == null) return;

    await _handleManageUser(
      vendorId: vendorId,
      type: 'add_to_community',
      communityId: selectedCommunityId,
      role: selectedRole,
    );
  }

  Future<void> _showDmListSheet() async {
    await _fetchDmChatList();
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Direct Messages',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _dmList.isEmpty
                      ? const Center(
                          child: Text(
                            'No conversations yet',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _dmList.length,
                          itemBuilder: (context, index) {
                            final item = _dmList[index];
                            final userId =
                                int.tryParse(item['user_id'].toString()) ?? 0;
                            final name = (item['name'] ?? 'User').toString();
                            final lastTime = (item['last_msg_time'] ?? '')
                                .toString();

                            return ListTile(
                              leading: const CircleAvatar(
                                child: Icon(Icons.person_outline),
                              ),
                              title: Text(name),
                              subtitle: Text(lastTime),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: userId <= 0
                                  ? null
                                  : () {
                                      Navigator.pop(context);
                                      _openDmChatSheet(userId, name);
                                    },
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openDmChatSheet(int receiverId, String title) async {
    final messages = await _fetchDmChat(receiverId);
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.72,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openSendDmDialog(receiverId);
                        },
                        child: const Text('Send Message'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: messages.isEmpty
                      ? const Center(
                          child: Text(
                            'No messages found',
                            style: TextStyle(color: AppTheme.textMuted),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: messages.length,
                          itemBuilder: (context, index) {
                            final item = messages[index];
                            final message = (item['message'] ?? '').toString();
                            final senderName = (item['name'] ?? 'User')
                                .toString();
                            final created = (item['created_date'] ?? '')
                                .toString();

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    senderName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(message),
                                  const SizedBox(height: 6),
                                  Text(
                                    created,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
