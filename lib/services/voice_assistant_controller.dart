import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as speech;

import '../core/formatters.dart';
import '../models/mikiezy_models.dart';
import 'voice/voice_parse_context.dart';
import 'voice/voice_parse_result.dart';
import 'voice/voice_transaction_parser_v2.dart';

enum VoiceAssistantPhase {
  listening,
  processing,
  completed,
  unclear,
  permissionDenied,
}

class VoiceAssistantResult {
  const VoiceAssistantResult({
    required this.draft,
    required this.transcript,
    required this.feedback,
    required this.confidence,
    required this.parseResult,
  });

  final TransactionDraft draft;
  final String transcript;
  final String feedback;
  final double confidence;
  final VoiceParseResult parseResult;

  bool get needsReview => parseResult.needsReview;
  List<String> get warnings => parseResult.warnings;
}

class VoiceAssistantController extends ChangeNotifier {
  VoiceAssistantController({
    VoiceTransactionParserV2? parser,
    speech.SpeechToText? speechToText,
    FlutterTts? textToSpeech,
  }) : _parser = parser ?? const VoiceTransactionParserV2(),
       _speech = speechToText ?? speech.SpeechToText(),
       _tts = textToSpeech ?? FlutterTts();

  final VoiceTransactionParserV2 _parser;
  final speech.SpeechToText _speech;
  final FlutterTts _tts;

  VoiceAssistantPhase phase = VoiceAssistantPhase.listening;
  String transcript =
      'Miki, jual nasi goreng tiga porsi harga lima belas ribu per porsi';
  String feedback = 'Miki siap mendengarkan transaksi.';
  String? lastError;
  VoiceAssistantResult? latestResult;
  double confidence = -1;
  double soundLevel = 0;
  bool wakeWordDetected = false;
  bool speechAvailable = false;
  bool nativeListening = false;
  bool ttsEnabled = true;
  bool _initialized = false;
  bool _isStarting = false;

  bool get isListening => phase == VoiceAssistantPhase.listening;
  bool get isProcessing => phase == VoiceAssistantPhase.processing;
  bool get isStarting => _isStarting;
  bool get isError =>
      phase == VoiceAssistantPhase.unclear ||
      phase == VoiceAssistantPhase.permissionDenied;
  bool get hasTranscript => transcript.trim().isNotEmpty;

  Future<bool> initialize() async {
    if (_initialized) return speechAvailable;
    await _configureTts();
    try {
      speechAvailable = await _speech.initialize(
        onStatus: _handleSpeechStatus,
        onError: _handleSpeechError,
        debugLogging: kDebugMode,
      );
      _initialized = true;
      return speechAvailable;
    } catch (error) {
      _initialized = true;
      speechAvailable = false;
      lastError = error.toString();
      return false;
    } finally {
      notifyListeners();
    }
  }

