---
name: stt-debugging
description: Panduan prosedur debugging STT, TTS, wake word, microphone permission, lifecycle, dan asynchronous voice callbacks khusus aplikasi Mikiezy.
---

# STT & Voice Subsystem Debugging Guide

Skill ini menyediakan prosedur investigasi, perbaikan terarah, dan verifikasi untuk subsistem suara Mikiezy. Panduan ini melengkapi `AGENTS.md`, Karpathy Rule, dan Official Flutter Skills tanpa menggantikannya.

## 1. Peta Modul & Arsitektur Suara
- **Standby Wake Word**: `lib/services/voice/voice_assistant_manager.dart` (deteksi kata "Miki", standby loop, health check).
- **Session Controller**: `lib/services/voice_assistant_controller.dart` (transkripsi STT, normalizer, router, parser, feedback TTS).
- **Global Orchestrator**: `lib/services/voice/global_voice_controller.dart` (manajemen overlay, silence timeout, relisten delay, pause/resume wake word).
- **Engine Interface**: `lib/services/voice/global_voice_engine.dart` (abstraksi session controller untuk orchestrator).
- **Microphone Permission**: `lib/services/voice/microphone_permission_service.dart` (pemetaan granted/denied/permanentlyDenied/restricted/error).

## 2. Alur Investigasi Bertahap
1. **Reproduksi & Hipotesis Akar Masalah**:
   - Telusuri alur eksekusi spesifik dari pemicu masalah (misal: tombol PTT, wake word, overlay dismiss, atau rotasi/background).
   - Bentuk hipotesis teknis jelas sebelum mengubah kode. Hindari perubahan coba-coba.
2. **Inspeksi Kode Terarah**:
   - Gunakan Dart MCP `analyze_files` pada file terkait untuk mendeteksi error diagnostik.
   - Baca hanya berkas pada jalur eksekusi relevan, jangan memuat seluruh subdirektori suara.
3. **Pencegahan Refactor Berlebih**:
   - Dilarang merombak arsitektur controller, mengganti plugin `speech_to_text`/`flutter_tts`, atau menambah dependency baru tanpa izin eksplisit pemilik project.

## 3. Kriteria Keberimaan (Acceptance Criteria) & Guard Invarian
Sebelum mengimplementasikan perbaikan, pastikan solusi memenuhi kriteria:
- **Cancel & Dispose**: Saat sesi dibatalkan atau controller di-dispose, pembacaan audio native dihentikan, `_generation` dinaikkan, dan callback tidak memanggil `notifyListeners()` setelah dispose.
- **Background & AppLock**: Saat aplikasi terkunci (`AppLockGate`) atau ke background, input suara diblokir dan wake word dipause; wake word pulih saat kembali ke foreground dan terbuka.
- **Late Callback & Race Protection**: Callback asynchronous dari STT dengan generation lama wajib diabaikan secara fail-closed.
- **Idempotency & Duplicate Execution**: Command fingerprint (`_activeCommandFingerprint`) mencegah eksekusi mutasi atau navigasi berulang dari transcript akumulatif.
- **Permission Fail-Closed**: Status `denied` menampilkan pesan edukatif, `permanentlyDenied` membuka settings hanya atas aksi user, dan `restricted`/`error` tidak membuka mikrofon.

## 4. Catatan Khusus KI-01 (TTS Stop Gap)
- `GlobalVoiceEngine` saat ini tidak mengekspos metode `stopSpeaking()`, sehingga pemanggilan `cancelListening()` hanya membatalkan engine STT tetapi tidak menghentikan pemutaran audio TTS.
- **Status Bukti**: Ini adalah **temuan statis** yang memerlukan reproduksi pada perangkat fisik, bukan bug hardware yang sudah terbukti. Jangan melakukan perbaikan arsitektur sebelum ada persetujuan dan verifikasi reproduksi.

## 5. Privasi & Redaksi Informasi Sensitif
- Gunakan selalu `SafeDiagnostics` untuk logging event dan kegagalan.
- Periksa agar pesan error, payload exception, raw transcript ucapan, dan informasi transaksi bisnis tidak bocor melalui unhandled exception logging atau `print()` console.

## 6. Strategi Verifikasi: Automated Tests vs Validasi Fisik
- **Targeted Automated Tests (Verifikasi Logika Dart)**:
  - Permission: `test/voice_permission_hardening_test.dart`
  - Overlay & Lifecycle: `test/voice_overlay_controller_test.dart`
  - Wake Word: `test/voice_wake_word_test.dart`
  - Voice Session End-to-End: `test/voice_system_test.dart`
  - Parser Transaksi: `test/voice_transaction_parser_v2_test.dart`
- **Validasi Perangkat Fisik (Hardware/Native)**:
  - Pengujian automated di atas memverifikasi kontrak logika Dart. Perilaku native OS (audio focus, background mic kill oleh OEM seperti MIUI/Samsung, dan performa acoustic wake word nyata) tetap memerlukan pengujian fisik di perangkat Android nyata sebelum statusnya dapat diverifikasi penuh.
