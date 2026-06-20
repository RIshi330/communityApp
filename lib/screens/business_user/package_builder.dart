import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../app_constants.dart';

void main() {
  runApp(const PackageBuilderApp());
}

class PackageBuilderApp extends StatelessWidget {
  const PackageBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Package Builder Hub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Manrope',
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: Color(0xFF474DC5),
          onPrimary: Color(0xFFFFFFFF),
          primaryContainer: Color(0xFF6067DF),
          onPrimaryContainer: Color(0xFFFFFFFF),
          secondary: Color(0xFF5C5E69),
          onSecondary: Color(0xFFFFFFFF),
          secondaryContainer: Color(0xFFDEDFEC),
          onSecondaryContainer: Color(0xFF60626D),
          tertiary: Color(0xFF805200),
          onTertiary: Color(0xFFFFFFFF),
          error: Color(0xFFBA1A1A),
          onError: Color(0xFFFFFFFF),
          background: Color(0xFFF9F9FF),
          onBackground: Color(0xFF151C27),
          surface: Color(0xFFF9F9FF),
          onSurface: Color(0xFF151C27),
          surfaceVariant: Color(0xFFDCE2F3),
          onSurfaceVariant: Color(0xFF464653),
          outline: Color(0xFF767685),
          outlineVariant: Color(0xFFC6C5D6),
          shadow: Color(0xFF000000),
          scrim: Color(0xFF000000),
          inverseSurface: Color(0xFF2A313D),
          onInverseSurface: Color(0xFFEBF1FF),
          inversePrimary: Color(0xFFBFC2FF),
          surfaceTint: Color(0xFF474DC5),
        ),
        scaffoldBackgroundColor: const Color(0xFFF9F9FF),
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          elevation: 0,
          scrolledUnderElevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF151C27),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6E6F0), width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE6E6F0), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF474DC5), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
      home: const PackageBuilderHome(),
    );
  }
}

// ===================== API Service =====================
class ApiService {
  // Replace with your actual API URL
  static const String apiEndpoint = '${baseUrl}new_apis/package_builder_api.php';

  static Future<Map<String, dynamic>> post(String action, Map<String, dynamic> data) async {
    try {
      final body = jsonEncode({
        'action': action,
        ...data,
      });
      print(action);

      final response = await http.post(
        Uri.parse(apiEndpoint),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: body,
      );
      print(response.body);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
        print(response.statusCode);
      } else {
        return {'success': false, 'message': 'Server error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  static Future<String?> uploadImage(File imageFile) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/upload_image.php'));
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = jsonDecode(responseData);
        print(response.statusCode);
        return jsonData['image_url'];
      }
      return null;
    } catch (e) {
      print('Upload error: $e');
      return null;
    }
  }
}

// ===================== Models =====================
class PackageModel {
  final String id;
  String title;
  String description;
  int price;
  String tags;
  String benefits;
  String deliverables;
  String timeline;
  String mode;
  String imageUrl;
  int discount;
  String discountType;
  String saveType;
  int status;

  PackageModel({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.tags,
    required this.benefits,
    required this.deliverables,
    required this.timeline,
    required this.mode,
    required this.imageUrl,
    required this.discount,
    required this.discountType,
    required this.saveType,
    required this.status,
  });

  factory PackageModel.fromJson(Map<String, dynamic> json) {
    return PackageModel(
      id: json['id']?.toString() ?? '',
      title: json['name'] ?? '',
      description: json['desc'] ?? '',
      price: (json['price'] as num?)?.toInt() ?? 0,
      tags: json['tags'] ?? '',
      benefits: json['benefits'] ?? '',
      deliverables: json['deliverables'] ?? '',
      timeline: json['timeline'] ?? '',
      mode: json['mode'] ?? '',
      imageUrl: json['img'] ?? '',
      discount: (json['discount'] as num?)?.toInt() ?? 0,
      discountType: json['discountType'] ?? '',
      saveType: json['save_type'] ?? 'TEMPLATE',
      status: json['status'] ?? 0,
    );
  }

  List<String> get tagsList => tags.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  List<String> get benefitsList => benefits.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  List<String> get deliverablesList => deliverables.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  List<String> get timelineList => timeline.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
}

class CategoryModel {
  final String id;
  final String name;
  final String image;

  CategoryModel({required this.id, required this.name, required this.image});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['category_title'] ?? '',
      image: json['image'] ?? json['image_url'] ?? '',
    );
  }
}

// ===================== Main Home Screen =====================
class PackageBuilderHome extends StatefulWidget {
  const PackageBuilderHome({super.key});

  @override
  State<PackageBuilderHome> createState() => _PackageBuilderHomeState();
}

class _PackageBuilderHomeState extends State<PackageBuilderHome> {
  int _selectedNavIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  List<PackageModel> _packages = [];
  bool _isLoading = true;
  String _sortBy = '';
  String _selectedCategory = '';

  @override
  void initState() {
    super.initState();
    _fetchPackages();
    _checkServicePosts();
  }

