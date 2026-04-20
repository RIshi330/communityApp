// lib/screens/crete_group.dart

import 'package:commity_app1/screens/invite_member_screen.dart';
import 'package:flutter/material.dart';

// Temporary list for created communities
List<Group> createdCommunities = [];

// Group class definition
class Group {
  final String id;
  final String name;
  final String privacy;
  final String imageUrl;

  Group({
    required this.id,
    required this.name,
    required this.privacy,
    required this.imageUrl,
  });
}

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({Key? key}) : super(key: key);

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedPrivacy = 'Private';
  String _selectedVisibility = 'Visible';
  String _selectedCategory = 'general';
  bool _isCreating = false;

  final List<String> _visibilityOptions = ['Visible', 'Hidden'];

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Gaming',     'value': 'gaming',      'icon': Icons.sports_esports},
    {'label': 'Technology', 'value': 'technology',  'icon': Icons.computer},
    {'label': 'Sports',     'value': 'sports',      'icon': Icons.sports_soccer},
    {'label': 'Music',      'value': 'music',       'icon': Icons.music_note},
    {'label': 'Fitness',    'value': 'fitness',     'icon': Icons.fitness_center},
    {'label': 'Travel',     'value': 'travel',      'icon': Icons.flight},
    {'label': 'Food',       'value': 'food',        'icon': Icons.restaurant},
    {'label': 'Business',   'value': 'business',    'icon': Icons.business},
    {'label': 'General',    'value': 'general',     'icon': Icons.group},
  ];

  String _getPrivacyDescription() {
    if (_selectedPrivacy == 'Private') {
      return "🔒 Private Community: Only your followers can see this community, its members, and their posts.";
    }
    return "🌍 Public Community: Anyone can see this community, its members, and what they post.";
  }

  Color _getPrivacyColor() =>
      _selectedPrivacy == 'Private' ? const Color(0xFFFFF3E0) : const Color(0xFFE8F5E9);
  Color _getPrivacyBorderColor() =>
      _selectedPrivacy == 'Private' ? const Color(0xFFFF9800) : const Color(0xFF4CAF50);

  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a community name'),
          backgroundColor: Color(0xff8F7CFF),
        ),
      );
      return;
    }

    setState(() => _isCreating = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isCreating = false);

    if (mounted) {
      final generatedCommunityId = DateTime.now().millisecondsSinceEpoch.toString();
      // ✅ Tuzya Community class nusaar save karto
      createdCommunities.add(
        Group(
          id: generatedCommunityId,
          name: _nameController.text.trim(),
          privacy: _selectedPrivacy,
          imageUrl:
              'https://picsum.photos/200/200?random=${DateTime.now().millisecondsSinceEpoch % 100}',
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => InviteMembersScreen(
            groupName: _nameController.text.trim(),
            privacy: _selectedPrivacy,
            communityId: generatedCommunityId,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCreating) {
      return Scaffold(
        backgroundColor: const Color(0xFFE5E7EB),
        body: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xff8F7CFF)),
                ),
                SizedBox(width: 16),
                Text('Creating Community...',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87)),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Create Community',
            style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),

              // ── Name ──────────────────────────────────────────────────────
              const Text('Name',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 12),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.black, fontSize: 16),
                decoration: InputDecoration(
                  hintText: 'Name your Community',
                  hintStyle:
                      const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFD1D5DB))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(
                          color: Color(0xff8F7CFF), width: 2)),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),

              // ── Category ──────────────────────────────────────────────────
              const Text('Category',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['value'];
                  return GestureDetector(
                    onTap: () =>
                        setState(() => _selectedCategory = cat['value']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xff8F7CFF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff8F7CFF)
                              : const Color(0xFFD1D5DB),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(cat['icon'] as IconData,
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF6B7280)),
                          const SizedBox(width: 6),
                          Text(cat['label'] as String,
                              style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),

              // ── Privacy ───────────────────────────────────────────────────
              const Text('Privacy',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 12),
              Row(
                children: [
                  _privacyToggle('Public', Icons.public),
                  const SizedBox(width: 12),
                  _privacyToggle('Private', Icons.lock_outline),
                ],
              ),
              const SizedBox(height: 12),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _getPrivacyColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _getPrivacyBorderColor()),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                        _selectedPrivacy == 'Private'
                            ? Icons.lock_outline
                            : Icons.public,
                        color: _getPrivacyBorderColor(),
                        size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_getPrivacyDescription(),
                          style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                              height: 1.5)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE5E7EB)),
              const SizedBox(height: 16),

              // ── Visibility ────────────────────────────────────────────────
              const Text('Visibility',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFD1D5DB)),
                    borderRadius: BorderRadius.circular(8)),
                child: DropdownButtonFormField<String>(
                  value: _selectedVisibility,
                  decoration: const InputDecoration(
                    labelText: 'Visibility',
                    labelStyle:
                        TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    border: InputBorder.none,
                  ),
                  style: const TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w500),
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.black),
                  dropdownColor: Colors.white,
                  items: _visibilityOptions
                      .map((o) =>
                          DropdownMenuItem(value: o, child: Text(o)))
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedVisibility = value!),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: ElevatedButton(
          onPressed: _createCommunity,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: const Text('Create Community',
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _privacyToggle(String label, IconData icon) {
    final isSelected = _selectedPrivacy == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPrivacy = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xff8F7CFF) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected
                    ? const Color(0xff8F7CFF)
                    : const Color(0xFFD1D5DB),
                width: isSelected ? 2 : 1),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? Colors.white
                      : const Color(0xFF6B7280),
                  size: 22),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}