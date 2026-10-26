import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'auth_screen.dart';
import '../services/navigation/app_navigation_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _current = 0;

  static const _slides = [
    _OnboardingSlide(
      tag: 'Voice-Powered',
      title: 'Record sales using\nyour voice',
      subtitle:
          'No typing needed. Just speak naturally and Miki captures every transaction instantly.',
      accent: AppColors.accent,
      illustration: _OnboardingIllustrationType.microphone,
    ),
    _OnboardingSlide(
      tag: 'AI Powered',
      title: 'Just say:\n"Miki, sold 2 fried rice"',
      subtitle:
          'Miki understands natural Bahasa Indonesia and English. AI extracts product, quantity, and price automatically.',
      accent: Color(0xFF8B5CF6),
      illustration: _OnboardingIllustrationType.phone,
    ),
    _OnboardingSlide(
      tag: 'Smart Analytics',
      title: 'Get automatic\nsales insights',
      subtitle:
          'Daily reports, best sellers, and revenue trends are ready without spreadsheets.',
      accent: AppColors.accent,
      illustration: _OnboardingIllustrationType.analytics,
    ),
  ];

  bool get _isLast => _current == _slides.length - 1;

  void _goToAuth([AuthMode mode = AuthMode.login]) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRouteNames.auth),
        builder: (_) => AuthScreen(initialMode: mode),
      ),
    );
  }

  void _next() {
    if (_isLast) {
      _goToAuth(AuthMode.register);
      return;
    }
    setState(() => _current += 1);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_current];
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F1117), Color(0xFF1A1B2E), Color(0xFF1E1B3A)],
          ),
        ),
        child: CustomPaint(
          painter: const _OnboardingBackdropPainter(),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => _goToAuth(),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white.withValues(alpha: 0.58),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 260),
                    child: _SlideContent(key: ValueKey(_current), slide: slide),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 8, 28, 30),
                  child: Column(
                    children: [
                      _ProgressDots(
                        count: _slides.length,
                        current: _current,
                        onSelected: (index) => setState(() => _current = index),
                      ),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _next,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.accent,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shadowColor: AppColors.accent.withValues(
                              alpha: 0.55,
                            ),
                            elevation: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_isLast ? 'Get Started' : 'Continue'),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                      if (_isLast) ...[
                        const SizedBox(height: 14),
                        TextButton(
                          onPressed: () => _goToAuth(),
                          child: Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.42),
                                fontSize: 13,
                              ),
                              children: const [
                                TextSpan(
                                  text: 'Sign in',
                                  style: TextStyle(
                                    color: Color(0xFF818CF8),
                                    fontWeight: FontWeight.w900,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Color(0xFF818CF8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({super.key, required this.slide});

  final _OnboardingSlide slide;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight < 450;
        final artSize = compact ? const Size(172, 150) : const Size(220, 200);
        final titleSize = compact ? 23.0 : 26.0;
        final tagGap = compact ? 14.0 : 22.0;
        final textGap = compact ? 10.0 : 22.0;

        return Padding(
          padding: EdgeInsets.fromLTRB(28, compact ? 6 : 18, 28, 0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _TagPill(text: slide.tag, accent: slide.accent),
              SizedBox(height: tagGap),
              SizedBox(
                width: artSize.width,
                height: artSize.height,
                child: CustomPaint(
                  painter: _OnboardingIllustrationPainter(
                    type: slide.illustration,
                    accent: slide.accent,
                  ),
                ),
              ),
              SizedBox(height: textGap),
              Text(
                slide.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  height: 1.22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 290),
                child: Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 13,
                    height: 1.48,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.text, required this.accent});

  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: accent == AppColors.accent
                  ? const Color(0xFF818CF8)
                  : const Color(0xFFA78BFA),
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({
    required this.count,
    required this.current,
    required this.onSelected,
  });

  final int count;
  final int current;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++) ...[
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: i == current ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i == current
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.20),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          if (i != count - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

class _OnboardingSlide {
  const _OnboardingSlide({
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.illustration,
  });

  final String tag;
  final String title;
  final String subtitle;
  final Color accent;
  final _OnboardingIllustrationType illustration;
}

enum _OnboardingIllustrationType { microphone, phone, analytics }

class _OnboardingIllustrationPainter extends CustomPainter {
  const _OnboardingIllustrationPainter({
    required this.type,
    required this.accent,
  });

  final _OnboardingIllustrationType type;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.53);
    final glow = Paint()..color = accent.withValues(alpha: 0.08);
    canvas.drawOval(
      Rect.fromCenter(center: center, width: 178, height: 140),
      glow,
    );

    switch (type) {
      case _OnboardingIllustrationType.microphone:
        _paintMic(canvas, size);
      case _OnboardingIllustrationType.phone:
        _paintPhone(canvas, size);
      case _OnboardingIllustrationType.analytics:
        _paintAnalytics(canvas, size);
    }
  }

  void _paintMic(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.52);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = accent.withValues(alpha: 0.20);
    canvas.drawCircle(center, 70, ring);
    canvas.drawCircle(center, 50, ring..color = accent.withValues(alpha: 0.26));

    final micRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - 15, center.dy - 50, 30, 54),
      const Radius.circular(15),
    );
    final micPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF818CF8), AppColors.accent],
      ).createShader(micRect.outerRect);
    canvas.drawRRect(micRect, micPaint);

    final white = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    for (final y in [center.dy - 34, center.dy - 27, center.dy - 20]) {
      canvas.drawLine(
        Offset(center.dx - 8, y),
        Offset(center.dx + 8, y),
        white,
      );
    }

    final stand = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..color = accent;
    final path = Path()
      ..moveTo(center.dx - 30, center.dy + 2)
      ..quadraticBezierTo(
        center.dx - 30,
        center.dy + 28,
        center.dx,
        center.dy + 28,
      )
      ..quadraticBezierTo(
        center.dx + 30,
        center.dy + 28,
        center.dx + 30,
        center.dy + 2,
      );
    canvas.drawPath(path, stand);
    canvas.drawLine(
      Offset(center.dx, center.dy + 28),
      Offset(center.dx, center.dy + 44),
      stand,
    );
    canvas.drawLine(
      Offset(center.dx - 15, center.dy + 44),
      Offset(center.dx + 15, center.dy + 44),
      stand,
    );
  }

  void _paintPhone(Canvas canvas, Size size) {
    final body = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 38, 36, 76, 126),
      const Radius.circular(14),
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xCC0F1117));
    canvas.drawRRect(
      body,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.30),
    );

    final screen = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width / 2 - 32, 48, 64, 104),
      const Radius.circular(8),
    );
    canvas.drawRRect(screen, Paint()..color = const Color(0xFF1A1B2E));

    _drawBubble(
      canvas,
      Rect.fromLTWH(size.width / 2 - 24, 59, 48, 22),
      accent.withValues(alpha: 0.82),
    );
    _drawBubble(
      canvas,
      Rect.fromLTWH(size.width / 2 - 28, 90, 56, 28),
      Colors.white.withValues(alpha: 0.10),
      border: accent.withValues(alpha: 0.35),
    );

    final mic = Paint()..color = accent;
    final c = Offset(size.width / 2, 135);
    canvas.drawCircle(c, 10, mic);
    canvas.drawCircle(c, 17, Paint()..color = accent.withValues(alpha: 0.16));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(c.dx, c.dy - 1), width: 7, height: 11),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white,
    );
  }

  void _drawBubble(Canvas canvas, Rect rect, Color color, {Color? border}) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    canvas.drawRRect(rrect, Paint()..color = color);
    if (border != null) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = border,
      );
    }
  }

  void _paintAnalytics(Canvas canvas, Size size) {
    final card = RRect.fromRectAndRadius(
      Rect.fromLTWH(40, 66, 140, 112),
      const Radius.circular(16),
    );
    canvas.drawRRect(
      card,
      Paint()..color = Colors.white.withValues(alpha: 0.06),
    );
    canvas.drawRRect(
      card,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = accent.withValues(alpha: 0.16),
    );

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = accent.withValues(alpha: 0.10);
    for (final y in [108.0, 128.0, 148.0]) {
      canvas.drawLine(Offset(52, y), Offset(168, y), grid);
    }

    final bars = [
      (x: 54.0, y: 118.0, h: 44.0),
      (x: 80.0, y: 102.0, h: 60.0),
      (x: 106.0, y: 112.0, h: 50.0),
      (x: 132.0, y: 84.0, h: 78.0),
      (x: 158.0, y: 98.0, h: 64.0),
    ];
    for (final bar in bars) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bar.x, bar.y, 18, bar.h),
          const Radius.circular(5),
        ),
        Paint()..color = accent.withValues(alpha: 0.62),
      );
    }

    final trend = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..color = accent;
    final path = Path()
      ..moveTo(63, 118)
      ..lineTo(89, 102)
      ..lineTo(115, 112)
      ..lineTo(141, 84)
      ..lineTo(167, 98);
    canvas.drawPath(path, trend);
    for (final dot in [
      const Offset(63, 118),
      const Offset(89, 102),
      const Offset(115, 112),
      const Offset(141, 84),
      const Offset(167, 98),
    ]) {
      canvas.drawCircle(dot, 3.5, Paint()..color = accent);
    }

    final badge = RRect.fromRectAndRadius(
      const Rect.fromLTWH(60, 76, 100, 22),
      const Radius.circular(11),
    );
    canvas.drawRRect(badge, Paint()..color = accent.withValues(alpha: 0.86));
  }

  @override
  bool shouldRepaint(covariant _OnboardingIllustrationPainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.accent != accent;
  }
}

class _OnboardingBackdropPainter extends CustomPainter {
  const _OnboardingBackdropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.045);

    for (var i = -size.height; i < size.width; i += 42) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i + size.height * 0.66, size.height),
        linePaint,
      );
    }

    final accentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.accent.withValues(alpha: 0.12);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 108, 88, 140, 74),
        const Radius.circular(8),
      ),
      accentPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-40, size.height - 190, 128, 76),
        const Radius.circular(8),
      ),
      accentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
