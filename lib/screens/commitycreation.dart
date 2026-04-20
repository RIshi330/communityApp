import 'package:flutter/material.dart';

class PackageCreationScreen extends StatefulWidget {
  const PackageCreationScreen({super.key});

  @override
  State<PackageCreationScreen> createState() =>
      _PackageCreationScreenState();
}

class _PackageCreationScreenState
    extends State<PackageCreationScreen> {
  // BASIC
  String packageName = "Gold Sponsored Package";
  String description =
      "High visibility sponsored placement for business partners.";
  String promotionType = "Sponsored Post";

  // MODEL
  String selectedModel = "Fixed Price";

  // MODEL A
  String fixedPrice = "999";
  String duration = "3";
  bool pinned = true;

  // MODEL B
  List<Map<String, String>> slots = [
    {"slot": "Morning (6AM-12PM)", "price": "500"},
    {"slot": "Evening (5PM-10PM)", "price": "1000"},
  ];

  // MODEL C
  String cpmPrice = "200";
  String minImpressions = "5000";

  // MODEL D
  List<Map<String, String>> tiers = [
    {
      "name": "Silver",
      "price": "999",
      "duration": "3 days",
      "benefits": "Basic pin"
    }
  ];

  // PAYMENT RULES
  String billingType = "One Time";
  String gst = "18";

  // SCHEDULING
  bool autoApprove = false;
  bool allowBusinessChooseSchedule = true;
  String dailyLimit = "5";

  // VISIBILITY
  bool showPinned = true;
  bool showBanner = false;
  bool showBroadcast = false;

  // MODERATION
  bool requireApproval = true;
  bool restrictedFilter = true;

  void _editText(String title, String value,
      Function(String) onSave) {
    showDialog(
      context: context,
      builder: (_) {
        String temp = value;
        return AlertDialog(
          title: Text("Edit $title"),
          content: TextField(
            controller:
                TextEditingController(text: value),
            onChanged: (v) => temp = v,
          ),
          actions: [
            TextButton(
              onPressed: () {
                onSave(temp);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            )
          ],
        );
      },
    );
  }

  Widget sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget editableBlock(String label, String value,
      Function(String) onSave) {
    return GestureDetector(
      onTap: () => _editText(label, value, onSave),
      child: Container(
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey)),
            const SizedBox(height: 6),
            Text(value),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
            "Create Promotion Package"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // BASIC
          sectionTitle("1. Package Basics"),
          editableBlock("Package Name",
              packageName,
              (v) =>
                  setState(() => packageName = v)),
          editableBlock("Description",
              description,
              (v) =>
                  setState(() => description = v)),

          editableBlock("Promotion Type",
              promotionType,
              (v) => setState(
                  () => promotionType = v)),

          // MODEL SELECTOR
          sectionTitle("2. Pricing Model"),
          DropdownButton<String>(
            value: selectedModel,
            isExpanded: true,
            items: [
              "Fixed Price",
              "Slot Based",
              "CPM Model",
              "Tier Based"
            ]
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    ))
                .toList(),
            onChanged: (v) =>
                setState(() => selectedModel = v!),
          ),

          const SizedBox(height: 20),

          if (selectedModel == "Fixed Price")
            _fixedPriceUI(),

          if (selectedModel == "Slot Based")
            _slotUI(),

          if (selectedModel == "CPM Model")
            _cpmUI(),

          if (selectedModel == "Tier Based")
            _tierUI(),

          // PAYMENT RULES
          sectionTitle("3. Payment Rules"),
          editableBlock("Billing Type",
              billingType,
              (v) =>
                  setState(() => billingType = v)),
          editableBlock("GST %",
              gst,
              (v) => setState(() => gst = v)),

          // SCHEDULING
          sectionTitle("4. Scheduling Rules"),
          SwitchListTile(
            title:
                const Text("Auto Approve After Payment"),
            value: autoApprove,
            onChanged: (v) =>
                setState(() => autoApprove = v),
          ),
          SwitchListTile(
            title: const Text(
                "Allow Business Choose Schedule"),
            value:
                allowBusinessChooseSchedule,
            onChanged: (v) => setState(
                () =>
                    allowBusinessChooseSchedule =
                        v),
          ),
          editableBlock("Daily Promotion Limit",
              dailyLimit,
              (v) =>
                  setState(() => dailyLimit = v)),

          // VISIBILITY
          sectionTitle("5. Visibility Rules"),
          SwitchListTile(
              title: const Text("Pinned Post"),
              value: showPinned,
              onChanged: (v) =>
                  setState(() => showPinned = v)),
          SwitchListTile(
              title: const Text("Banner Placement"),
              value: showBanner,
              onChanged: (v) =>
                  setState(() => showBanner = v)),
          SwitchListTile(
              title:
                  const Text("Broadcast Notification"),
              value: showBroadcast,
              onChanged: (v) =>
                  setState(() => showBroadcast = v)),

          // MODERATION
          sectionTitle("6. Moderation Rules"),
          SwitchListTile(
            title:
                const Text("Require Admin Approval"),
            value: requireApproval,
            onChanged: (v) =>
                setState(() => requireApproval = v),
          ),
          SwitchListTile(
            title: const Text(
                "Restricted Word Filter"),
            value: restrictedFilter,
            onChanged: (v) => setState(
                () => restrictedFilter = v),
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {},
            child:
                const Text("Save & Publish Package"),
          ),

          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _fixedPriceUI() {
    return Column(
      children: [
        editableBlock("Price (₹)",
            fixedPrice,
            (v) =>
                setState(() => fixedPrice = v)),
        editableBlock("Duration (Days)",
            duration,
            (v) =>
                setState(() => duration = v)),
        SwitchListTile(
          title: const Text("Pin Post"),
          value: pinned,
          onChanged: (v) =>
              setState(() => pinned = v),
        ),
      ],
    );
  }

  Widget _slotUI() {
    return Column(
      children: slots
          .map((slot) => Card(
                child: ListTile(
                  title: Text(slot["slot"]!),
                  subtitle:
                      Text("₹${slot["price"]}"),
                ),
              ))
          .toList(),
    );
  }

  Widget _cpmUI() {
    return Column(
      children: [
        editableBlock("Price per 1000 Impressions",
            cpmPrice,
            (v) =>
                setState(() => cpmPrice = v)),
        editableBlock("Minimum Impressions",
            minImpressions,
            (v) => setState(
                () => minImpressions = v)),
      ],
    );
  }

  Widget _tierUI() {
    return Column(
      children: tiers
          .map((tier) => Card(
                child: ListTile(
                  title: Text(tier["name"]!),
                  subtitle: Text(
                      "₹${tier["price"]} • ${tier["duration"]}\n${tier["benefits"]}"),
                ),
              ))
          .toList(),
    );
  }
}