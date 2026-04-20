import 'dart:io';

import 'package:commity_app1/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../Database/Database.dart';
import 'commity_admin.dart';
import 'invite_member_screen.dart' as invite_screen;

class CreateCommunityScreen extends StatefulWidget {
  final bool openCommunityHomeOnCreate;

  const CreateCommunityScreen({
    super.key,
    this.openCommunityHomeOnCreate = false,
  });

  @override
  State<CreateCommunityScreen> createState() => _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  // Form Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _geographyController = TextEditingController();

  // Images
  File? _logoImage;
  File? _bannerImage;
  final ImagePicker _picker = ImagePicker();

  // Community Info
  String _joiningRule = 'Free to Join';
  String _communityMode = 'Online';

  // Tags
  List<String> _communityTags = ['Technology', 'Startup'];
  List<String> _demographyTags = [];
  List<String> _professionalTags = [];

  // Geography
  String _geographyType = 'Global';

  // Loading state
  bool _isCreating = false;

  // Options
  final List<String> _joiningRules = [
    'Free to Join',
    'Join Post Approval',
    'Pay to Join',
  ];

  final List<String> _communityModes = ['Online', 'Onsite', 'Hybrid'];

  final List<String> _geographyOptions = [
    'Pin Code',
    'City',
    'State',
    'Country',
    'Global',
  ];

  final List<String> _demographyOptions = [
    'Men',
    'Women',
    'Kids',
    'Senior Citizens',
    'Others',
  ];

