import 'package:flutter/material.dart';

import '../../core/constants/app_dimensions.dart';
import '../../theme/app_theme.dart';

class MikiezySectionHeader extends StatelessWidget {
  const MikiezySectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (action != null) ...[const SizedBox(width: AppSpacing.sm), action!],
      ],
    );
  }
}

class MikiezyEmptyState extends StatelessWidget {
  const MikiezyEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: AppDurations.normal,
      child: Container(
        key: ValueKey(title),
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xxl,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.cardBackground,
              context.colors.surfaceContainerHigh.withValues(alpha: .68),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: context.subtleBorder),
          boxShadow: context.softShadow,
        ),
        child: Column(
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: context.colors.primaryContainer.withValues(alpha: .72),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: .14),
                ),
              ),
              child: Icon(icon, color: context.colors.primary, size: 32),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: context.mutedText,
                height: 1.52,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: AppSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class MikiezySegmentedControl<T> extends StatelessWidget {
  const MikiezySegmentedControl({
    super.key,
    required this.values,
    required this.selected,
    required this.labelBuilder,
    required this.onChanged,
  });

  final List<T> values;
  final T selected;
  final String Function(T value) labelBuilder;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxs),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.subtleBorder),
      ),
      child: Row(
        children: [
          for (final value in values)
            Expanded(
              child: _SegmentButton<T>(
                value: value,
                label: labelBuilder(value),
                selected: value == selected,
                onChanged: onChanged,
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton<T> extends StatelessWidget {
  const _SegmentButton({
    required this.value,
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final T value;
  final String label;
  final bool selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          curve: Curves.easeOutCubic,
          height: 42,
          margin: const EdgeInsets.all(0),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? context.colors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: selected
                ? Border.all(color: context.colors.outlineVariant)
                : null,
            boxShadow: selected ? context.softShadow.take(1).toList() : null,
          ),
          child: AnimatedDefaultTextStyle(
            duration: AppDurations.fast,
            style: Theme.of(context).textTheme.labelLarge!.copyWith(
              color: selected ? context.colors.primary : context.mutedText,
              fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            ),
            child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
      ),
    );
  }
}

class MikiezyStatusPill extends StatelessWidget {
  const MikiezyStatusPill({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? .18 : .11),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: .22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class MikiezySkeletonLine extends StatelessWidget {
  const MikiezySkeletonLine({
    super.key,
    this.width = double.infinity,
    this.height = 14,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.normal,
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}
