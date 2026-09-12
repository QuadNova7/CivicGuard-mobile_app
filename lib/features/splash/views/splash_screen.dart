import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.go('/language-selection');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07192C),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Background Image Asset
            Positioned.fill(
              child: Image.asset(
                'assets/images/splash_bg.png',
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFF0A223B),
                          Color(0xFF041221),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Cinematic Black Shader Overlay for deep contrast & modern dark theme
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.42),
                      Colors.black.withOpacity(0.25),
                      Colors.black.withOpacity(0.60),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Foreground Content with Top-Aligned Branding
            Positioned.fill(
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 102),

                      // Shield Logo Emblem
                      Container(
                        width: 102,
                        height: 102,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.40),
                            width: 1.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                size: 68,
                                color: Colors.white,
                              ),
                              Positioned(
                                top: 25,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.person, size: 17, color: Color(0xFF0F2B48)),
                                    Icon(Icons.person, size: 21, color: Color(0xFF0F2B48)),
                                    Icon(Icons.person, size: 17, color: Color(0xFF0F2B48)),
                                  ],
                                ),
                              ),
                              Positioned(
                                bottom: 15,
                                right: 18,
                                child: Icon(
                                  Icons.eco_rounded,
                                  size: 19,
                                  color: Color(0xFF22C55E),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      // App Title - Crisp, Sharp, Pure White
                      Text(
                        'CivicGuard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 35,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.6,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 2),

                      // Tagline
                      Text(
                        'Safer Communities Stronger Tomorrow',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.92),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          height: 1.35,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      // Center Spacer
                      const Spacer(),

                      // 3-Dot Animated Loading Indicator
                      const ThreeDotLoader(),

                      const SizedBox(height: 18),

                      // Bottom Footer: Powered by © 2026 QuadNova
                      Text(
                        'Powered by © 2026 QuadNova',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 22),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Smooth 3-Dot Pulsating & Bouncing Loading Animation
class ThreeDotLoader extends StatefulWidget {
  const ThreeDotLoader({super.key});

  @override
  State<ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final rawValue = (_controller.value - delay) % 1.0;
            final normalizedValue = rawValue < 0 ? rawValue + 1.0 : rawValue;
            final wave = 1.0 - (normalizedValue - 0.5).abs() * 2.0;
            final scale = 0.65 + 0.45 * wave;
            final opacity = 0.4 + 0.6 * wave;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
              child: Transform.scale(
                scale: scale.clamp(0.65, 1.1),
                child: Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(opacity.clamp(0.4, 1.0)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.35),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
