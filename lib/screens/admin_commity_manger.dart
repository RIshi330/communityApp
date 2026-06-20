import 'package:commity_app1/screens/commity_Manage.dart';
import 'package:commity_app1/screens/create_community_screen.dart'
    hide InviteMembersScreen;
import 'package:commity_app1/screens/feed_screen.dart';
import 'package:commity_app1/screens/invite_member_screen.dart';
import 'package:commity_app1/screens/promotion/package_manage.dart';
import 'package:commity_app1/screens/promation_engine.dart';
import 'package:commity_app1/screens/promationschedular.dart';
import 'package:commity_app1/screens/wallet_screen.dart';
import 'package:commity_app1/screens/seller_bank_accounts_screen.dart';
import 'package:flutter/material.dart';

class AdminCommunityManagerScreen extends StatefulWidget {
  final String groupName;
  final String privacy;

  const AdminCommunityManagerScreen({
    super.key,
    required this.groupName,
    required this.privacy,
  });

  @override
  State<AdminCommunityManagerScreen> createState() =>
      _AdminCommunityManagerScreenState();
}

class _AdminCommunityManagerScreenState
    extends State<AdminCommunityManagerScreen> {
  bool communityExpanded = false;
  bool membersExpanded = false;
  bool postsExpanded = false;
  bool monetizationExpanded = false;
  bool promotionsExpanded = false;
  bool paymentsExpanded = false;
  bool insightsExpanded = false;

  int pendingRequests = 24;
  int reportedPosts = 3;
  int livePromotions = 2;

  bool get isPrivate => widget.privacy == 'Private';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xff8F7CFF),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.groupName,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isPrivate
                      ? Colors.orange.withValues(alpha: 0.85)
                      : Colors.green.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPrivate ? Icons.lock_outline : Icons.public,
                      size: 11,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.privacy,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _expandableSection(
            title: "Community Info",
            icon: Icons.info_outline,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: Colors.blue,
            expanded: communityExpanded,
            toggle: () =>
                setState(() => communityExpanded = !communityExpanded),
            children: [
              _subTile(
                "Create Community",
                const CreateCommunityScreen(openCommunityHomeOnCreate: true),
              ),
              _subTile(
                "Invite Members",
                InviteMembersScreen(
                  groupName: widget.groupName,
                  privacy: widget.privacy,
                ),
              ),
            ],
          ),

          _expandableSection(
            title: "Members",
            icon: Icons.people_outline,
            iconBg: const Color(0xFFF3E5F5),
            iconColor: Colors.purple,
            expanded: membersExpanded,
            badge: pendingRequests.toString(),
            toggle: () => setState(() => membersExpanded = !membersExpanded),
            children: [
              _subTile(
                "Manage Members",
                InviteMembersScreen(
                  groupName: widget.groupName,
                  privacy: widget.privacy,
                ),
              ),
              _subTile(
                "Pending Requests",
                InviteMembersScreen(
                  groupName: widget.groupName,
                  privacy: widget.privacy,
                ),
              ),
            ],
          ),

          _expandableSection(
            title: "Posts & Moderation",
            icon: Icons.article_outlined,
            iconBg: const Color(0xFFFFF3E0),
            iconColor: Colors.orange,
            expanded: postsExpanded,
            badge: reportedPosts.toString(),
            toggle: () => setState(() => postsExpanded = !postsExpanded),
            children: [
              _subTile(
                "All Posts",
                CommunityPrivateAdminView(
                  groupName: widget.groupName,
                  privacy: widget.privacy,
                ),
              ),
              _subTile(
                "Reported Posts",
                CommunityPrivateAdminView(
                  groupName: widget.groupName,
                  privacy: widget.privacy,
                ),
              ),
            ],
          ),

          _expandableSection(
            title: "Monetization",
            icon: Icons.currency_rupee,
            iconBg: const Color(0xFFE8F5E9),
            iconColor: Colors.green,
            expanded: monetizationExpanded,
            toggle: () =>
                setState(() => monetizationExpanded = !monetizationExpanded),
            children: [
              _subTile("Manage Package", const ManagePackagesScreen()),
              _subTile("Package Orders", const ManagePackagesScreen()),
            ],
          ),

          _expandableSection(
            title: "Promotions & Ads",
            icon: Icons.campaign_outlined,
            iconBg: const Color(0xFFFFEBEE),
            iconColor: Colors.red,
            expanded: promotionsExpanded,
            badge: livePromotions.toString(),
            toggle: () =>
                setState(() => promotionsExpanded = !promotionsExpanded),
            children: [
              _subTile("Promotion Scheduler", PromotionSchedulerScreen()),
              _subTile("Promotion Engine", PromotionEngineScreen()),
            ],
          ),

          _expandableSection(
            title: "Payments and Billing",
            icon: Icons.account_balance_wallet_outlined,
            iconBg: const Color(0xFFE3F2FD),
            iconColor: Colors.blue,
            expanded: paymentsExpanded,
            toggle: () => setState(() => paymentsExpanded = !paymentsExpanded),
            children: [
              _subTile("Wallet", const WalletScreen()),
              _subTile("Bank Account", const SellerBankAccountsScreen()),
            ],
          ),

          _expandableSection(
            title: "Insights & Analytics",
            icon: Icons.analytics_outlined,
            iconBg: const Color(0xFFE8E5FF),
            iconColor: const Color(0xff8F7CFF),
            expanded: insightsExpanded,
            toggle: () => setState(() => insightsExpanded = !insightsExpanded),
            children: [
              _subTile(
                "Engagement Overview",
                CommunityPrivateAdminView(
                  groupName: widget.groupName,
                  privacy: widget.privacy,
                ),
              ),
              _subTile(
                "Revenue Analytics",
                CommunityPrivateAdminView(
                  groupName: widget.groupName,
                  privacy: widget.privacy,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ✅ Delete Group
          _menuTile(
            title: "Delete Group",
            icon: Icons.delete_outline,
            iconBg: const Color(0xFFFFEBEE),
            iconColor: Colors.red,
            onTap: () => _confirmDeleteGroup(),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ✅ Delete confirmation dialog
  void _confirmDeleteGroup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Group?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_forever, color: Colors.red, size: 48),
            const SizedBox(height: 12),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Are you sure you want to delete '),
                  TextSpan(
                    text: '"${widget.groupName}"',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const TextSpan(text: '?\n\nThis action cannot be undone.'),
                ],
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.zero,
        actions: [
          Divider(height: 1, color: Colors.grey.shade200),
          Row(
            children: [
              // Cancel
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black54, fontSize: 16),
                  ),
                ),
              ),
              Container(width: 1, height: 48, color: Colors.grey.shade200),
              // Yes Delete
              Expanded(
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx); // dialog बंद
                    // ✅ थेट FeedScreen वर — सगळ्या screens remove
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const FeedScreen()),
                      (route) => false,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          '"${widget.groupName}" deleted successfully',
                        ),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text(
                    'Yes, Delete',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 14,
          color: Color(0xFF6B7280),
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _expandableSection({
    required String title,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required bool expanded,
    required VoidCallback toggle,
    required List<Widget> children,
    String? badge,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                Icon(
                  expanded ? Icons.expand_less : Icons.expand_more,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
            onTap: toggle,
          ),
          if (expanded) ...[
            const Divider(height: 1, color: Color(0xFFE5E7EB)),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _subTile(String title, Widget screen) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 72, right: 16),
      title: Text(
        title,
        style: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 12,
        color: Color(0xFF9CA3AF),
      ),
      onTap: _navigate(screen),
    );
  }

  VoidCallback _navigate(Widget screen) {
    return () =>
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
