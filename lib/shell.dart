import 'package:commity_app1/screens/create_post.dart';
import 'package:commity_app1/screens/create_community_screen.dart';
import 'package:flutter/material.dart';
import 'screens/feed_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;

  // ✅ Exit confirmation dialog
  Future<bool> _showExitConfirmation() async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Exit App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
              content: const Text(
                'Are you sure you want to exit the app?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              actionsPadding: EdgeInsets.zero,
              actions: [
                Divider(height: 1, color: Colors.grey.shade200),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(color: Colors.black54, fontSize: 16),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 48,
                      color: Colors.grey.shade200,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Exit',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ) ??
        false;
  }

  // ✅ Create options modal bottom sheet
  void _showCreateOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Create',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff1DA1F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.article,
                    color: Color(0xff1DA1F2),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Create a post',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePostFinalScreen(),
                    ),
                  ).then((_) {
                    setState(() {
                      index = 0;
                    });
                  });
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff8F7CFF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Color(0xff8F7CFF),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Create a group',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreateCommunityScreen(),
                    ),
                  );
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xffE0245E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Color(0xffE0245E),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Camera',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePostFinalScreen(),
                    ),
                  ).then((_) {
                    setState(() {
                      index = 0;
                    });
                  });
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xff1DA1F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.photo_library,
                    color: Color(0xff1DA1F2),
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Gallery',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CreatePostFinalScreen(),
                    ),
                  ).then((_) {
                    setState(() {
                      index = 0;
                    });
                  });
                },
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.black54,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black54, fontSize: 15),
                ),
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isFeed = index == 0;
    final bool isProfile = index == 4;

    Widget currentScreen;
    switch (index) {
      case 0:
        currentScreen = const FeedScreen();
        break;
      case 1:
        currentScreen = ChatListScreen();
        break;
      case 2:
        // ✅ index 2 la blank/feed dikhav — create button navigate karto
        currentScreen = const FeedScreen();
        break;
      case 3:
        currentScreen = const FeedScreen();
        break;
      case 4:
        currentScreen = ProfileScreen();
        break;
      default:
        currentScreen = const FeedScreen();
    }

    return WillPopScope(
      onWillPop: () async {
        // ✅ Show exit confirmation when back button is pressed
        if (index == 0) {
          // Only show exit confirmation on the first tab (Feed)
          return await _showExitConfirmation();
        } else {
          // Navigate back to first tab instead of exiting
          setState(() {
            index = 0;
          });
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        appBar: (isFeed || isProfile)
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(kToolbarHeight),
                child: Container(
                  color: const Color(0xff8F7CFF),
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          const Center(
                            child: Text(
                              'Lavender',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 0,
                            child: IconButton(
                              icon: const Icon(
                                Icons.notification_add,
                                color: Colors.black,
                              ),
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => NotificationsScreen(),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

        body: currentScreen,

        bottomNavigationBar: Container(
          color: Colors.black,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 75,
              child: BottomNavigationBar(
                currentIndex: index == 2
                    ? 0
                    : index, // ✅ index 2 select dikhvaycha nahi
                onTap: (i) {
                  if (i == 2) {
                    // ✅ Show options instead of direct navigation
                    _showCreateOptions();
                    return;
                  }
                  setState(() {
                    index = i;
                  });
                },
                backgroundColor: Colors.black,
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                selectedItemColor: const Color(0xff8F7CFF),
                unselectedItemColor: Colors.white,
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home, size: 26),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.send_sharp, size: 26),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.add_circle_outline, size: 30),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.play_arrow_rounded, size: 26),
                    label: "",
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person, size: 26),
                    label: "",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
