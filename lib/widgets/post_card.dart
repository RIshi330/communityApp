import 'package:commity_app1/screens/post_detail.dart';
import 'package:commity_app1/widgets/comment_sheet.dart';
import 'package:flutter/material.dart';
import '../theme.dart';

class PostCard extends StatefulWidget {
  final String username;
  final String content;

  const PostCard({
    super.key,
    required this.username,
    required this.content,
  });

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool liked = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              child: Text(widget.username[0]),
            ),
            title: Text(widget.username),
            trailing: OutlinedButton(
              onPressed: () {},
              child: const Text("Follow"),
            ),

            /// FIXED NAVIGATION
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PostDetailScreen(
                    userName: widget.username,
                    postImage:
                        "https://images.unsplash.com/photo-1506744038136-46273834b3fb",
                    caption: widget.content,
                  ),
                ),
              );
            },
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Text(widget.content),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: Icon(
                  liked ? Icons.favorite : Icons.favorite_border,
                  color: liked ? Colors.red : AppTheme.muted,
                ),
                onPressed: () {
                  setState(() {
                    liked = !liked;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.comment_outlined),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => const CommentSheet(),
                  );
                },
              ),
              const Icon(Icons.repeat),
              const Icon(Icons.share_outlined),
            ],
          ),
        ],
      ),
    );
  }
}
