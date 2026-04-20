// lib/models/group_model.dart
// lib/data/groups_data.dart

// वापरकर्त्याने तयार केलेल्या सर्व ग्रुप्सची यादी साठवण्यासाठी.
List<Group> userCreatedGroups = [];

class Group {
  final String id;
  final String name;
  final String privacy;
  final String imageUrl;

  Group({
    required this.id,
    required this.name,
    required this.privacy,
    required this.imageUrl,
  });
}
