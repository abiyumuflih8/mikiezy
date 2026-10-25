# Mikiezy Project State

Dokumen ini adalah ringkasan status operasional kanonikal terkini (*current operational truth*) proyek Mikiezy pada workspace Antigravity. Dokumen ini diperbarui hanya saat milestone penting selesai, keputusan arsitektur berubah, fitur utama berubah, blocker terselesaikan, atau status verifikasi berubah signifikan.

---

## 1. Project Overview
- **Scope & Tujuan**: [REPORTED] Aplikasi POS dan pembukuan keuangan UMKM *offline-first* dengan pemahaman transaksi berbasis suara berbahasa Indonesia, sekaligus subjek penelitian skripsi peminatan AI.
- **Repository Baseline**: [VERIFIED] Workspace `C:\kuliah\pbm\mikiezy-antigravity` pada branch `migration/antigravity-pilot`. Baseline Phase 7A berasal dari commit `3680e1a` (`master`, v1.0.0+1). Checkpoint konfigurasi agent terakhir adalah commit `4fdc3ea`.

---

## 2. Existing Architecture & Technology Stack
- **Framework & SDK**: [VERIFIED] Flutter 3.44.4 (channel stable), Dart 3.12.2.
- **State Management**: [VERIFIED] Custom `ChangeNotifier` (`MikiezyState`) dihubungkan ke UI via `InheritedNotifier` (`MikiezyScope`) pada `lib/main.dart`. Bukan Provider pihak ketiga, Bloc, atau Riverpod.
- **Data Persistence**: [VERIFIED] Native SQLite menggunakan Drift v6 (`mikiezy.sqlite` via `NativeDatabase.createInBackground`). Web runtime memakai in-memory fallback.
- **Voice Pipeline**: [VERIFIED] Plugin native `speech_to_text` dan `flutter_tts`. Pemrosesan teks berbasis rule/heuristik lokal (`voice_transaction_parser_v2.dart`, entity extractor, regex/keyword match, dan fuzzy resolver). Tidak ada LLM runtime atau cloud dependency pada jalur transaksi aktif.
- **Security & Lock**: [VERIFIED] PIN dengan hashing Argon2id bersalt, `flutter_secure_storage`, biometrik via `local_auth`, dan lifecycle auto-lock (`AppLockGate`).

---

## 3. Implemented Features
- **Pencatatan Transaksi**: [VERIFIED] Penjualan, pemasukan, pengeluaran; manual form dan voice input; preview draft interaktif; kalkulasi stok otomatis; snapshot harga/modal historis.
- **Katalog & Stok**: [VERIFIED] Manajemen produk, kategori, harga bertingkat/satuan (pack/carton multiplier), tracking kuantitas pecahan, penyesuaian stok.
- **Mutasi Suara Aktif**: [VERIFIED] Tepat 3 mutasi diaktifkan di `lib/main.dart`: Tambah Produk, Tambah Stok, Update Harga. Mutasi lain (hapus/kurangi stok) dinonaktifkan demi integritas ledger.
- **Laporan & Dompet**: [VERIFIED] Dashboard metrik, laporan laba/rugi, multi-wallet/kas, riwayat transaksi, filter tanggal.
- **Fitur Non-Runtime / Prototype**: [REPORTED] Cloud sync Supabase dan user login online masih berupa rancangan/prototipe dan belum aktif di runtime.

---

## 4. Database, API, & Integrasi Existing
- **Drift Schema**: [VERIFIED] Versi 6 dengan 12 tabel: `ProductCategories`, `Products`, `Wallets`, `TransactionCategories`, `Transactions`, `TransactionLines`, `BusinessProfiles`, `AppSettings`, `VoiceProductAliases`, `VoiceUnitAliases`, `VoiceCorrections`, `VoiceActionAudits`.
- **Integrasi Cloud**: [VERIFIED] Tidak ada koneksi cloud aktif. Sifat aplikasi 100% *offline-first*.
- **Hardware Integration**: [VERIFIED] Driver mikrofon dan speaker terhubung lewat plugin OS Android.

---

## 5. Verified Milestones
- **M3 (Agent Configuration Checkpoint)**: [VERIFIED] Commit lokal `4fdc3ea` (73 file mencakup Karpathy principles, 4 custom skills: stt-debugging, ai-integration, mikiezy-design-system, ui-ux-pro-max + LICENSE).
- **M4A / M4A.1 (Flutter Baseline Regression)**: [VERIFIED]
  - `pubspec.lock` SHA-256 identik dengan Phase 7A (`7E1316761F...`).
  - `.dart_tool/package_config.json` dipulihkan via `flutter pub get --offline --enforce-lockfile`.
  - `flutter analyze --no-pub`: 0 issues found (bersih).
  - `flutter test --no-pub`: 530/530 tests PASS.
- **M4B (Dart MCP Runtime & Git Integrity)**: [VERIFIED]
  - Official Dart MCP Server (`dart-mcp-server` v1.0.6 dari Flutter Team) aktif dan fungsional.
  - Smoke test `analyze_files` pada `lib/main.dart`: PASS (`No errors`).
  - File `.agents/mcp_config.json` terbukti redundan dan tetap untracked.
  - 7 file desktop plugin registrant terbukti 0 content diff (hanya metadata touch Windows).
