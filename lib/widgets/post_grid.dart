import 'package:commity_app1/model/post_model.dart';
import 'package:flutter/material.dart';


class PostGrid extends StatelessWidget {
  final List<PostModel> posts;

  const PostGrid({super.key, required this.posts});

  @override
  Widget build(BuildContext context) {
    if (posts.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: posts.length,
      itemBuilder: (context, index) => _buildPostTile(context, posts[index]),
    );
  }

  Widget _buildPostTile(BuildContext context, PostModel post) {
    return GestureDetector(
      onTap: () {
        // Navigate to post detail
        Navigator.pushNamed(context, '/post', arguments: post);
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            post.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: Colors.grey.shade900,
              child: const Icon(Icons.broken_image, color: Colors.white38),
            ),
          ),
          if (post.type == PostType.reel)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.play_arrow, color: Colors.white, size: 16),
            ),
          if (post.type == PostType.carousel)
            const Positioned(
              top: 6,
              right: 6,
              child: Icon(Icons.collections, color: Colors.white, size: 16),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Instagram's "Create your first post" illustration area
            Container(
              width: 160,
              height: 160,
              margin: const EdgeInsets.only(bottom: 24),
              child: CustomPaint(
                painter: _IllustrationPainter(),
              ),
            ),
            const Text(
              'Create your first post',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Make this space your own.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Draw a simple illustrated person with phone
    final paint = Paint()..style = PaintingStyle.fill;

    // Body
    paint.color = const Color(0xFFE8E8E8);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.3, size.height * 0.4, size.width * 0.4, size.height * 0.45),
        const Radius.circular(20),
      ),
      paint,
    );

    // Head
    paint.color = const Color(0xFFFFD4A0);
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.28),
      size.width * 0.14,
      paint,
    );

    // Phone in hand (orange accent)
    paint.color = const Color(0xFFFF8C42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.35, size.height * 0.52, size.width * 0.30, size.height * 0.20),
        const Radius.circular(6),
      ),
      paint,
    );

    // Hat / hair
    paint.color = const Color(0xFF8B4513);
    final path = Path();
    path.moveTo(size.width * 0.30, size.height * 0.22);
    path.quadraticBezierTo(size.width * 0.50, size.height * 0.05, size.width * 0.70, size.height * 0.22);
    path.close();
    canvas.drawPath(path, paint);

    // Purple accent
    paint.color = const Color(0xFFAA6FDF);
    canvas.drawCircle(
      Offset(size.width * 0.75, size.height * 0.35),
      size.width * 0.07,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ReelsGrid extends StatelessWidget {
  final List<PostModel> reels;

  const ReelsGrid({super.key, required this.reels});

  @override
  Widget build(BuildContext context) {
    if (reels.isEmpty) {
      return _buildEmptyState();
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 0.56, // portrait ratio for reels
      ),
      itemCount: reels.length,
      itemBuilder: (context, index) => _buildReelTile(context, reels[index]),
    );
  }

  Widget _buildReelTile(BuildContext context, PostModel reel) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/reel', arguments: reel),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            reel.imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
          ),
          const Positioned(
            bottom: 8,
            left: 8,
            child: Row(
              children: [
                Icon(Icons.play_arrow, color: Colors.white, size: 16),
                SizedBox(width: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.play_circle_outline, color: Colors.white38, size: 56),
            SizedBox(height: 16),
            Text('No reels yet', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class TaggedGrid extends StatelessWidget {
  final List<PostModel> tagged;

  const TaggedGrid({super.key, required this.tagged});

  @override
  Widget build(BuildContext context) {
    if (tagged.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_pin_outlined, color: Colors.white38, size: 56),
              SizedBox(height: 16),
              Text('No tagged posts', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
        childAspectRatio: 1,
      ),
      itemCount: tagged.length,
      itemBuilder: (context, index) => Image.network(
        tagged[index].imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade900),
      ),
    );
  }
}