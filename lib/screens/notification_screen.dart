import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  /// DEMO DATA
  List<Map<String, dynamic>> notifications = [
    {
      "type": "message",
      "user": "Ananya",
      "text": "Sent you a message",
      "preview": "Hey, let’s collaborate on this!",
      "time": DateTime.now().subtract(const Duration(minutes: 5)),
      "unread": true,
    },
    {
      "type": "follow",
      "user": "Rohit",
      "text": "started following you",
      "time": DateTime.now().subtract(const Duration(hours: 2)),
      "unread": true,
    },
    {
      "type": "order",
      "user": "Order #4521",
      "text": "Your payment was successful",
      "time": DateTime.now().subtract(const Duration(hours: 5)),
      "unread": false,
    },
    {
      "type": "community",
      "user": "Startup Hub",
      "text": "New post in your community",
      "preview": "Funding tips for 2026 🚀",
      "time": DateTime.now().subtract(const Duration(days: 1)),
      "unread": false,
    },
  ];

  /// TIME AGO FUNCTION
  String timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 7) return "${diff.inDays}d ago";
    return "${time.day}/${time.month}";
  }

  /// GROUPING
  Map<String, List<Map>> groupNotifications() {
    Map<String, List<Map>> grouped = {
      "Today": [],
      "Yesterday": [],
      "Earlier": [],
    };

    for (var n in notifications) {
      final diff = DateTime.now().difference(n["time"]);

      if (diff.inDays == 0) {
        grouped["Today"]!.add(n);
      } else if (diff.inDays == 1) {
        grouped["Yesterday"]!.add(n);
      } else {
        grouped["Earlier"]!.add(n);
      }
    }

    return grouped;
  }

  IconData getIcon(String type) {
    switch (type) {
      case "message":
        return Icons.chat;
      case "follow":
        return Icons.person_add;
      case "order":
        return Icons.shopping_bag;
      default:
        return Icons.notifications;
    }
  }

  Color getColor(String type) {
    switch (type) {
      case "message":
        return Colors.blue;
      case "follow":
        return Colors.green;
      case "order":
        return Colors.orange;
      default:
        return Colors.deepPurple;
    }
  }

  Widget buildNotificationCard(Map n) {
    return Dismissible(
      key: UniqueKey(),
      background: Container(color: Colors.red),
      onDismissed: (_) {
        setState(() => notifications.remove(n));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n["unread"] ? Colors.deepPurple.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// AVATAR / ICON
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: getColor(n["type"]).withOpacity(0.2),
                  child: Icon(getIcon(n["type"]), color: getColor(n["type"])),
                ),
                if (n["unread"])
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      height: 10,
                      width: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 12),

            /// CONTENT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black),
                      children: [
                        TextSpan(
                          text: "${n["user"]} ",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: n["text"]),
                      ],
                    ),
                  ),

                  if (n["preview"] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        n["preview"],
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),

                  const SizedBox(height: 6),

                  /// ACTION BUTTONS
                  Row(
                    children: [
                      if (n["type"] == "message") _actionBtn("Reply"),

                      if (n["type"] == "follow") _actionBtn("Follow Back"),

                      if (n["type"] == "order") _actionBtn("View"),

                      const SizedBox(width: 10),

                      Text(
                        timeAgo(n["time"]),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn(String label) {
    return TextButton(onPressed: () {}, child: Text(label));
  }

  @override
  Widget build(BuildContext context) {
    final grouped = groupNotifications();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Notifications"),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (var n in notifications) {
                  n["unread"] = false;
                }
              });
            },
            child: const Text("Mark all read"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          if (entry.value.isEmpty) return const SizedBox();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  entry.key,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              ...entry.value.map((n) => buildNotificationCard(n)),
            ],
          );
        }).toList(),
      ),
    );
  }
}
