import 'package:commity_app1/model/user_model.dart';
import 'package:flutter/material.dart';

class FollowingScreen extends StatefulWidget {
  final UserModel user;

  const FollowingScreen({super.key, required this.user});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<FollowingModel> _following = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFollowing();
  }

  Future<void> _loadFollowing() async {
    await Future.delayed(const Duration(milliseconds: 400));
    setState(() {
      _following = FollowingModel.sampleFollowing;
      _isLoading = false;
    });
  }

  List<FollowingModel> get _filteredFollowing {
    if (_searchQuery.isEmpty) return _following;
    return _following
        .where((f) =>
            f.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            f.displayName.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Text(
          widget.user.username,
          style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16),
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _buildFollowingList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            prefixIcon:
                Icon(Icons.search, color: Colors.grey.shade500, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 10),
          ),
        ),
      ),
    );
  }

  Widget _buildFollowingList() {
    if (_filteredFollowing.isEmpty) {
      return const Center(
        child: Text('No accounts found',
            style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.builder(
      itemCount: _filteredFollowing.length,
      itemBuilder: (context, index) =>
          _buildFollowingTile(_filteredFollowing[index]),
    );
  }

  Widget _buildFollowingTile(FollowingModel following) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundImage: NetworkImage(following.profileImageUrl),
            backgroundColor: Colors.grey.shade800,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  following.username,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14),
                ),
                Text(
                  following.displayName,
                  style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // ✅ ALWAYS SHOW LAVENDER MESSAGE BUTTON
          _MessageButton(onTap: () {
            // TODO: Add message action
          }),

          const SizedBox(width: 8),
        ],
      ),
    );
  }
}

// ─── LAVENDER MESSAGE BUTTON ────────────────────────────────
class _MessageButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MessageButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFB39DDB), // Lavender
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          'Message',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
