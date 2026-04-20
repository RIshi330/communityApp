import 'dart:convert';
import 'package:http/http.dart' as http;

/// Skill/Interest Model
class Skill {
  final int id;
  final String title;
  final String? iconUrl;
  final String? description;

  Skill({
    required this.id,
    required this.title,
    this.iconUrl,
    this.description,
  });

  factory Skill.fromJson(Map<String, dynamic> json) {
    return Skill(
      id: json['id'] as int,
      title: json['title'] as String,
      iconUrl: json['icon_url'] as String?,
      description: json['description'] as String?,
    );
  }
}


class SkillsApiService {
  
  
  static const String baseUrl = 
      'http://192.168.40.76/SetupBackendCCBUL/SetupBackendCCBUL/android/community/social_app_api_v1';
  
  /// Fetch all skills
  static Future<List<Skill>> fetchSkills() async {
    try {
      final url = Uri.parse('$baseUrl?action=get_skills');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        
        if (jsonData['success'] == true) {
          final List<dynamic> skillsJson = jsonData['data'] ?? [];
          return skillsJson.map((json) => Skill.fromJson(json)).toList();
        } else {
          throw Exception(jsonData['message'] ?? 'Failed to fetch skills');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching skills: $e');
      rethrow;
    }
  }


  static Future<bool> saveUserInterests({
    required int vendorId,
    required List<int> interestIds,
    int siteId = 1,
  }) async {
    try {
      final url = Uri.parse(baseUrl);
      
      final response = await http.post(
        url,
        body: {
          'action': 'save_user_interests',
          'vendor_id': vendorId.toString(),
          'site_id': siteId.toString(),
          'interest_ids': json.encode(interestIds),
        },
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        return jsonData['success'] == true;
      }
      return false;
    } catch (e) {
      print('Error saving interests: $e');
      return false;
    }
  }
}