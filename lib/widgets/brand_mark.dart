import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class MikiezyBrandMark extends StatelessWidget {
  const MikiezyBrandMark({super.key, this.size = 56, this.showShadow = true});

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.accent, Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.35),
                  offset: const Offset(0, 10),
                  blurRadius: 24,
                ),
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.18),
                  spreadRadius: 4,
                  blurRadius: 0,
                ),
              ]
            : null,
      ),
      child: Text(
        'M',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.47,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }
}
