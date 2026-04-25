import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:commity_app1/Database/Database.dart';

/// AuthService - Handles session persistence (30-day auto-login like Instagram)
/// Stores login timestamp, vendor_id, and user data in SharedPreferences
class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyVendorId = 'vendor_id';
  static const String _keyLoginTimestamp = 'login_timestamp';
  static const String _keyLastActiveTimestamp = 'last_active_timestamp';
  static const String _keyUserData = 'user_data_cache';
  static const String _keyUserInterests = 'user_interests';
  static const String _keyHasSelectedInterests = 'has_selected_interests';
  static const String _keyUserLocation = 'user_location';
  static const String _keyIsAdminLoggedIn = 'is_admin_logged_in';
  static const String _keyAdminId = 'admin_id';
  static const String _keyAdminEmail = 'admin_email';

  /// 30-day session duration in milliseconds
  static const int _sessionDurationMs = 30 * 24 * 60 * 60 * 1000;

  /// Save login session after successful login
  static Future<void> saveLoginSession({
    required int vendorId,
    Map<String, dynamic>? userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setInt(_keyVendorId, vendorId);
    await prefs.setInt(_keyLoginTimestamp, now);
    await prefs.setInt(_keyLastActiveTimestamp, now);

    if (userData != null) {
      await prefs.setString(_keyUserData, jsonEncode(userData));
    }
  }

  /// Update last active timestamp to current time
  static Future<void> touchSessionActivity() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastActiveTimestamp,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Check if user is logged in and session is still valid (inactive < 30 days)
  static Future<bool> isSessionValid() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
    if (!isLoggedIn) return false;

    final loginTimestamp = prefs.getInt(_keyLoginTimestamp) ?? 0;
    final lastActiveTimestamp =
        prefs.getInt(_keyLastActiveTimestamp) ?? loginTimestamp;
    final currentTime = DateTime.now().millisecondsSinceEpoch;
    final elapsed = currentTime - lastActiveTimestamp;

    // Auto logout if user did not open app for 30+ days
    if (elapsed > _sessionDurationMs) {
      await logout();
      return false;
    }

    // Keep session alive based on recent app opens/activity
    await prefs.setInt(_keyLastActiveTimestamp, currentTime);

    return true;
  }

  /// Get stored vendor ID
  static Future<int?> getVendorId() async {
    final prefs = await SharedPreferences.getInstance();
    int? vendorId = prefs.getInt(_keyVendorId);

    if (vendorId != null && vendorId != 0) {
      return vendorId;
    }

    // Fallback: check FlutterSecureStorage from Database
    try {
      final db = Database();
      final userData = await db.getUserData();
      if (userData != null) {
        if (userData['vendor_id'] != null) {
          return int.tryParse(userData['vendor_id'].toString());
        }
        if (userData['id'] != null) {
          return int.tryParse(userData['id'].toString());
        }
      }
    } catch (e) {
      print('Fallback int vendor ID error: $e');
    }

    return null;
  }

  /// Get stored vendor ID as string
  static Future<String> getVendorIdString() async {
    final vendorId = await getVendorId();
    if (vendorId != null && vendorId != 0) {
      return vendorId.toString();
    }

    // Fallback: check FlutterSecureStorage from Database (e.g., after auto_login)
    try {
      final db = Database();
      final userData = await db.getUserData();
      if (userData != null) {
        if (userData['vendor_id'] != null)
          return userData['vendor_id'].toString();
        if (userData['id'] != null) return userData['id'].toString();
      }
    } catch (e) {
      print('Fallback vendor ID error: $e');
    }

    return '0';
  }

  /// Get cached user data
  static Future<Map<String, dynamic>?> getCachedUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserData);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Save user interests selection status
  static Future<void> setHasSelectedInterests(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyHasSelectedInterests, value);
  }

  /// Check if user has already selected interests
  static Future<bool> hasSelectedInterests() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyHasSelectedInterests) ?? false;
  }

  /// Save user interests locally
  static Future<void> saveUserInterests(List<int> interestIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserInterests, jsonEncode(interestIds));
    await prefs.setBool(_keyHasSelectedInterests, true);
  }

  /// Get saved interests
  static Future<List<int>?> getSavedInterests() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserInterests);
    if (data != null) {
      final decoded = jsonDecode(data) as List;
      return decoded.cast<int>();
    }
    return null;
  }

  /// Save user location
  static Future<void> saveUserLocation(
    double lat,
    double lng,
    String? address,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _keyUserLocation,
      jsonEncode({
        'latitude': lat,
        'longitude': lng,
        'address': address ?? '',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }

  /// Get saved location
  static Future<Map<String, dynamic>?> getSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyUserLocation);
    if (data != null) {
      return jsonDecode(data);
    }
    return null;
  }

  /// Save admin login session
  static Future<void> saveAdminSession({
    required int adminId,
    required String email,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now().millisecondsSinceEpoch;
    await prefs.setBool(_keyIsAdminLoggedIn, true);
    await prefs.setInt(_keyAdminId, adminId);
    await prefs.setString(_keyAdminEmail, email);
    await prefs.setInt(_keyLoginTimestamp, now);
    await prefs.setInt(_keyLastActiveTimestamp, now);
  }

  /// Check if an admin session is active
  static Future<bool> isAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsAdminLoggedIn) ?? false;
  }

  /// Get stored admin ID
  static Future<int?> getAdminId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyAdminId);
  }

  /// Get stored admin email
  static Future<String?> getAdminEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAdminEmail);
  }

  /// Clear session (logout)
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyVendorId);
    await prefs.remove(_keyLoginTimestamp);
    await prefs.remove(_keyLastActiveTimestamp);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyUserInterests);
    await prefs.remove(_keyHasSelectedInterests);
    await prefs.remove(_keyUserLocation);
    await prefs.remove(_keyIsAdminLoggedIn);
    await prefs.remove(_keyAdminId);
    await prefs.remove(_keyAdminEmail);
  }

  /// Perform logout - clears both API and local session
  static Future<void> logout() async {
    try {
      final vendorId = await getVendorIdString();
      final database = Database();
      await database.getData({'action': 'logout', 'vendor_id': vendorId});
    } catch (e) {
      print('Logout API error (non-critical): $e');
    }

    // Always clear local session regardless of API result
    await clearSession();

    // Also clear secure storage
    try {
      final database = Database();
      await database.clearAllData();
    } catch (e) {
      print('Clear secure storage error: $e');
    }
  }
}