- **M4C.3 (Android Debug APK Build)**: [VERIFIED]
  - `flutter build apk --debug --no-pub`: SUCCESS (exit code 0).
  - Output: `build/app/outputs/flutter-apk/app-debug.apk` (164,293,821 bytes, SHA-256 `EF5213BC2B...`).
- **M4C.4 (Device Safety Check)**: [VERIFIED]
  - Target Android fisik: `21121210G` (Android 13 / API 33, arm64-v8a).
  - Package `com.mikiezy.mikiezy` berstatus *PACKAGE NOT INSTALLED* di perangkat.
  - Jalur dinilai: *SAFE FOR CONTROLLED FIRST INSTALL*.
- **Hardware Scenarios & Smoke Runs**: [NOT TESTED] 234 hardware scenarios dan 3 manual smoke runs (`SMOKE-01` s.d. `SMOKE-03`) belum dijalankan pada fisik perangkat.

---

## 6. Current Operational State
- **Build & Test Suite**: [VERIFIED] 100% PASS (530 automated tests, clean analyze, APK debug valid).
- **Perangkat Fisik**: [VERIFIED] Terhubung via ADB, display/input didukung via `scrcpy`, belum dipasang APK.
- **Demo / Release Readiness**: [REPORTED] **NO-GO** (Tetap ditahan hingga pembuktian 3 run smoke test dan skenario hardware kritis tervalidasi).

---

## 7. Known Issues & Blockers
- **KI-01 (Voice Engine Stop/TTS)**: [REPORTED] Potensi TTS tetap berbicara saat stop/background; interface `GlobalVoiceEngine` belum memiliki `stopSpeaking` eksplisit.
- **KI-04 (Hardware Matrix Unverified)**: [VERIFIED] 234 skenario hardware dan smoke test 0/3 masih berstatus NOT TESTED.
- **KI-05 (Debug Signing)**: [VERIFIED] Build Android masih menggunakan signing key debug.
- **KI-07 (Local Privacy)**: [VERIFIED] SQLite lokal belum terenkripsi; raw voice transcript tersimpan pada tabel koreksi lokal.
- **Desktop Registrant Metadata**: [VERIFIED] 7 file platform desktop terdeteksi modified di Git stat cache pasca `pub get` (konten 0 diff).
- **Local MCP Config**: [VERIFIED] `.agents/mcp_config.json` lokal berstatus redundan terhadap official plugin.

---

## 8. Protected Components & Invariants
- **Database Schema**: Pertahankan skema Drift v6 dan kompatibilitas migrasi; jangan ubah tabel tanpa migration script dan izin pemilik.
- **Financial Invariants**: Snapshot harga historis, snapshot modal, atomic multi-line writes, dan validasi non-negatif mutlak dipertahankan.
- **State Architecture**: Jangan mengganti `ChangeNotifier`/`MikiezyScope` menjadi state management lain secara sepihak.
- **Safety Boundaries**: Mutasi database voice harus melalui preview dan konfirmasi; dilarang bypass domain validation.

---

## 9. Key Technical Decisions
- **D01**: Data foundation first; perubahan bertahap tanpa refactor besar.
- **D02**: Pertahankan custom notifier dan InheritedNotifier runtime.
- **D03**: Drift/SQLite native v6 sebagai penyimpanan data kanonikal.
- **D05**: Atomic transaction graph writes dan idempotency guards.
- **D06**: Pembatasan mutasi suara hanya pada create product, increment stock, update price.
- **D07**: Preview & confirmation eksplisit wajib mendahului mutasi database.
- **D08**: Permission fail-closed dan generation lifecycle guard pada voice callbacks.

---

## 10. Current Priorities
1. Menjaga kontinuitas konteks agent agar tidak melakukan modifikasi tak terarah atau rebuild komponen existing.
2. Menyelesaikan verifikasi migrasi M4 sebelum melangkah ke controlled pilot (M5).
3. Melakukan instalasi terkontrol dan uji smoke test manual pertama (`SMOKE-01`) pada perangkat fisik target via scrcpy bila disetujui.

---

## 11. Next Recommended Action
- Melakukan pembersihan status untracked `.agents/mcp_config.json` (checkpoint terpisah) atau melanjutkan ke instalasi terbatas APK debug (`M4C.5` / `SMOKE-01`) atas persetujuan pemilik.

---

## 12. Reference Documents & Sources of Truth
- **Current Operational Truth**: `docs/PROJECT_STATE.md` (dokumen ini).
- **Agent Operating Rules**: `AGENTS.md` & `.agents/rules/karpathy-principles.md`.
- **Handoff History**: `docs/PROJECT_HANDOFF.md`.
- **Detailed Architecture**: `docs/ARCHITECTURE.md`.
- **Feature Inventory**: `docs/FEATURE_INVENTORY.md`.
- **Technical Decisions**: `docs/DECISIONS.md`.
- **Known Issues & Gaps**: `docs/KNOWN_ISSUES.md`.
- **Long-term Roadmap**: `docs/ROADMAP.md`.
- **Device Test Matrix & Smoke Spec**: `docs/phase_7a_device_validation.md` & `docs/phase_7a_validation_report.md`.
