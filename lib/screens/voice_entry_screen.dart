import 'dart:async';

import 'package:flutter/material.dart';

import '../services/voice/voice_entry_launch_source.dart';
import '../services/voice/voice_parse_context.dart';
import '../services/voice_assistant_controller.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import 'preview_transaction_screen.dart';

class VoiceEntryScreen extends StatefulWidget {
  const VoiceEntryScreen({
    super.key,
    this.autoStart = false,
    this.launchSource = VoiceEntryLaunchSource.direct,
    this.initialWakeWordDetected = false,
    this.initialTranscript,
  });

  final bool autoStart;
  final VoiceEntryLaunchSource launchSource;
  final bool initialWakeWordDetected;
  final String? initialTranscript;

  @override
  State<VoiceEntryScreen> createState() => _VoiceEntryScreenState();
}

class _VoiceEntryScreenState extends State<VoiceEntryScreen> {
  late final VoiceAssistantController voice;
  late final TextEditingController transcriptController;
  Timer? _silenceTimer;
  String _lastSilenceTranscript = '';
  bool _hasAutoStarted = false;
  bool _isProcessingTranscript = false;
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    voice = VoiceAssistantController();
    if (widget.initialWakeWordDetected) {
      voice.primeFromWakeWord(widget.initialTranscript);
    } else if ((widget.initialTranscript ?? '').trim().isNotEmpty) {
      voice.setTranscript(widget.initialTranscript!.trim());
    }
    transcriptController = TextEditingController(text: voice.transcript);
    voice.addListener(_handleVoiceChanged);
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _hasAutoStarted) return;
        _hasAutoStarted = true;
        if (voice.nativeListening || voice.isStarting) return;
        unawaited(
          voice.startListening(
            initialTranscript: widget.initialTranscript,
            wakeWordAlreadyDetected: widget.initialWakeWordDetected,
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    voice.removeListener(_handleVoiceChanged);
    voice.dispose();
    transcriptController.dispose();
    super.dispose();
  }

  void _handleVoiceChanged() {
    _syncTranscriptField();
    _syncSilenceTimer();
  }

  void _syncTranscriptField() {
    if (transcriptController.text == voice.transcript) return;
    transcriptController.value = TextEditingValue(
      text: voice.transcript,
      selection: TextSelection.collapsed(offset: voice.transcript.length),
    );
  }

  void _syncSilenceTimer() {
    if (!voice.nativeListening || !voice.isListening) {
      _silenceTimer?.cancel();
      _silenceTimer = null;
      return;
    }

    final transcript = voice.transcript.trim();
    if (_silenceTimer == null || transcript != _lastSilenceTranscript) {
      _lastSilenceTranscript = transcript;
      _silenceTimer?.cancel();
      _silenceTimer = Timer(const Duration(seconds: 5), () {
        unawaited(_processFromSilence());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: voice,
      builder: (context, _) {
        return PopScope<void>(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            unawaited(_cancelAndPop());
          },
          child: Scaffold(
            backgroundColor: const Color(0xFF0F1117),
            body: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _VoiceBackdropPainter(isError: voice.isError),
                  ),
                ),
                SafeArea(
                  child: Column(
                    children: [
                      _TopBar(
                        state: voice.phase,
                        onBack: () => unawaited(_cancelAndPop()),
                        onStateChanged: voice.previewPhase,
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(22, 10, 22, 18),
                          children: [
                            _StatusBadge(state: voice.phase),
                            const SizedBox(height: 12),
                            _TitleBlock(state: voice.phase),
                            const SizedBox(height: 14),
                            _VoiceVisual(
                              state: voice.phase,
                              nativeListening: voice.nativeListening,
                              onTap: _toggleNativeListening,
                            ),
                            if (voice.isListening) ...[
                              const SizedBox(height: 10),
                              _Waveform(level: voice.soundLevel),
                              const SizedBox(height: 8),
                              Center(
                                child: Text(
                                  voice.nativeListening ? 'LIVE' : 'DEMO',
                                  style: const TextStyle(
                                    color: Colors.white30,
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            if (!voice.isError)
                              _TranscriptCard(
                                controller: transcriptController,
                                onChanged: voice.setTranscript,
                              ),
                            if (voice.isError) _ErrorCard(state: voice.phase),
                            const SizedBox(height: 10),
                            _FeedbackCard(
                              feedback: voice.feedback,
                              confidence: voice.confidence,
                              wakeWordDetected: voice.wakeWordDetected,
                            ),
                            const SizedBox(height: 12),
                            if (voice.isListening) const _HintCard(),
                            const SizedBox(height: 18),
                            _SampleCommands(onSelected: voice.setTranscript),
                          ],
                        ),
                      ),
                      _BottomActions(
                        state: voice.phase,
                        onCancel: () => unawaited(_cancelAndPop()),
                        onRetry: voice.startListening,
                        onReview: _process,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleNativeListening() async {
    if (voice.nativeListening) {
      await _process();
    } else {
      await voice.startListening();
    }
  }

  Future<void> _processFromSilence() async {
    if (_isProcessingTranscript || !mounted || !voice.nativeListening) return;
    voice.markSilenceTimeout();
    await _process();
  }

  Future<void> _process() async {
    if (_isProcessingTranscript) return;
    _isProcessingTranscript = true;
    _silenceTimer?.cancel();
    _silenceTimer = null;
    final VoiceAssistantResult? result;
    try {
      result = await voice.stopAndProcess(
        parseContext: _voiceParseContext(),
        speakResult: false,
      );
    } finally {
      _isProcessingTranscript = false;
    }
    if (!mounted) return;
    final parsedResult = result;
    if (parsedResult == null) return;
    unawaited(voice.speak(parsedResult.feedback));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            PreviewTransactionScreen(initialDraft: parsedResult.draft),
      ),
    );
  }

  Future<void> _cancelAndPop() async {
    if (_isClosing) return;
    _isClosing = true;
    _silenceTimer?.cancel();
    await voice.cancelListening();
    if (mounted) Navigator.of(context).pop();
  }

  VoiceParseContext _voiceParseContext() {
    final state = MikiezyScope.of(context);
    return VoiceParseContext(
      products: state.products,
      wallets: state.wallets,
      categories: state.categories,
      defaultWalletName: _defaultWalletName(state),
    );
  }

  String? _defaultWalletName(MikiezyState state) {
    for (final wallet in state.wallets) {
      if (wallet.isPrimary) return wallet.name;
    }
    return state.wallets.isEmpty ? null : state.wallets.first.name;
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.state,
    required this.onBack,
    required this.onStateChanged,
  });

  final VoiceAssistantPhase state;
  final VoidCallback onBack;
  final ValueChanged<VoiceAssistantPhase> onStateChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onBack,
              icon: const Icon(Icons.chevron_left_rounded, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white70,
                side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                minimumSize: const Size(0, 36),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _StateChip(
                label: 'Listening',
                selected: state == VoiceAssistantPhase.listening,
                onTap: () => onStateChanged(VoiceAssistantPhase.listening),
              ),
              _StateChip(
                label: 'Processing',
                selected: state == VoiceAssistantPhase.processing,
                onTap: () => onStateChanged(VoiceAssistantPhase.processing),
              ),
              _StateChip(
                label: 'Unclear',
                selected: state == VoiceAssistantPhase.unclear,
                onTap: () => onStateChanged(VoiceAssistantPhase.unclear),
              ),
              _StateChip(
                label: 'No Mic',
                selected: state == VoiceAssistantPhase.permissionDenied,
                onTap: () =>
                    onStateChanged(VoiceAssistantPhase.permissionDenied),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StateChip extends StatelessWidget {
  const _StateChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: onTap,
          child: Container(
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent.withValues(alpha: 0.34)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? AppColors.accent.withValues(alpha: 0.50)
                    : Colors.white.withValues(alpha: 0.08),
              ),
            ),
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? const Color(0xFFA5B4FC)
                    : Colors.white.withValues(alpha: 0.34),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.state});

  final VoiceAssistantPhase state;

  @override
  Widget build(BuildContext context) {
    final isError =
        state == VoiceAssistantPhase.unclear ||
        state == VoiceAssistantPhase.permissionDenied;
    final color = isError
        ? AppColors.danger
        : state == VoiceAssistantPhase.processing
        ? AppColors.accent
        : AppColors.success;
    final label = isError
        ? state == VoiceAssistantPhase.permissionDenied
              ? 'MICROPHONE REQUIRED'
              : 'VOICE NOT CLEAR'
        : state == VoiceAssistantPhase.processing
        ? 'PROCESSING...'
        : 'RECORDING';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: isError
                    ? const Color(0xFFFCA5A5)
                    : state == VoiceAssistantPhase.processing
                    ? const Color(0xFFA5B4FC)
                    : const Color(0xFF6EE7B7),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.state});

  final VoiceAssistantPhase state;

  @override
  Widget build(BuildContext context) {
    final title = switch (state) {
      VoiceAssistantPhase.listening => 'Miki is listening...',
      VoiceAssistantPhase.processing => 'Processing your\nvoice...',
      VoiceAssistantPhase.completed => 'Miki understood\nyour voice',
      VoiceAssistantPhase.unclear => 'Voice not clear,\ntry again',
      VoiceAssistantPhase.permissionDenied => 'Microphone access\nrequired',
    };
    final subtitle = switch (state) {
      VoiceAssistantPhase.listening =>
        'Speak your transaction clearly in Bahasa Indonesia or English',
      VoiceAssistantPhase.processing =>
        'AI is understanding your transaction...',
      VoiceAssistantPhase.completed =>
        'Voice feedback is ready. Review the transaction before saving.',
      VoiceAssistantPhase.unclear =>
        'Speak louder and more clearly. Try a quieter environment.',
      VoiceAssistantPhase.permissionDenied =>
        'Please allow microphone access in your device settings.',
    };
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            height: 1.18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 13,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _VoiceVisual extends StatelessWidget {
  const _VoiceVisual({
    required this.state,
    required this.nativeListening,
    required this.onTap,
  });

  final VoiceAssistantPhase state;
  final bool nativeListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 124,
      child: Center(
        child: switch (state) {
          VoiceAssistantPhase.listening => _MicVisual(
            nativeListening: nativeListening,
            onTap: onTap,
          ),
          VoiceAssistantPhase.processing => const _ProcessingVisual(),
          VoiceAssistantPhase.completed => _MicVisual(
            nativeListening: false,
            onTap: onTap,
          ),
          VoiceAssistantPhase.unclear => const _ErrorVisual(
            icon: Icons.warning_amber_rounded,
          ),
          VoiceAssistantPhase.permissionDenied => const _ErrorVisual(
            icon: Icons.mic_off_outlined,
          ),
        },
      ),
    );
  }
}

class _MicVisual extends StatelessWidget {
  const _MicVisual({required this.nativeListening, required this.onTap});

  final bool nativeListening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        for (final size in const [132.0, 108.0, 84.0])
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(
                  alpha: nativeListening ? 0.25 : 0.12,
                ),
                width: 1.4,
              ),
            ),
          ),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Hero(
            tag: 'mikiezy-mic',
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              width: 74,
              height: 74,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent, AppColors.teal],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.45),
                    blurRadius: nativeListening ? 34 : 22,
                    spreadRadius: nativeListening ? 6 : 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProcessingVisual extends StatelessWidget {
  const _ProcessingVisual();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 3,
            color: AppColors.accent,
            backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.22),
              ),
            ),
            child: const Center(
              child: Text(
                'AI',
                style: TextStyle(
                  color: Color(0xFF818CF8),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorVisual extends StatelessWidget {
  const _ErrorVisual({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.13),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.32)),
      ),
      child: Icon(icon, color: const Color(0xFFFCA5A5), size: 32),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform({required this.level});

  final double level;

  @override
  Widget build(BuildContext context) {
    const bars = [
      6,
      12,
      18,
      26,
      34,
      28,
      40,
      22,
      32,
      14,
      38,
      24,
      16,
      30,
      10,
      22,
      36,
      18,
      28,
      12,
    ];
    return SizedBox(
      height: 44,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final height in bars)
            Container(
              width: 4,
              height: (height + _levelBoost()).clamp(8, 48).toDouble(),
              margin: const EdgeInsets.symmetric(horizontal: 1.8),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.30 + (height / 92)),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
        ],
      ),
    );
  }

  int _levelBoost() {
    if (level <= 0) return 0;
    return (level.abs() * 0.18).round().clamp(0, 12);
  }
}

