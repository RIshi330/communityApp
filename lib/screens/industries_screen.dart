import 'package:flutter/material.dart';

// तुमचा AppColors क्लास
class AppColors {
  static const accent = Color(0xFF7C83FD);
  static const accent2 = Color(0xFF9EA3FF);
  static const accentSoft = Color(0xFFEEEFFF);
  static const bg = Color(0xFFF5F5FF);
  static const card = Color(0xFFFFFFFF);
  static const border = Color(0xFFE4E5FF);
  static const muted = Color(0xFF6B7280);
  static const text = Color(0xFF1A1A2E);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444); 
  static const lavenderBg = Color(0xFFF3E8FF);
  static const textDark = Color(0xFF1F1F1F);
  static const textMuted = Color(0xFF6B7280);
}

class TopicSelectionScreen2 extends StatefulWidget {
  final List<String>? initialTopics;

  const TopicSelectionScreen2({
    super.key,
    this.initialTopics,
  });

  @override
  State<TopicSelectionScreen2> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen2> {
  // Hardcoded list of topics
  final List<String> _allTopics = [
    'IT & Software', 'Medical & Healthcare', 'Media & Entertainment', 'Finance & Banking',
    'Education', 'E-commerce', 'Manufacturing',
    'Real Estate', 'Food & Beverage', 'Transportation', 'Travel & Tourism',
    'Cloud Computing', 'Web Development', 'Mobile Development', 'Gaming',
    'E-commerce', 'Fintech', 'Healthtech', 'Edutech', 'SaaS', 'Content Creation',
    'Photography', 'Videography', 'Music Production', 'Creative Writing',
    'Public Speaking', 'Leadership', 'Entrepreneurship', 'Investing',
    'Personal Finance', 'Fitness & Health', 'Travel', 'Cooking & Food',
  ];

  final Set<String> _selectedTopics = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTopics != null) {
      _selectedTopics.addAll(widget.initialTopics!);
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  List<String> get _filteredTopics {
    if (_searchQuery.isEmpty) return _allTopics;
    return _allTopics
        .where((topic) => topic.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _toggleSkill(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  // Save button UI logic only (Navigation removed)
  void _saveAndContinue() {
    if (_selectedTopics.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one interest'),
          backgroundColor: AppColors.danger, // Updated to AppColors.danger
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    
    // Navigation removed as requested
    print("Selected Topics: $_selectedTopics");
  }

  Widget _buildTopicChip(String topic) {
    final isSelected = _selectedTopics.contains(topic);

    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 10),
      child: InkWell(
        onTap: () => _toggleSkill(topic),
        borderRadius: BorderRadius.circular(30),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : AppColors.card,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? AppColors.accent : AppColors.border,
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [BoxShadow(color: AppColors.accent.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
                : [],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 14),
                const SizedBox(width: 5),
              ],
              Text(
                topic,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.text,
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
      backgroundColor: AppColors.bg, // Updated background color
      
      // Left Drawer Setup
      drawer: Drawer(
        backgroundColor: AppColors.card,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: AppColors.accent, // Updated to AppColors.accent
              ),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: AppColors.muted),
              title: const Text('Option 1', style: TextStyle(color: AppColors.textDark)),
              onTap: () {
                // इथे तुमचे Navigation कोड टाका (Option 1 साठी)
              },
            ),
            ListTile(
              leading: const Icon(Icons.person, color: AppColors.muted),
              title: const Text('Option 2', style: TextStyle(color: AppColors.textDark)),
              onTap: () {
                // इथे तुमचे Navigation कोड टाका (Option 2 साठी)
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings, color: AppColors.muted),
              title: const Text('Option 3', style: TextStyle(color: AppColors.textDark)),
              onTap: () {
                // इथे तुमचे Navigation कोड टाका (Option 3 साठी)
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications, color: AppColors.muted),
              title: const Text('Option 4', style: TextStyle(color: AppColors.textDark)),
              onTap: () {
                // इथे तुमचे Navigation कोड टाका (Option 4 साठी)
              },
            ),
            ListTile(
              leading: const Icon(Icons.help, color: AppColors.muted),
              title: const Text('Option 5', style: TextStyle(color: AppColors.textDark)),
              onTap: () {
                // इथे तुमचे Navigation कोड टाका (Option 5 साठी)
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: AppColors.danger),
              title: const Text('Option 6', style: TextStyle(color: AppColors.danger)),
              onTap: () {
                // इथे तुमचे Navigation कोड टाका (Option 6 साठी)
              },
            ),
          ],
        ),
      ),

      // AppBar Setup with Menu Icon
      appBar: AppBar(
        backgroundColor: AppColors.bg, // Match Scaffold background
        elevation: 0,
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.text), // Ensure proper back button
              onPressed: () {
                Navigator.pop(context); // Fixed leading back button
              },
            );
          },
        ),
        title: const Text(
          'Industries',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
      ),

      body: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.accentSoft, // Updated color
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.business_center_rounded, color: AppColors.accent, size: 26),
                    ),
                    TextButton(
                      onPressed: () {
                        // Skip Button UI Logic
                      },
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: AppColors.muted, // Updated color
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Choose your Industries',
                  style: TextStyle(
                    color: AppColors.text, // Updated color
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Select at least 1 topic to personalize your experience',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 14), // Updated color
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
              style: const TextStyle(color: AppColors.text),
              decoration: InputDecoration(
                hintText: 'Search topics...',
                hintStyle: TextStyle(color: AppColors.muted.withOpacity(0.7)),
                filled: true,
                fillColor: AppColors.card, // Updated to AppColors.card for contrast on bg
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.muted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, color: AppColors.muted),
                        onPressed: () {
                          _searchController.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.accent, width: 2),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Topics list
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedTopics.isNotEmpty) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent, // Updated color
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_selectedTopics.length} selected',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => setState(() => _selectedTopics.clear()),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Clear all',
                            style: TextStyle(color: AppColors.danger, fontSize: 12), // Updated to AppColors.danger
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    _searchQuery.isEmpty ? 'All Topics' : 'Results',
                    style: const TextStyle(
                      color: AppColors.muted, // Updated color
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    children: _filteredTopics.map(_buildTopicChip).toList(),
                  ),
                  const SizedBox(height: 100), // Padding for bottom button
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom button
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
        decoration: BoxDecoration(
          color: AppColors.card, // Updated color
          border: const Border(top: BorderSide(color: AppColors.border)), // Added subtle border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          height: 54,
          child: ElevatedButton(
            onPressed: _selectedTopics.isNotEmpty ? _saveAndContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent, // Updated color
              foregroundColor: Colors.white,
              disabledBackgroundColor: AppColors.accent.withOpacity(0.4),
              disabledForegroundColor: Colors.white60,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Get Started →',
              style: TextStyle(
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
