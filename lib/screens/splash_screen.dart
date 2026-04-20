import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:commity_app1/screens/loginscreen.dart';
import 'package:commity_app1/services/auth_service.dart';
import 'package:commity_app1/shell.dart';
import 'package:commity_app1/screens/choicescreen.dart';

class CommitySplashScreen extends StatefulWidget {
  const CommitySplashScreen({Key? key}) : super(key: key);

  @override
  _CommitySplashScreenState createState() => _CommitySplashScreenState();
}

class _CommitySplashScreenState extends State<CommitySplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _orbitAnimation;

  final List<IconData> _icons = [
    Icons.music_note,
    Icons.computer,
    Icons.flight,
    Icons.videogame_asset,
    Icons.fitness_center,
    Icons.book,
    Icons.brush,
    Icons.camera_alt,
    Icons.group,
    Icons.event,
  ];
  final List<String> _texts = ['Connect', 'Explore', 'Grow Together'];

  bool _showLogo = false;
  bool _endingAnimation = false;
  bool _endingSequenceStarted = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _orbitAnimation = Tween<double>(begin: 0, end: 2 * pi).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _navigateTo(Widget page) {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  /// ✅ Check for existing 30-day session and decide navigation
  Future<void> _checkSessionAndNavigate() async {
    try {
      final isValid = await AuthService.isSessionValid();

      if (isValid) {
        // Session is valid (within 30 days) - check interests
        final hasInterests = await AuthService.hasSelectedInterests();
        final vendorId = await AuthService.getVendorId();

        if (hasInterests) {
          // User has interests selected - go directly to feed
          print('✅ Auto-login: Session valid, interests set → Feed');
          _navigateTo(const AppShell());
        } else {
          // User needs to select interests
          print('✅ Auto-login: Session valid, no interests → Interest Selection');
          _navigateTo(TopicSelectionScreen(
            vendorId: vendorId ?? 0,
            isEditing: false,
          ));
        }
      } else {
        // No valid session - go to login
        print('🔑 No valid session → Login');
        _navigateTo(const LoginScreen());
      }
    } catch (e) {
      print('❌ Session check error: $e');
      _navigateTo(const LoginScreen());
    }
  }

  void _startEndingSequence() {
    if (_endingSequenceStarted) return;
    _endingSequenceStarted = true;

    setState(() => _endingAnimation = true);

    _animationController.duration = const Duration(seconds: 2);
    _animationController.forward(from: 0.6);

    Timer(const Duration(milliseconds: 200), () {
      setState(() => _showLogo = true);
    });

    // ✅ Check session instead of always going to login
    Timer(const Duration(seconds: 3), () {
      _checkSessionAndNavigate();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            _buildParticles(),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildOrbit(),
                  const SizedBox(height: 20),
                  if (_showLogo) _buildLogo() else _buildTextAnimation(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticles() => IgnorePointer(
        child: SizedBox.expand(
          child: CustomPaint(painter: ParticlePainter()),
        ),
      );

  Widget _buildOrbit() {
    return SizedBox(
      width: 200,
      height: 100,
      child: Stack(
        children: [
          if (!_showLogo)
            CustomPaint(size: const Size(200, 100), painter: OrbitPathPainter()),
          for (int i = 0; i < _icons.length; i++)
            Positioned(
              child: AnimatedBuilder(
                animation: _orbitAnimation,
                builder: (context, child) {
                  final angle =
                      _orbitAnimation.value + (2 * pi * i / _icons.length);
                  final x = 100 + 80 * cos(angle);
                  final y = 100 - 80 * sin(angle);

                  return Transform.translate(
                    offset: Offset(x - 20, y - 120),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1e1e3c).withOpacity(0.7),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF6496ff).withOpacity(0.5),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Icon(_icons[i], color: Colors.white, size: 20),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextAnimation() {
    return SizedBox(
      height: 60,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        child: _endingAnimation
            ? Container()
            : DefaultTextStyle(
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1,
                  color: Colors.white,
                  shadows: [Shadow(blurRadius: 10, color: Color(0xFF6496ff))],
                ),
                child: AnimatedTextKit(
                  animatedTexts: _texts
                      .map((text) => FadeAnimatedText(
                            text,
                            duration: const Duration(milliseconds: 900),
                          ))
                      .toList(),
                  totalRepeatCount: 1,
                  onFinished: _startEndingSequence,
                ),
              ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Community',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            foreground: Paint()
              ..shader = const LinearGradient(
                colors: [Color(0xFF64a0ff), Color(0xFFa264ff)],
              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedOpacity(
          opacity: _showLogo ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 600),
          child: const Text(
            'Join. Create. Grow.',
            style: TextStyle(
              fontSize: 16,
              letterSpacing: 1,
              color: Color(0xFFc8dcff),
              shadows: [Shadow(blurRadius: 10, color: Color(0xFF6496ff))],
            ),
          ),
        ),
      ],
    );
  }
}

// === PAINTERS ===

class OrbitPathPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6496ff).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final rect = Rect.fromCircle(center: Offset(size.width / 2, 100), radius: 80);
    canvas.drawArc(rect, pi, pi, false, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ParticlePainter extends CustomPainter {
  final Random _random = Random();
  final List<Particle> _particles = [];

  ParticlePainter() {
    for (int i = 0; i < 20; i++) {
      _particles.add(Particle(_random));
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in _particles) {
      particle.update();
      particle.draw(canvas, size);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class Particle {
  final Random _random;
  late double x;
  late double y;
  late double size;
  late double speed;
  late double opacity;
  late double angle;

  Particle(this._random) {
    reset();
  }

  void reset() {
    x = _random.nextDouble() * 100;
    y = _random.nextDouble() * 100;
    size = _random.nextDouble() * 3 + 1;
    speed = _random.nextDouble() * 2 + 1;
    opacity = _random.nextDouble() * 0.5 + 0.3;
    angle = _random.nextDouble() * 2 * pi;
  }

  void update() {
    x += cos(angle) * 0.5;
    y -= speed * 0.1;
    opacity -= 0.005;

    if (opacity <= 0 || y < -10) {
      reset();
      y = 110;
      opacity = _random.nextDouble() * 0.5 + 0.3;
    }
  }

  void draw(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF6496ff).withOpacity(opacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

    canvas.drawCircle(
      Offset(x / 100 * size.width, y / 100 * size.height),
      this.size,
      paint,
    );
  }
}