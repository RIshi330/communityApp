import 'package:flutter/material.dart';

class PostDetailScreen extends StatelessWidget {
  final String userName;
  final String postImage;
  final String caption;

  const PostDetailScreen({
    super.key,
    required this.userName,
    required this.postImage,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Post Details"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// USER INFO
            ListTile(
              leading: const CircleAvatar(
                backgroundImage:
                    NetworkImage("https://i.pravatar.cc/150?img=3"),
              ),
              title: Text(
                userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("2 hours ago"),
              trailing: const Icon(Icons.more_vert),
            ),

            /// POST IMAGE
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                postImage,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 12),

            /// ACTION BUTTONS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: const [
                  Icon(Icons.favorite_border),
                  SizedBox(width: 16),
                  Icon(Icons.comment_outlined),
                  SizedBox(width: 16),
                  Icon(Icons.share_outlined),
                ],
              ),
            ),

            const SizedBox(height: 12),

            /// CAPTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(color: textColor),
                  children: [
                    TextSpan(
                      text: "$userName ",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: caption),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// COMMENTS TITLE
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "Comments",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            _buildComment(context, "Rahul", "Amazing platform bro 🔥"),
            _buildComment(context, "Sneha", "Very useful idea!"),
            _buildComment(context, "Amit", "Waiting for launch 🚀"),
          ],
        ),
      ),
    );
  }

  Widget _buildComment(BuildContext context, String name, String comment) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 16,
            backgroundImage:
                NetworkImage("https://i.pravatar.cc/100?img=5"),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: textColor),
                children: [
                  TextSpan(
                    text: "$name ",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: comment),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