  String _extractCommunityId(Map response) {
    String pick(dynamic v) {
      if (v == null) return '';
      final s = v.toString().trim();
      if (s.isEmpty || s.toLowerCase() == 'null' || s == '0') return '';
      return s;
    }

    final topLevelKeys = [
      'community_id',
      'id',
      'group_id',
      'communityId',
      'insert_id',
    ];
    for (final key in topLevelKeys) {
      final val = pick(response[key]);
      if (val.isNotEmpty) return val;
    }

    final data = response['data'];
    if (data is Map) {
      for (final key in topLevelKeys) {
        final val = pick(data[key]);
        if (val.isNotEmpty) return val;
      }
    } else if (data is List && data.isNotEmpty && data.first is Map) {
      final first = data.first as Map;
      for (final key in topLevelKeys) {
        final val = pick(first[key]);
        if (val.isNotEmpty) return val;
      }
    }

    return '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _geographyController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool isLogo) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() {
          if (isLogo) {
            _logoImage = File(image.path);
          } else {
            _bannerImage = File(image.path);
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addTag(List<String> tagList, String tag) {
    if (tag.isNotEmpty && !tagList.contains(tag)) {
      setState(() {
        tagList.add(tag);
      });
    }
  }

  void _removeTag(List<String> tagList, String tag) {
    setState(() {
      tagList.remove(tag);
    });
  }

  void _showAddTagDialog(List<String> tagList, String title) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add $title'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter tag name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _addTag(tagList, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  /// Check if the API response indicates success
  bool _isSuccessResponse(Map response) {
    // Check various success indicators
    if (response['success'] == true) return true;
    if (response['status'] == 200) return true;
    if (response['status'] == 'success') return true;
    // If we got data back and no explicit error, treat as success
    if (response.containsKey('data') &&
        response['status'] != 300 &&
        response['error'] == null)
      return true;
    // If we got a community_id or insert_id back, it was created
    if (response['community_id'] != null ||
        response['insert_id'] != null ||
        response['id'] != null)
      return true;
    return false;
  }

  Future<void> _createCommunity() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a community name'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a community description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final database = Database();

      final vendorId = await AuthService.getVendorIdString();

      // Prepare request body for create_community API
      final requestBody = {
        'action': 'create_community',
        'community_title': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'community_type': 'community',
        'visibility': 'public',
        'joining_rule': _joiningRule.toLowerCase().replaceAll(' ', '_'),
        'joining_fee': _joiningRule == 'Pay to Join' ? '499' : '0',
        'logo': _logoImage?.path ?? '',
        'cover_image': _bannerImage?.path ?? '',
        'tags': _communityTags.join(','),
        'vendor_id': vendorId,
      };

      // Call create_community API
      final response = await database.getData(requestBody);

      if (!mounted) return;

      if (_isSuccessResponse(response)) {
        // Community created successfully
        final communityId = _extractCommunityId(response);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Community created successfully! 🎉'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        if (widget.openCommunityHomeOnCreate) {
          // Replace current screen to return 'true' to GroupsScreen while showing AdminView
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPrivateAdminView(
                groupName: _nameController.text.trim(),
                privacy: 'Public',
              ),
            ),
            result: true,
          );
        } else {
          // Replace current screen to return 'true' to GroupsScreen while showing Invite screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => invite_screen.InviteMembersScreen(
                groupName: _nameController.text.trim(),
                privacy: 'Public',
                communityId: communityId,
              ),
            ),
            result: true,
          );
        }
      } else {
        // Handle API error
        final errorMessage =
            response['message']?.toString() ??
            response['error']?.toString() ??
            'Failed to create community';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );

        print("❌ Create Community Error: $errorMessage");
        print("❌ Full response: $response");
      }
    } catch (e) {
      if (!mounted) return;

      // Handle network or other errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );

      print("❌ Create Community Exception: $e");
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
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
        title: const Text(
          'Create Community',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: _isCreating
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF8F7CFF),
                    ),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Creating Community...',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Community Info Section
                  _buildSectionHeader('Community Info'),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _nameController,
                    label: 'Community Name',
                    hintText: 'Enter your community name',
                  ),
                  const SizedBox(height: 16),

                  _buildMultilineTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hintText: 'Describe your community...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),

                  // Logo & Banner Upload
                  _buildImageUploadSection(),
                  const SizedBox(height: 24),

                  // Joining Rule Section
                  _buildSectionHeader('Joining Rule'),
                  const SizedBox(height: 16),
                  _buildRadioGroup(
                    options: _joiningRules,
                    selected: _joiningRule,
                    onChanged: (value) => setState(() => _joiningRule = value!),
                  ),
                  const SizedBox(height: 24),

                  // Community Mode Section
                  _buildSectionHeader('Community Mode'),
                  const SizedBox(height: 16),
                  _buildRadioGroup(
                    options: _communityModes,
                    selected: _communityMode,
                    onChanged: (value) =>
                        setState(() => _communityMode = value!),
                  ),
                  const SizedBox(height: 24),

                  // Tags Section
                  _buildSectionHeader('Tags'),
                  const SizedBox(height: 16),
                  _buildTagsSection(
                    tags: _communityTags,
                    title: 'Community Tags',
                    onAdd: () =>
                        _showAddTagDialog(_communityTags, 'Community Tag'),
                  ),
                  const SizedBox(height: 24),

                  // Members Info Section
                  _buildSectionHeader('Members Info'),
                  const SizedBox(height: 16),

                  // Demography Tags
                  _buildSubSectionHeader('Demography'),
                  const SizedBox(height: 12),
                  _buildChipSelector(
                    options: _demographyOptions,
                    selectedTags: _demographyTags,
                    title: 'Demography',
                  ),
                  const SizedBox(height: 20),

                  // Geography
                  _buildSubSectionHeader('Geography'),
                  const SizedBox(height: 12),
                  _buildGeographySection(),
                  const SizedBox(height: 20),

                  // Professional Tags
                  _buildSubSectionHeader('Professional'),
                  const SizedBox(height: 12),
                  _buildTagsSection(
                    tags: _professionalTags,
                    title: 'Professional Tags',
                    onAdd: () => _showAddTagDialog(
                      _professionalTags,
                      'Professional Tag',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Create Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _createCommunity,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8F7CFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Create Community',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.black,
      ),
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8F7CFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMultilineTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    int maxLines = 3,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 16),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8F7CFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Logo & Banner',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Logo Upload
            Expanded(
              child: _buildImageUploadCard(
                title: 'Community Logo',
                image: _logoImage,
                onTap: () => _pickImage(true),
                width: 80,
                height: 80,
              ),
            ),
            const SizedBox(width: 16),
            // Banner Upload
            Expanded(
              child: _buildImageUploadCard(
                title: 'Community Banner',
                image: _bannerImage,
                onTap: () => _pickImage(false),
                width: double.infinity,
                height: 120,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildImageUploadCard({
    required String title,
    required File? image,
    required VoidCallback onTap,
    required double width,
    required double height,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: image != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  image!,
                  width: width,
                  height: height,
                  fit: BoxFit.cover,
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 32,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildRadioGroup({
    required List<String> options,
    required String selected,
    required Function(String?) onChanged,
  }) {
    return Column(
      children: options.map((option) {
        return RadioListTile<String>(
          title: Text(
            option,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          value: option,
          groupValue: selected,
          onChanged: onChanged,
          activeColor: const Color(0xFF8F7CFF),
          contentPadding: EdgeInsets.zero,
        );
      }).toList(),
    );
  }

  Widget _buildTagsSection({
    required List<String> tags,
    required String title,
    required VoidCallback onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Tag', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF8F7CFF),
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags
              .map((tag) => _buildChip(tag, () => _removeTag(tags, tag)))
              .toList(),
        ),
        if (tags.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'No tags added. Click "Add Tag" to add tags.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildChip(String label, VoidCallback onDelete) {
    return Chip(
      label: Text(label),
      deleteIcon: const Icon(Icons.close, size: 16),
      onDeleted: onDelete,
      backgroundColor: const Color(0xFFE8E5FF),
      deleteIconColor: const Color(0xFF8F7CFF),
      labelStyle: const TextStyle(
        color: Color(0xFF8F7CFF),
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildChipSelector({
    required List<String> options,
    required List<String> selectedTags,
    required String title,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selectedTags.contains(option);
            return FilterChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedTags.add(option);
                  } else {
                    selectedTags.remove(option);
                  }
                });
              },
              backgroundColor: Colors.grey.shade100,
              selectedColor: const Color(0xFFE8E5FF),
              checkmarkColor: const Color(0xFF8F7CFF),
              labelStyle: TextStyle(
                color: isSelected ? const Color(0xFF8F7CFF) : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildGeographySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Geography Type Selector
        DropdownButtonFormField<String>(
          value: _geographyType,
          decoration: InputDecoration(
            labelText: 'Geography Type',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF8F7CFF), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
          items: _geographyOptions.map((option) {
            return DropdownMenuItem<String>(value: option, child: Text(option));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _geographyType = value!;
              _geographyController.clear();
            });
          },
        ),

        if (_geographyType != 'Global') ...[
          const SizedBox(height: 16),
          TextField(
            controller: _geographyController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Enter ${_geographyType.toLowerCase()}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF8F7CFF),
                  width: 2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// Invite Members Screen with Skip Option
class InviteMembersScreen extends StatefulWidget {
  final String communityName;
  final String joiningRule;
  final String communityId;

  const InviteMembersScreen({
    super.key,
    required this.communityName,
    required this.joiningRule,
    required this.communityId,
  });

  @override
  State<InviteMembersScreen> createState() => _InviteMembersScreenState();
}

class _InviteMembersScreenState extends State<InviteMembersScreen> {
  bool _isLoading = false;
  bool _isGeneratingLink = false;
  final Database _database = Database();

  Future<void> _generateInviteLink({int validityDays = 10}) async {
    if (widget.communityId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Community ID missing. Please recreate community.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isGeneratingLink = true);
    try {
      final response = await _database.getData({
        'action': 'share_invite_link',
        'community_id': widget.communityId,
        'validity_days': validityDays.toString(),
      });

      if (!mounted) return;

      final success = response['success'] == true || response['status'] == 200;
      if (!success) {
        final msg =
            response['message']?.toString() ?? 'Failed to generate invite link';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
        return;
      }

      final data = (response['data'] is Map)
          ? response['data'] as Map
          : <String, dynamic>{};
      final inviteLink = (data['invite_link'] ?? response['invite_link'] ?? '')
          .toString();

      if (inviteLink.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invite link not returned by server'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Invite Link Generated'),
          content: SelectableText(inviteLink),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: inviteLink));
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Invite link copied')),
                  );
                }
              },
              child: const Text('Copy Link'),
            ),
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
        SnackBar(
          content: Text('Error generating invite: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGeneratingLink = false);
      }
    }
  }

  Future<void> _skipInvitation() async {
    setState(() => _isLoading = true);

    // Simulate navigation delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      // Navigate to Community Groups screen
      Navigator.pushReplacementNamed(context, '/community_groups');
    }

    setState(() => _isLoading = false);
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
        title: const Text(
          'Invite Members',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _skipInvitation,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF8F7CFF),
                      ),
                    ),
                  )
                : const Text(
                    'Skip',
                    style: TextStyle(
                      color: Color(0xFF8F7CFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Community Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8E5FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.communityName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Joining Rule: ${widget.joiningRule}',
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Invite Options
            const Text(
              'Invite members to your community',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),

            const SizedBox(height: 16),

            // Invite Options List
            _inviteOption(
              icon: Icons.link,
              title: 'Invite with Link',
              subtitle: 'Share invitation link with others',
              onTap: () {
                _generateInviteLink();
              },
            ),

            _inviteOption(
              icon: Icons.email_outlined,
              title: 'Invite via Email',
              subtitle: 'Send email invitations',
              onTap: () {
                _generateInviteLink();
              },
            ),

            _inviteOption(
              icon: Icons.contacts_outlined,
              title: 'Invite from Contacts',
              subtitle: 'Select from your contacts',
              onTap: () {
                _generateInviteLink();
              },
            ),

            if (_isGeneratingLink)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            const Spacer(),

            // Skip Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _isLoading ? null : _skipInvitation,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFF8F7CFF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Color(0xFF8F7CFF),
                          ),
                        ),
                      )
                    : const Text(
                        'Skip for Now',
                        style: TextStyle(
                          color: Color(0xFF8F7CFF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inviteOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8E5FF),
        child: Icon(icon, color: const Color(0xFF8F7CFF)),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 14),
      ),
      onTap: onTap,
    );
  }
}
