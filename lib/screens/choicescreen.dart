import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/services/location_service.dart';
import 'package:commity_app1/shell.dart';
import 'package:commity_app1/theme.dart';
import 'package:flutter/material.dart';

/// Skill/Interest Model
class Skill {
  final int id;
  final String title;
  final String? type;

  Skill({required this.id, required this.title, this.type});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id:
          int.tryParse(json['id'].toString()) ??
          0, // Handle string to int conversion
      title: json['title'].toString(), // Ensure string conversion
      type: json['type']?.toString(), // Handle null type
    );
  }
}

class TopicSelectionScreen extends StatefulWidget {
  final bool isEditing;
  final List<String>? initialTopics;
  final int vendorId; // ✅ User ID

  const TopicSelectionScreen({
    super.key,
    this.isEditing = false,
    this.initialTopics,
    required this.vendorId, // ✅ Required
  });

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen> {
  // ✅ Changed from hardcoded list to API data
  List<Skill> _skills = [];
  bool _isLoadingSkills = false;
  String? _skillsError;

  final Set<int> _selectedSkillIds = {}; // ✅ Store IDs instead of names
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _fetchSkills(); // ✅ Fetch from API
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  // NEW: Fetch skills from API using Database class with proper session management
  Future<void> _fetchSkills() async {
    setState(() {
      _isLoadingSkills = true;
      _skillsError = null;
    });

    try {
      final database = Database();

      // Call Database.getData with get_interests action and vendor_id for PHP fallback
      final response = await database.getData({
        'action': 'get_interests',
        'vendor_id': widget.vendorId
            .toString(), // Pass vendor_id for PHP session validation
      });

      if (!mounted) return;

      print('Interests Response: $response'); // Debug

      if (response['success'] == true || response['status'] == 200) {
        final List<dynamic> skillsData = response['data'] ?? [];
        final skills = skillsData.map((json) => Skill.fromJson(json)).toList();

        // ADD FALLBACK TOPICS IF API RETURNS EMPTY
        if (skills.isEmpty) {
          skills.addAll([
            Skill(id: 1, title: 'Sports', type: 'interest'),
            Skill(id: 2, title: 'Technology', type: 'interest'),
            Skill(id: 3, title: 'Music', type: 'interest'),
            Skill(id: 4, title: 'Gaming', type: 'interest'),
            Skill(id: 5, title: 'Fitness', type: 'interest'),
            Skill(id: 6, title: 'Food', type: 'interest'),
            Skill(id: 7, title: 'Travel', type: 'interest'),
            Skill(id: 8, title: 'Art', type: 'interest'),
            Skill(id: 9, title: 'Education', type: 'interest'),
            Skill(id: 10, title: 'Finance', type: 'interest'),
          ]);
        }

        setState(() {
          _skills = skills;
          _isLoadingSkills = false;
        });
      } else {
        throw Exception(
          response['message'] ??
              response['error'] ??
              'Failed to fetch interests',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _skillsError = e.toString();
        _isLoadingSkills = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  // ✅ Updated filter
  List<Skill> get _filteredSkills {
    if (_searchQuery.isEmpty) return _skills;
    return _skills
        .where((skill) => skill.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  // ✅ Updated toggle - now uses skill ID
  void _toggleSkill(int skillId) {
    setState(() {
      if (_selectedSkillIds.contains(skillId)) {
        _selectedSkillIds.remove(skillId);
      } else {
        _selectedSkillIds.add(skillId);
      }
    });
  }

  void _skip() {
    // Request location even when skipping interests
    LocationService.requestAndGetLocation();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  // Updated save - now calls API through Database class with proper session management
  Future<void> _saveAndContinue() async {
    if (_selectedSkillIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final database = Database();

      // Call Database.getData with save_user_interests action
      final interestsList = _selectedSkillIds.toList();
      print('Sending interests: $interestsList'); // Debug what we're sending
      print(
        'Selected skill IDs count: ${_selectedSkillIds.length}',
      ); // Debug selection count

      // Create request body with individual interest parameters for PHP
      final requestBody = {
        'action': 'save_user_interests',
        'vendor_id': widget.vendorId
            .toString(), // Pass vendor_id for session validation
      };

      // Add each interest as a separate parameter
      for (int i = 0; i < interestsList.length; i++) {
        requestBody['interest_$i'] = interestsList[i].toString();
        print('Adding interest_$i: ${interestsList[i]}'); // Debug each interest
      }

      print('Final request body: $requestBody'); // Debug complete request

      final response = await database.getData(requestBody);

      if (!mounted) return;

      print('Save Interests Response: $response'); // Debug

      if (response['success'] == true || response['status'] == 200) {
        // ✅ Save interests locally for session persistence
        await AuthService.saveUserInterests(interestsList);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Interests saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        if (widget.isEditing) {
          Navigator.pop(context, true);
        } else {
          // ✅ Request location permission after interest selection
          LocationService.requestAndGetLocation();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AppShell()),
            (route) => false,
          );
        }
      } else {
        throw Exception(
          response['message'] ??
              response['error'] ??
              'Failed to save interests',
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(' Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  // Updated chip - now receives Skill object
  Widget _buildTopicChip(Skill skill) {
    final isSelected = _selectedSkillIds.contains(skill.id);

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: InkWell(
        onTap: () => _toggleSkill(skill.id),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.lavender : AppTheme.softLavender,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? AppTheme.lavender : AppTheme.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppTheme.lavender.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 5),
              ],
              Text(
                skill.title,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: widget.isEditing
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text(
                'Edit Interests',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: Column(
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(24, widget.isEditing ? 8 : 52, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditing) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppTheme.softLavender,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.interests_rounded,
                          color: AppTheme.lavender,
                          size: 26,
                        ),
                      ),
                      TextButton(
                        onPressed: _skip,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: AppTheme.muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  widget.isEditing
                      ? 'Choose your Interests'
                      : 'Choose your Interests',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isEditing
                      ? 'Add or remove topics to personalize your feed'
                      : 'Select at least 1 topic to personalize your experience',
                  style: const TextStyle(color: AppTheme.muted, fontSize: 14),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.black),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                hintStyle: TextStyle(color: AppTheme.muted.withOpacity(0.7)),
                filled: true,
                fillColor: AppTheme.softLavender,
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: AppTheme.muted,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.clear_rounded,
                          color: AppTheme.muted,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.lavender,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ✅ Topics list with loading/error states
          Expanded(
            child: _isLoadingSkills
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading interests...',
                          style: TextStyle(color: AppTheme.muted),
                        ),
                      ],
                    ),
                  )
                : _skillsError != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Error loading interests',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            _skillsError!,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _fetchSkills,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.lavender,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_selectedSkillIds.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.lavender,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${_selectedSkillIds.length} selected',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () =>
                                    setState(() => _selectedSkillIds.clear()),
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: const Text(
                                  'Clear all',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          _searchQuery.isEmpty ? 'All Topics' : 'Results',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          children: _filteredSkills
                              .map(_buildTopicChip)
                              .toList(),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
          ),
        ],
      ),

      // Bottom button
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 16,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _selectedSkillIds.isNotEmpty && !_isSaving
                ? _saveAndContinue
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lavender,
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppTheme.lavender.withOpacity(0.4),
              disabledForegroundColor: Colors.white60,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    widget.isEditing ? 'Update Interests' : 'Get Started →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
