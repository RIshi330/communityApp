import 'package:flutter/material.dart';
import 'package:commity_app1/screens/admin/admin_bottom_navigation.dart';
import 'package:commity_app1/screens/admin/Marketplace.dart' hide AppTheme;

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
        title: const Text('Team & Partner'),
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
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplacePartnersScreen())),
            backgroundColor: AppTheme.primarySoft,
            child: const Icon(Icons.storefront_outlined, color: AppTheme.primary),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'add',
            onPressed: () => _showInviteModal(),
            backgroundColor: AppTheme.primary,
            child: const Icon(Icons.person_add_alt_1, color: Colors.white),
          ),
        ],
      ),
      bottomNavigationBar: const AdminBottomNavigation(currentIndex: 2),
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

  void _showInviteModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.mail_outline, color: AppTheme.primary)),
              const SizedBox(width: 12),
              const Text('Invite Member', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ]),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 20),
          _modalField('Full Name', 'Johnathan Smith'),
          _modalField('Email Address', 'john@company.com'),
          Row(children: [
            Expanded(child: _modalDropdown('Assign Role', ['Manager', 'Admin', 'Editor', 'Viewer'])),
            const SizedBox(width: 12),
            Expanded(child: _modalDropdown('Member Type', ['Team', 'Partner'])),
          ]),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(ctx), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppTheme.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Cancel'))),
            const SizedBox(width: 12),
            Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Send Invitation', style: TextStyle(fontWeight: FontWeight.bold)))),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  void _showChatModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(16)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Row(children: const [Icon(Icons.chat_bubble_outline, color: Colors.white), SizedBox(width: 8), Text('New Message', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))]),
              IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(ctx)),
            ]),
          ),
          const SizedBox(height: 16),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: AppTheme.primarySoft, borderRadius: BorderRadius.circular(10)),
            child: const Row(children: [Text('To: ', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)), Text('Member Workspace', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w600))]),
          ),
          const SizedBox(height: 12),
          TextField(maxLines: 4, decoration: InputDecoration(hintText: 'Type your message here...', filled: true, fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(icon: const Icon(Icons.attach_file, color: AppTheme.textMuted), onPressed: () {}),
            IconButton(icon: const Icon(Icons.mood, color: AppTheme.textMuted), onPressed: () {}),
            const Spacer(),
            ElevatedButton.icon(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.send, size: 16), label: const Text('Send'), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showTaskModal() {
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Assign New Task', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 16),
          const Text('Quick Select', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(border: Border.all(color: AppTheme.border), borderRadius: BorderRadius.circular(12)),
            child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, hint: const Text('Select predefined task...'), items: ['Review Design Specs', 'Weekly Performance Sync', 'Q3 Roadmap Planning'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (_) {})),
          ),
          const SizedBox(height: 16),
          Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('OR', style: TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold))), const Expanded(child: Divider())]),
          const SizedBox(height: 16),
          const Text('Create Custom Task', style: TextStyle(fontSize: 12, color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(decoration: InputDecoration(hintText: 'Task title...', filled: true, fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 8),
          TextField(maxLines: 3, decoration: InputDecoration(hintText: 'Task description...', filled: true, fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => Navigator.pop(ctx), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Assign Task', style: TextStyle(fontWeight: FontWeight.bold)))),
          const SizedBox(height: 12),
        ]),
      ),
    );
  }

  Widget _modalField(String label, String hint) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
      const SizedBox(height: 6),
      TextField(decoration: InputDecoration(hintText: hint, filled: true, fillColor: AppTheme.surface, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
    ]));
  }

  Widget _modalDropdown(String label, List<String> items) {
    return Padding(padding: const EdgeInsets.only(bottom: 14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textMuted)),
      const SizedBox(height: 6),
      Container(padding: const EdgeInsets.symmetric(horizontal: 12), decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(child: DropdownButton<String>(isExpanded: true, value: items.first, items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(), onChanged: (_) {})),
      ),
    ]));
  }
}
