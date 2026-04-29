import 'dart:async';

import 'package:commity_app1/screens/auth_screen.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/shell.dart';
import 'package:commity_app1/screens/admin/Community_Admin_Dashboard.dart';
import 'package:commity_app1/screens/choicescreen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const CommUnityApp());
}

class CommUnityApp extends StatelessWidget {
  const CommUnityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'comm-Unity',
      theme: AppTheme.theme,
      home: const AnimatedSplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AppTheme {
  static const Color primary = Color(0xFF7C83FD);
  static const Color backgroundStart = Color(0xFFF9F9FF);
  static const Color backgroundEnd = Color(0xFFE8EAF6);
  static const Color textMain = Color(0xFF1F2937);
  static const Color textMuted = Color(0xFF6B7280);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: primary, primary: primary),
      fontFamily: 'Manrope',
    );
  }
}

class AnimatedSplashScreen extends StatefulWidget {
  const AnimatedSplashScreen({super.key});

  @override
  State<AnimatedSplashScreen> createState() => _AnimatedSplashScreenState();
}

class _AnimatedSplashScreenState extends State<AnimatedSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  double _progress = 0.0;
  Timer? _timer;
  Timer? _redirectTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _controller.forward();
    _startLoading();
    _scheduleRedirect();
  }

  void _startLoading() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        if (_progress < 1.0) {
          _progress += 0.01;
        } else {
          _timer?.cancel();
        }
      });
    });
  }

  void _scheduleRedirect() {
    _redirectTimer = Timer(const Duration(seconds: 3), _redirectNextScreen);
  }

  Future<void> _redirectNextScreen() async {
    final isAdmin = await AuthService.isAdminSession();
    if (isAdmin) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
      );
      return;
    }

    final hasValidSession = await AuthService.isSessionValid();
    if (!mounted) return;

    if (hasValidSession) {
      final hasInterests = await AuthService.hasSelectedInterests();
      if (hasInterests) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShell()),
        );
      } else {
        final vendorId = await AuthService.getVendorId() ?? 0;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => TopicSelectionScreen(vendorId: vendorId, isEditing: false),
          ),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthProduction()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    _redirectTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppTheme.backgroundStart, AppTheme.backgroundEnd],
          ),
        ),
        child: Stack(
          children: [
            // Decorative background elements
            Positioned(
              top: -50,
              right: -50,
              child: _buildBlurCircle(
                150,
                AppTheme.primary.withValues(alpha: 0.05),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -30,
              child: _buildBlurCircle(
                100,
                AppTheme.primary.withValues(alpha: 0.08),
              ),
            ),

            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo Container
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          size: 50,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'comm-Unity',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textMain,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Connecting people, Businesses and Ideas',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Section: Loading & Status
            Positioned(
              bottom: 60,
              left: 40,
              right: 40,
              child: Column(
                children: [
                  Text(
                    'INITIALIZING...',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary.withValues(alpha: 0.7),
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppTheme.primary,
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatusItem(Icons.verified_user, 'SECURE'),
                      const SizedBox(width: 20),
                      _buildStatusItem(Icons.sync, 'SYNCED'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'POWERED BY COMM-UNITY TECH',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted.withValues(alpha: 0.5),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildStatusItem(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, size: 12, color: AppTheme.textMuted.withValues(alpha: 0.6)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}
