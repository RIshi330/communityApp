import 'package:flutter/material.dart';
import 'package:commity_app1/model/story_model.dart';

class StoryItem extends StatelessWidget {
  final Story story;

  const StoryItem({
    Key? key,
    required this.story,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: story.hasStory && !story.isYourStory
                  ? const LinearGradient(
                      colors: [
                        Color(0xFF7C83FD), // Lavender
                        Color(0xFFB8A4FF), // Light purple
                        Color(0xFF7C83FD), // Lavender
                      ],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    )
                  : null,
              border: story.isYourStory
                  ? Border.all(color: const Color(0xFFE6E6F0), width: 2)
                  : null,
            ),
            padding: const EdgeInsets.all(2),
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage(story.imageUrl),
                  ),
                ),
                if (story.isYourStory)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C83FD),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 70,
            child: Text(
              story.username,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}