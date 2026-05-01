import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:commity_app1/Database/Database.dart';

class VendorPromotionDashboard extends StatefulWidget {
  const VendorPromotionDashboard({super.key});

  @override
  State<VendorPromotionDashboard> createState() => _VendorPromotionDashboardState();
}

class _VendorPromotionDashboardState extends State<VendorPromotionDashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _packages = [];
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPackages();
    _loadOrders();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final response = await Database().getData({
        'action': 'get_packages',
        // The PHP script relies on session vendor_id, but if needed we can pass it here.
      });
      if (response['success'] == true || response['status'] == 200) {
        setState(() {
          _packages = response['data'] is List ? response['data'] : (response['data']['packages'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error loading vendor packages: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadOrders() async {
    try {
      final response = await Database().getData({
        'action': 'get_package_orders',
      });
      if (response['success'] == true || response['status'] == 200) {
        if (mounted) {
          setState(() {
            _orders = response['data'] is List ? response['data'] : [];
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading orders: $e');
    }
  }

  void _showCreatePackageModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _CreatePackageSheet(
        onSaved: () {
          _loadPackages();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activePackages = _packages.where((p) => p['status'] == 1).toList();
    final draftPackages = _packages.where((p) => p['status'] == 0).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6B46C1),
        foregroundColor: Colors.white,
        title: const Text('Vendor Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Packages'),
            Tab(text: 'Drafts'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPackageList(activePackages),
                _buildPackageList(draftPackages),
                _buildOrdersList(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePackageModal,
        backgroundColor: const Color(0xFF6B46C1),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Create Package', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPackageList(List<dynamic> packages) {
    if (packages.isEmpty) {
      return const Center(child: Text('No packages found.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: packages.length,
      itemBuilder: (context, index) {
        final pkg = packages[index];
        final price = pkg['price']?.toString() ?? '0';
        final orders = pkg['orders_count']?.toString() ?? '0';
        final revenue = pkg['revenue']?.toString() ?? '0';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pkg['name']?.toString() ?? 'Untitled',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B46C1).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹$price',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF6B46C1)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  pkg['description']?.toString() ?? 'No description',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
                const SizedBox(height: 12),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statColumn('Orders', orders, Icons.shopping_bag_outlined),
                    _statColumn('Revenue', '₹$revenue', Icons.monetization_on_outlined),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
      ],
    );
  }

  Widget _buildOrdersList() {
    if (_orders.isEmpty) {
      return const Center(child: Text('No orders found.', style: TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final order = _orders[index];
        final amount = order['amount']?.toString() ?? '0';
        final status = order['status']?.toString() ?? 'Unknown';
        final pkgName = order['package_name']?.toString() ?? 'Unknown Package';

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xFFE9D8FD),
              child: Icon(Icons.receipt_long, color: Color(0xFF6B46C1)),
            ),
            title: Text(pkgName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Status: $status'),
            trailing: Text(
              '₹$amount',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF6B46C1)),
            ),
          ),
        );
      },
    );
  }
}

class _CreatePackageSheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _CreatePackageSheet({required this.onSaved});

  @override
  State<_CreatePackageSheet> createState() => _CreatePackageSheetState();
}

class _CreatePackageSheetState extends State<_CreatePackageSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _durationValueCtrl = TextEditingController();
  String _durationType = 'Days';
  bool _isSaving = false;

  Future<void> _submit(bool isDraft) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final payload = {
        'action': isDraft ? 'add_package_draft' : 'add_package',
        'name': _nameCtrl.text,
        'description': _descCtrl.text,
        'duration_value': _durationValueCtrl.text,
        'duration_type': _durationType,
        'pricing': jsonEncode({'type': 'Fixed', 'amount': _priceCtrl.text}),
        'targeting': jsonEncode({'audience': ['General']}),
        'features': jsonEncode(['Standard Support']),
        'addons': jsonEncode({}),
        'placements': jsonEncode({'Feed': true}),
      };

      final response = await Database().getData(payload);

      if (!mounted) return;
      if (response['success'] == true || response['status'] == 'success') {
        Navigator.pop(context);
        widget.onSaved();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isDraft ? 'Saved as draft' : 'Package published')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to save package')),
        );
      }
    } catch (e) {
      debugPrint('Error saving package: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Create New Package', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Package Name', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Base Price (₹)', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _durationValueCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Duration', border: OutlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: _durationType,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: ['Days', 'Weeks', 'Months']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _durationType = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _isSaving
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => _submit(true),
                          child: const Text('Save as Draft'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6B46C1), foregroundColor: Colors.white),
                          onPressed: () => _submit(false),
                          child: const Text('Publish Package'),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
