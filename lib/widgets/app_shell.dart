import 'dart:async';

import 'package:flutter/material.dart';

import '../screens/dashboard_screen.dart';
import '../screens/reports_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/transactions_screen.dart';
import '../core/constants/app_dimensions.dart';
import '../models/mikiezy_models.dart';
import '../services/voice/voice_assistant_manager.dart';
import '../services/voice/voice_command.dart';
import '../services/navigation/app_navigation_service.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.title,
    required this.currentIndex,
    required this.child,
    this.actions,
    this.floatingActionButton,
    this.showAppBar = true,
    this.showDefaultFab = true,
  });

  final String title;
  final int currentIndex;
  final Widget child;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showAppBar;
  final bool showDefaultFab;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  VoiceAssistantManager? _manager;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final manager = VoiceAssistantScope.maybeOf(context);
    if (identical(manager, _manager)) return;
    final previous = _manager;
    _manager = manager;
    if (previous != null) unawaited(previous.detachForeground());
    _manager?.attachForeground();
  }

  @override
  void dispose() {
    final manager = _manager;
    if (manager != null) unawaited(manager.detachForeground());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.showAppBar
          ? AppBar(
              title: Text(
                widget.title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: widget.actions,
            )
          : null,
      body: SafeArea(child: widget.child),
      floatingActionButton: widget.showDefaultFab
          ? widget.floatingActionButton
          : null,
      bottomNavigationBar: _MikiezyBottomNav(
        currentIndex: widget.currentIndex,
        onSelected: (index) => _goTo(context, index),
      ),
    );
  }

  void _goTo(BuildContext context, int index) {
    if (index == widget.currentIndex) return;
    final pages = <Widget>[
      const DashboardScreen(),
      const TransactionsScreen(),
      const ReportsScreen(),
      const SettingsScreen(),
    ];
    const targets = [
      VoiceNavigationTarget.dashboard,
      VoiceNavigationTarget.transactions,
      VoiceNavigationTarget.analytics,
      VoiceNavigationTarget.settings,
    ];
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        settings: RouteSettings(name: AppRouteNames.forTarget(targets[index])),
        builder: (_) => pages[index],
      ),
    );
  }
}

class _MikiezyBottomNav extends StatelessWidget {
  const _MikiezyBottomNav({
    required this.currentIndex,
    required this.onSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final state = MikiezyScope.of(context);
    final en = state.language == AppLanguage.en;
    const items = [
      _NavItem(
        Icons.dashboard_outlined,
        Icons.dashboard_rounded,
        'Home',
        'Home',
      ),
      _NavItem(
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        'Transaksi',
        'Transactions',
      ),
      _NavItem(
        Icons.bar_chart_outlined,
        Icons.bar_chart_rounded,
        'Analitik',
        'Analytics',
      ),
      _NavItem(
        Icons.settings_outlined,
        Icons.settings_rounded,
        'Setelan',
        'Settings',
      ),
    ];

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: context.colors.surface.withValues(alpha: .96),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: context.subtleBorder),
            boxShadow: context.softShadow,
          ),
          child: SizedBox(
            height: 70,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: items[i],
                      selected: i == currentIndex,
                      label: en ? items[i].enLabel : items[i].idLabel,
                      onTap: () => onSelected(i),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.normal,
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xxs,
          vertical: AppSpacing.xs,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        decoration: BoxDecoration(
          color: selected
              ? context.colors.primaryContainer.withValues(alpha: .86)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              selected ? item.selectedIcon : item.icon,
              color: selected ? context.colors.primary : context.mutedText,
              size: selected ? 23 : 21,
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: Theme.of(context).textTheme.labelSmall!.copyWith(
                color: selected ? context.colors.primary : context.mutedText,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
              ),
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.selectedIcon, this.idLabel, this.enLabel);

  final IconData icon;
  final IconData selectedIcon;
  final String idLabel;
  final String enLabel;
}
