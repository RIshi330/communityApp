class Story {
  final String username;
  final String imageUrl;
  final bool hasStory;
  final bool isYourStory;

  Story({
    required this.username,
    required this.imageUrl,
    this.hasStory = false,
    this.isYourStory = false,
  });
}