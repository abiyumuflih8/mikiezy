import 'package:flutter/material.dart';

import '../services/navigation/app_navigation_service.dart';
import '../services/voice/voice_command.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_mark.dart';
import 'dashboard_screen.dart';
import 'onboarding_screen.dart';

enum AuthMode { login, register }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.initialMode = AuthMode.login});

  final AuthMode initialMode;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late AuthMode _mode;
  bool _showPassword = false;

  bool get _isRegister => _mode == AuthMode.register;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
  }

  void _setMode(AuthMode value) {
    setState(() => _mode = value);
  }

  void _finishAuth() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Mode prototype: auth produksi belum aktif, masuk ke data lokal.',
        ),
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: RouteSettings(
          name: AppRouteNames.forTarget(VoiceNavigationTarget.dashboard),
        ),
        builder: (_) => const DashboardScreen(),
      ),
    );
  }

  void _backToOnboarding() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: const RouteSettings(name: AppRouteNames.onboarding),
        builder: (_) => const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _AuthHeader(onBack: _backToOnboarding),
          Transform.translate(
            offset: const Offset(0, -10),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 28),
              child: Column(
                children: [
                  _AuthCard(
                    mode: _mode,
                    showPassword: _showPassword,
                    onTogglePassword: () =>
                        setState(() => _showPassword = !_showPassword),
                    onModeChanged: _setMode,
                    onSubmit: _finishAuth,
                  ),
                  const SizedBox(height: 18),
                  _AuthFooter(
                    isRegister: _isRegister,
                    onTap: () => _setMode(
                      _isRegister ? AuthMode.login : AuthMode.register,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showAuthPlaceholder(BuildContext context, String feature) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$feature belum aktif di prototype lokal Mikiezy.')),
  );
}

class _AuthHeader extends StatelessWidget {
  const _AuthHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 175,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1117), Color(0xFF1A1B2E), Color(0xFF1E1B3A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: const _HeaderPainter()),
            ),
            Positioned(
              top: 14,
              left: 18,
              child: IconButton(
                tooltip: 'Back',
                onPressed: onBack,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.10),
                  foregroundColor: Colors.white.withValues(alpha: 0.82),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
              ),
            ),
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MikiezyBrandMark(size: 56),
                  SizedBox(height: 12),
                  Text(
                    'MIKI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
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
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.mode,
    required this.showPassword,
    required this.onTogglePassword,
    required this.onModeChanged,
    required this.onSubmit,
  });

  final AuthMode mode;
  final bool showPassword;
  final VoidCallback onTogglePassword;
  final ValueChanged<AuthMode> onModeChanged;
  final VoidCallback onSubmit;

  bool get isRegister => mode == AuthMode.register;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _AuthTabButton(
                    label: 'Sign In',
                    selected: !isRegister,
                    onTap: () => onModeChanged(AuthMode.login),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _AuthTabButton(
                    label: 'Register',
                    selected: isRegister,
                    onTap: () => onModeChanged(AuthMode.register),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              isRegister ? 'Create your account' : 'Welcome back',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              isRegister
                  ? 'Mode demo lokal, auth production belum aktif'
                  : 'Mode demo lokal, belum tersambung ke auth production',
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            if (isRegister) ...[
              const _AuthTextField(
                label: 'Business Name',
                hint: 'e.g. Warung Maju Jaya',
                icon: Icons.storefront_rounded,
              ),
              const SizedBox(height: 14),
            ],
            const _AuthTextField(
              label: 'Email Address',
              hint: 'nama@email.com',
              icon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _AuthTextField(
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              obscureText: !showPassword,
              trailing: IconButton(
                tooltip: showPassword ? 'Hide password' : 'Show password',
                onPressed: onTogglePassword,
                icon: Icon(
                  showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: AppColors.faint,
                ),
              ),
              labelTrailing: isRegister
                  ? null
                  : TextButton(
                      onPressed: () =>
                          _showAuthPlaceholder(context, 'Reset password'),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F1117),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: Text(isRegister ? 'Create Account' : 'Sign In'),
              ),
            ),
            const SizedBox(height: 16),
            const _DividerLabel(),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _showAuthPlaceholder(context, 'Login Google'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  side: const BorderSide(color: AppColors.border, width: 1.4),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _GoogleMark(),
                    SizedBox(width: 10),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AuthTabButton extends StatelessWidget {
  const _AuthTabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Container(
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.faint,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.trailing,
    this.labelTrailing,
  });

  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? trailing;
  final Widget? labelTrailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ?labelTrailing,
          ],
        ),
        const SizedBox(height: 7),
        TextField(
          keyboardType: keyboardType,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, size: 18, color: AppColors.faint),
            suffixIcon: trailing,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _DividerLabel extends StatelessWidget {
  const _DividerLabel();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'or',
            style: TextStyle(color: AppColors.faint, fontSize: 11),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class _AuthFooter extends StatelessWidget {
  const _AuthFooter({required this.isRegister, required this.onTap});

  final bool isRegister;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isRegister ? 'Already have an account? ' : "Don't have an account? ",
          style: const TextStyle(color: AppColors.faint, fontSize: 12),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            isRegister ? 'Sign in' : 'Register free',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(painter: const _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  const _GoogleMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = size.width * 0.16;
    final rect = Offset.zero & size;
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    arcPaint.color = const Color(0xFF4285F4);
    canvas.drawArc(rect.deflate(stroke / 2), -0.18, 1.38, false, arcPaint);
    arcPaint.color = const Color(0xFF34A853);
    canvas.drawArc(rect.deflate(stroke / 2), 1.15, 1.38, false, arcPaint);
    arcPaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(rect.deflate(stroke / 2), 2.48, 1.15, false, arcPaint);
    arcPaint.color = const Color(0xFFEA4335);
    canvas.drawArc(rect.deflate(stroke / 2), 3.55, 1.52, false, arcPaint);

    final barPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square
      ..color = const Color(0xFF4285F4);
    canvas.drawLine(
      Offset(size.width * 0.52, size.height * 0.52),
      Offset(size.width * 0.94, size.height * 0.52),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeaderPainter extends CustomPainter {
  const _HeaderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.05);

    for (var i = -size.height; i < size.width; i += 34) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i + size.height * 0.58, size.height),
        paint,
      );
    }

    paint.color = AppColors.accent.withValues(alpha: 0.15);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width - 86, 18, 120, 64),
        const Radius.circular(8),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(-26, 94, 102, 54),
        const Radius.circular(8),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
