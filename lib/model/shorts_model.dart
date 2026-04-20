class Short {
  final String id;
  final String username;
  final String userImage;
  final String videoUrl;
  final String caption;
  final String musicName;
  int likes;
  int comments;
  int shares;
  final bool isVerified;
  bool isLiked;
  bool isFollowing;
  List<Comment> commentsList;

  Short({
    required this.id,
    required this.username,
    required this.userImage,
    required this.videoUrl,
    required this.caption,
    required this.musicName,
    required this.likes,
    required this.comments,
    required this.shares,
    this.isVerified = false,
    this.isLiked = false,
    this.isFollowing = false,
    List<Comment>? commentsList,
  }) : commentsList = commentsList ?? [];
}

// Comment Model
class Comment {
  final String id;
  final String username;
  final String userImage;
  final String text;
  final DateTime timestamp;
  int likes;
  bool isLiked;

  Comment({
    required this.id,
    required this.username,
    required this.userImage,
    required this.text,
    required this.timestamp,
    this.likes = 0,
    this.isLiked = false,
  });
}

// Sample shorts - सगळे counts 0 ठेवले आहेत
List<Short> sampleShorts = [
  Short(
    id: '1',
    username: 'travel_vibes',
    userImage: 'https://i.pravatar.cc/150?img=1',
    videoUrl: 'assets/video1.mp4',  // 👈 असा assets वापर
    caption: 'Beautiful sunset at the beach 🌅 #travel #sunset',
    musicName: 'Chill Vibes - Lofi Beats',
    likes: 0,  // 👈 0 ठेवलं
    comments: 0,  // 👈 0 ठेवलं
    shares: 0,  // 👈 0 ठेवलं
    isVerified: true,
  ),
  Short(
    id: '2',
    username: 'food_lover',
    userImage: 'https://i.pravatar.cc/150?img=2',
    videoUrl: 'assets/video2.mp4',  // 👈 असा assets वापर
    caption: 'Best pizza in town! 🍕 #food #pizza',
    musicName: 'Tasty - Food Music',
    likes: 0,
    comments: 0,
    shares: 0,
  ),
  Short(
    id: '3',
    username: 'fitness_guru',
    userImage: 'https://i.pravatar.cc/150?img=3',
    videoUrl: 'assets/video2.mp4',  // 👈 असा assets वापर
    caption: 'Daily workout routine 💪 #fitness #workout',
    musicName: 'Workout Beats - Gym Mix',
    likes: 0,
    comments: 0,
    shares: 0,
    isVerified: true,
  ),
  Short(
    id: '4',
    username: 'dance_queen',
    userImage: 'https://i.pravatar.cc/150?img=4',
    videoUrl: 'assets/video2.mp4',  // 👈 असा assets वापर
    caption: 'New dance trend! 💃 #dance #trending',
    musicName: 'Dance Hit - Trending',
    likes: 0,
    comments: 0,
    shares: 0,
    isVerified: true,
  ),
  Short(
    id: '5',
    username: 'pet_love',
    userImage: 'https://i.pravatar.cc/150?img=5',
    videoUrl: 'assets/video2.mp4',  // 👈 असा assets वापर
    caption: 'Cute puppy moments 🐶❤️ #pets #cute',
    musicName: 'Happy Vibes - Pet Song',
    likes: 0,
    comments: 0,
    shares: 0,
  ),
];