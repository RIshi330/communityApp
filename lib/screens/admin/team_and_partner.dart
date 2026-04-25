import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';

void main() {
  runApp(const AdminDashboardApp());
}

class AdminDashboardApp extends StatelessWidget {
  const AdminDashboardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lavender Admin',
      theme: AppTheme.theme,
      home: const TeamPartnerManagerScreen(),
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
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class TeamPartnerManagerScreen extends StatefulWidget {
  const TeamPartnerManagerScreen({super.key});

  @override
  State<TeamPartnerManagerScreen> createState() =>
      _TeamPartnerManagerScreenState();
}

class _TeamPartnerManagerScreenState extends State<TeamPartnerManagerScreen> {
  bool isListView = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Admin Dashboard'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?auto=format&fit=crop&q=80&w=100',
              ),
              backgroundColor: AppTheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Team Management',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const Text(
                    'Manage your internal team and external partnerships seamlessly.',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // System Suggested Profiles Section
            _buildSuggestedSection(),

            const SizedBox(height: 32),

            // Active Members Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Active Members',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textMain,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildViewToggle(),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppTheme.border),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              icon: Icon(
                                Icons.search,
                                color: AppTheme.textMuted,
                                size: 20,
                              ),
                              hintText: 'Search members...',
                              border: InputBorder.none,
                              hintStyle: TextStyle(fontSize: 14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Members Table/List
            isListView ? _buildMembersList() : _buildMembersGrid(),

            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'market',
            onPressed: () {},
            backgroundColor: AppTheme.primarySoft,
            child: const Icon(
              Icons.storefront_outlined,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () {},
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.person_add_alt_1, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 1),
    );
  }

  Widget _buildSuggestedSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4FF),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'System Suggested Profiles',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSuggestedCard(
                  'Jane Doe',
                  'Product Architect',
                  'PARTNER',
                  'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&q=80&w=200',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSuggestedCard(
                  'Marcus King',
                  'Backend Expert',
                  'TEAM',
                  'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=200',
                  isInviteSent: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestedCard(
    String name,
    String role,
    String type,
    String img, {
    bool isInviteSent = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 35, backgroundImage: NetworkImage(img)),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.primarySoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role,
              style: const TextStyle(
                color: AppTheme.primary,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            type,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: isInviteSent
                    ? AppTheme.primarySoft
                    : AppTheme.primary,
                foregroundColor: isInviteSent ? AppTheme.primary : Colors.white,
                elevation: 0,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                isInviteSent ? 'Invite Sent' : 'Invite',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2FF),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => setState(() => isListView = true),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isListView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: isListView
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.list_rounded,
                size: 20,
                color: isListView ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => setState(() => isListView = false),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: !isListView ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                boxShadow: !isListView
                    ? [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                Icons.grid_view_rounded,
                size: 20,
                color: !isListView ? AppTheme.primary : AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          _buildMemberRow(
            'Alex Long',
            'alex.l@lavender.com',
            'TEAM',
            'Admin',
            'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=100',
          ),
          const Divider(height: 1, color: AppTheme.border),
          _buildMemberRow(
            'Benson Wei',
            'benson.w@lavender.com',
            'PARTNER',
            'Manager',
            'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=100',
          ),
        ],
      ),
    );
  }

  Widget _buildMemberRow(
    String name,
    String email,
    String type,
    String role,
    String img,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.all(16),
      leading: CircleAvatar(backgroundImage: NetworkImage(img)),
      title: Text(
        name,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
      subtitle: Text(
        email,
        style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                type,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMuted,
                ),
              ),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          _buildActionMenu(),
        ],
      ),
    );
  }

  Widget _buildActionMenu() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: AppTheme.textMuted),
      onSelected: (val) {
        if (val == 'message') _showChatModal();
        if (val == 'task') _showTaskModal();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'team', child: Text('Add to Team')),
        const PopupMenuItem(value: 'role', child: Text('Assign Role')),
        const PopupMenuItem(value: 'message', child: Text('Message')),
        const PopupMenuItem(value: 'task', child: Text('Assign Task')),
        const PopupMenuItem(
          value: 'suspend',
          child: Text('Suspend', style: TextStyle(color: AppTheme.error)),
        ),
      ],
    );
  }

  Widget _buildMembersGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      childAspectRatio: 0.8,
      children: [
        _buildMemberGridCard(
          'Alex Long',
          'TEAM',
          'Admin',
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&q=80&w=100',
        ),
        _buildMemberGridCard(
          'Benson Wei',
          'PARTNER',
          'Manager',
          'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&q=80&w=100',
        ),
      ],
    );
  }

  Widget _buildMemberGridCard(
    String name,
    String type,
    String role,
    String img,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundImage: NetworkImage(img)),
          const SizedBox(height: 12),
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            role,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          Text(
            type,
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildActionMenu(),
        ],
      ),
    );
  }

  void _showChatModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'Send Message',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Expanded(
              child: Center(child: Text('Chat Interface Placeholder')),
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assign Task',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Task from List',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            _buildTaskItem('Verify New Communities'),
            _buildTaskItem('Review Flagged Content'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Create New Task'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(String title) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(
        Icons.check_circle_outline,
        color: AppTheme.textMuted,
      ),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: () {},
    );
  }
}
