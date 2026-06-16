import 'package:flutter/material.dart';

import '../core/constants/app_dimensions.dart';
import '../theme/app_theme.dart';

class MikiezyCard extends StatefulWidget {
  const MikiezyCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.radius = AppRadius.md,
    this.backgroundColor,
    this.borderColor,
    this.showShadow = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showShadow;

  @override
  State<MikiezyCard> createState() => _MikiezyCardState();
}

class _MikiezyCardState extends State<MikiezyCard> {
  bool pressed = false;

  void _setPressed(bool value) {
    if (widget.onTap == null || pressed == value) return;
    setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(widget.radius),
      side: BorderSide(color: widget.borderColor ?? context.subtleBorder),
    );
    final decoration = BoxDecoration(
      borderRadius: BorderRadius.circular(widget.radius),
      boxShadow: widget.showShadow ? context.softShadow : null,
    );
    final card = DecoratedBox(
      decoration: decoration,
      child: Material(
        color: widget.backgroundColor ?? context.cardBackground,
        surfaceTintColor: Colors.transparent,
        shape: shape,
        clipBehavior: Clip.antiAlias,
        child: widget.onTap == null
            ? Padding(padding: widget.padding, child: widget.child)
            : InkWell(
                onTap: widget.onTap,
                onTapDown: (_) => _setPressed(true),
                onTapUp: (_) => _setPressed(false),
                onTapCancel: () => _setPressed(false),
                child: Padding(padding: widget.padding, child: widget.child),
              ),
      ),
    );

    if (widget.onTap == null) return card;

    return AnimatedScale(
      duration: AppDurations.fast,
      curve: Curves.easeOutCubic,
      scale: pressed ? 0.985 : 1,
      child: card,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({super.key, required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        ?action,
      ],
    );
  }
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.accent,
    this.subLabel,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? subLabel;

  @override
  Widget build(BuildContext context) {
    return MikiezyCard(
      radius: AppRadius.md,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: context.isDarkMode ? .26 : .15),
                      color.withValues(alpha: context.isDarkMode ? .10 : .06),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: color.withValues(alpha: .16)),
                ),
                child: Icon(icon, size: 20, color: color),
              ),
              const SizedBox(width: AppSpacing.xs),
              if (subLabel != null)
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: .10),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          subLabel!,
                          maxLines: 1,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: color,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.mutedText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
