import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.03).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOutCubic),
    );

    _glowAnimation = Tween<double>(begin: 0.35, end: 0.75).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _timer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        context.go('/language-selection');
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B14),
      body: SizedBox.expand(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. Cinematic Background Image Asset
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
                          Color(0xFF051322),
                          Color(0xFF02070D),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 2. Extra Dark Cinematic Gradient Shader Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.68),
                      Colors.black.withValues(alpha: 0.42),
                      Colors.black.withValues(alpha: 0.82),
                    ],
                    stops: const [0.0, 0.45, 1.0],
                  ),
                ),
              ),
            ),

            // 3. Foreground Content: Large, Dark, High-Contrast Shield Emblem
            Positioned.fill(
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 86),

                      // Large Animated Dark-Navy Apex Shield Emblem
                      AnimatedBuilder(
                        animation: _animController,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _scaleAnimation.value,
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF0284C7).withValues(alpha: _glowAnimation.value * 0.40),
                                    blurRadius: 48,
                                    spreadRadius: 6,
                                  ),
                                  BoxShadow(
                                    color: const Color(0xFF10B981).withValues(alpha: _glowAnimation.value * 0.20),
                                    blurRadius: 60,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: child,
                            ),
                          );
                        },
                        child: const ModernApexShieldLogo(size: 114),
                      ),

                      const SizedBox(height: 20),

                      // Brand Title: CivicGuard
                      Text(
                        'CivicGuard',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 37,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.7,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 14,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 3),

                      // Tagline
                      Text(
                        'Safer Communities • Stronger Tomorrow',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
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
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.4,
                          shadows: [
                            Shadow(
                              color: Colors.black.withValues(alpha: 0.5),
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

/// Custom-Painted Dark Geometric Bi-Facet Apex Shield with Glowing Emerald Core
class ModernApexShieldLogo extends StatelessWidget {
  final double size;

  const ModernApexShieldLogo({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ModernApexShieldPainter(),
      ),
    );
  }
}

class _ModernApexShieldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // 1. Outer Left Facet (Dark Obsidian Navy to Royal Midnight Blue)
    final leftPath = Path()
      ..moveTo(cx, h * 0.05)
      ..lineTo(w * 0.12, h * 0.20)
      ..cubicTo(w * 0.10, h * 0.58, cx * 0.8, h * 0.86, cx, h * 0.96)
      ..lineTo(cx, h * 0.05)
      ..close();

    final leftPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF0F2B48),
          Color(0xFF051322),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(leftPath, leftPaint);

    // 2. Outer Right Facet (Deep Navy to Indigo Steel)
    final rightPath = Path()
      ..moveTo(cx, h * 0.05)
      ..lineTo(w * 0.88, h * 0.20)
      ..cubicTo(w * 0.90, h * 0.58, cx + (w - cx) * 0.2, h * 0.86, cx, h * 0.96)
      ..lineTo(cx, h * 0.05)
      ..close();

    final rightPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
        colors: [
          Color(0xFF1E3A8A),
          Color(0xFF0A1E33),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(rightPath, rightPaint);

    // 3. Central Dynamic Safety Spark / Beacon Core (Vibrant Emerald Core)
    final corePath = Path()
      ..moveTo(cx, h * 0.22)
      ..lineTo(w * 0.32, h * 0.44)
      ..lineTo(cx * 0.92, h * 0.44)
      ..lineTo(cx * 0.82, h * 0.70)
      ..lineTo(cx * 1.28, h * 0.46)
      ..lineTo(cx * 1.06, h * 0.46)
      ..lineTo(w * 0.68, h * 0.28)
      ..close();

    final corePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF34D399),
          Color(0xFF059669),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    // Dynamic Emerald Core Glow Filter
    final glowPaint = Paint()
      ..color = const Color(0xFF10B981).withValues(alpha: 0.70)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    canvas.drawPath(corePath, glowPaint);
    canvas.drawPath(corePath, corePaint);

    // 4. Subtle Inner Centerline Crease (Adds 3D Bevel)
    final creasePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.35)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(cx, h * 0.05), Offset(cx, h * 0.96), creasePaint);

    // 5. Crisp Perimeter Chamfer Border (Cyan to White Accent)
    final borderPath = Path()
      ..moveTo(cx, h * 0.05)
      ..lineTo(w * 0.12, h * 0.20)
      ..cubicTo(w * 0.10, h * 0.58, cx * 0.8, h * 0.86, cx, h * 0.96)
      ..cubicTo(cx + (w - cx) * 0.2, h * 0.86, w * 0.90, h * 0.58, w * 0.88, h * 0.20)
      ..close();

    final borderPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF0284C7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
                    color: Colors.white.withValues(alpha: opacity.clamp(0.4, 1.0)),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.35),
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
