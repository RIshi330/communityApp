import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/screens/admin/Community_Admin_Dashboard.dart';
import 'package:commity_app1/screens/choicescreen.dart';
import 'package:commity_app1/screens/signupscreen.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/services/location_service.dart';
import 'package:commity_app1/shell.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _isLoading = false;
  bool _obscure = true;

  static const Color white = Colors.white;
  static const Color black = Color(0xFF1A1A1A);
  static const Color lavender = Color(0xFF7C83FD);
  static const Color lavenderLight = Color(0xFFEEEFFF);
  static const Color grey = Color(0xFF757575);

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: grey),
      prefixIcon: icon != null ? Icon(icon, color: grey) : null,
      filled: true,
      fillColor: lavenderLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: lavender, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.red, width: 2),
      ),
    );
  }

  // ✅ LOGIN FUNCTION - Now with 30-day session & location
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final database = Database();

      final requestBody = {
        'action': 'vendor_login',
        'email': _email.text.trim(),
        'password': _password.text.trim(),
        'rememberMe': 'true', // ✅ Always remember for 30 days
      };

      final response = await database.getData(requestBody);

      if (!mounted) return;

      print('Database Response: $response');

      // ✅ SUCCESS
      if (response['success'] == true || response['status'] == 200) {
        final vendorId =
            int.tryParse(
              response['data']?['vendor_id']?.toString() ??
                  response['vendor_id']?.toString() ??
                  '0',
            ) ??
            0;

        // ✅ Save 30-day session (like Instagram)
        await AuthService.saveLoginSession(
          vendorId: vendorId,
          userData: response['data'] is Map
              ? Map<String, dynamic>.from(response['data'])
              : null,
        );

        print('✅ Session saved for vendor_id: $vendorId');

        // ✅ Request location permission (real-time)
        _requestLocationInBackground();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Login successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // ✅ Check if user already has interests
        final hasInterests = await _checkUserHasInterests(vendorId);

        if (!mounted) return;

        if (hasInterests) {
          // User already has interests - go to feed directly
          print('✅ User already has interests → Feed');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AppShell()),
            (route) => false,
          );
        } else {
          // Navigate to Interest/Topic Selection Screen
          print('🎯 User needs to select interests → Topic Selection');
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TopicSelectionScreen(vendorId: vendorId, isEditing: false),
            ),
            (route) => false,
          );
        }
      } else {
        // ❌ LOGIN FAILED
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ??
                  response['error'] ??
                  'Invalid email or password',
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('Login Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Network error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openAdminDashboard() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
    );
  }

  /// ✅ Request location permission in background after login
  void _requestLocationInBackground() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        final locationData = await LocationService.requestAndGetLocation();
        if (locationData != null) {
          print('📍 Location obtained after login: ${locationData['address']}');
        } else {
          print('📍 Location permission denied or unavailable');
        }
      } catch (e) {
        print('📍 Location request error: $e');
      }
    });
  }

  /// ✅ Check if user already has interests saved (from API)
  Future<bool> _checkUserHasInterests(int vendorId) async {
    try {
      // First check local cache
      final localInterests = await AuthService.hasSelectedInterests();
      if (localInterests) return true;

      // Then check from API
      final database = Database();
      final response = await database.getData({
        'action': 'get_user_interests',
        'vendor_id': vendorId.toString(),
      });

      if (response['success'] == true || response['status'] == 200) {
        final data = response['data'];
        if (data != null && data is List && data.isNotEmpty) {
          // User has interests - save locally
          final interestIds = data
              .map(
                (item) =>
                    int.tryParse(
                      item['interest_id']?.toString() ??
                          item['id']?.toString() ??
                          '0',
                    ) ??
                    0,
              )
              .toList();
          await AuthService.saveUserInterests(interestIds.cast<int>());
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error checking interests: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  // Icon
                  Center(
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: lavenderLight,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: lavender,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  const Text(
                    'Welcome back 👋',
                    style: TextStyle(
                      color: black,
                      fontSize: 36,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(color: grey, fontSize: 15, height: 1.5),
                  ),

                  const SizedBox(height: 40),

                  // Email
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: black),
                    decoration: _dec('Email', icon: Icons.email_outlined),
                    validator: (v) {
                      final value = (v ?? '').trim();
                      if (value.isEmpty) return 'Please enter your email';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: _password,
                    obscureText: _obscure,
                    style: const TextStyle(color: black),
                    decoration: _dec('Password', icon: Icons.lock_outline)
                        .copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscure
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: grey,
                            ),
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                          ),
                        ),
                    validator: (v) {
                      if ((v ?? '').isEmpty)
                        return 'Please enter your password';
                      if ((v ?? '').length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),

                  const SizedBox(height: 8),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Forgot Password?',
                        style: TextStyle(
                          color: lavender,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 4),

                  const SizedBox(height: 16),

                  // Login Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lavender,
                        disabledBackgroundColor: lavenderLight,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  white,
                                ),
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _openAdminDashboard,
                      style: TextButton.styleFrom(
                        foregroundColor: lavender,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                      ),
                      icon: const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 18,
                      ),
                      label: const Text(
                        'Temp Admin',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Divider
                  Row(
                    children: [
                      Expanded(
                        child: Divider(color: Colors.grey.withOpacity(0.3)),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 14),
                        child: Text('or', style: TextStyle(color: grey)),
                      ),
                      Expanded(
                        child: Divider(color: Colors.grey.withOpacity(0.3)),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Google Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: black,
                        side: BorderSide(color: Colors.grey.withOpacity(0.35)),
                        backgroundColor: white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(
                        Icons.g_mobiledata,
                        color: lavender,
                        size: 30,
                      ),
                      label: const Text(
                        'Continue with Google',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sign up link
                  Center(
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignupScreen()),
                      ),
                      child: RichText(
                        text: const TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(color: grey, fontSize: 14),
                          children: [
                            TextSpan(
                              text: "Sign up",
                              style: TextStyle(
                                color: lavender,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