class _TranscriptCard extends StatelessWidget {
  const _TranscriptCard({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Center(
                  child: Text(
                    'AI',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'LIVE TRANSCRIPT',
                style: TextStyle(
                  color: Color(0xFFA5B4FC),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            onChanged: onChanged,
            minLines: 3,
            maxLines: 5,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Waiting for speech...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.28)),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({
    required this.feedback,
    required this.confidence,
    required this.wakeWordDetected,
  });

  final String feedback;
  final double confidence;
  final bool wakeWordDetected;

  @override
  Widget build(BuildContext context) {
    final confidenceLabel = confidence < 0
        ? 'Confidence: demo'
        : 'Confidence: ${(confidence * 100).round()}%';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MIKI FEEDBACK',
                  style: TextStyle(
                    color: Color(0xFFA5B4FC),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  feedback,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  wakeWordDetected
                      ? '$confidenceLabel - Wake word aktif'
                      : confidenceLabel,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.state});

  final VoiceAssistantPhase state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.22)),
      ),
      child: Text(
        state == VoiceAssistantPhase.permissionDenied
            ? 'Aktifkan izin mikrofon agar Miki bisa mendengar transaksi.'
            : 'Suara kurang jelas. Coba ulangi dengan lebih pelan dan dekat ke mikrofon.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: Color(0xFFFCA5A5), height: 1.45),
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  const _HintCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Try: "Miki, sold 2 nasi goreng at 15 thousand each"',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
        ),
      ),
    );
  }
}

