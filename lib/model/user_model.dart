class UserModel {
  final String uid;
  final String username;
  final String displayName;
  final String profileImageUrl;
  final String bio;
  final List<String> bioLines;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isPrivate;
  final bool isVerified;
  final String? website;
  final List<String> highlights;

  UserModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.bio,
    required this.bioLines,
    required this.postsCount,
    required this.followersCount,
    required this.followingCount,
    this.isPrivate = false,
    this.isVerified = false,
    this.website,
    this.highlights = const [],
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      username: map['username'] ?? '',
      displayName: map['displayName'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      bio: map['bio'] ?? '',
      bioLines: List<String>.from(map['bioLines'] ?? []),
      postsCount: map['postsCount'] ?? 0,
      followersCount: map['followersCount'] ?? 0,
      followingCount: map['followingCount'] ?? 0,
      isPrivate: map['isPrivate'] ?? false,
      isVerified: map['isVerified'] ?? false,
      website: map['website'],
      highlights: List<String>.from(map['highlights'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'displayName': displayName,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'bioLines': bioLines,
      'postsCount': postsCount,
      'followersCount': followersCount,
      'followingCount': followingCount,
      'isPrivate': isPrivate,
      'isVerified': isVerified,
      'website': website,
      'highlights': highlights,
    };
  }

  UserModel copyWith({
    String? uid,
    String? username,
    String? displayName,
    String? profileImageUrl,
    String? bio,
    List<String>? bioLines,
    int? postsCount,
    int? followersCount,
    int? followingCount,
    bool? isPrivate,
    bool? isVerified,
    String? website,
    List<String>? highlights,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      bio: bio ?? this.bio,
      bioLines: bioLines ?? this.bioLines,
      postsCount: postsCount ?? this.postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      isPrivate: isPrivate ?? this.isPrivate,
      isVerified: isVerified ?? this.isVerified,
      website: website ?? this.website,
      highlights: highlights ?? this.highlights,
    );
  }

  // Sample data matching the screenshots
  static UserModel get sampleUser => UserModel(
        uid: 'narsiha_06',
        username: 'narsiha_06',
        displayName: '|| NARSIHA 🖐️',
        profileImageUrl: 'https://i.pravatar.cc/150?img=12',
        bio: '',
        bioLines: [
          '• Hare krishna',
          '• Karm||Dharm||moksha',
        ],
        postsCount: 0,
        followersCount: 234,
        followingCount: 276,
        isPrivate: true,
        isVerified: false,
        highlights: ['महाराज 🧡🚩'],
      );
}

class FollowerModel {
  final String uid;
  final String username;
  final String displayName;
  final String profileImageUrl;
  final bool isFollowingBack;

  FollowerModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    required this.isFollowingBack,
  });

  static List<FollowerModel> get sampleFollowers => [
        FollowerModel(
          uid: '1',
          username: 'harshad_0941',
          displayName: 'Harshad',
          profileImageUrl: 'https://i.pravatar.cc/150?img=1',
          isFollowingBack: false,
        ),
        FollowerModel(
          uid: '2',
          username: 'pratiksha__672',
          displayName: 'pratu',
          profileImageUrl: 'https://i.pravatar.cc/150?img=2',
          isFollowingBack: false,
        ),
        FollowerModel(
          uid: '3',
          username: '_shivkumar7005',
          displayName: 'Shiv Kumar',
          profileImageUrl: 'https://i.pravatar.cc/150?img=3',
          isFollowingBack: true,
        ),
        FollowerModel(
          uid: '4',
          username: 'payalllll.07',
          displayName: 'Payal',
          profileImageUrl: 'https://i.pravatar.cc/150?img=4',
          isFollowingBack: false,
        ),
        FollowerModel(
          uid: '5',
          username: 'yashraj_d8777',
          displayName: 'Yashraj',
          profileImageUrl: 'https://i.pravatar.cc/150?img=5',
          isFollowingBack: true,
        ),
      ];
}

class FollowingModel {
  final String uid;
  final String username;
  final String displayName;
  final String profileImageUrl;
  final int? newPostsCount;

  FollowingModel({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.profileImageUrl,
    this.newPostsCount,
  });

  static List<FollowingModel> get sampleFollowing => [
        FollowingModel(
          uid: '1',
          username: 'sujall_41',
          displayName: 'Sujal Salke patil...',
          profileImageUrl: 'https://i.pravatar.cc/150?img=6',
          newPostsCount: 1,
        ),
        FollowingModel(
          uid: '2',
          username: 'rushikesh_shinde...',
          displayName: 'Rushikesh Shinde',
          profileImageUrl: 'https://i.pravatar.cc/150?img=7',
          newPostsCount: 1,
        ),
        FollowingModel(
          uid: '3',
          username: 'bagalshashi',
          displayName: 'Shashi Bagal',
          profileImageUrl: 'https://i.pravatar.cc/150?img=8',
          newPostsCount: 3,
        ),
        FollowingModel(
          uid: '4',
          username: 'core2web',
          displayName: 'Core2web | Pune |...',
          profileImageUrl: 'https://i.pravatar.cc/150?img=9',
          newPostsCount: 3,
        ),
        FollowingModel(
          uid: '5',
          username: 'chautha_stambh_...',
          displayName: 'Chautha Stambh...',
          profileImageUrl: 'https://i.pravatar.cc/150?img=10',
          newPostsCount: 9,
        ),
        FollowingModel(
          uid: '6',
          username: 'rohan_kore99',
          displayName: 'Rohan',
          profileImageUrl: 'https://i.pravatar.cc/150?img=11',
          newPostsCount: null,
        ),
        FollowingModel(
          uid: '7',
          username: '_nishant.rathod_21',
          displayName: 'Nishant Rathod',
          profileImageUrl: 'https://i.pravatar.cc/150?img=13',
          newPostsCount: null,
        ),
        FollowingModel(
          uid: '8',
          username: 'harshraktate_29',
          displayName: '• HARSH RAKTAT...',
          profileImageUrl: 'https://i.pravatar.cc/150?img=14',
          newPostsCount: null,
        ),
      ];
}