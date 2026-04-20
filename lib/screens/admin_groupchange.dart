// lib/screens/admin_commity_manger.dart


import 'package:commity_app1/screens/group_model.dart';
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

  // ✅ गट हटवण्यासाठीची पद्धत
  void _deleteGroup() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: const Text('Delete Group'),
        content: Text(
            'Are you sure you want to permanently delete "${widget.groupName}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              // जागतिक यादीमधून गट हटवा
              setState(() {
                userCreatedGroups
                    .removeWhere((group) => group.name == widget.groupName);
              });

              // Dialog बंद करा
              Navigator.pop(dialogContext);

              // ✅ थेट FeedScreen वर जा आणि बाकीच्या स्क्रीन काढून टाका
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Manage Group', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 16),
          _buildSectionTitle('General Settings'),
          _buildOptionTile(Icons.edit, 'Edit Group Info', () {}),
          _buildOptionTile(Icons.shield_outlined, 'Privacy Settings', () {}),
          _buildOptionTile(
              Icons.notifications_outlined, 'Notification Settings', () {}),
          const SizedBox(height: 16),
          _buildSectionTitle('Member Management'),
          _buildOptionTile(Icons.person_add_outlined, 'Member Requests', () {}),
          _buildOptionTile(Icons.people_outline, 'View Members', () {}),
          const Divider(height: 32),

          // ✅ Delete Group Tile
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: InkWell(
              onTap: _deleteGroup,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.delete_forever, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Delete Group',
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildOptionTile(IconData icon, String title, VoidCallback onTap) {
    return Container(
      color: Colors.white,
      child: ListTile(
        leading: Icon(icon, color: Colors.grey.shade800),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}