class _SampleCommands extends StatelessWidget {
  const _SampleCommands({required this.onSelected});

  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    const samples = [
      'Miki, jual kopi susu 2 pcs harga dua belas ribu diskon dua ribu',
      'Catat pengeluaran bahan baku sebesar seratus delapan puluh ribu',
      'Modal masuk ke dompet utama sebesar satu juta',
      'Jual es teh satu karton harga dua ratus ribu grosir',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CONTOH CEPAT',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 10,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: samples
              .map(
                (sample) => ActionChip(
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                  label: Text(
                    sample,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  onPressed: () => onSelected(sample),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.state,
    required this.onCancel,
    required this.onRetry,
    required this.onReview,
  });

  final VoiceAssistantPhase state;
  final VoidCallback onCancel;
  final VoidCallback onRetry;
  final VoidCallback onReview;

  @override
  Widget build(BuildContext context) {
    final isError =
        state == VoiceAssistantPhase.unclear ||
        state == VoiceAssistantPhase.permissionDenied;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onCancel,
                icon: const Icon(Icons.close_rounded, size: 17),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white60,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.10)),
                  backgroundColor: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isError ? onRetry : onReview,
                icon: Icon(
                  isError ? Icons.refresh_rounded : Icons.square_rounded,
                  size: 17,
                ),
                label: Text(isError ? 'Try Again' : 'Stop & Review'),
                style: FilledButton.styleFrom(
                  backgroundColor: isError ? AppColors.accent : Colors.white,
                  foregroundColor: isError ? Colors.white : AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoiceBackdropPainter extends CustomPainter {
  const _VoiceBackdropPainter({required this.isError});

  final bool isError;

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Paint()
      ..shader =
          RadialGradient(
            colors: [
              (isError ? AppColors.danger : AppColors.accent).withValues(
                alpha: 0.20,
              ),
              Colors.transparent,
            ],
          ).createShader(
            Rect.fromCircle(center: Offset(size.width / 2, 0), radius: 220),
          );
    canvas.drawCircle(Offset(size.width / 2, 0), 220, glow);

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1;
    for (var i = -size.height; i < size.width; i += 46) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i + size.height * 0.68, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceBackdropPainter oldDelegate) {
    return oldDelegate.isError != isError;
  }
}