  Future<void> _fetchPackages() async {
    setState(() => _isLoading = true);
    final response = await ApiService.post('get_services', {
      'search': _searchController.text,
      'sort': _sortBy,
      'cat_id': _selectedCategory,
    });

    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      setState(() {
        _packages = data.map((item) => PackageModel.fromJson(item)).toList();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to load packages')),
      );
    }
  }

  Future<void> _checkServicePosts() async {
    final response = await ApiService.post('checkServicePosts', {});
    if (response['success'] == true) {
      final postsLeft = response['data']['posts_left'] ?? 0;
      if (postsLeft <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You have no posts left. Please buy a membership or package.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<List<CategoryModel>> _fetchCategories() async {
    final response = await ApiService.post('get_categories', {});
    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => CategoryModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<List<CategoryModel>> _fetchSubCategories(String catId) async {
    if (catId.isEmpty) return [];
    final response = await ApiService.post('get_sub_categories', {'cat_id': catId});
    if (response['success'] == true) {
      final List<dynamic> data = response['data'] ?? [];
      return data.map((item) => CategoryModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<void> _createPackage(Map<String, dynamic> data) async {
    final response = await ApiService.post('save_service', data);
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package created successfully!'), backgroundColor: Colors.green),
      );
      _fetchPackages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to create package'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updatePackage(String serviceId, Map<String, dynamic> data) async {
    final response = await ApiService.post('edit_service', {
      ...data,
      'service_id': serviceId,
    });
    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package updated successfully!'), backgroundColor: Colors.green),
      );
      _fetchPackages();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['message'] ?? 'Failed to update package'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _onCustomizePress(PackageModel? package) async {
    final categories = await _fetchCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EditPackageSheet(
        package: package,
        categories: categories,
        subCategories: const [],
        onSave: (updatedData) async {
          if (package == null) {
            await _createPackage(updatedData);
          } else {
            await _updatePackage(package.id, updatedData);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Package Builder'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {},
              color: colorScheme.primary,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {},
                color: colorScheme.primary,
              ),
            ],
            backgroundColor: Colors.white,
            foregroundColor: colorScheme.onSurface,
            surfaceTintColor: Colors.transparent,
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => _fetchPackages(),
                      decoration: InputDecoration(
                        hintText: 'Search packages...',
                        prefixIcon: const Icon(Icons.search, size: 22),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE6E6F0)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showSortDialog(),
                            icon: const Icon(Icons.sort, size: 18),
                            label: const Text('Sort'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE6E6F0)),
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showFilterDialog(),
                            icon: const Icon(Icons.filter_list, size: 18),
                            label: const Text('Filter'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              side: const BorderSide(color: Color(0xFFE6E6F0)),
                              foregroundColor: colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Packages',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => _fetchPackages(),
                          child: const Text('Refresh'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
                if (!_isLoading && _packages.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No packages found. Create your first package!'),
                    ),
                  ),
                ..._packages.map((package) => _buildPackageCard(package, theme, colorScheme)),
                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _onCustomizePress(null),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPackageCard(PackageModel package, ThemeData theme, ColorScheme colors) {
    final finalPrice = package.discount > 0
        ? package.discountType == '%'
        ? package.price - (package.price * package.discount / 100)
        : package.price - package.discount
        : package.price;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6E6F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                child: package.imageUrl.isNotEmpty
                    ? Image.network(
                  package.imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 160,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.image, size: 50),
                  ),
                )
                    : Container(
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image, size: 50),
                ),
              ),
              if (package.discount > 0)
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${package.discountType == '%' ? package.discount : '₹${package.discount}'} OFF',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(package.title, style: theme.textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Text(
                            package.description,
                            style: theme.textTheme.bodyMedium?.copyWith(color: const Color(0xFF6B7280)),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (package.discount > 0)
                          Text(
                            '₹${package.price}',
                            style: const TextStyle(fontSize: 12, decoration: TextDecoration.lineThrough, color: Color(0xFF9CA3AF)),
                          ),
                        Text(
                          '₹${finalPrice.toInt()}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontSize: 20,
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: package.tagsList.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F2FF),
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Text(tag, style: theme.textTheme.labelMedium?.copyWith(color: colors.primary)),
                  )).toList(),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1, color: Color(0xFFE6E6F0)),
                const SizedBox(height: 12),
                Text(
                  'KEY BENEFITS',
                  style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...package.benefitsList.take(2).map((benefit) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.stars, size: 16, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(child: Text(benefit, style: theme.textTheme.bodyMedium)),
                    ],
                  ),
                )),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _onCustomizePress(package),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Customize & Use'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sort by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Recommended'),
              leading: const Icon(Icons.trending_up),
              onTap: () {
                setState(() => _sortBy = '');
                _fetchPackages();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Price: Low to High'),
              leading: const Icon(Icons.arrow_upward),
              onTap: () {
                setState(() => _sortBy = 'low');
                _fetchPackages();
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('Price: High to Low'),
              leading: const Icon(Icons.arrow_downward),
              onTap: () {
                setState(() => _sortBy = 'high');
                _fetchPackages();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filter Packages'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(title: Text('Category: All'), leading: Icon(Icons.category)),
            ListTile(title: Text('Price Range: Under ₹3000'), leading: Icon(Icons.currency_rupee)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Apply')),
        ],
      ),
    );
  }
}

