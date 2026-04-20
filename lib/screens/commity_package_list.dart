import 'package:flutter/material.dart';

class PackageOrdersScreen extends StatefulWidget {
  const PackageOrdersScreen({super.key});

  @override
  State<PackageOrdersScreen> createState() =>
      _PackageOrdersScreenState();
}

class _PackageOrdersScreenState
    extends State<PackageOrdersScreen> {

  String search = "";
  String paymentFilter = "All";
  String statusFilter = "All";

  List<Map<String, dynamic>> orders = [
    {
      "partner": "ABC Marketing Pvt Ltd",
      "package": "Gold Sponsored Package",
      "model": "Fixed Price",
      "orderId": "ORD12345",
      "amount": "999",
      "paymentStatus": "Paid",
      "billing": "One Time",
      "promotionStatus": "Scheduled",
      "schedule": "15 Feb - 18 Feb",
      "impressions": "12,450",
      "clicks": "345",
    },
    {
      "partner": "XYZ Digital Agency",
      "package": "Evening Slot Premium",
      "model": "Slot Based",
      "orderId": "ORD56789",
      "amount": "1000",
      "paymentStatus": "Pending",
      "billing": "One Time",
      "promotionStatus": "Pending Approval",
      "schedule": "Not Scheduled",
      "impressions": "0",
      "clicks": "0",
    },
  ];

  List<Map<String, dynamic>> get filteredOrders {
    return orders.where((order) {
      final matchSearch = order["partner"]
          .toLowerCase()
          .contains(search.toLowerCase());

      final matchPayment =
          paymentFilter == "All" ||
              order["paymentStatus"] ==
                  paymentFilter;

      final matchStatus =
          statusFilter == "All" ||
              order["promotionStatus"] ==
                  statusFilter;

      return matchSearch &&
          matchPayment &&
          matchStatus;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Promotion Package Orders"),
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
              onChanged: (v) =>
                  setState(() => search = v),
            ),
          ),

          // FILTERS
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly,
            children: [
              _dropdownFilter(
                  paymentFilter,
                  ["All", "Paid", "Pending"],
                  (v) =>
                      setState(() => paymentFilter = v)),
              _dropdownFilter(
                  statusFilter,
                  [
                    "All",
                    "Scheduled",
                    "Pending Approval"
                  ],
                  (v) =>
                      setState(() => statusFilter = v)),
            ],
          ),

          const SizedBox(height: 10),

          // ORDER LIST
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.all(12),
              itemCount:
                  filteredOrders.length,
              itemBuilder: (_, i) {
                var order =
                    filteredOrders[i];
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
      Function(String) onChanged) {
    return DropdownButton<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: (v) =>
          onChanged(v!),
    );
  }

  Widget _orderCard(
      Map<String, dynamic> order) {
    return Card(
      margin: const EdgeInsets.only(
          bottom: 14),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [

            // HEADER
            Row(
              children: [
                const CircleAvatar(
                    child: Icon(
                        Icons.business)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    order["partner"],
                    style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                        fontSize: 16),
                  ),
                ),
                _statusChip(
                    order["promotionStatus"])
              ],
            ),

            const SizedBox(height: 10),

            Text(
                "Package: ${order["package"]}"),
            Text(
                "Model: ${order["model"]}"),
            Text(
                "Order ID: ${order["orderId"]}"),

            const SizedBox(height: 8),

            Text(
                "Amount: ₹${order["amount"]} (${order["billing"]})"),
            Text(
                "Payment: ${order["paymentStatus"]}"),
            Text(
                "Schedule: ${order["schedule"]}"),

            const SizedBox(height: 8),

            Text(
                "Impressions: ${order["impressions"]}"),
            Text(
                "Clicks: ${order["clicks"]}"),

            const Divider(),

            Wrap(
              spacing: 8,
              children: [
                ElevatedButton(
                  onPressed: () {},
                  child: const Text(
                      "View Details"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child:
                      const Text("Approve"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child:
                      const Text("Schedule"),
                ),
                ElevatedButton(
                  onPressed: () {},
                  child:
                      const Text("Invoice"),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusChip(String status) {
    Color color = Colors.grey;

    if (status == "Scheduled")
      color = Colors.green;
    if (status ==
        "Pending Approval")
      color = Colors.orange;

    return Chip(
      label: Text(status),
      backgroundColor:
          color.withOpacity(0.2),
      labelStyle:
          TextStyle(color: color),
    );
  }
}
