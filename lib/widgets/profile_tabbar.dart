import 'package:flutter/material.dart';

class ProfileTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;

  const ProfileTabBar({
    super.key,
    required this.tabController,
  });

  @override
  Size get preferredSize => const Size.fromHeight(44);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade800, width: 0.5),
        ),
      ),
      child: TabBar(
        controller: tabController,
        indicatorColor: Colors.white,
        indicatorWeight: 1.5,
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.grey,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.grid_on, size: 24)),
          Tab(icon: Icon(Icons.play_circle_outline, size: 24)),
          Tab(icon: Icon(Icons.loop, size: 24)),
          Tab(icon: Icon(Icons.person_pin_outlined, size: 24)),
        ],
      ),
    );
  }
}