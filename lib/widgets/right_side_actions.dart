import 'package:commity_app1/model/shorts_model.dart';
import 'package:flutter/material.dart';

class RightSideActions extends StatefulWidget {
  final Short short;
  final VoidCallback onLike;
  final VoidCallback onComment;
  final VoidCallback onShare;
  final VoidCallback onFollow;

  const RightSideActions({
    Key? key,
    required this.short,
    required this.onLike,
    required this.onComment,
    required this.onShare,
    required this.onFollow,
  }) : super(key: key);

  @override
  State<RightSideActions> createState() => _RightSideActionsState();
}

class _RightSideActionsState extends State<RightSideActions>
    with SingleTickerProviderStateMixin {
  late AnimationController _likeAnimationController;
  late Animation<double> _likeAnimation;

  @override
  void initState() {
    super.initState();
    _likeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _likeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _likeAnimationController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _likeAnimationController.dispose();
    super.dispose();
  }

  void _handleLike() {
    widget.onLike();
    _likeAnimationController.forward().then((_) {
      _likeAnimationController.reverse();
    });
  }

  // ✅ Count format करण्यासाठी - 0 ते K/M format
  String _formatCount(int count) {
    if (count == 0) return '0';
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Profile Picture with Follow Button
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () {},
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: NetworkImage(widget.short.userImage),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            // ✅ Follow Button - username च्या बाजूला दिसेल
            if (!widget.short.isFollowing)
              Positioned(
                bottom: -8,
                child: GestureDetector(
                  onTap: widget.onFollow,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: 24),

        // ✅ Like Button - count properly वाढेल
        _buildActionButton(
          icon: widget.short.isLiked ? Icons.favorite : Icons.favorite_border,
          label: _formatCount(widget.short.likes),
          color: widget.short.isLiked ? Colors.red : Colors.white,
          onTap: _handleLike,
          animation: _likeAnimation,
        ),

        const SizedBox(height: 24),

        // ✅ Comment Button - count दाखवेल
        _buildActionButton(
          icon: Icons.mode_comment_outlined,
          label: _formatCount(widget.short.comments),
          color: Colors.white,
          onTap: widget.onComment,
        ),

        const SizedBox(height: 24),

        // ✅ Share Button - count दाखवेल
        _buildActionButton(
          icon: Icons.send,
          label: _formatCount(widget.short.shares),
          color: Colors.white,
          onTap: widget.onShare,
        ),

        const SizedBox(height: 24),

        // More Options
        _buildActionButton(
          icon: Icons.more_vert,
          label: '',
          color: Colors.white,
          onTap: () {
            _showMoreOptions(context);
          },
        ),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Animation<double>? animation,
  }) {
    Widget button = GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 32,
            shadows: const [
              Shadow(
                blurRadius: 8,
                color: Colors.black45,
              ),
            ],
          ),
          if (label.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black45,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );

    if (animation != null) {
      return ScaleTransition(
        scale: animation,
        child: button,
      );
    }

    return button;
  }

  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildMoreOption(Icons.bookmark_border, 'Save', () {}),
            _buildMoreOption(Icons.flag_outlined, 'Report', () {}),
            _buildMoreOption(Icons.block, 'Not Interested', () {}),
            _buildMoreOption(Icons.info_outline, 'About this account', () {}),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOption(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: Colors.black, size: 24),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(fontSize: 16, color: Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}