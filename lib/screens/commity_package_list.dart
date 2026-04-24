import 'package:flutter/material.dart';
import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/screens/promotion/promotional_package_builder.dart';

class PackageOrdersScreen extends StatefulWidget {
  const PackageOrdersScreen({super.key});

  @override
  State<PackageOrdersScreen> createState() => _PackageOrdersScreenState();
}

class _PackageOrdersScreenState extends State<PackageOrdersScreen> {
  final _database = Database();

  String search = "";
  String paymentFilter = "All";
  String statusFilter = "All";
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> orders = [];

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final vendorId = await AuthService.getVendorIdString();
      final response = await _database.getData({
        'action': 'get_packages',
        if (vendorId != '0') 'vendor_id': vendorId,
      });

      if (response['success'] == true || response['status'] == 200) {
        final rawPackages =
            response['packages'] ??
            response['promotion_packages'] ??
            response['data'] ??
            [];

        final parsedOrders = <Map<String, dynamic>>[];
        if (rawPackages is List) {
          for (final item in rawPackages) {
            if (item is Map) {
              final package = Map<String, dynamic>.from(item);
              final durationValue = package['duration_value']?.toString() ?? '';
              final durationType = package['duration_type']?.toString() ?? '';

              parsedOrders.add({
                'partner':
                    package['community_name']?.toString() ??
                    package['community_title']?.toString() ??
                    package['community']?.toString() ??
                    'Community ${package['community_id'] ?? ''}',
                'package': package['name']?.toString() ?? 'Promotion Package',
                'model':
                    package['pricing_type']?.toString() ??
                    package['pricing']?.toString() ??
                    'Fixed Price',
                'orderId':
                    package['id']?.toString() ??
                    package['package_id']?.toString() ??
                    '',
                'amount':
                    package['fixed_price']?.toString() ??
                    package['base_price']?.toString() ??
                    '0',
                'paymentStatus':
                    package['payment_status']?.toString() ??
                    package['status']?.toString() ??
                    'Pending',
                'billing': durationType.isNotEmpty ? durationType : 'One Time',
                'promotionStatus': package['status']?.toString() ?? 'Active',
                'schedule': durationValue.isNotEmpty
                    ? '$durationValue $durationType'
                    : 'Not Scheduled',
                'impressions':
                    package['impressions']?.toString() ??
                    package['reach']?.toString() ??
                    '0',
                'clicks': package['clicks']?.toString() ?? '0',
              });
            }
          }
        }

        setState(() {
          orders = parsedOrders;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              response['message']?.toString() ??
              response['error']?.toString() ??
              'Unable to load packages';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Unable to load packages: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateProject() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => const PromotionalPackageBuilderScreen(),
      ),
    );

    if (created == true && mounted) {
      await _loadPackages();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Package saved successfully'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final matchSearch = order["partner"].toLowerCase().contains(
        search.toLowerCase(),
      );

      final matchPayment =
          paymentFilter == "All" || order["paymentStatus"] == paymentFilter;

      final matchStatus =
          statusFilter == "All" || order["promotionStatus"] == statusFilter;

      return matchSearch && matchPayment && matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Promotion Package Orders"),
        actions: [
          TextButton.icon(
            onPressed: _openCreateProject,
            icon: const Icon(Icons.add),
            label: const Text('Create Project'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateProject,
        icon: const Icon(Icons.add),
        label: const Text('Create Project'),
      ),
      body: Column(
        children: [
          // SEARCH
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Search partner...",
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (v) => setState(() => search = v),
            ),
          ),

          // FILTERS
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _dropdownFilter(paymentFilter, [
                "All",
                "Paid",
                "Pending",
              ], (v) => setState(() => paymentFilter = v)),
              _dropdownFilter(statusFilter, [
                "All",
                "Scheduled",
                "Pending Approval",
              ], (v) => setState(() => statusFilter = v)),
            ],
          ),

          const SizedBox(height: 10),

          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ),

          const SizedBox(height: 10),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                ? const Center(child: Text('No packages found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (_, i) {
                      var order = filteredOrders[i];
                      return _orderCard(order);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dropdownFilter(
    String value,
    List<String> items,
    Function(String) onChanged,
  ) {
    return DropdownButton<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: (v) => onChanged(v!),
    );
  }

  Widget _orderCard(Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.business)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order["partner"],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                _statusChip(order["promotionStatus"]),
              ],
            ),

            const SizedBox(height: 10),

            Text("Package: ${order["package"]}"),
            Text("Model: ${order["model"]}"),
            Text("Order ID: ${order["orderId"]}"),

            const SizedBox(height: 8),

            Text("Amount: ₹${order["amount"]} (${order["billing"]})"),
            Text("Payment: ${order["paymentStatus"]}"),
            Text("Schedule: ${order["schedule"]}"),

            const SizedBox(height: 8),

            Text("Impressions: ${order["impressions"]}"),
            Text("Clicks: ${order["clicks"]}"),

            const Divider(),

            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text("View Details"),
                ),
                ElevatedButton(onPressed: () {}, child: const Text("Approve")),
                ElevatedButton(onPressed: () {}, child: const Text("Schedule")),
                ElevatedButton(onPressed: () {}, child: const Text("Invoice")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.grey;

    if (status == "Scheduled") {
      color = Colors.green;
    }
    if (status == "Pending Approval") {
      color = Colors.orange;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color),
    );
  }
}
