import 'package:commity_app1/model/user_model.dart';
import 'package:flutter/material.dart';


class ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback? onFollowTap;
  final VoidCallback? onMessageTap;

  const ProfileHeader({
    super.key,
    required this.user,
    this.isCurrentUser = true,
    this.onFollowTap,
    this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopRow(context),
          const SizedBox(height: 12),
          _buildDisplayName(),
          const SizedBox(height: 4),
          _buildBio(),
          const SizedBox(height: 12),
          if (isCurrentUser) _buildCurrentUserActions(context) else _buildOtherUserActions(context),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildTopRow(BuildContext context) {
    return Row(
      children: [
        _buildAvatar(),
        const SizedBox(width: 24),
        Expanded(child: _buildStats(context)),
      ],
    );
  }

  Widget _buildAvatar() {
    return Stack(
      children: [
        Container(
          width: 86,
          height: 86,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade700, width: 1),
          ),
          child: ClipOval(
            child: user.profileImageUrl.isNotEmpty
                ? Image.network(
                    user.profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _defaultAvatar(),
                  )
                : _defaultAvatar(),
          ),
        ),
        if (true) // always show add button for current user
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _defaultAvatar() {
    return Container(
      color: Colors.grey.shade800,
      child: const Icon(Icons.person, color: Colors.white54, size: 40),
    );
  }

  Widget _buildStats(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('${user.postsCount}', 'posts', context),
        _buildStatItem('${user.followersCount}', 'followers', context),
        _buildStatItem('${user.followingCount}', 'following', context),
      ],
    );
  }

  Widget _buildStatItem(String count, String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == 'followers') {
          Navigator.pushNamed(context, '/followers');
        } else if (label == 'following') {
          Navigator.pushNamed(context, '/following');
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayName() {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: user.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          if (user.isVerified)
            const WidgetSpan(
              child: Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.verified, color: Colors.blue, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBio() {
    if (user.bioLines.isEmpty && user.bio.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (user.bio.isNotEmpty)
          Text(
            user.bio,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ...user.bioLines.map(
          (line) => Text(
            line,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
        if (user.website != null && user.website!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              user.website!,
              style: const TextStyle(color: Colors.blueAccent, fontSize: 13),
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentUserActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Edit profile',
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'Share profile',
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          label: '',
          icon: Icons.person_add_alt_1,
          isSmall: true,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildOtherUserActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionButton(
            label: 'Follow',
            isPrimary: true,
            onTap: onFollowTap ?? () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _ActionButton(
            label: 'Message',
            onTap: onMessageTap ?? () {},
          ),
        ),
        const SizedBox(width: 8),
        _ActionButton(
          label: '',
          icon: Icons.person_add_alt_1,
          isSmall: true,
          onTap: () {},
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isPrimary;
  final bool isSmall;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.isPrimary = false,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        width: isSmall ? 40 : null,
        decoration: BoxDecoration(
          color: isPrimary ? Colors.blue : Colors.grey.shade800,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: icon != null
            ? Icon(icon, color: Colors.white, size: 18)
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}