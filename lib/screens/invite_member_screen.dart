import 'package:commity_app1/screens/commity_Manage.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
// ✅ import

class InviteMembersScreen extends StatefulWidget {
  final String groupName;
  final String privacy;
  final String? communityId;

  const InviteMembersScreen({
    super.key,
    required this.groupName,
    required this.privacy,
    this.communityId,
  });

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  String searchQuery = "";
  bool _isGeneratingLink = false;
  bool _isLoadingInvites = false;
  bool _isLoadingSharedInvites = false;
  final Database _database = Database();

  List<Map<String, dynamic>> people = [
    {"name": "Bhanu Tyagi Adv", "invited": false},
    {"name": "Adv Ankit Kumar", "invited": false},
    {"name": "Jagadish TG", "invited": false},
    {"name": "Ajay Prakash Agnihotri", "invited": false},
    {"name": "Adv Daksh Sharma", "invited": false},
    {"name": "Adv Salman Shaykh", "invited": false},
    {"name": "Adv Garima Chaudhary", "invited": false},
    {"name": "Adv Ritik Sonkar", "invited": false},
  ];

  List<Map<String, dynamic>> get filteredPeople {
    return people.where((person) {
      return person["name"]
          .toLowerCase()
          .contains(searchQuery.toLowerCase());
    }).toList();
  }

  int get invitedCount => people.where((p) => p["invited"] == true).length;

