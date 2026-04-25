import 'dart:async';
import 'dart:math';

import 'package:commity_app1/Database/Database.dart';
import 'package:commity_app1/screens/admin/Community_Admin_Dashboard.dart';
import 'package:commity_app1/screens/choicescreen.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/shell.dart';
import 'package:flutter/material.dart';

enum AuthMode { signIn, signUp }

enum SignInMethod { password, otp, admin }

enum SignUpMethod { full, otpOnly }

enum OtpFlow { signUp, signInOtp }

enum LoginRole { normalUser, businessUser, admin }

class AuthProduction extends StatefulWidget {
  const AuthProduction({super.key});

  @override
  State<AuthProduction> createState() => _AuthProductionState();
}

class _AuthProductionState extends State<AuthProduction> {
  static const Color _primary = Color(0xFF7C83FD);
  static const Color _light = Color(0xFFEEEFFF);
  static const Color _text = Color(0xFF1A1A1A);

  final _db = Database();

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _mobile = TextEditingController();
  final _password = TextEditingController();

  final List<TextEditingController> _otpCtrls = List.generate(
    6,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  AuthMode _authMode = AuthMode.signIn;
  SignInMethod _signInMethod = SignInMethod.password;
  SignUpMethod _signUpMethod = SignUpMethod.full;
  OtpFlow? _otpFlow;
  LoginRole _loginRole = LoginRole.normalUser;

  bool _loading = false;
  bool _obscurePassword = true;
  bool _otpSent = false;
  String _otpTargetEmail = '';
  int _resendIn = 0;
  Timer? _timer;

  int _selectedVendorType = 500;

  bool get _isAdminRole => _loginRole == LoginRole.admin;

  void _selectLoginRole(LoginRole role) {
    setState(() {
      _loginRole = role;
      _otpSent = false;
      _otpFlow = null;
      for (final c in _otpCtrls) {
        c.clear();
      }

      if (role == LoginRole.admin) {
        _signInMethod = SignInMethod.admin;
        _selectedVendorType = 1;
      } else {
        _signInMethod = SignInMethod.password;
        _selectedVendorType = role == LoginRole.businessUser ? 20 : 500;
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _name.dispose();
    _email.dispose();
    _mobile.dispose();
    _password.dispose();
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String get _otpValue => _otpCtrls.map((e) => e.text).join();

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = 120);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_resendIn <= 1) {
        t.cancel();
        setState(() => _resendIn = 0);
      } else {
        setState(() => _resendIn -= 1);
      }
    });
  }

