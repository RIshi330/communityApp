// ============================================================
// UPDATED FULL FILE — Post & Comment final removed
// ============================================================

class Comment {
  String username;
  String userImage;
  String text;
  String timeAgo;
  int likes;

  Comment({
    required this.username,
    required this.userImage,
    required this.text,
    required this.timeAgo,
    this.likes = 0,
  });
}

class Post {
  String id;
  String username;
  String userImage;
  bool isVerified;
  List<String> postImages;
  int likes;
  String caption;
  String timeAgo;
  int comments;
  int shares;
  bool isLiked;
  bool isBookmarked;
  List<Comment> commentsList;

  Post({
    required this.id,
    required this.username,
    required this.userImage,
    this.isVerified = false,
    required this.postImages,
    required this.likes,
    required this.caption,
    required this.timeAgo,
    required this.comments,
    required this.shares,
    this.isLiked = false,
    this.isBookmarked = false,
    List<Comment>? commentsList,
  }) : commentsList = commentsList ?? [];

  void addComment(Comment comment) {
    commentsList.insert(0, comment);
    comments++;
  }
}

// 🆕 Global Posts List
List<Post> globalPosts = [];

// ============================================================
// NEW ADDITIONS — PostType + PostModel
// ============================================================

enum PostType { image, video, reel, carousel }

class PostModel {
  String postId;
  String userId;
  String imageUrl;
  String? videoUrl;
  String caption;
  int likesCount;
  int commentsCount;
  DateTime createdAt;
  PostType type;
  List<String> imageUrls;
  bool isLiked;
  bool isSaved;

  PostModel({
    required this.postId,
    required this.userId,
    required this.imageUrl,
    this.videoUrl,
    required this.caption,
    required this.likesCount,
    required this.commentsCount,
    required this.createdAt,
    required this.type,
    this.imageUrls = const [],
    this.isLiked = false,
    this.isSaved = false,
  });

  factory PostModel.fromMap(Map<String, dynamic> map) {
    return PostModel(
      postId: map['postId'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      videoUrl: map['videoUrl'],
      caption: map['caption'] ?? '',
      likesCount: map['likesCount'] ?? 0,
      commentsCount: map['commentsCount'] ?? 0,
      createdAt:
          DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      type: PostType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => PostType.image,
      ),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      isLiked: map['isLiked'] ?? false,
      isSaved: map['isSaved'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'userId': userId,
      'imageUrl': imageUrl,
      'videoUrl': videoUrl,
      'caption': caption,
      'likesCount': likesCount,
      'commentsCount': commentsCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'type': type.name,
      'imageUrls': imageUrls,
      'isLiked': isLiked,
      'isSaved': isSaved,
    };
  }

  PostModel copyWith({
    String? postId,
    String? userId,
    String? imageUrl,
    String? videoUrl,
    String? caption,
    int? likesCount,
    int? commentsCount,
    DateTime? createdAt,
    PostType? type,
    List<String>? imageUrls,
    bool? isLiked,
    bool? isSaved,
  }) {
    return PostModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      imageUrl: imageUrl ?? this.imageUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      caption: caption ?? this.caption,
      likesCount: likesCount ?? this.likesCount,
      commentsCount: commentsCount ?? this.commentsCount,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
      imageUrls: imageUrls ?? this.imageUrls,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
    );
  }

  static List<PostModel> get samplePosts => [];

  static List<PostModel> get dummyPosts =>
      List.generate(12, (index) {
        return PostModel(
          postId: 'post_$index',
          userId: 'narsiha_06',
          imageUrl: 'https://picsum.photos/seed/$index/300/300',
          caption: 'Post $index caption',
          likesCount: (index + 1) * 10,
          commentsCount: index * 2,
          createdAt:
              DateTime.now().subtract(Duration(days: index)),
          type: index % 3 == 0
              ? PostType.reel
              : PostType.image,
          isLiked: index % 2 == 0,
          isSaved: index % 4 == 0,
        );
      });

  // Bridge: PostModel → Post
  Post toPost() {
    return Post(
      id: postId,
      username: userId,
      userImage: imageUrl,
      postImages:
          imageUrls.isNotEmpty ? imageUrls : [imageUrl],
      likes: likesCount,
      caption: caption,
      timeAgo: _timeAgoFromDate(createdAt),
      comments: commentsCount,
      shares: 0,
      isLiked: isLiked,
      isBookmarked: isSaved,
    );
  }

  // Bridge: Post → PostModel
  static PostModel fromPost(Post post) {
    return PostModel(
      postId: post.id,
      userId: post.username,
      imageUrl:
          post.postImages.isNotEmpty ? post.postImages.first : '',
      caption: post.caption,
      likesCount: post.likes,
      commentsCount: post.comments,
      createdAt: DateTime.now(),
      type: post.postImages.length > 1
          ? PostType.carousel
          : PostType.image,
      imageUrls: post.postImages,
      isLiked: post.isLiked,
      isSaved: post.isBookmarked,
    );
  }

  static String _timeAgoFromDate(DateTime date) {
    final diff = DateTime.now().difference(date);

    if (diff.inDays >= 365) {
      return '${(diff.inDays / 365).floor()}y';
    }
    if (diff.inDays >= 30) {
      return '${(diff.inDays / 30).floor()}mo';
    }
    if (diff.inDays >= 7) {
      return '${(diff.inDays / 7).floor()}w';
    }
    if (diff.inDays >= 1) {
      return '${diff.inDays}d';
    }
    if (diff.inHours >= 1) {
      return '${diff.inHours}h';
    }
    if (diff.inMinutes >= 1) {
      return '${diff.inMinutes}m';
    }
    return 'just now';
  }
}