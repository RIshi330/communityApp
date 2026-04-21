import 'dart:convert';
import 'package:commity_app1/app_constants.dart';
import 'package:commity_app1/screens/feed_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class CreateProfileScreen extends StatefulWidget {
  final String email;
  final bool isRecruiter;
  final bool mergeRequired;

  const CreateProfileScreen({
    super.key,
    required this.email,
    required this.isRecruiter,
    this.mergeRequired = false,
  });

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _mobile = TextEditingController();
  bool _termsAccepted = false;
  bool _isLoading = false;

  static const Color white = Colors.white;
  static const Color black = Color(0xFF1A1A1A);
  static const Color lavender = Color(0xFF7C83FD);
  static const Color lavenderLight = Color(0xFFEEEFFF);
  static const Color grey = Color(0xFF757575);

  static const String _apiUrl = '${baseUrl}community/sign_up_API.php';

  @override
  void initState() {
    super.initState();
    // Show merge dialog if required
    if (widget.mergeRequired) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showMergeDialog());
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _mobile.dispose();
    super.dispose();
  }

  void _showMergeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Merge Account',
          style: TextStyle(color: black, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'You already have a Seller account. Do you want to merge it with this account?',
          style: TextStyle(color: grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: lavender,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Merge', style: TextStyle(color: white)),
          ),
        ],
      ),
    );
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms & Conditions'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        body: {
          'action': 'createAccount',
          'email': widget.email,
          'name': _name.text.trim(),
          'mobile': _mobile.text.trim(),
          'merge_confirm': widget.mergeRequired ? '1' : '0',
        },
      );

      print('RAW SIGN UP RESPONSE: ${response.body}');
      print('HEADERS: ${response.headers}');

      if (response.body.isEmpty) {
        throw FormatException('Server returned empty response');
      }

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (data['status'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account Created Successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const FeedScreen()),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Failed to create account'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      print('❌ Create Profile Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: lavenderLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      color: black,
                      size: 18,
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: lavenderLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.edit_note_rounded,
                    color: lavender,
                    size: 32,
                  ),
                ),

                const SizedBox(height: 24),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: lavenderLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.isRecruiter
                            ? Icons.business_center_outlined
                            : Icons.person_outline_rounded,
                        color: lavender,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        widget.isRecruiter ? 'Recruiter' : 'Candidate',
                        style: const TextStyle(
                          color: lavender,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Complete Profile',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: black,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tell us a bit about yourself',
                  style: TextStyle(fontSize: 15, color: grey, height: 1.5),
                ),

                const SizedBox(height: 40),

                // Name
                TextFormField(
                  controller: _name,
                  style: const TextStyle(color: black),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(color: grey),
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: grey,
                    ),
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
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty)
                      return 'Please enter your name';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email - Read Only
                TextFormField(
                  initialValue: widget.email,
                  readOnly: true,
                  style: const TextStyle(color: grey),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(color: grey),
                    prefixIcon: const Icon(Icons.email_outlined, color: grey),
                    suffixIcon: const Icon(
                      Icons.lock_outline,
                      color: grey,
                      size: 18,
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF0F0F0),
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
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Mobile
                TextFormField(
                  controller: _mobile,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: black),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Mobile Number',
                    labelStyle: const TextStyle(color: grey),
                    prefixIcon: const Icon(Icons.phone_outlined, color: grey),
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
                  ),
                  validator: (v) {
                    if ((v ?? '').trim().isEmpty)
                      return 'Please enter your mobile number';
                    if ((v ?? '').trim().length < 10)
                      return 'Enter valid 10 digit number';
                    return null;
                  },
                ),

                const SizedBox(height: 24),

                // Terms & Conditions
                GestureDetector(
                  onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _termsAccepted ? lavender : white,
                          border: Border.all(
                            color: _termsAccepted ? lavender : grey,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: _termsAccepted
                            ? const Icon(Icons.check, color: white, size: 14)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              color: grey,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(text: 'I agree to the '),
                              TextSpan(
                                text: 'Terms & Conditions',
                                style: TextStyle(
                                  color: lavender,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: lavender,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  color: lavender,
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                  decorationColor: lavender,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _createAccount,
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
                              valueColor: AlwaysStoppedAnimation<Color>(white),
                            ),
                          )
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: white,
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
    );
  }
}
