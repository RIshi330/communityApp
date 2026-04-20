import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  
  
 static const String baseUrl = 'http://192.168.40.76/SetupBackendCCBUL/SetupBackendCCBUL/android/community/social_app_api_v1.php';
  static const String uploadUrl = 'http://192.168.40.76/SetupBackendCCBUL/SetupBackendCCBUL/android/community/upload_post_images.php';
  

  /// Create new post
  static Future<Map<String, dynamic>> createPost({
    required String contentType,
    required String visibility,
    required String label,
    String? tags,
    String? location,
    required int vendorId,
    required int siteId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        body: {
          'action': 'create_post',
          'content_type': contentType,
          'visibility': visibility,
          'status': 'active',
          'label': label,
          'tags': tags ?? '',
          'location': location ?? '',
          'vendor_id': vendorId.toString(),
          'site_id': siteId.toString(),
        },
      );

      print('Post API Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error creating post: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  /// Upload images for a post
  static Future<Map<String, dynamic>> uploadPostImages({
    required int postId,
    required List<String> imagePaths,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(uploadUrl));
      request.fields['post_id'] = postId.toString();

      for (int i = 0; i < imagePaths.length; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images[]',
            imagePaths[i],
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Upload Response: ${response.body}');

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Upload failed: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error uploading images: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}