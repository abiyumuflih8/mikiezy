# Architecture

## Composition and state

- VERIFIED: `lib/main.dart` adalah composition root: repository, MikiezyState, AppLockController, AppNavigationService, VoiceAssistantManager, VoiceAssistantController, GlobalVoiceController, mutation preview handler, dan tiga executor.
- VERIFIED: `lib/state/app_state.dart` adalah ChangeNotifier penghubung UI/data; `MikiezyScope` adalah InheritedNotifier. UI/screens dan state belum sepenuhnya terpisah; domain services sudah menampung kalkulasi/validasi tertentu. Ini bukan implementasi clean architecture penuh.
- VERIFIED: `lib/screens/` berisi halaman; `lib/widgets/` komponen dan gates; `lib/theme/app_theme.dart` diimpor root. Ada struktur theme/shared paralel; jangan memilih canonical hanya dari nama folder.
- VERIFIED: `AppLockGate` membungkus `VoiceOverlayHost` pada MaterialApp builder. Root lifecycle diteruskan ke lock, global voice, navigation, dan wake-word manager.
- VERIFIED: `lib/services/navigation/app_navigation_service.dart` dan observer mengatur target, route terlindungi, foreground dan duplicate navigation.

## Persistence and financial domain

- VERIFIED: Repository canonical: `lib/data/repositories/mikiezy_repository.dart`. Native persistent factory membuka `MikiezyLocalDataSource(AppDatabase())`; web/nonpersistent memilih MemoryMikiezyRepository.
- VERIFIED: `lib/data/local/mikiezy_repository.dart` hanya compatibility export; database lama `lib/data/local/app_database.dart` telah dihapus pada baseline.
- VERIFIED: `lib/core/database/database_connection_io.dart` membuka `mikiezy.sqlite` dalam application documents via NativeDatabase.createInBackground. Tidak ada konfigurasi enkripsi SQLite pada jalur ini.
- VERIFIED: `lib/core/database/app_database.dart` v6 memiliki 12 tabel: ProductCategories, Products, Wallets, TransactionCategories, Transactions, TransactionLines, BusinessProfiles, AppSettings, VoiceProductAliases, VoiceUnitAliases, VoiceCorrections, VoiceActionAudits. Generated source: `app_database.g.dart`.
- VERIFIED: Migration `from < 2` membuat tabel lalu return; jalur lama berikutnya mengubah quantity/line schema, menambah learning tables, metadata stok dan audit. Sebelum v5, stok positif dipetakan tracked, stok nol menjadi untracked untuk mempertahankan perilaku lama. Jangan menyamakan fixture v1 dengan semua database v1 pengguna.
- VERIFIED: `mikiezy_local_data_source.dart` menyimpan transaction graph dalam database transaction, termasuk produk, wallet, kategori, header dan lines. Mutasi voice melakukan validasi commit/audit dan pemeriksaan stale/duplicate di jalur repository/data source.
- VERIFIED: `lib/models/mikiezy_models.dart` menyimpan quantity pecahan dan snapshot transaksi; `domain/services/` berisi quantity normalization, konversi satuan, kalkulasi stok, metrics, validator produk/harga, dan fingerprint. Pack/carton bergantung metadata produk.
- VERIFIED: `VoiceActionAudits` memiliki uniqueness actionId/status. Learning corrections dapat menyimpan rawText; audit yang direduksi tidak menghapus sensitivitas tabel lain.

## Voice pipeline