  String _generateAccessKey() {
    final rand = Random();
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(20, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  String _generateSecretKey() {
    final rand = Random();
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(32, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _showMessage(String text, {bool isError = false}) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _goPostLogin(Map<String, dynamic> response) async {
    final rawData = response['data'];
    final data = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    final vendorId =
        int.tryParse(
          data['vendor_id']?.toString() ??
              response['vendor_id']?.toString() ??
              data['id']?.toString() ??
              '0',
        ) ??
        0;

    if (vendorId > 0) {
      await AuthService.saveLoginSession(vendorId: vendorId, userData: data);

      final hasInterests = await _checkUserHasInterests(vendorId);
      if (!mounted) return;

      if (hasInterests) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AppShell()),
          (route) => false,
        );
      } else {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) =>
                TopicSelectionScreen(vendorId: vendorId, isEditing: false),
          ),
          (route) => false,
        );
      }
      return;
    }

    await _showMessage('Login successful but vendor_id missing', isError: true);
  }

  Future<bool> _checkUserHasInterests(int vendorId) async {
    try {
      final localInterests = await AuthService.hasSelectedInterests();
      if (localInterests) return true;

      final response = await _db.getData({
        'action': 'get_user_interests',
        'vendor_id': vendorId.toString(),
      });

      if (response['success'] == true || response['status'] == 200) {
        final data = response['data'];
        if (data is List && data.isNotEmpty) {
          final ids = data
              .map(
                (item) =>
                    int.tryParse(
                      item['interest_id']?.toString() ??
                          item['id']?.toString() ??
                          '0',
                    ) ??
                    0,
              )
              .where((id) => id > 0)
              .toList();
          if (ids.isNotEmpty) {
            await AuthService.saveUserInterests(ids);
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> _submitSignInPassword() async {
    final email = _email.text.trim();
    final pass = _password.text.trim();

    if (!_isValidEmail(email)) {
      _showMessage('Enter valid email', isError: true);
      return;
    }
    if (pass.length < 6) {
      _showMessage('Password must be at least 6 characters', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      // Admin login uses admin_login_password action from PHP API
      // Send as JSON since the auth API reads json_decode(file_get_contents('php://input'))
      if (_signInMethod == SignInMethod.admin) {
        final response = await _db.postJsonData({
          'action': 'admin_login_password',
          'email': email,
          'password': pass,
        });

        if (response['success'] == true || response['status'] == 200) {
          await _showMessage('Admin login successful');
          // Save admin session
          final adminId = int.tryParse(
            response['admin_id']?.toString() ??
                response['data']?['admin_id']?.toString() ?? '0',
          ) ?? 0;
          await AuthService.saveAdminSession(
            adminId: adminId,
            email: response['email']?.toString() ?? email,
          );
          if (!mounted) return;
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
            (route) => false,
          );
        } else {
          await _showMessage(
            response['message']?.toString() ??
                response['error']?.toString() ??
                'Admin login failed',
            isError: true,
          );
        }
        return;
      }

      // Normal/Business user login
      final Map<String, dynamic> request = {
        'action': 'vendor_login',
        'email': email,
        'password': pass,
        'rememberMe': 'true',
        'vendor_type': _selectedVendorType.toString(),
      };

      Map response = await _db.getData(request);

      if (!(response['success'] == true || response['status'] == 200)) {
        final fallback = await _db.getData({
          'login': 'true',
          'email': email,
          'password': pass,
          'vendor_type': _selectedVendorType.toString(),
        });

        if (fallback['LOGIN_RESPONSE'] is Map) {
          final loginResponse = Map<String, dynamic>.from(
            fallback['LOGIN_RESPONSE'],
          );
          if (loginResponse['status'] == 200) {
            response = {
              'status': 200,
              'success': true,
              'data': {
                'vendor_id':
                    loginResponse['full_data']?['id']?.toString() ??
                    fallback['vendor_id']?.toString() ??
                    '0',
                ...(loginResponse['full_data'] is Map
                    ? Map<String, dynamic>.from(loginResponse['full_data'])
                    : <String, dynamic>{}),
              },
            };
          }
        }
      }

      if (response['success'] == true || response['status'] == 200) {
        await _showMessage('Login successful');
        await _goPostLogin(Map<String, dynamic>.from(response));
      } else {
        await _showMessage(
          response['message']?.toString() ??
              response['error']?.toString() ??
              'Login failed',
          isError: true,
        );
      }
    } catch (e) {
      await _showMessage('Login failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtpForLogin() async {
    final email = _email.text.trim();
    if (!_isValidEmail(email)) {
      _showMessage('Enter valid email', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _db.getData({
        'action': 'vendor_send_otp',
        'sendOtp': email,
      });

      if (response['success'] == true || response['status'] == 200) {
        setState(() {
          _otpFlow = OtpFlow.signInOtp;
          _otpSent = true;
          _otpTargetEmail = email;
          for (final c in _otpCtrls) {
            c.clear();
          }
        });
        _startResendTimer();
        await _showMessage('OTP sent to email');
      } else {
        await _showMessage(
          response['message']?.toString() ??
              response['error']?.toString() ??
              'Unable to send OTP',
          isError: true,
        );
      }
    } catch (e) {
      await _showMessage('Unable to send OTP: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtpForLogin() async {
    if (_otpValue.length != 6) {
      _showMessage('Enter 6-digit OTP', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await _db.getData({
        'action': 'vendor_validate_otp',
        'validateOtp': _otpValue,
      });

      if (response['success'] == true || response['status'] == 200) {
        await _showMessage('OTP verified');
        await _goPostLogin(Map<String, dynamic>.from(response));
      } else {
        await _showMessage(
          response['message']?.toString() ??
              response['error']?.toString() ??
              'OTP verification failed',
          isError: true,
        );
      }
    } catch (e) {
      await _showMessage('OTP verification failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendOtpForSignup() async {
    final email = _email.text.trim();
    if (!_isValidEmail(email)) {
      _showMessage('Enter valid email', isError: true);
      return;
    }
    if (_signUpMethod == SignUpMethod.full) {
      if (_name.text.trim().isEmpty) {
        _showMessage('Name is required', isError: true);
        return;
      }
      if (_mobile.text.trim().length < 10) {
        _showMessage('Enter valid mobile number', isError: true);
        return;
      }
      if (_password.text.trim().length < 6) {
        _showMessage('Password must be at least 6 characters', isError: true);
        return;
      }
    }

    setState(() => _loading = true);
    try {
      final response = await _db.getData({
        'action': 'sendOTP',
        'email': email,
        'name': _name.text.trim(),
        'mobile': _mobile.text.trim(),
        'vendor_type': _selectedVendorType.toString(),
        'type': _selectedVendorType.toString(),
      });

      if (response['success'] == true ||
          response['status'] == 200 ||
          response['status'] == true) {
        setState(() {
          _otpFlow = OtpFlow.signUp;
          _otpSent = true;
          _otpTargetEmail = email;
          for (final c in _otpCtrls) {
            c.clear();
          }
        });
        _startResendTimer();
        await _showMessage('OTP sent to email');
      } else {
        await _showMessage(
          response['message']?.toString() ??
              response['error']?.toString() ??
              'Unable to send OTP',
          isError: true,
        );
      }
    } catch (e) {
      await _showMessage('Unable to send OTP: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyAndCreateSignup() async {
    if (_otpValue.length != 6) {
      _showMessage('Enter 6-digit OTP', isError: true);
      return;
    }

    setState(() => _loading = true);
    try {
      final verify = await _db.getData({
        'action': 'verifyOTP',
        'email': _otpTargetEmail,
        'otp': _otpValue,
      });

      if (!(verify['success'] == true ||
          verify['status'] == 200 ||
          verify['status'] == true)) {
        await _showMessage(
          verify['message']?.toString() ??
              verify['error']?.toString() ??
              'OTP verification failed',
          isError: true,
        );
        return;
      }

      final request = {
        'action': 'createAccount',
        'email': _otpTargetEmail,
        'name': _name.text.trim(),
        'mobile': _mobile.text.trim(),
        'password': _password.text.trim(),
        'vendor_type': _selectedVendorType.toString(),
        'type': _selectedVendorType.toString(),
        'access_key': _generateAccessKey(),
        'secret_key': _generateSecretKey(),
      };

      final create = await _db.getData(request);

      if (create['success'] == true ||
          create['status'] == 200 ||
          create['status'] == true) {
        await _showMessage('Sign up completed. Please sign in.');
        if (!mounted) return;
        setState(() {
          _authMode = AuthMode.signIn;
          _signInMethod = SignInMethod.password;
          _otpSent = false;
          _otpFlow = null;
          for (final c in _otpCtrls) {
            c.clear();
          }
        });
      } else {
        await _showMessage(
          create['message']?.toString() ??
              create['error']?.toString() ??
              'Account creation failed',
          isError: true,
        );
      }
    } catch (e) {
      await _showMessage('Sign up failed: $e', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    if (_resendIn > 0 || _otpTargetEmail.isEmpty) return;

    if (_otpFlow == OtpFlow.signInOtp) {
      await _sendOtpForLogin();
      return;
    }
    await _sendOtpForSignup();
  }

  void _onOtpChanged(String value, int i) {
    if (value.length > 1) {
      final pasted = value.replaceAll(RegExp(r'\D'), '');
      for (var idx = 0; idx < 6; idx++) {
        _otpCtrls[idx].text = idx < pasted.length ? pasted[idx] : '';
      }
      FocusScope.of(context).unfocus();
      setState(() {});
      return;
    }

    if (value.isNotEmpty && i < 5) {
      _otpFocus[i + 1].requestFocus();
    }
    if (value.isEmpty && i > 0) {
      _otpFocus[i - 1].requestFocus();
    }
    setState(() {});
  }

  InputDecoration _input(String label, {IconData? icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF757575)),
      prefixIcon: icon != null
          ? Icon(icon, color: const Color(0xFF757575))
          : null,
      filled: true,
      fillColor: _light,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
    );
  }

  String _formatCountdown(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _maskedOtpTarget() {
    final target = _otpTargetEmail.trim();
    if (target.isEmpty) {
      return '+1 (555) *** **89';
    }

    if (target.contains('@')) {
      final parts = target.split('@');
      final local = parts.first;
      final domain = parts.length > 1 ? parts[1] : '';
      if (local.length <= 2) {
        return '${local[0]}***@$domain';
      }
      final start = local.substring(0, 2);
      return '$start***@$domain';
    }

    final digits = target.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 4) {
      return '+* *** *** ${digits.substring(digits.length - 2)}';
    }
    return '***';
  }

  // Temporary dashboard access removed — admin login now goes through proper auth

  Widget _buildTopTabs() {
    return Container(
      decoration: BoxDecoration(
        color: _light,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _authMode = AuthMode.signIn;
                _otpSent = false;
                _otpFlow = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _authMode == AuthMode.signIn
                      ? _primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sign In',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _authMode == AuthMode.signIn ? Colors.white : _text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() {
                _authMode = AuthMode.signUp;
                _otpSent = false;
                _otpFlow = null;
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _authMode == AuthMode.signUp
                      ? _primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Sign Up',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _authMode == AuthMode.signUp ? Colors.white : _text,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignInMethodSelector() {
    Widget roleButton({
      required LoginRole role,
      required String label,
      required IconData icon,
    }) {
      final selected = _loginRole == role;
      return Expanded(
        child: GestureDetector(
          onTap: () => _selectLoginRole(role),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              color: selected ? Colors.white : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? const Color(0xFFE6E6F0) : Colors.transparent,
              ),
              boxShadow: selected
                  ? const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 10,
                        offset: Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected ? _primary : const Color(0xFF757575),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: selected ? _primary : const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF1F2FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE6E6F0)),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          roleButton(
            role: LoginRole.normalUser,
            label: 'Normal User',
            icon: Icons.person_outline,
          ),
          const SizedBox(width: 4),
          roleButton(
            role: LoginRole.businessUser,
            label: 'Business User',
            icon: Icons.business_outlined,
          ),
          const SizedBox(width: 4),
          roleButton(
            role: LoginRole.admin,
            label: 'Admin',
            icon: Icons.admin_panel_settings_outlined,
          ),
        ],
      ),
    );
  }

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 46,
          child: TextField(
            controller: _otpCtrls[i],
            focusNode: _otpFocus[i],
            maxLength: 1,
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(counterText: ''),
            onChanged: (v) => _onOtpChanged(v, i),
          ),
        );
      }),
    );
  }

  Widget _buildOtpVerificationScreen() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          children: [
            IconButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _otpSent = false;
                        for (final c in _otpCtrls) {
                          c.clear();
                        }
                      });
                    },
              icon: const Icon(Icons.arrow_back, color: _primary),
            ),
            const Expanded(
              child: Text(
                'Community Hub',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 18),
        Container(
          width: 96,
          height: 96,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F2FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.lock_open_rounded, color: _primary, size: 50),
        ),
        const SizedBox(height: 22),
        const Text(
          'Verification Code',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Text(
            'Please enter the 6-digit verification code sent to ${_maskedOtpTarget()}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildOtpBoxes(),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.schedule_outlined,
              size: 16,
              color: Color(0xFF6B7280),
            ),
            const SizedBox(width: 6),
            Text(
              _resendIn > 0
                  ? 'Resend code in ${_formatCountdown(_resendIn)}'
                  : 'You can resend the code now',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: (_resendIn == 0 && !_loading) ? _resendOtp : null,
          child: const Text(
            'Resend via SMS',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtpForLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Verify Identity',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: _loading
                ? null
                : () {
                    setState(() {
                      _otpSent = false;
                      _signInMethod = SignInMethod.password;
                      for (final c in _otpCtrls) {
                        c.clear();
                      }
                    });
                  },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0x33474DC5)),
              backgroundColor: const Color(0xFFF1F2FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'Try another method',
              style: TextStyle(color: _primary, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignInContent() {
    final useOtp = _signInMethod == SignInMethod.otp;
    final canUseOtp = !_isAdminRole;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 78,
            height: 78,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F2FF),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE6E6F0)),
            ),
            child: const Icon(
              Icons.lock_open_rounded,
              color: _primary,
              size: 38,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Center(
          child: Text(
            'Welcome back',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: _text,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text(
            _isAdminRole
                ? 'Sign in to continue as admin'
                : 'Join your community conversations today',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF757575)),
          ),
        ),
        const SizedBox(height: 18),
        _buildSignInMethodSelector(),
        const SizedBox(height: 16),
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _input(
            _isAdminRole ? 'Admin Email' : 'Username or Email',
            icon: Icons.person_outline,
          ),
        ),
        const SizedBox(height: 12),
        if (!useOtp)
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: _input('Password', icon: Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : () {
                    if (!useOtp) {
                      _submitSignInPassword();
                    } else if (!_otpSent) {
                      _sendOtpForLogin();
                    } else {
                      _verifyOtpForLogin();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    useOtp
                        ? (!_otpSent ? 'Send OTP' : 'Verify OTP')
                        : 'Sign In',
                  ),
          ),
        ),
        // Toggle between OTP and Email/Password sign-in
        if (canUseOtp) ...[
          const SizedBox(height: 16),
          Row(
            children: const [
              Expanded(child: Divider(color: Color(0xFFE6E6F0))),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text('OR', style: TextStyle(color: Color(0xFF757575))),
              ),
              Expanded(child: Divider(color: Color(0xFFE6E6F0))),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        if (useOtp) {
                          // Switch back to password
                          _signInMethod = SignInMethod.password;
                        } else {
                          // Switch to OTP
                          _signInMethod = SignInMethod.otp;
                        }
                        _otpSent = false;
                        _otpFlow = null;
                        for (final c in _otpCtrls) {
                          c.clear();
                        }
                      });
                    },
              icon: Icon(
                useOtp ? Icons.lock_outline : Icons.phonelink_lock_outlined,
                color: _primary,
              ),
              label: Text(
                useOtp ? 'Sign In with Email & Password' : 'Sign In with OTP',
                style: const TextStyle(
                  color: _primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0x33474DC5)),
                backgroundColor: const Color(0xFFF1F2FF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSignUpMethodSelector() {
    return Wrap(
      spacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Full Sign Up'),
          selected: _signUpMethod == SignUpMethod.full,
          onSelected: (_) => setState(() {
            _signUpMethod = SignUpMethod.full;
            _otpSent = false;
            _otpFlow = null;
          }),
        ),
        ChoiceChip(
          label: const Text('Email + OTP'),
          selected: _signUpMethod == SignUpMethod.otpOnly,
          onSelected: (_) => setState(() {
            _signUpMethod = SignUpMethod.otpOnly;
            _otpSent = false;
            _otpFlow = null;
          }),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<int>(
      initialValue: _selectedVendorType,
      decoration: _input('Type', icon: Icons.badge_outlined),
      items: const [
        DropdownMenuItem(value: 500, child: Text('User (500)')),
        DropdownMenuItem(value: 1, child: Text('Admin (1)')),
        DropdownMenuItem(value: 20, child: Text('Vendor (20)')),
        DropdownMenuItem(value: 30, child: Text('Vendor (30)')),
      ],
      onChanged: (v) {
        if (v != null) setState(() => _selectedVendorType = v);
      },
    );
  }

  Widget _buildSignUpContent() {
    final full = _signUpMethod == SignUpMethod.full;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: _text,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Sign up with OTP verification',
          style: TextStyle(color: Color(0xFF757575)),
        ),
        const SizedBox(height: 18),
        _buildSignUpMethodSelector(),
        const SizedBox(height: 14),
        if (full) ...[
          TextField(
            controller: _name,
            decoration: _input('Name', icon: Icons.person_outline),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _mobile,
            keyboardType: TextInputType.phone,
            decoration: _input('Mobile Number', icon: Icons.phone_outlined),
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _input('Email', icon: Icons.email_outlined),
        ),
        const SizedBox(height: 10),
        _buildTypeSelector(),
        if (full) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _password,
            obscureText: _obscurePassword,
            decoration: _input('Password', icon: Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
          ),
        ],
        if (_otpSent) ...[
          const SizedBox(height: 12),
          _buildOtpBoxes(),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _resendIn == 0 ? _resendOtp : null,
              child: Text(
                _resendIn == 0 ? 'Resend OTP' : 'Resend in ${_resendIn}s',
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _loading
                ? null
                : () {
                    if (!_otpSent) {
                      _sendOtpForSignup();
                    } else {
                      _verifyAndCreateSignup();
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_otpSent ? 'Verify OTP & Create Account' : 'Send OTP'),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showOtpVerification =
        _authMode == AuthMode.signIn &&
        _signInMethod == SignInMethod.otp &&
        _otpSent;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FF),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 460),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: _primary.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!showOtpVerification) ...[
                    _buildTopTabs(),
                    const SizedBox(height: 18),
                  ],
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    child: showOtpVerification
                        ? _buildOtpVerificationScreen()
                        : _authMode == AuthMode.signIn
                        ? _buildSignInContent()
                        : _buildSignUpContent(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