// ===================== Enhanced Edit/Create Bottom Sheet =====================
class EditPackageSheet extends StatefulWidget {
  final PackageModel? package;
  final List<CategoryModel> categories;
  final List<CategoryModel> subCategories;
  final Function(Map<String, dynamic>) onSave;

  const EditPackageSheet({
    super.key,
    this.package,
    required this.categories,
    required this.subCategories,
    required this.onSave,
  });

  @override
  State<EditPackageSheet> createState() => _EditPackageSheetState();
}

class _EditPackageSheetState extends State<EditPackageSheet> {
  late TextEditingController _titleController;
  late TextEditingController _priceController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  late TextEditingController _benefitsController;
  late TextEditingController _deliverablesController;
  late TextEditingController _timelineController;
  late TextEditingController _modeController;
  late TextEditingController _discountController;
  late String _discountType;
  late String _selectedCategory;
  String? _imageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.package?.title ?? '');
    _priceController = TextEditingController(text: widget.package?.price.toString() ?? '');
    _descController = TextEditingController(text: widget.package?.description ?? '');
    _tagsController = TextEditingController(text: widget.package?.tags ?? '');
    _benefitsController = TextEditingController(text: widget.package?.benefits ?? '');
    _deliverablesController = TextEditingController(text: widget.package?.deliverables ?? '');
    _timelineController = TextEditingController(text: widget.package?.timeline ?? '');
    _modeController = TextEditingController(text: widget.package?.mode ?? '');
    _discountController = TextEditingController(text: widget.package?.discount.toString() ?? '');
    _discountType = (widget.package?.discountType.isEmpty == true || widget.package?.discountType == null) ? '%' : widget.package!.discountType;
    _selectedCategory = '';
    _imageUrl = widget.package?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _benefitsController.dispose();
    _deliverablesController.dispose();
    _timelineController.dispose();
    _modeController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUploading = true);
      // TODO: Implement actual image upload to your server
      // final uploadedUrl = await ApiService.uploadImage(File(image.path));
      // if (uploadedUrl != null) {
      //   setState(() => _imageUrl = uploadedUrl);
      // }
      // For demo, just set local path
      setState(() {
        _imageUrl = image.path;
        _isUploading = false;
      });
    }
  }

  void _save() {
    final data = {
      'site_id': 1,
      'cat_id': _selectedCategory,
      'title': _titleController.text,
      'description': _descController.text,
      'tags': _tagsController.text,
      'benefits': _benefitsController.text,
      'deliverables': _deliverablesController.text,
      'timeline': _timelineController.text,
      'mode': _modeController.text,
      'price': double.tryParse(_priceController.text) ?? 0,
      'discountType': _discountType,
      'discount': double.tryParse(_discountController.text) ?? 0,
      'image': _imageUrl ?? '',
      'save_type': widget.package?.saveType ?? 'TEMPLATE',
    };
    widget.onSave(data);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.96,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.package == null ? 'Create New Package' : 'Edit Package',
                style: theme.textTheme.headlineSmall?.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // Image Picker
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE6E6F0)),
                        ),
                        child: _isUploading
                            ? const Center(child: CircularProgressIndicator())
                            : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _imageUrl!.startsWith('http')
                              ? Image.network(_imageUrl!, fit: BoxFit.cover, width: double.infinity, height: 140)
                              : Image.file(File(_imageUrl!), fit: BoxFit.cover, width: double.infinity, height: 140),
                        )
                            : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            Text('Tap to add image', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory.isEmpty ? null : _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                      items: widget.categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                      onChanged: (value) => setState(() => _selectedCategory = value ?? ''),
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Package Title',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Price
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Price (INR)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Discount Row (Fixed - no SegmentedButton)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Discount',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('%'),
                                    value: '%',
                                    groupValue: _discountType,
                                    onChanged: (value) => setState(() => _discountType = value!),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Flat ₹'),
                                    value: 'flat',
                                    groupValue: _discountType,
                                    onChanged: (value) => setState(() => _discountType = value!),
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextField(
                      controller: _descController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Tags
                    TextField(
                      controller: _tagsController,
                      decoration: const InputDecoration(
                        labelText: 'Tags (comma separated)',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Ads, Growth, Banners',
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Benefits
                    TextField(
                      controller: _benefitsController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Benefits (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Deliverables
                    TextField(
                      controller: _deliverablesController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Deliverables (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Timeline
                    TextField(
                      controller: _timelineController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Timeline (comma separated)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Mode
                    TextField(
                      controller: _modeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Mode',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Online, In-person',
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _save,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: Text(widget.package == null ? 'Create Package' : 'Save Changes'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}