- VERIFIED: STT adapter: `speech_to_text` pada `voice_assistant_controller.dart` dan `voice/voice_assistant_manager.dart`. Manager standby wake word dan session controller adalah jalur berbeda yang dikoordinasikan; jangan mengklaim singleton recognizer hardware sudah terbukti.
- VERIFIED: `voice/global_voice_engine.dart` membungkus session controller. `global_voice_controller.dart` mengatur overlay, timer diam, processing, speaking, conversation relisten, foreground/lock dan generation.
- VERIFIED: `voice_assistant_controller.dart` menggabungkan final/partial transcript, menangani STT status, routing, parser, feedback dan TTS. Plugin verbose logging off; TTS menggunakan id-ID dan await completion. Lihat KI-01 sebelum mengubah stop flow.
- VERIFIED: `voice/microphone_permission_service.dart` memetakan granted/denied/permanent/restricted/error dan fail-closed. Settings hanya dibuka melalui tindakan user yang diizinkan status.
- VERIFIED: `voice_command_router.dart` -> normalizer -> `voice_intent_classifier.dart` -> entity extractor umum/khusus create product, stock increment, price update. Classifier memakai frasa/regex dan skor heuristik tetap.
- VERIFIED: Jalur transaksi: `voice_transaction_parser_v2.dart` -> intent detector -> `voice_slot_extractor.dart` -> `voice_transaction_resolver.dart` -> validator -> draft adapter. Number/money parser dan unit dictionary menjadi komponen pendukung.
- VERIFIED: `voice_product_resolver.dart` memakai exact, alias, fuzzy dan ambiguity; default threshold auto-match 0.88, candidate 0.72, gap 0.06. Angka ini parameter heuristik, bukan probabilitas terkalibrasi.
- VERIFIED: `voice_clarification_parser.dart`, conversation context, business conversation, dan conversation khusus mutasi menangani kandidat, jawaban, cancel/new command dan expiry. Context umum mempunyai timeout default dua menit.
- VERIFIED: `voice_mutation_preview_handler.dart` menghubungkan typed draft/payload, conversation, action coordinator dan executor. Coordinator menegakkan flag, confirmation, authentication requirement, expiry/fingerprint, finalization dan audit.
- VERIFIED: Runtime mengaktifkan create product, increment stock, update price di root; jenis lain tetap disabled. Domain execution tetap deterministik.

## Security and dependencies

- VERIFIED: `services/security/` menyediakan Argon2id verifier bersalt, secure storage, cooldown, lifecycle lock, native biometric dan fallback PIN. AuthScreen login/register tetap prototype, bukan authentication backend.
- VERIFIED: Android manifest meminta RECORD_AUDIO, INTERNET dan USE_BIOMETRIC; backup disabled. iOS Info.plist memiliki microphone, speech recognition dan Face ID usage descriptions. Permission runtime OS belum diuji ulang M1.
- VERIFIED: Dependency declarations: speech_to_text ^7.4.0; flutter_tts ^4.2.5; permission_handler ^12.0.1; drift ^2.33.0; sqlite3_flutter_libs ^0.6.0+eol; path_provider ^2.1.5; path ^1.9.1; flutter_secure_storage ^10.3.1; local_auth ^3.0.2; cryptography ^2.9.0; url_launcher ^6.3.2. Gunakan pubspec.lock untuk resolusi tepat.
- VERIFIED: Dev tools meliputi flutter_test, flutter_lints, drift_dev dan build_runner. Tidak ditemukan Supabase client atau LLM SDK runtime pada dependency declarations.

## Tests to preserve

- VERIFIED: `test/drift_database_test.dart` dan `local_persistence_test.dart`: persistence/migration; `product_stock_service_test.dart`, `unit_conversion_service_test.dart`, metrics/validator tests: domain.
- VERIFIED: `voice_transaction_parser_v2_test.dart`, `voice_system_test.dart`, resolver/router/extractor/conversation tests: pemahaman ucapan dan draft.
- VERIFIED: `voice_create_product_*`, `voice_stock_increment_*`, `voice_price_update_*`: commit, confirmation, stale/duplicate, atomicity, history dan undo policy.
- VERIFIED: `voice_permission_hardening_test.dart`, `voice_overlay_controller_test.dart`, `voice_wake_word_test.dart`, navigation/lock/privacy/diagnostics tests dan `widget_test.dart`: lifecycle dan UI guards.
- REPORTED: Hasil baseline seluruh suite 530 PASS; keberadaan test tidak membuktikan hasil eksekusi ulang.
