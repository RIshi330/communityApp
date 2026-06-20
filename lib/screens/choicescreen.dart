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

  const Skill({required this.id, required this.title, this.type});

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: int.tryParse(json['id'].toString()) ?? 0,
      title: json['title'].toString(),
      type: json['type']?.toString(),
    );
  }
}

// Emoji map for visual interest icons
const Map<String, String> _interestEmojis = {
  'sports': '⚽',
  'technology': '💻',
  'music': '🎵',
  'gaming': '🎮',
  'fitness': '💪',
  'food': '🍕',
  'travel': '✈️',
  'art': '🎨',
  'education': '📚',
  'finance': '💰',
  'fashion': '👗',
  'health': '🏥',
  'science': '🔬',
  'movies': '🎬',
  'books': '📖',
  'photography': '📷',
  'nature': '🌿',
  'politics': '🏛️',
  'business': '💼',
  'cooking': '🍳',
  'pets': '🐾',
  'yoga': '🧘',
  'comedy': '😂',
  'spirituality': '🙏',
};

String _emojiFor(String title) {
  final key = title.toLowerCase().trim();
  for (final entry in _interestEmojis.entries) {
    if (key.contains(entry.key)) return entry.value;
  }
  return '✨';
}

class TopicSelectionScreen extends StatefulWidget {
  final bool isEditing;
  final List<String>? initialTopics;
  final int vendorId;

  const TopicSelectionScreen({
    super.key,
    this.isEditing = false,
    this.initialTopics,
    required this.vendorId,
  });

  @override
  State<TopicSelectionScreen> createState() => _TopicSelectionScreenState();
}

