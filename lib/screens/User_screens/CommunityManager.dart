import 'dart:convert';

import 'package:commity_app1/app_constants.dart' as app_constants;
import 'package:commity_app1/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CommunityAdminScreen extends StatefulWidget {
  const CommunityAdminScreen({super.key, this.communityId = '2'});

  final String communityId;

  @override
  _CommunityAdminScreenState createState() => _CommunityAdminScreenState();
}

class _CommunityAdminScreenState extends State<CommunityAdminScreen> {
  String activeTab = "insights";
  int _memberCount = 0;
  bool _isMemberCountLoading = true;

  static const String _memberCountEndpoint =
      '${baseUrl}new_apis/community_dashboard_api.php';

  @override
  void initState() {
    super.initState();
    _fetchCommunityMemberCount();
  }

  Future<void> _fetchCommunityMemberCount() async {
    setState(() {
      _isMemberCountLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse(_memberCountEndpoint),
        body: {
          'action': 'community_member_count',
          'community_id': widget.communityId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Failed with status: ${response.statusCode}');
      }

      final Map<String, dynamic> payload =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (payload['success'] != true) {
        throw Exception(payload['message']?.toString() ?? 'Unknown API error');
      }

      final Map<String, dynamic> data =
          (payload['data'] as Map?)?.cast<String, dynamic>() ?? {};
      final int count =
          int.tryParse(data['total_members']?.toString() ?? '0') ?? 0;

      if (!mounted) return;

      setState(() {
        _memberCount = count;
        _isMemberCountLoading = false;
      });
    } catch (_) {
      final Uri fallbackUri = Uri.parse(
        '${app_constants.baseUrl}new_apis/community_dashboard_api.php',
      );

      try {
        final response = await http.post(
          fallbackUri,
          body: {
            'action': 'community_member_count',
            'community_id': widget.communityId,
          },
        );

        if (response.statusCode == 200) {
          final Map<String, dynamic> payload =
              jsonDecode(response.body) as Map<String, dynamic>;

          if (payload['success'] == true) {
            final Map<String, dynamic> data =
                (payload['data'] as Map?)?.cast<String, dynamic>() ?? {};
            final int count =
                int.tryParse(data['total_members']?.toString() ?? '0') ?? 0;

            if (!mounted) return;
            setState(() {
              _memberCount = count;
              _isMemberCountLoading = false;
            });
            return;
          }
        }
      } catch (_) {
        // Keep UI stable if API is temporarily unavailable.
      }

      if (!mounted) return;
      setState(() {
        _isMemberCountLoading = false;
      });
    }
  }

  void switchTab(String tab) {
    setState(() {
      activeTab = tab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final primary = Color(0xFF474DC5);
    final bg = Color(0xFFF9F9FF);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          "Community Admin",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: Icon(Icons.menu, color: primary),
        actions: [
          Icon(Icons.settings, color: primary),
          SizedBox(width: 16),
        ],
      ),

      body: Column(
        children: [
          /// HEADER
          Container(
            margin: EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.grey.shade200,
                    image: DecorationImage(
                      image: NetworkImage(
                        "https://lh3.googleusercontent.com/aida/ADBb0ugl5a8rO9oRZqH2KE6SSOBiVKHKDc9P53fORvdReVFnEdSzuqE7mZaFjYSMYs6AYoUDXiCkvDHc8adALZSW_TGqFRmnJAXaFNqaFif4JlYIIk8hza-iE-j4ZY71AZD6_0TxI3zFTFcgfS65rRpDIEe3y7xRFDMbLVj2SQ-lfu_3P6HVUTkxtfgtc5N91dAbn4iK8JgW1z07Ld6K9MAKJFVF1FIQ5-XR_yReji22gUWED3zzCYboZ0-9bSsJC3y8ISGQGSM_5cQX-Ak",
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                SizedBox(height: 16),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: primary,
                      child: Text(
                        "C",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Collectors Hub",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Admin Panel • Private Access",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),

                SizedBox(height: 12),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primary,
                    side: BorderSide(color: primary.withOpacity(0.3)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.visibility),
                  label: Text("Switch to Public View"),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          /// TABS
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                tabButton("Insights"),
                tabButton("Manage"),
                tabButton("About"),
              ],
            ),
          ),

          SizedBox(height: 10),

          /// CONTENT
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: buildContent(),
            ),
          ),
        ],
      ),

      /// BOTTOM NAV
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade200)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            bottomItem(Icons.dashboard, "Dashboard", true),
            bottomItem(Icons.group, "Members", false),
            bottomItem(Icons.payments, "Finance", false),
            bottomItem(Icons.person, "Profile", false),
          ],
        ),
      ),
    );
  }

  /// TAB BUTTON
  Widget tabButton(String title) {
    bool active = activeTab.toLowerCase() == title.toLowerCase();

    return GestureDetector(
      onTap: () => switchTab(title.toLowerCase()),
      child: Container(
        margin: EdgeInsets.only(right: 16),
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: active ? Color(0xFF474DC5) : Colors.grey,
              ),
            ),
            if (active)
              Container(
                margin: EdgeInsets.only(top: 4),
                height: 2,
                width: 40,
                color: Color(0xFF474DC5),
              ),
          ],
        ),
      ),
    );
  }

  /// CONTENT SWITCH
  Widget buildContent() {
    switch (activeTab) {
      case "manage":
        return manageSection();
      case "about":
        return aboutSection();
      default:
        return insightsSection();
    }
  }

  /// INSIGHTS
  Widget insightsSection() {
    return Column(
      children: [
        /// METRICS
        Row(
          children: [
            Expanded(
              child: metricCard(
                "Total Members",
                _isMemberCountLoading ? "..." : _memberCount.toString(),
              ),
            ),
            SizedBox(width: 12),
            Expanded(child: metricCard("Active Promos", "18")),
          ],
        ),

        SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: metricCard("Avg Time", "24m")),
            SizedBox(width: 12),
            Expanded(child: metricCard("Posts/day", "142")),
          ],
        ),

        SizedBox(height: 16),

        /// REVENUE
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Revenue Trend", style: TextStyle(color: Colors.grey)),
              SizedBox(height: 6),
              Text(
                "\$12,450",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        SizedBox(height: 16),

        /// CONTRIBUTORS
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Top Contributors",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 10),
              contributor("Julian Dash", "#1"),
              contributor("Alice Stone", "#2"),
              contributor("Marcus King", "#3"),
            ],
          ),
        ),
      ],
    );
  }

  /// MANAGE
  Widget manageSection() {
    return Column(
      children: [
        actionButton(Icons.person_add, "Invite Members"),
        actionButton(Icons.edit, "Edit Profile"),
        actionButton(Icons.gavel, "Moderation Queue"),
        actionButton(Icons.block, "Banned Users"),
      ],
    );
  }

  /// ABOUT
  Widget aboutSection() {
    return card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "About Collectors Hub",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Text(
            "Collectors Hub is a private community dedicated to digital asset trading.",
          ),
        ],
      ),
    );
  }

  /// REUSABLES

  Widget metricCard(String title, String value) {
    return card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget contributor(String name, String rank) {
    return ListTile(
      leading: CircleAvatar(child: Text(name[0])),
      title: Text(name),
      trailing: Text(rank, style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }

  Widget actionButton(IconData icon, String text) {
    return card(
      Row(
        children: [
          Icon(icon, color: Colors.blue),
          SizedBox(width: 12),
          Text(text),
        ],
      ),
    );
  }

  Widget card(Widget child) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: child,
    );
  }

  Widget bottomItem(IconData icon, String label, bool active) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, color: active ? Color(0xFF474DC5) : Colors.grey),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Color(0xFF474DC5) : Colors.grey,
          ),
        ),
      ],
    );
  }
}
