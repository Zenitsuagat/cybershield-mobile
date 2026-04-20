import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor:          Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: kBgDark,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  runApp(const CyberShieldApp());
}

class CyberShieldApp extends StatelessWidget {
  const CyberShieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CyberShield',
      theme: buildTheme(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─── Splash Screen ────────────────────────────────────────────────────────────
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // Controllers
  late AnimationController _ringCtrl;
  late AnimationController _fadeCtrl;
  late AnimationController _scanCtrl;
  late AnimationController _pulseCtrl;
  late AnimationController _exitCtrl;

  // Animations
  late Animation<double> _ringProgress;
  late Animation<double> _shieldScale;
  late Animation<double> _shieldFade;
  late Animation<double> _textFade;
  late Animation<double> _taglineFade;
  late Animation<double> _scanLine;
  late Animation<double> _pulse;
  late Animation<double> _exitFade;

  // State
  String _statusText = 'Initializing systems...';
  int    _percent     = 0;
  bool   _navigating  = false;

  final _steps = [
    (0.3,  'Loading threat database...'),
    (0.55, 'Calibrating heuristics...'),
    (0.75, 'Connecting secure modules...'),
    (1.0,  'All systems ready'),
  ];

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    _ringCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scanCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))
      ..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _exitCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _ringProgress = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ringCtrl, curve: Curves.easeInOut));

    _shieldScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.15).chain(CurveTween(curve: Curves.easeOut)), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 40),
    ]).animate(_fadeCtrl);

    _shieldFade  = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: const Interval(0.0, 0.6)));
    _textFade    = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: const Interval(0.5, 1.0)));
    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _fadeCtrl, curve: const Interval(0.7, 1.0)));

    _scanLine = Tween<double>(begin: -1, end: 2).animate(
        CurvedAnimation(parent: _scanCtrl, curve: Curves.easeInOut));
    _pulse    = Tween<double>(begin: 0.85, end: 1.05).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _exitFade = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _exitCtrl, curve: Curves.easeIn));
  }

  Future<void> _startSequence() async {
    // 1. Shield pops in
    await Future.delayed(const Duration(milliseconds: 200));
    _fadeCtrl.forward();

    // 2. Ring starts filling
    await Future.delayed(const Duration(milliseconds: 400));
    _ringCtrl.forward();

    // 3. Step through loading messages
    for (final step in _steps) {
      final targetPct = (step.$1 * 100).toInt();
      final msg       = step.$2;

      await Future.delayed(Duration(
        milliseconds: (step.$1 * 1800).toInt(),
      ));
      if (!mounted) return;
      setState(() { _statusText = msg; _percent = targetPct; });
    }

    // 4. Brief pause at 100%
    await Future.delayed(const Duration(milliseconds: 600));

    // 5. Fade out and navigate
    if (!mounted || _navigating) return;
    _navigating = true;
    _scanCtrl.stop();
    _pulseCtrl.stop();
    await _exitCtrl.forward();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const HomeScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _ringCtrl.dispose();
    _fadeCtrl.dispose();
    _scanCtrl.dispose();
    _pulseCtrl.dispose();
    _exitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: Listenable.merge([
        _ringCtrl, _fadeCtrl, _scanCtrl, _pulseCtrl, _exitCtrl,
      ]),
      builder: (context, _) {
        return Opacity(
          opacity: _exitFade.value,
          child: Scaffold(
            backgroundColor: kBgDark,
            body: Stack(
              children: [
                // ── Grid background ──────────────────────────────────────
                Positioned.fill(child: CustomPaint(painter: _GridPainter())),

                // ── Scan line sweep ──────────────────────────────────────
                Positioned(
                  top: size.height * _scanLine.value,
                  left: 0, right: 0,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.transparent,
                        kAccentCyan.withOpacity(0.6),
                        Colors.transparent,
                      ]),
                    ),
                  ),
                ),

                // ── Corner decorations ───────────────────────────────────
                Positioned(top: 40, left: 20,
                    child: _CornerBracket(flip: false)),
                Positioned(top: 40, right: 20,
                    child: _CornerBracket(flip: true)),
                Positioned(bottom: 40, left: 20,
                    child: _CornerBracket(flip: false, bottom: true)),
                Positioned(bottom: 40, right: 20,
                    child: _CornerBracket(flip: true, bottom: true)),

                // ── Main content ─────────────────────────────────────────
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Outer glow ring + shield
                      SizedBox(
                        width: 180, height: 180,
                        child: Stack(alignment: Alignment.center, children: [
                          // Progress ring
                          CustomPaint(
                            size: const Size(180, 180),
                            painter: _SplashRingPainter(
                              progress: _ringProgress.value,
                              color: kAccentCyan,
                            ),
                          ),
                          // Pulse ring
                          Transform.scale(
                            scale: _pulse.value,
                            child: Container(
                              width: 140, height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: kAccentCyan.withOpacity(0.15),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                          // Shield icon
                          FadeTransition(
                            opacity: _shieldFade,
                            child: ScaleTransition(
                              scale: _shieldScale,
                              child: Container(
                                width: 110, height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: kAccentCyan.withOpacity(0.1),
                                  border: Border.all(
                                    color: kAccentCyan.withOpacity(0.4),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: kAccentCyan.withOpacity(0.2),
                                      blurRadius: 30, spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.shield_rounded,
                                  size: 54,
                                  color: kAccentCyan,
                                ),
                              ),
                            ),
                          ),
                        ]),
                      ),

                      const SizedBox(height: 32),

                      // App name
                      FadeTransition(
                        opacity: _textFade,
                        child: const Text(
                          'CYBERSHIELD',
                          style: TextStyle(
                            fontFamily: 'Orbitron',
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: kAccentCyan,
                            letterSpacing: 6,
                          ),
                        ),
                      ),

                      const SizedBox(height: 6),

                      // Tagline
                      FadeTransition(
                        opacity: _taglineFade,
                        child: const Text(
                          'MOBILE SECURITY SUITE',
                          style: TextStyle(
                            fontSize: 11,
                            color: kTextSecond,
                            letterSpacing: 4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),

                      const SizedBox(height: 52),

                      // Progress bar
                      FadeTransition(
                        opacity: _textFade,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 48),
                          child: Column(children: [
                            // Percentage
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _statusText,
                                  style: const TextStyle(
                                    fontSize: 11, color: kTextSecond,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  '$_percent%',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: kAccentCyan,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // Bar
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _ringProgress.value,
                                minHeight: 4,
                                backgroundColor: kBorderColor,
                                valueColor: AlwaysStoppedAnimation(kAccentCyan),
                              ),
                            ),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Version tag ──────────────────────────────────────────
                Positioned(
                  bottom: 52, left: 0, right: 0,
                  child: FadeTransition(
                    opacity: _taglineFade,
                    child: const Text(
                      'v1.0.0  •  Secured by CyberShield',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: kTextSecond, letterSpacing: 1),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─── Ring Painter for splash ───────────────────────────────────────────────────
class _SplashRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SplashRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final c      = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;
    const start  = -pi / 2;

    // Background track
    canvas.drawCircle(c, radius,
        Paint()
          ..color = color.withOpacity(0.1)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke);

    if (progress <= 0) return;

    // Glowing foreground arc
    final sweep = 2 * pi * progress.clamp(0.0, 1.0);
    final rect  = Rect.fromCircle(center: c, radius: radius);

    canvas.drawArc(rect, start, sweep, false,
        Paint()
          ..shader = SweepGradient(
            startAngle: start,
            endAngle:   start + sweep,
            colors: [color.withOpacity(0.3), color],
          ).createShader(rect)
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Sharp inner arc on top
    canvas.drawArc(rect, start, sweep, false,
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_SplashRingPainter old) => old.progress != progress;
}

// ─── Dot grid background painter ──────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAccentCyan.withOpacity(0.04)
      ..strokeWidth = 1;
    const spacing = 28.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_GridPainter _) => false;
}

// ─── Corner bracket decoration ─────────────────────────────────────────────────
class _CornerBracket extends StatelessWidget {
  final bool flip;
  final bool bottom;
  const _CornerBracket({required this.flip, this.bottom = false});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scaleX: flip   ? -1 : 1,
      scaleY: bottom ? -1 : 1,
      child: SizedBox(
        width: 20, height: 20,
        child: CustomPaint(painter: _BracketPainter()),
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = kAccentCyan.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
  }

  @override
  bool shouldRepaint(_) => false;
}