class _TopicSelectionScreenState extends State<TopicSelectionScreen>
    with SingleTickerProviderStateMixin {
  List<Skill> _skills = [];
  bool _isLoadingSkills = false;
  String? _skillsError;

  final Set<int> _selectedSkillIds = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSaving = false;

  late final AnimationController _fabAnim;
  late final Animation<double> _fabScale;

  static const List<Skill> _fallbackSkills = [
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
  ];

  @override
  void initState() {
    super.initState();
    _fabAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fabScale = CurvedAnimation(parent: _fabAnim, curve: Curves.elasticOut);
    _fetchSkills();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _fabAnim.dispose();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchSkills() async {
    setState(() {
      _isLoadingSkills = true;
      _skillsError = null;
    });

    try {
      final database = Database();
      final response = await database.getData({
        'action': 'get_interests',
        'vendor_id': widget.vendorId.toString(),
      });

      if (!mounted) return;

      debugPrint('Interests Response: $response');

      if (response['success'] == true || response['status'] == 200) {
        final List<dynamic> skillsData = response['data'] ?? [];
        final skills = skillsData
            .map((json) => Skill.fromJson(json as Map<String, dynamic>))
            .where((s) => s.id > 0)
            .toList();

        setState(() {
          _skills = skills.isEmpty ? _fallbackSkills : skills;
          _isLoadingSkills = false;
        });
      } else {
        throw Exception(
          response['message'] ?? response['error'] ?? 'Failed to fetch interests',
        );
      }
    } catch (e) {
      if (!mounted) return;
      // On error, show fallback skills so the user can still proceed
      setState(() {
        _skills = _fallbackSkills;
        _skillsError = e.toString();
        _isLoadingSkills = false;
      });
    }
  }

  void _onSearchChanged() {
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  List<Skill> get _filteredSkills {
    if (_searchQuery.isEmpty) return _skills;
    return _skills
        .where((s) => s.title.toLowerCase().contains(_searchQuery))
        .toList();
  }

  void _toggleSkill(int skillId) {
    setState(() {
      if (_selectedSkillIds.contains(skillId)) {
        _selectedSkillIds.remove(skillId);
      } else {
        _selectedSkillIds.add(skillId);
      }
    });
    // Animate the bottom button
    if (_selectedSkillIds.isNotEmpty) {
      _fabAnim.forward();
    } else {
      _fabAnim.reverse();
    }
  }

  void _skip() {
    LocationService.requestAndGetLocation();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
    );
  }

  Future<void> _saveAndContinue() async {
    if (_selectedSkillIds.isEmpty) {
      _showSnack('Please select at least one interest', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final database = Database();
      final interestsList = _selectedSkillIds.toList();

      // Backend expects 'interests' as an array (see save_user_interests action)
      final requestBody = <String, dynamic>{
        'action': 'save_user_interests',
        'interests': interestsList, // array of ints, matches $input['interests']
      };

      debugPrint('Saving interests: $requestBody');
      final response = await database.getData(requestBody);

      if (!mounted) return;

      debugPrint('Save Interests Response: $response');

      if (response['success'] == true || response['status'] == 200) {
        await AuthService.saveUserInterests(interestsList);
        _showSnack('Interests saved!', isError: false);

        if (widget.isEditing) {
          Navigator.pop(context, true);
        } else {
          LocationService.requestAndGetLocation();
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AppShell()),
                (route) => false,
          );
        }
      } else {
        throw Exception(
          response['message'] ?? response['error'] ?? 'Failed to save interests',
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 14))),
          ],
        ),
        backgroundColor: isError ? const Color(0xFFE53935) : const Color(0xFF43A047),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );
  }

  Widget _buildChip(Skill skill) {
    final isSelected = _selectedSkillIds.contains(skill.id);
    final emoji = _emojiFor(skill.title);

    return GestureDetector(
      onTap: () => _toggleSkill(skill.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.lavender : Colors.white,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? AppTheme.lavender : const Color(0xFFE0D8F5),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppTheme.lavender.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3))]
              : [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 15)),
            const SizedBox(width: 6),
            Text(
              skill.title,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                letterSpacing: 0.1,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 5),
              const Icon(Icons.check_rounded, color: Colors.white, size: 14),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Wrap(
        spacing: 10,
        runSpacing: 12,
        children: List.generate(14, (i) {
          final widths = [80.0, 110.0, 90.0, 120.0, 75.0, 100.0, 95.0, 85.0, 115.0, 70.0, 105.0, 88.0, 92.0, 78.0];
          return _SkeletonChip(width: widths[i]);
        }),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6FF),
      appBar: widget.isEditing
          ? AppBar(
        backgroundColor: const Color(0xFFF8F6FF),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2D2D2D), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Edit Interests',
          style: TextStyle(color: Color(0xFF2D2D2D), fontWeight: FontWeight.w700, fontSize: 18),
        ),
      )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(24, widget.isEditing ? 12 : 56, 24, 0),
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
                          color: AppTheme.lavender.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text('✨', style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      TextButton(
                        onPressed: _skip,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        child: const Text(
                          'Skip for now',
                          style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 14, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
                const Text(
                  'What are you into?',
                  style: TextStyle(
                    color: Color(0xFF1A1A2E),
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  widget.isEditing
                      ? 'Add or remove topics to personalize your feed'
                      : 'Pick topics you love — we\'ll tailor your feed just for you',
                  style: const TextStyle(color: Color(0xFF888888), fontSize: 14.5, height: 1.5),
                ),
                const SizedBox(height: 22),
              ],
            ),
          ),

          // ── Search Bar ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE8E0FF), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Color(0xFF2D2D2D), fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Search interests…',
                  hintStyle: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 14.5),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFBBBBBB), size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.close_rounded, color: Color(0xFFBBBBBB), size: 18),
                    onPressed: () {
                      _searchController.clear();
                      FocusScope.of(context).unfocus();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Selection badge ─────────────────────────────────────
          if (_selectedSkillIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.lavender,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_selectedSkillIds.length} selected',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedSkillIds.clear());
                      _fabAnim.reverse();
                    },
                    child: const Text(
                      'Clear all',
                      style: TextStyle(color: Color(0xFFE53935), fontSize: 12.5, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),

          // ── Chips / States ──────────────────────────────────────
          Expanded(
            child: _isLoadingSkills
                ? SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _buildLoadingSkeleton(),
                ],
              ),
            )
                : _skills.isEmpty
                ? _buildEmptyState()
                : _buildChipGrid(),
          ),
        ],
      ),

      // ── Bottom CTA ──────────────────────────────────────────────
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(24, 16, 24, bottomPad + 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F6FF),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, -4))],
        ),
        child: ScaleTransition(
          scale: _selectedSkillIds.isNotEmpty ? const AlwaysStoppedAnimation(1.0) : _fabScale,
          child: SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: _selectedSkillIds.isNotEmpty && !_isSaving ? _saveAndContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.lavender,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppTheme.lavender.withOpacity(0.35),
                disabledForegroundColor: Colors.white60,
                elevation: _selectedSkillIds.isNotEmpty ? 4 : 0,
                shadowColor: AppTheme.lavender.withOpacity(0.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isSaving
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    widget.isEditing ? 'Update Interests' : 'Continue',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.2),
                  ),
                  if (!widget.isEditing) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward_rounded, size: 20),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChipGrid() {
    final filtered = _filteredSkills;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🔍', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(
              'No results for "$_searchQuery"',
              style: const TextStyle(color: Color(0xFF888888), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section label
          if (_skillsError != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, size: 16, color: Color(0xFFE65100)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Showing default interests — couldn\'t reach server',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFFE65100)),
                    ),
                  ),
                  GestureDetector(
                    onTap: _fetchSkills,
                    child: const Text(
                      'Retry',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFFE65100), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),

          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              _searchQuery.isEmpty
                  ? '${_skills.length} topics available'
                  : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
              style: const TextStyle(color: Color(0xFFBBBBBB), fontSize: 12.5, fontWeight: FontWeight.w600, letterSpacing: 0.3),
            ),
          ),

          Wrap(
            spacing: 10,
            runSpacing: 12,
            children: filtered.map(_buildChip).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('😕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text(
            'No interests found',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF444444)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Pull to refresh or tap retry below',
            style: TextStyle(fontSize: 13.5, color: Color(0xFF888888)),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _fetchSkills,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.lavender,
              side: BorderSide(color: AppTheme.lavender),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton placeholder chip while loading
class _SkeletonChip extends StatefulWidget {
  final double width;
  const _SkeletonChip({required this.width});

  @override
  State<_SkeletonChip> createState() => _SkeletonChipState();
}

class _SkeletonChipState extends State<_SkeletonChip> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: 40,
        decoration: BoxDecoration(
          color: Color.lerp(const Color(0xFFEEE8FF), const Color(0xFFD8CCFF), _anim.value),
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }
}