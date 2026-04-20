import 'package:flutter/material.dart';
import 'dart:math';

class CreateCommunityScreen extends StatefulWidget {
  const CreateCommunityScreen({super.key});

  @override
  State<CreateCommunityScreen> createState() =>
      _CreateCommunityScreenState();
}

class _CreateCommunityScreenState extends State<CreateCommunityScreen> {
  // BASIC INFO
  String name = "Community Name";
  String description =
      "Write a powerful description about your community. Click to edit.";
  String mode = "Online";
  List<String> tags = ["Startup", "Networking"];

  // MEMBER INFO
  String groupFor = "Professionals";
  String demography = "All";
  String geography = "Global";

  // JOINING RULES
  String joiningType = "Free to Join";
  String inviteLink = "";

  // PAID SETTINGS
  bool isPaid = false;
  String billingType = "Monthly";
  String price = "499";

  // BENEFITS
  String benefits =
      "• Access to premium content\n• Networking events\n• Member-only discussions";

  // TERMS
  String terms =
      "Members must follow community guidelines. No spam or abusive content.";

  @override
  void initState() {
    super.initState();
    inviteLink = _generateInvite();
  }

  String _generateInvite() {
    const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
    return List.generate(
            8, (index) => chars[Random().nextInt(chars.length)])
        .join();
  }

  void _editText(String title, String current,
      Function(String) onSave) {
    showDialog(
      context: context,
      builder: (_) {
        String temp = current;
        return AlertDialog(
          title: Text("Edit $title"),
          content: TextField(
            maxLines: 4,
            autofocus: true,
            onChanged: (v) => temp = v,
            controller: TextEditingController(text: current),
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
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style:
            const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: Colors.grey)),
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
      appBar:
          AppBar(title: const Text("Create Community (Enterprise)")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // BASIC INFO
          sectionTitle("1. Basic Information"),

          editableBlock("Community Name", name,
              (v) => setState(() => name = v)),

          editableBlock("Description", description,
              (v) => setState(() => description = v)),

          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                description =
                    "AI Generated: This is a premium professional community designed to connect like-minded individuals, foster growth, and create opportunities.";
              });
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text("AI Assist Description"),
          ),

          editableBlock("Tags (comma separated)",
              tags.join(", "),
              (v) => setState(
                  () => tags = v.split(","))),

          editableBlock("Mode (Online/Offline/Onsite)",
              mode, (v) => setState(() => mode = v)),

          // MEMBER INFO
          sectionTitle("2. Member Information"),

          editableBlock("Group For (Women, Kids, Professionals)",
              groupFor,
              (v) => setState(() => groupFor = v)),

          editableBlock("Demography (Women/Men/All)",
              demography,
              (v) => setState(() => demography = v)),

          editableBlock("Geography (Pin, City, State, Country)",
              geography,
              (v) => setState(() => geography = v)),

          // JOIN RULES
          sectionTitle("3. Joining Rules"),

          editableBlock("Joining Type",
              joiningType,
              (v) => setState(() => joiningType = v)),

          if (joiningType == "By invite only")
            editableBlock("Invite Link (Auto Generated)",
                inviteLink, (_) {}),

          // PAID
          sectionTitle("4. Membership Rules"),

          SwitchListTile(
            title: const Text("Paid Membership"),
            value: isPaid,
            onChanged: (v) =>
                setState(() => isPaid = v),
          ),

          if (isPaid) ...[
            editableBlock("Billing Type (Monthly/Yearly)",
                billingType,
                (v) =>
                    setState(() => billingType = v)),
            editableBlock("Price (₹)",
                price,
                (v) => setState(() => price = v)),
          ],

          // BENEFITS
          sectionTitle("5. Membership Benefits"),

          editableBlock("Benefits", benefits,
              (v) => setState(() => benefits = v)),

          // TERMS
          sectionTitle("6. Terms & Conditions"),

          editableBlock("Terms & Conditions",
              terms,
              (v) => setState(() => terms = v)),

          const SizedBox(height: 30),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding:
                  const EdgeInsets.symmetric(vertical: 16),
            ),
            onPressed: () {},
            child: const Text("Create Community"),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