  Future<void> startListening({
    String localeId = 'id_ID',
    String? initialTranscript,
    bool wakeWordAlreadyDetected = false,
  }) async {
    if (_isStarting || nativeListening) return;
    _isStarting = true;
    phase = VoiceAssistantPhase.processing;
    feedback = 'Menyiapkan mikrofon...';
    lastError = null;
    notifyListeners();

    try {
      final granted = await _requestMicrophonePermission();
      if (!granted) {
        phase = VoiceAssistantPhase.permissionDenied;
        feedback = 'Izin mikrofon belum aktif.';
        await speak(feedback);
        return;
      }

      final available = await initialize();
      if (!available) {
        phase = VoiceAssistantPhase.permissionDenied;
        feedback = 'Speech recognition belum tersedia di perangkat ini.';
        await speak(feedback);
        return;
      }

      transcript = initialTranscript?.trim() ?? '';
      wakeWordDetected = wakeWordAlreadyDetected || _hasWakeWord(transcript);
      confidence = -1;
      soundLevel = 0;
      nativeListening = true;
      phase = VoiceAssistantPhase.listening;
      feedback = wakeWordDetected
          ? 'Wake word terdeteksi. Lanjutkan perintah transaksi.'
          : 'Silakan ucapkan transaksi.';
      notifyListeners();

      await _speech.listen(
        onResult: _handleSpeechResult,
        onSoundLevelChange: (level) {
          soundLevel = level;
          notifyListeners();
        },
        listenOptions: speech.SpeechListenOptions(
          localeId: localeId,
          listenFor: const Duration(seconds: 45),
          pauseFor: const Duration(seconds: 30),
          partialResults: true,
          cancelOnError: false,
          listenMode: speech.ListenMode.dictation,
        ),
      );
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  Future<VoiceAssistantResult?> stopAndProcess({
    VoiceParseContext parseContext = const VoiceParseContext(),
    bool speakResult = true,
  }) async {
    if (nativeListening) {
      nativeListening = false;
      await _speech.stop();
    }
    return processCurrentTranscript(
      parseContext: parseContext,
      speakResult: speakResult,
    );
  }

  Future<VoiceAssistantResult?> processCurrentTranscript({
    VoiceParseContext parseContext = const VoiceParseContext(),
    bool speakResult = true,
  }) async {
    final text = _transcriptWithoutWakeWord(transcript).trim();
    if (text.isEmpty) {
      phase = VoiceAssistantPhase.unclear;
      feedback = wakeWordDetected
          ? 'Wake word terdeteksi, tapi transaksi belum terdengar jelas.'
          : 'Maaf, suara belum terbaca. Coba ulangi lebih jelas.';
      if (speakResult) await speak(feedback);
      notifyListeners();
      return null;
    }

    phase = VoiceAssistantPhase.processing;
    feedback = 'Miki sedang memahami transaksi...';
    notifyListeners();

    final parsed = _parser.parse(text, context: parseContext);
    final draft = parsed.draft ?? _bestEffortDraft(text, parsed, parseContext);
    final parseResult = parsed.draft == null
        ? parsed.copyWith(draft: draft, needsReview: true)
        : parsed;
    confidence = parseResult.confidence;
    final resultFeedback = _buildFeedback(draft, parseResult);
    feedback = resultFeedback;
    latestResult = VoiceAssistantResult(
      draft: draft,
      transcript: text,
      feedback: resultFeedback,
      confidence: parseResult.confidence,
      parseResult: parseResult,
    );
    phase = VoiceAssistantPhase.completed;
    notifyListeners();

    if (speakResult) await speak(resultFeedback);
    return latestResult;
  }

  Future<void> cancelListening() async {
    _isStarting = false;
    if (nativeListening) {
      nativeListening = false;
      await _speech.cancel();
    }
    notifyListeners();
  }

  void markSilenceTimeout() {
    feedback = 'Tidak ada suara selama 5 detik. Miki memproses transcript...';
    notifyListeners();
  }

  Future<void> speak(String text) async {
    if (!ttsEnabled || text.trim().isEmpty) return;
    try {
      await _configureTts();
      await _tts.stop();
      await _tts.speak(text);
    } catch (error) {
      lastError = error.toString();
      notifyListeners();
    }
  }

  void setTranscript(String value) {
    transcript = value;
    wakeWordDetected = _hasWakeWord(value);
    latestResult = null;
    if (phase == VoiceAssistantPhase.unclear ||
        phase == VoiceAssistantPhase.permissionDenied ||
        phase == VoiceAssistantPhase.completed) {
      phase = VoiceAssistantPhase.listening;
    }
    notifyListeners();
  }

  void primeFromWakeWord(String? commandTranscript) {
    transcript = commandTranscript?.trim() ?? '';
    wakeWordDetected = true;
    latestResult = null;
    phase = VoiceAssistantPhase.listening;
    feedback = transcript.isEmpty
        ? 'Wake word Miki terdeteksi. Silakan ucapkan transaksi.'
        : 'Wake word Miki terdeteksi. Lanjutkan transaksi.';
    notifyListeners();
  }

  void previewPhase(VoiceAssistantPhase value) {
    phase = value;
    nativeListening = false;
    feedback = switch (value) {
      VoiceAssistantPhase.listening => 'Miki siap mendengarkan transaksi.',
      VoiceAssistantPhase.processing => 'Miki sedang memahami transaksi...',
      VoiceAssistantPhase.completed => feedback,
      VoiceAssistantPhase.unclear =>
        'Suara belum jelas. Coba ulangi lebih dekat ke mikrofon.',
      VoiceAssistantPhase.permissionDenied => 'Izin mikrofon belum aktif.',
    };
    notifyListeners();
  }

  Future<bool> _requestMicrophonePermission() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      return true;
    }
  }

