// lib/screens/commity_admin.dart

import 'package:commity_app1/screens/admin_commity_manger.dart';
import 'package:flutter/material.dart';

class CommunityPrivateAdminView extends StatefulWidget {
  final String groupName;
  final String privacy;

  const CommunityPrivateAdminView({
    super.key,
    required this.groupName,
    required this.privacy,
  });

  @override
  State<CommunityPrivateAdminView> createState() =>
      _CommunityPrivateAdminViewState();
}

class _CommunityPrivateAdminViewState
    extends State<CommunityPrivateAdminView> {
  int totalMembers = 12540;
  int pendingRequests = 24;
  int livePromotions = 3;
  double monthlyRevenue = 54000;

  bool get isPrivate => widget.privacy == 'Private';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: const Color(0xff8F7CFF),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff8F7CFF), Color(0xff6C63FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 70,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.groups,
                                  size: 35, color: Color(0xff8F7CFF)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.groupName,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isPrivate
                                          ? Colors.orange.withOpacity(0.9)
                                          : Colors.green.withOpacity(0.9),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                            isPrivate
                                                ? Icons.lock_outline
                                                : Icons.public,
                                            color: Colors.white,
                                            size: 13),
                                        const SizedBox(width: 4),
                                        Text(
                                            isPrivate
                                                ? 'Private Group'
                                                : 'Public Group',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isPrivate
                              ? '🔒 Only followers can see members & posts'
                              : '🌍 Anyone can find and view this group',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onPressed: () {
                  // ✅ येथे आता नवीन AdminCommunityManagerScreen वर जाईल
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminCommunityManagerScreen(
                        groupName: widget.groupName,
                        privacy: widget.privacy,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text("Create Post"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff8F7CFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon:
                              const Icon(Icons.person_add_outlined, size: 16),
                          label: const Text("Invite"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE8E5FF),
                            foregroundColor: const Color(0xff8F7CFF),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Quick Stats",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _statCard("Total Members", totalMembers.toString(),
                      Icons.people, const Color(0xFFE8E5FF), const Color(0xff8F7CFF)),
                  _statCard(
                      "Pending Requests",
                      pendingRequests.toString(),
                      Icons.pending_actions,
                      const Color(0xFFFFF3E0),
                      Colors.orange),
                  _statCard("Live Promotions", livePromotions.toString(),
                      Icons.campaign, const Color(0xFFE8F5E9), Colors.green),
                  _statCard("Monthly Revenue", "₹${monthlyRevenue.toStringAsFixed(0)}",
                      Icons.currency_rupee, const Color(0xFFE3F2FD), Colors.blue),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color bgColor,
      Color iconColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: Color(0xFFE5E7EB))),
      child: ListTile(
        leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 20)),
        title: Text(title,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
        trailing: Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black)),
      ),
    );
  }
}