  Future<void> _fetchMyInvites() async {
    setState(() => _isLoadingInvites = true);
    try {
      final response = await _database.getData({'action': 'fetch_my_invites'});
      if (!mounted) return;

      final success = response['success'] == true || response['status'] == 200;
      if (!success) {
        final msg = response['message']?.toString() ?? 'Failed to fetch invites';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      final data = response['data'];
      final invites = data is List
          ? data.cast<dynamic>().map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _InviteListSheet(
          title: 'My Invites',
          invites: invites,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingInvites = false);
    }
  }

  Future<void> _fetchSharedInvitesAdmin() async {
    setState(() => _isLoadingSharedInvites = true);
    try {
      final response = await _database.getData({'action': 'fetch_shared_invites_admin'});
      if (!mounted) return;

      final success = response['success'] == true || response['status'] == 200;
      if (!success) {
        final msg = response['message']?.toString() ?? 'Failed to fetch shared invites';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      final data = response['data'];
      final communities = data is List
          ? data.cast<dynamic>().map((e) => Map<String, dynamic>.from(e as Map)).toList()
          : <Map<String, dynamic>>[];

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (_) => _SharedInvitesSheet(communities: communities),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoadingSharedInvites = false);
    }
  }

  Future<void> _promptInviteLinkAction({required bool validateOnly}) async {
    final controller = TextEditingController();
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(validateOnly ? 'Validate Invite Link' : 'Fetch Invite Details'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Paste invite link',
            border: OutlineInputBorder(),
          ),
          minLines: 2,
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final link = controller.text.trim();
              if (link.isEmpty) return;
              Navigator.pop(dialogContext);
              if (validateOnly) {
                await _validateInvite(link);
              } else {
                await _fetchInviteDetails(link);
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _validateInvite(String inviteLink) async {
    try {
      final response = await _database.getData({
        'action': 'validate_invite',
        'invite_link': inviteLink,
      });
      if (!mounted) return;

      final success = response['success'] == true || response['status'] == 200;
      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};

      final message = success
          ? 'Valid until ${data['expires_at'] ?? '-'}\nRemaining: ${data['remaining_human'] ?? '-'}'
          : (response['message']?.toString() ?? 'Invite validation failed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _fetchInviteDetails(String inviteLink) async {
    try {
      final response = await _database.getData({
        'action': 'fetch_invite_details',
        'invite_link': inviteLink,
      });
      if (!mounted) return;

      final success = response['success'] == true || response['status'] == 200;
      if (!success) {
        final msg = response['message']?.toString() ?? 'Failed to fetch invite details';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      final data = response['data'] is Map
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};

      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Invite Details'),
          content: SingleChildScrollView(
            child: Text(
              'Community: ${data['community_title'] ?? '-'}\n'
              'Status: ${data['invite_status'] ?? '-'}\n'
              'Validity: ${data['validity_days'] ?? '-'} days\n'
              'Expires: ${data['expires_at'] ?? '-'}\n'
              'Remaining: ${data['remaining_human'] ?? '-'}',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _generateInviteLink({int validityDays = 10, int? sharedToVendor}) async {
    final communityId = widget.communityId?.trim() ?? '';
    if (communityId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('community_id is required by API. Open this screen from a flow that passes communityId.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGeneratingLink = true);
    try {
      final requestBody = <String, String>{
        'action': 'share_invite_link',
        'community_id': communityId,
        'validity_days': validityDays.toString(),
      };

      if (sharedToVendor != null && sharedToVendor > 0) {
        requestBody['shared_to_vendor'] = sharedToVendor.toString();
      }

      final response = await _database.getData(requestBody);

      if (!mounted) return;

      final success = response['success'] == true || response['status'] == 200;
      if (!success) {
        final msg = response['message']?.toString() ?? 'Failed to generate invite link';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      final data = (response['data'] is Map)
          ? Map<String, dynamic>.from(response['data'])
          : <String, dynamic>{};
      final inviteLink = (data['invite_link'] ?? response['invite_link'] ?? '').toString();

      if (inviteLink.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite link not returned by server')),
        );
        return;
      }

      await _showInviteShareActions(inviteLink);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating invite link: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLink = false);
      }
    }
  }

  Future<void> _showInviteShareActions(String inviteLink) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Share via apps'),
              subtitle: const Text('WhatsApp, Email, Telegram, etc.'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await SharePlus.instance.share(
                  ShareParams(
                    text: 'Join ${widget.groupName} community: $inviteLink',
                    subject: 'Community Invite',
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.forum_outlined),
              title: const Text('Send via in-app DM'),
              subtitle: const Text('Open chat and prefill invite link'),
              onTap: () {
                Navigator.pop(sheetContext);
                _sendInviteViaDm(inviteLink);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy link'),
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: inviteLink));
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendInviteViaDm(String inviteLink) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 320,
          child: Column(
            children: [
              const ListTile(
                title: Text('Send invite as DM', style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('Choose a user to open chat'),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: people.length,
                  itemBuilder: (_, i) {
                    final person = people[i];
                    final name = (person['name'] ?? 'User').toString();
                    return ListTile(
                      title: Text(name),
                      leading: CircleAvatar(child: Text(name.isNotEmpty ? name[0] : 'U')),
                      onTap: () {
                        // Navigator.pop(sheetContext);
                        // final user = ChatUser.fromFollowing(
                        //   id: 'invite_dm_$i',
                        //   name: name,
                        //   avatarUrl: 'https://i.pravatar.cc/150?img=${(i % 70) + 1}',
                        // );
                        //
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(
                        //     builder: (_) => ChatScreen(
                        //       user: user,
                        //       initialMessage: 'Join ${widget.groupName} community: $inviteLink',
                        //     ),
                        //   ),
                        // );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _inviteWithEmailPlaceholder() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email-targeted invite is a separate flow. Use Invite with link for share sheet.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Invite people",
              style: TextStyle(
                color: Colors.black,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            // ✅ Show group name + privacy badge
            Row(
              children: [
                Text(
                  widget.groupName,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: widget.privacy == 'Private'
                        ? const Color(0xFFFFF3E0)
                        : const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.privacy == 'Private'
                            ? Icons.lock_outline
                            : Icons.public,
                        size: 10,
                        color: widget.privacy == 'Private'
                            ? Colors.orange
                            : Colors.green,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        widget.privacy,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: widget.privacy == 'Private'
                              ? Colors.orange
                              : Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () {
        //           // ✅ Next/Skip दोन्ही → CommunityPrivateAdminView
        //           Navigator.push(
        //             context,
        //             MaterialPageRoute(
        //               builder: (_) => CommunityPrivateAdminView(
        //                 groupName: widget.groupName,
        //                 privacy: widget.privacy,
        //               ),
        //             ),
        //           );
        //         },
        //     child: Text(
        //       invitedCount > 0 ? "Next ($invitedCount)" : "Next",
        //       style: TextStyle(
        //         color: invitedCount > 0
        //             ? const Color(0xff8F7CFF)
        //             : const Color(0xFF6B7280),
        //         fontWeight: FontWeight.w600,
        //         fontSize: 15,
        //       ),
        //     ),
        //   ),
        // ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Privacy info banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: widget.privacy == 'Private'
                  ? const Color(0xFFFFF3E0)
                  : const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: widget.privacy == 'Private'
                    ? const Color(0xFFFF9800)
                    : const Color(0xFF4CAF50),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.privacy == 'Private'
                      ? Icons.lock_outline
                      : Icons.public,
                  color: widget.privacy == 'Private'
                      ? Colors.orange
                      : Colors.green,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    widget.privacy == 'Private'
                        ? "Private group — Only invited followers can join & view posts."
                        : "Public group — Anyone can find and view this group's posts.",
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          // INVITE OPTIONS
          _inviteOption(
            Icons.link,
            "Invite with link",
            "Invite people to this group with a link",
            onTap: _generateInviteLink,
          ),
          _inviteOption(
            Icons.email_outlined,
            "Invite with email",
            "Send an email invite to people",
            onTap: _inviteWithEmailPlaceholder,
          ),

          if (_isGeneratingLink)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          _simpleOption("Suggested friends"),
          _simpleOption("Friends in Kolhapur, India"),

          const SizedBox(height: 8),
          _simpleOption(
            _isLoadingInvites ? "Loading my invites..." : "My received invites",
            onTap: _isLoadingInvites ? null : _fetchMyInvites,
          ),
          _simpleOption(
            _isLoadingSharedInvites ? "Loading shared invites..." : "My shared invites (Admin)",
            onTap: _isLoadingSharedInvites ? null : _fetchSharedInvitesAdmin,
          ),
          _simpleOption(
            "Validate invite link",
            onTap: () => _promptInviteLinkAction(validateOnly: true),
          ),
          _simpleOption(
            "Fetch invite link details",
            onTap: () => _promptInviteLinkAction(validateOnly: false),
          ),

          const SizedBox(height: 16),

          // SEARCH
          TextField(
            decoration: InputDecoration(
              hintText: "Search for people",
              prefixIcon: const Icon(Icons.search, color: Color(0xFF9CA3AF)),
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
            onChanged: (v) => setState(() => searchQuery = v),
          ),

          const SizedBox(height: 20),

          const Text(
            "Suggested",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // PEOPLE LIST
          ...filteredPeople.map((person) => _personTile(person)),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _inviteOption(IconData icon, String title, String subtitle, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8E5FF),
        child: Icon(icon, color: const Color(0xff8F7CFF)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
      ),
      onTap: onTap,
    );
  }

  Widget _simpleOption(String title, {VoidCallback? onTap}) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 2),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: Color(0xFF6B7280),
      ),
      onTap: onTap,
    );
  }

  Widget _personTile(Map<String, dynamic> person) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8E5FF),
        child: Text(
          person["name"][0],
          style: const TextStyle(
            color: Color(0xff8F7CFF),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        person["name"],
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: person["invited"]
              ? Colors.grey.shade300
              : const Color(0xff8F7CFF),
          foregroundColor:
              person["invited"] ? Colors.black54 : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          elevation: 0,
        ),
        onPressed: () {
          setState(() {
            person["invited"] = !person["invited"];
          });
        },
        child: Text(
          person["invited"] ? "Invited ✓" : "Invite",
          style: const TextStyle(fontSize: 13),
        ),
      ),
    );
  }
}

class _InviteListSheet extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> invites;

  const _InviteListSheet({required this.title, required this.invites});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            ListTile(
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('Count: ${invites.length}'),
            ),
            const Divider(height: 1),
            Expanded(
              child: invites.isEmpty
                  ? const Center(child: Text('No invites found'))
                  : ListView.builder(
                      itemCount: invites.length,
                      itemBuilder: (_, i) {
                        final invite = invites[i];
                        return ListTile(
                          title: Text((invite['community_title'] ?? '-').toString()),
                          subtitle: Text(
                            'Status: ${invite['invite_status'] ?? '-'}\n'
                            'Expires: ${invite['expires_at'] ?? '-'}\n'
                            'Remaining: ${invite['remaining_human'] ?? '-'}',
                          ),
                          isThreeLine: true,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SharedInvitesSheet extends StatelessWidget {
  final List<Map<String, dynamic>> communities;

  const _SharedInvitesSheet({required this.communities});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: communities.isEmpty
            ? const Center(child: Text('No shared invites found'))
            : ListView.builder(
                itemCount: communities.length,
                itemBuilder: (_, i) {
                  final community = communities[i];
                  final invites = community['invites'] is List ? community['invites'] as List : [];
                  return ExpansionTile(
                    title: Text((community['community_title'] ?? '-').toString()),
                    subtitle: Text('Shares: ${community['share_count'] ?? invites.length}'),
                    children: invites.map((e) {
                      final invite = e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{};
                      return ListTile(
                        title: Text((invite['vendor_name'] ?? '-').toString()),
                        subtitle: Text(
                          'Status: ${invite['status'] ?? '-'}\n'
                          'Remaining: ${invite['remaining_human'] ?? '-'}',
                        ),
                        isThreeLine: true,
                      );
                    }).toList(),
                  );
                },
              ),
      ),
    );
  }
}