import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:brain_link/navigation/AppRoutes.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _animateButton = false;

  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _animateButton = true;
        });
      }
    });
  }

  void _checkAuthState() async {
    await Future.delayed(const Duration(seconds: 2));
    if (FirebaseAuth.instance.currentUser != null) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, AppRoutes.mainLayout);
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onContinuePressed() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/click.mp3'));
    } catch (e) {
      debugPrint("Error playing sound: $e");
    }

    HapticFeedback.lightImpact();

    if (FirebaseAuth.instance.currentUser != null) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainLayout);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.signup);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackgroundIcons(),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLottieAnimation(),
                const SizedBox(height: 40),
                const Text(
                  "BrainLink",
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF5E35B1),
                    letterSpacing: 1.2,
                  ),
                ),
                const Text(
                  "Where Ideas Are Met",
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF616161),
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),
          ),
          _buildAnimatedButton(),
        ],
      ),
    );
  }

  Widget _buildLottieAnimation() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7E57C2).withValues(alpha: 0.1),
            blurRadius: 40,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipOval(
        child: SizedBox(
          width: 250,
          height: 250,
          child: Lottie.asset(
            'assets/animation/animation.json',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedButton() {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutBack,
      bottom: _animateButton ? 80 : -100,
      left: 40,
      right: 40,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 1000),
        opacity: _animateButton ? 1 : 0,
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF9575CD), Color(0xFF673AB7)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7E57C2).withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _onContinuePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Continue",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, size: 26),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundIcons() {
    return Stack(
      children: [
        Positioned(
          top: MediaQuery.of(context).size.height * 0.08,
          left: 35,
          child: Opacity(
            opacity: 0.12,
            child: const Icon(
              Icons.psychology,
              size: 50,
              color: Color(0xFF5E35B1),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.15,
          right: 45,
          child: Opacity(
            opacity: 0.12,
            child: const Icon(Icons.memory, size: 45, color: Color(0xFF5E35B1)),
          ),
        ),
        Positioned(
          bottom: 180,
          left: 25,
          child: Opacity(
            opacity: 0.14,
            child: CustomPaint(
              size: const Size(55, 55),
              painter: OldComputerPainter(),
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          right: 40,
          child: Opacity(
            opacity: 0.1,
            child: const Icon(Icons.mouse, size: 38, color: Color(0xFF5E35B1)),
          ),
        ),
      ],
    );
  }
}

class OldComputerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF5E35B1)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double scale = size.width;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, scale * 0.9, scale * 0.7),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawLine(
      Offset(scale * 0.45, scale * 0.7),
      Offset(scale * 0.45, scale * 0.9),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(scale * 0.1, scale * 0.9, scale * 0.7, scale * 0.1),
        const Radius.circular(1),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
