import 'package:commity_app1/Database/Database.dart';
import 'package:flutter/material.dart';
import 'package:commity_app1/services/auth_service.dart';

class PackageBuilderApp extends StatelessWidget {
  const PackageBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Promotional Package Builder',
      theme: AppTheme.theme,
      home: const PromotionalPackageBuilderScreen(),
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF7C83FD);
  static const Color softPrimary = Color(0xFFF1F2FF);
  static const Color border = Color(0xFFE6E6F0);
  static const Color muted = Color(0xFF6B7280);
  static const Color surface = Color(0xFFF9F9FF);
  static const Color textMain = Color(0xFF1F2937);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Manrope',
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7F8FE),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontWeight: FontWeight.w700,
          fontSize: 18,
        ),
      ),
    );
  }
}

class PromotionalPackageBuilderScreen extends StatefulWidget {
  final String? communityId;
  final String? communityName;

  const PromotionalPackageBuilderScreen({
    super.key,
    this.communityId,
    this.communityName,
  });

  @override
  State<PromotionalPackageBuilderScreen> createState() =>
      _PromotionalPackageBuilderScreenState();
}

class _PromotionalPackageBuilderScreenState
    extends State<PromotionalPackageBuilderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _database = Database();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _communityIdController = TextEditingController();
  final _durationValueController = TextEditingController();
  final _fixedPriceController = TextEditingController();
  final _commissionController = TextEditingController();
  final _actionTypeController = TextEditingController();
  final _pricePerActionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _hybridActionCostController = TextEditingController();
  final _estimatedReachController = TextEditingController();
  final _impressionsController = TextEditingController();
  final _clicksController = TextEditingController();
  final _audienceController = TextEditingController();
  final _interestsController = TextEditingController();
  final _locationsController = TextEditingController();

  bool _saving = false;
  bool _savingDraft = false;

  String _durationType = 'days';
  String _pricingType = 'fixed_price';
  String _locationType = 'global';
  String _status = 'active';

  final Set<String> _applicableTo = {'new_users'};
  final Map<String, bool> _placements = {
    'homepage_banner': true,
    'featured_section': false,
    'search_top': true,
    'feed_ads': false,
    'push_notification': false,
    'email_campaign': false,
  };
  final Map<String, bool> _features = {
    'featured_badge': true,
    'trending_tag': false,
    'ai_boost': false,
    'priority_ranking': true,
  };
  final Map<String, bool> _addons = {
    'push_blast': false,
    'influencer': false,
    'extra_reach': false,
  };

  @override
  void initState() {
    super.initState();
    if (widget.communityId != null) {
      _communityIdController.text = widget.communityId!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _communityIdController.dispose();
    _durationValueController.dispose();
    _fixedPriceController.dispose();
    _commissionController.dispose();
    _actionTypeController.dispose();
    _pricePerActionController.dispose();
    _basePriceController.dispose();
    _hybridActionCostController.dispose();
    _estimatedReachController.dispose();
    _impressionsController.dispose();
    _clicksController.dispose();
    _audienceController.dispose();
    _interestsController.dispose();
    _locationsController.dispose();
    super.dispose();
  }

  List<String> _csvValues(String value) {
    return value
        .split(',')
        .map((entry) => entry.trim())
        .where((entry) => entry.isNotEmpty)
        .toList();
  }

  Future<void> _showMessage(String text, {bool isError = false}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submit({required bool saveDraft}) async {
    if (!_formKey.currentState!.validate()) return;

    final communityIdText = _communityIdController.text.trim();
    if (communityIdText.isEmpty) {
      await _showMessage('Community ID is required', isError: true);
      return;
    }

    final durationValue =
        int.tryParse(_durationValueController.text.trim()) ?? 0;
    final communityId = int.tryParse(communityIdText) ?? 0;

    if (communityId <= 0) {
      await _showMessage('Enter a valid community ID', isError: true);
      return;
    }

    setState(() {
      if (saveDraft) {
        _savingDraft = true;
      } else {
        _saving = true;
      }
    });

    try {
      final vendorId = await AuthService.getVendorIdString();

      final request = <String, dynamic>{
        'action': saveDraft ? 'add_package_draft' : 'add_package',
        if (vendorId != '0') 'vendor_id': vendorId,
        'community_id': communityId,
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'duration_value': durationValue,
        'duration_type': _durationType,
        'pricing_type': _pricingType,
        'fixed_price': _fixedPriceController.text.trim(),
        'commission': _commissionController.text.trim(),
        'action_type': _actionTypeController.text.trim(),
        'price_per_action': _pricePerActionController.text.trim(),
        'base_price': _basePriceController.text.trim(),
        'hybrid_action_cost': _hybridActionCostController.text.trim(),
        'location_type': _locationType,
        'estimated_reach': _estimatedReachController.text.trim(),
        'impressions': _impressionsController.text.trim(),
        'clicks': _clicksController.text.trim(),
        'status': saveDraft ? 'inactive' : _status,
      };

      final applicableTo = _applicableTo.toList();
      for (var i = 0; i < applicableTo.length; i++) {
        request['applicable_to[$i]'] = applicableTo[i];
      }

      final audience = _csvValues(_audienceController.text);
      for (var i = 0; i < audience.length; i++) {
        request['audience[$i]'] = audience[i];
      }

      final interests = _csvValues(_interestsController.text);
      for (var i = 0; i < interests.length; i++) {
        request['interests[$i]'] = interests[i];
      }

      final locations = _csvValues(_locationsController.text);
      for (var i = 0; i < locations.length; i++) {
        request['locations[$i]'] = locations[i];
      }

      final actions = _csvValues(_actionTypeController.text);
      for (var i = 0; i < actions.length; i++) {
        request['actions[$i]'] = actions[i];
      }

      _placements.forEach((key, value) {
        request['placements[$key]'] = value ? '1' : '0';
      });

      _features.forEach((key, value) {
        request['features[$key]'] = value ? '1' : '0';
      });

      _addons.forEach((key, value) {
        request['addons[$key]'] = value ? '1' : '0';
      });

      final response = await _database.getData(request);
      final success = response['success'] == true || response['status'] == 200;

      if (success) {
        await _showMessage(
          saveDraft ? 'Package saved as draft' : 'Package created successfully',
        );
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        await _showMessage(
          response['message']?.toString() ??
              response['error']?.toString() ??
              'Unable to save package',
          isError: true,
        );
      }
    } catch (e) {
      await _showMessage('Unable to save package: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
          _savingDraft = false;
        });
      }
    }
  }

  Widget _section({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.softPrimary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textMain,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppTheme.muted,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    String? label,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) _label(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppTheme.muted.withValues(alpha: 0.55)),
            filled: true,
            fillColor: AppTheme.softPrimary.withValues(alpha: 0.45),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppTheme.softPrimary.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _applicableTo.contains(value);
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (checked) {
        setState(() {
          if (checked) {
            _applicableTo.add(value);
          } else {
            _applicableTo.remove(value);
          }
        });
      },
      selectedColor: AppTheme.softPrimary,
      checkmarkColor: AppTheme.primary,
      labelStyle: TextStyle(
        color: selected ? AppTheme.primary : AppTheme.textMain,
        fontWeight: FontWeight.w600,
      ),
      side: BorderSide(color: selected ? AppTheme.primary : AppTheme.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }

  Widget _toggleTile({
    required String title,
    required String subtitle,
    required Map<String, bool> group,
    required String keyName,
  }) {
    final value = group[keyName] ?? false;
    return SwitchListTile.adaptive(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.muted, fontSize: 12),
      ),
      value: value,
      activeThumbColor: AppTheme.primary,
      onChanged: (checked) {
        setState(() => group[keyName] = checked);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Promotional Package Builder'),
        actions: [
          TextButton.icon(
            onPressed: _savingDraft ? null : () => _submit(saveDraft: true),
            icon: _savingDraft
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: const Text('Draft'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C83FD), Color(0xFF5D62E8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.communityName == null
                          ? 'Build a new promotional project'
                          : 'Build a promotional project for ${widget.communityName}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Create a package, configure targeting, pricing, and placements, then submit it to the backend.',
                      style: TextStyle(color: Colors.white70, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _section(
                icon: Icons.inventory_2_outlined,
                title: 'Package Basics',
                children: [
                  _field(
                    controller: _communityIdController,
                    label: 'Community ID',
                    hint: 'Enter the community ID',
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Community ID is required';
                      }
                      if (int.tryParse(value!.trim()) == null) {
                        return 'Enter a valid numeric ID';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _nameController,
                    label: 'Package Name',
                    hint: 'e.g. Summer Flash Sale',
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Package name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Short description of the promotional package',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _durationValueController,
                          label: 'Duration Value',
                          hint: '30',
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if ((value ?? '').trim().isEmpty) {
                              return 'Required';
                            }
                            if (int.tryParse(value!.trim()) == null) {
                              return 'Enter a number';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dropdown(
                          label: 'Duration Type',
                          value: _durationType,
                          items: const [
                            DropdownMenuItem(
                              value: 'seconds',
                              child: Text('Seconds'),
                            ),
                            DropdownMenuItem(
                              value: 'minutes',
                              child: Text('Minutes'),
                            ),
                            DropdownMenuItem(
                              value: 'hours',
                              child: Text('Hours'),
                            ),
                            DropdownMenuItem(
                              value: 'days',
                              child: Text('Days'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _durationType = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _dropdown(
                    label: 'Status',
                    value: _status,
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  ),
                ],
              ),
              _section(
                icon: Icons.track_changes_outlined,
                title: 'Targeting',
                children: [
                  _label('Applicable To'),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _filterChip('all_users', 'All Users'),
                      _filterChip('new_users', 'New Users'),
                      _filterChip('existing_users', 'Existing Users'),
                      _filterChip('business_users', 'Business Users'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _audienceController,
                    label: 'Audience',
                    hint: 'Comma separated values, e.g. active, premium',
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _interestsController,
                    label: 'Interests',
                    hint: 'Comma separated values, e.g. travel, tech',
                  ),
                  const SizedBox(height: 14),
                  _dropdown(
                    label: 'Location Type',
                    value: _locationType,
                    items: const [
                      DropdownMenuItem(value: 'global', child: Text('Global')),
                      DropdownMenuItem(
                        value: 'country',
                        child: Text('Country Wise'),
                      ),
                      DropdownMenuItem(value: 'city', child: Text('City Wise')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _locationType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _locationsController,
                    label: 'Locations',
                    hint: 'Comma separated values, e.g. India, Pune',
                  ),
                ],
              ),
              _section(
                icon: Icons.visibility_outlined,
                title: 'Placements',
                children: [
                  _toggleTile(
                    title: 'Homepage Banner',
                    subtitle: 'Show the package on the home page banner slot',
                    group: _placements,
                    keyName: 'homepage_banner',
                  ),
                  _toggleTile(
                    title: 'Featured Section',
                    subtitle: 'Promote inside a featured placement block',
                    group: _placements,
                    keyName: 'featured_section',
                  ),
                  _toggleTile(
                    title: 'Search Top',
                    subtitle: 'Increase visibility in search results',
                    group: _placements,
                    keyName: 'search_top',
                  ),
                  _toggleTile(
                    title: 'Feed Ads',
                    subtitle: 'Insert placements into the content feed',
                    group: _placements,
                    keyName: 'feed_ads',
                  ),
                  _toggleTile(
                    title: 'Push Notification',
                    subtitle: 'Send a push notification for promotion',
                    group: _placements,
                    keyName: 'push_notification',
                  ),
                  _toggleTile(
                    title: 'Email Campaign',
                    subtitle: 'Include the package in an email campaign',
                    group: _placements,
                    keyName: 'email_campaign',
                  ),
                ],
              ),
              _section(
                icon: Icons.payments_outlined,
                title: 'Pricing Model',
                children: [
                  _dropdown(
                    label: 'Pricing Type',
                    value: _pricingType,
                    items: const [
                      DropdownMenuItem(
                        value: 'fixed_price',
                        child: Text('Fixed Price'),
                      ),
                      DropdownMenuItem(
                        value: 'commission',
                        child: Text('Commission'),
                      ),
                      DropdownMenuItem(
                        value: 'action_based',
                        child: Text('Per Action'),
                      ),
                      DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _pricingType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _fixedPriceController,
                          label: 'Fixed Price',
                          hint: '999',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _commissionController,
                          label: 'Commission',
                          hint: '10%',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _actionTypeController,
                    label: 'Action Type / Actions',
                    hint: 'Comma separated, e.g. click, view, join',
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _pricePerActionController,
                          label: 'Price per Action',
                          hint: '5',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _basePriceController,
                          label: 'Base Price',
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _hybridActionCostController,
                    label: 'Hybrid Action Cost',
                    hint: 'Optional hybrid action cost',
                  ),
                ],
              ),
              _section(
                icon: Icons.bolt_outlined,
                title: 'Reach & Add-ons',
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _field(
                          controller: _estimatedReachController,
                          label: 'Estimated Reach',
                          hint: '100000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _field(
                          controller: _impressionsController,
                          label: 'Impressions',
                          hint: '500000',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _field(
                    controller: _clicksController,
                    label: 'Clicks',
                    hint: '1200',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _toggleTile(
                    title: 'Featured Badge',
                    subtitle: 'Display a highlighted badge for the package',
                    group: _features,
                    keyName: 'featured_badge',
                  ),
                  _toggleTile(
                    title: 'Trending Tag',
                    subtitle: 'Show the package as trending',
                    group: _features,
                    keyName: 'trending_tag',
                  ),
                  _toggleTile(
                    title: 'AI Boost',
                    subtitle: 'Use smart optimization for targeting',
                    group: _features,
                    keyName: 'ai_boost',
                  ),
                  _toggleTile(
                    title: 'Priority Ranking',
                    subtitle: 'Keep the package above lower priority items',
                    group: _features,
                    keyName: 'priority_ranking',
                  ),
                  const SizedBox(height: 8),
                  _toggleTile(
                    title: 'Push Blast',
                    subtitle: 'Enable push blast add-on',
                    group: _addons,
                    keyName: 'push_blast',
                  ),
                  _toggleTile(
                    title: 'Influencer',
                    subtitle: 'Include influencer support as an add-on',
                    group: _addons,
                    keyName: 'influencer',
                  ),
                  _toggleTile(
                    title: 'Extra Reach',
                    subtitle: 'Offer additional reach as a paid add-on',
                    group: _addons,
                    keyName: 'extra_reach',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saving ? null : () => _submit(saveDraft: false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Package',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: _savingDraft ? null : () => _submit(saveDraft: true),
                child: const Text(
                  'Save as draft for later review',
                  style: TextStyle(color: AppTheme.muted),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
