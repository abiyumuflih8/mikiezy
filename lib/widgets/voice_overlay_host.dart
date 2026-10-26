import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/navigation/app_navigation_service.dart';
import '../services/voice/global_voice_controller.dart';
import '../theme/app_theme.dart';

class VoiceOverlayHost extends StatelessWidget {
  const VoiceOverlayHost({
    super.key,
    required this.controller,
    required this.child,
    this.navigationObserver,
    this.initialRouteName,
  });

  final GlobalVoiceController controller;
  final Widget child;
  final AppNavigationObserver? navigationObserver;
  final String? initialRouteName;

  @override
  Widget build(BuildContext context) {
    final observer =
        navigationObserver ?? AppNavigationScope.maybeOf(context)?.observer;
    final listenable = observer != null
        ? Listenable.merge([controller, observer])
        : controller;

    return AnimatedBuilder(
      animation: listenable,
      child: child,
      builder: (context, navigator) {
        final rawTopName = observer?.topRouteName;
        final currentRouteName =
            (rawTopName != null && rawTopName != '/')
                ? rawTopName
                : initialRouteName;
        final isAllowed = AppRouteNames.isVoiceOverlayAllowed(currentRouteName);

        if (!isAllowed) {
          return navigator!;
        }

        final keyboardBottom = MediaQuery.viewInsetsOf(context).bottom;
        final bottom = keyboardBottom > 0 ? keyboardBottom + 12 : 92.0;
        return Stack(
          fit: StackFit.expand,
          children: [
            navigator!,
            if (controller.isOpen)
              Positioned(
                left: 12,
                right: 12,
                bottom: bottom,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: 520,
                      maxHeight: math.max(
                        180,
                        MediaQuery.sizeOf(context).height * 0.48,
                      ),
                    ),
                    child: _VoiceOverlayPanel(controller: controller),
                  ),
                ),
              )
            else
              Positioned(
                right: 16,
                bottom: bottom,
                child: SafeArea(
                  top: false,
                  child: FloatingActionButton(
                    key: const ValueKey('global-voice-microphone'),
                    onPressed: controller.startPushToTalk,
                    child: const Icon(Icons.mic_rounded),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _VoiceOverlayPanel extends StatelessWidget {
  const _VoiceOverlayPanel({required this.controller});

  final GlobalVoiceController controller;

  @override
  Widget build(BuildContext context) {
    final visual = _visualFor(controller.sessionState);
    return Material(
      color: context.colors.surface,
      elevation: 12,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: context.subtleBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Icon(
                    visual.icon,
                    key: ValueKey(controller.sessionState),
                    color: visual.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    visual.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: controller.close,
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            if (controller.transcript.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                controller.transcript,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              controller.feedback,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (controller.isListening || controller.isBusy)
                  OutlinedButton.icon(
                    onPressed: controller.isBusy ? null : controller.stop,
                    icon: const Icon(Icons.stop_rounded, size: 18),
                    label: const Text('Stop'),
                  )
                else
                  FilledButton.icon(
                    onPressed: controller.startPushToTalk,
                    icon: const Icon(Icons.mic_rounded, size: 18),
                    label: Text(
                      controller.sessionState == GlobalVoiceSessionState.idle
                          ? 'Mulai'
                          : 'Bicara lagi',
                    ),
                  ),
                FilterChip(
                  selected: controller.conversationMode,
                  onSelected: controller.setConversationMode,
                  avatar: const Icon(Icons.forum_outlined, size: 16),
                  label: const Text('Percakapan'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  _VoiceVisual _visualFor(GlobalVoiceSessionState state) {
    return switch (state) {
      GlobalVoiceSessionState.idle => const _VoiceVisual(
        Icons.mic_none_rounded,
        'Miki siap',
        AppColors.accent,
      ),
      GlobalVoiceSessionState.listening => const _VoiceVisual(
        Icons.graphic_eq_rounded,
        'Sedang mendengarkan',
        AppColors.success,
      ),
      GlobalVoiceSessionState.processing => const _VoiceVisual(
        Icons.auto_awesome_rounded,
        'Sedang memproses',
        AppColors.accent,
      ),
      GlobalVoiceSessionState.waitingClarification => const _VoiceVisual(
        Icons.help_outline_rounded,
        'Menunggu jawaban',
        AppColors.warning,
      ),
      GlobalVoiceSessionState.waitingConfirmation => const _VoiceVisual(
        Icons.fact_check_outlined,
        'Menunggu konfirmasi',
        AppColors.warning,
      ),
      GlobalVoiceSessionState.speaking => const _VoiceVisual(
        Icons.volume_up_rounded,
        'Miki sedang berbicara',
        AppColors.accent,
      ),
      GlobalVoiceSessionState.completed => const _VoiceVisual(
        Icons.check_circle_outline_rounded,
        'Selesai',
        AppColors.success,
      ),
      GlobalVoiceSessionState.error => const _VoiceVisual(
        Icons.error_outline_rounded,
        'Voice belum siap',
        AppColors.danger,
      ),
      GlobalVoiceSessionState.stopped => const _VoiceVisual(
        Icons.stop_circle_outlined,
        'Sesi dihentikan',
        AppColors.muted,
      ),
    };
  }
}

class _VoiceVisual {
  const _VoiceVisual(this.icon, this.label, this.color);

  final IconData icon;
  final String label;
  final Color color;
}
