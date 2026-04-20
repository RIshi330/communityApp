import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../app_constants.dart';

/// Database class for handling API communication
/// Centralized API client with session management and secure storage
class Database {
  int retry = 0;

  /// Get Android options for secure storage
  AndroidOptions _getAndroidOptions() => const AndroidOptions(
    encryptedSharedPreferences: true,
  );

  /// Main API communication method
  /// Handles all API calls with session management and error handling
  Future<Map> getData(Map postBody) async {
    var result = {};
    Map<String, String> stringBody = {}; // Initialize here

    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    final existingSessionId = await storage.read(key: "SESSION_ID");

    try {
      // Convert all body values to strings to avoid type cast issues
      stringBody = postBody.map((key, value) => MapEntry(key, value?.toString() ?? ''));
      
      final response = await http.post(
        Uri.parse(baseUrlLegacy),
        body: stringBody,
        headers: {
          'APP_ID' : appId.toString(),
          'SESSION_ID' : existingSessionId?.toString() ?? '',
        },
      );

      var copy = response.body;
      print('RAW RESPONSE BODY: "${copy}"');
      print('RESPONSE STATUS CODE: ${response.statusCode}');
      print('RESPONSE HEADERS: ${response.headers}');
      
      if (copy.isEmpty) {
        print('EMPTY RESPONSE - Server returned no content');
        result = {
          "status": 300,
          "error": "Server returned empty response",
          "debug_info": {
            "status_code": response.statusCode,
            "headers": response.headers.toString(),
          },
        };
      } else {
        try {
          dynamic decodedResponse = jsonDecode(copy);
          
          // Handle both Map and List responses
          if (decodedResponse is Map) {
            result = Map<String, dynamic>.from(decodedResponse);
          } else if (decodedResponse is List) {
            // If it's a list, wrap it in a map for consistency
            result = {
              'success': true,
              'data': decodedResponse,
              'status': 200,
            };
          } else {
            result = decodedResponse;
          }
        } catch (jsonError) {
          print('JSON DECODE ERROR: $jsonError');
          print('RAW RESPONSE THAT FAILED JSON DECODE: "${copy}"');
          result = {
            "status": 300,
            "error": "Invalid JSON response from server",
            "raw_response": copy,
            "json_error": jsonError.toString(),
            "debug_info": {
              "status_code": response.statusCode,
              "headers": response.headers.toString(),
            },
          };
        }
      }

      // Store Razorpay key if present
      if (result.containsKey('RAZORPAY_KEY') && result['RAZORPAY_KEY'] != null && liveModeEnabled) {
        var razorpayKey = result['RAZORPAY_KEY'];
        await storage.write(key: "razorpay_key", value: razorpayKey.toString());
      } else {
        var razorpayKey = razorpayTestKey;
        await storage.write(key: "razorpay_key", value: razorpayKey.toString());
      }

      // Store admin email if present
      if (result.containsKey('admin_email') && result['admin_email'] != null) {
        await storage.write(key: 'admin_email', value: result['admin_email'].toString());
      }

      // Handle session management - FIXED NULL SAFETY
      if (existingSessionId == null &&
          result.containsKey('SESSION_ID') &&
          result['SESSION_ID'] != null) {
        await storage.write(key: "SESSION_ID", value: result['SESSION_ID'].toString());
      } else if (result['status'] == 400 && result.containsKey("logged_out")) {
        if (retry == 0) {
          retry = 1;
          final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());

          String? accessToken;
          String? validator;

          try {
            accessToken = await storage.read(key: "access_token");
            validator = await storage.read(key: "validator");
          } catch (e) {
            validator = accessToken = null;
          }

          if (accessToken != null && validator != null) {
            Map<String, String> postData = {
              "auto_login": "true",
              "access_token": accessToken,
              "validator": validator,
            };

            final res = await getData(postData);

            var result = res['LOGIN_RESPONSE'];

            if (result != null && 
                result['status'] == 200 &&
                result['long_term_access_token'] != null &&
                result['token_verifier'] != null) {
              final token = result['long_term_access_token'];
              final validator = result['token_verifier'];

              await storage.write(key: "access_token", value: token.toString());
              await storage.write(key: "validator", value: validator.toString());
              await storage.write(
                  key: "user_data", value: jsonEncode(result['full_data'] ?? {}));
              await storage.write(
                  key: "user_products", value: jsonEncode(res['PRODUCTS'] ?? {}));
              await storage.write(
                  key: "filters", value: jsonEncode(res['filters'] ?? {}));

              return await getData(postBody);
            }
          }
        }
      }
    } catch (e) {
      print('Database.dart - Network Error Details:');
      print('Error: $e');
      print('Error Type: ${e.runtimeType}');
      print('Base URL: $baseUrlLegacy');
      print('Request Body: $stringBody');
      
      result = {
        "status": 300,
        "error": "Server not reachable - ${e.toString()}",
        "debug_info": {
          "base_url": baseUrlLegacy,
          "error_type": e.runtimeType.toString(),
          "error_message": e.toString(),
        }
      };
    }

    return result;
  }

  /// Get current session ID
  Future<String?> getSessionId() async {
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    return await storage.read(key: "SESSION_ID");
  }

  /// Get stored Razorpay key
  Future<String?> getRazorpayKey() async {
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    return await storage.read(key: "razorpay_key");
  }

  /// Store user data securely
  Future<void> storeUserData(Map<String, dynamic> userData) async {
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    await storage.write(key: "user_data", value: jsonEncode(userData));
  }

  /// Get stored user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
      final userData = await storage.read(key: "user_data");
      return userData != null ? jsonDecode(userData) : null;
    } catch (e) {
      print("Error reading user data: $e");
      return null;
    }
  }

  /// Clear all stored data (for logout)
  Future<void> clearAllData() async {
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    await storage.deleteAll();
  }

  /// Store access token for auto-login
  Future<void> storeAccessToken(String token, String validator) async {
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    await storage.write(key: "access_token", value: token);
    await storage.write(key: "validator", value: validator);
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    return await storage.read(key: "access_token");
  }

  /// Store user preferences
  Future<void> storeUserPreferences(Map<String, dynamic> preferences) async {
    final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
    await storage.write(key: "user_preferences", value: jsonEncode(preferences));
  }

  /// Get user preferences
  Future<Map<String, dynamic>?> getUserPreferences() async {
    try {
      final storage = FlutterSecureStorage(aOptions: _getAndroidOptions());
      final preferences = await storage.read(key: "user_preferences");
      return preferences != null ? jsonDecode(preferences) : null;
    } catch (e) {
      print("Error reading user preferences: $e");
      return null;
    }
  }
}
