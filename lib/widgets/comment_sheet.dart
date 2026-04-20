// commentsheet.dart

import 'package:flutter/material.dart';

class CommentSheet extends StatelessWidget {
  const CommentSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const SizedBox(height: 10),
          const Text("Comments", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: 10,
              itemBuilder: (_, i) => ListTile(
                leading: CircleAvatar(child: Text("U$i")),
                title: Text("User $i"),
                subtitle: const Text("Nice post!"),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Add a comment...",
                border: OutlineInputBorder(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