  Future<void> _configureTts() async {
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.48);
    await _tts.setPitch(1.0);
  }

  void _handleSpeechResult(SpeechRecognitionResult result) {
    transcript = result.recognizedWords;
    confidence = result.confidence;
    wakeWordDetected = _hasWakeWord(transcript);
    if (result.finalResult && transcript.trim().isEmpty) {
      phase = VoiceAssistantPhase.unclear;
      feedback = 'Suara belum terbaca.';
    } else {
      phase = VoiceAssistantPhase.listening;
      if (wakeWordDetected) {
        feedback = 'Wake word Miki terdeteksi. Lanjutkan perintah transaksi.';
      }
    }
    notifyListeners();
  }

  void _handleSpeechError(SpeechRecognitionError error) {
    nativeListening = false;
    lastError = error.errorMsg;
    final permissionError =
        error.errorMsg.contains('permission') ||
        error.errorMsg.contains('not_allowed');
    phase = permissionError
        ? VoiceAssistantPhase.permissionDenied
        : VoiceAssistantPhase.unclear;
    feedback = permissionError
        ? 'Izin mikrofon belum aktif.'
        : 'Suara belum jelas, coba rekam ulang.';
    notifyListeners();
  }

  void _handleSpeechStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      nativeListening = false;
      notifyListeners();
    }
  }

  TransactionDraft _bestEffortDraft(
    String text,
    VoiceParseResult result,
    VoiceParseContext context,
  ) {
    return TransactionDraft(
      kind: result.kind,
      productName: '',
      quantity: 1,
      unit: SaleUnit.pcs,
      unitPrice: 0,
      discount: 0,
      categoryName: result.categoryName ?? _fallbackCategory(result.kind),
      walletName: result.walletName ?? context.defaultWalletName ?? '',
      segment: PriceSegment.retail,
      note: result.normalizedText,
      rawText: text,
    );
  }

  String _fallbackCategory(TransactionKind kind) {
    return switch (kind) {
      TransactionKind.sale => 'Penjualan',
      TransactionKind.expense => 'Lain-lain',
      TransactionKind.income => 'Pemasukan',
      TransactionKind.adjustment => 'Penyesuaian',
    };
  }

  String _buildFeedback(TransactionDraft draft, VoiceParseResult parseResult) {
    if (parseResult.needsReview) {
      return 'Miki sudah menangkap sebagian transaksi. Ada detail yang perlu dicek, silakan koreksi di preview sebelum disimpan.';
    }

    final amount = rupiah(draft.amount);
    switch (draft.kind) {
      case TransactionKind.sale:
        return 'Oke, penjualan ${draft.productName} ${draft.quantity} ${draft.unit.label} senilai $amount. Silakan cek sebelum disimpan.';
      case TransactionKind.expense:
        return 'Oke, pengeluaran kategori ${draft.categoryName} sebesar $amount. Silakan cek detailnya.';
      case TransactionKind.income:
        return 'Oke, pemasukan kategori ${draft.categoryName} sebesar $amount sudah disiapkan.';
      case TransactionKind.adjustment:
        return 'Oke, penyesuaian saldo sebesar $amount sudah disiapkan.';
    }
  }

  bool _hasWakeWord(String value) {
    return RegExp(
      r'\b(miki|mikiezy|miky|micki)\b',
      caseSensitive: false,
    ).hasMatch(value);
  }

  String _transcriptWithoutWakeWord(String value) {
    return value
        .replaceFirst(
          RegExp(
            r'^\s*(hai|halo|hey)?\s*(miki|mikiezy|miky|micki)\s*,?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .trim();
  }

  @override
  void dispose() {
    if (nativeListening) {
      nativeListening = false;
      unawaited(_speech.cancel().catchError((_) {}));
    }
    try {
      unawaited(_tts.stop().catchError((_) {}));
    } catch (_) {
      // Platform TTS may be unavailable in widget tests or unsupported targets.
    }
    super.dispose();
  }
}
