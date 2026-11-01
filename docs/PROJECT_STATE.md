# Mikiezy Project State

Dokumen ini adalah ringkasan status operasional kanonikal terkini (*current operational truth*) proyek Mikiezy pada workspace Antigravity. Dokumen ini diperbarui hanya saat milestone penting selesai, keputusan arsitektur berubah, fitur utama berubah, blocker terselesaikan, atau status verifikasi berubah signifikan.

---

## 1. Project Overview
- **Scope & Tujuan**: [REPORTED] Aplikasi POS dan pembukuan keuangan UMKM *offline-first* dengan pemahaman transaksi berbasis suara berbahasa Indonesia, sekaligus subjek penelitian skripsi peminatan AI.
- **Repository Baseline**: [VERIFIED] Workspace `C:\kuliah\pbm\mikiezy-antigravity` pada branch `migration/antigravity-pilot`. Baseline Phase 7A berasal dari commit `3680e1a` (`master`, v1.0.0+1). Checkpoint Git terakhir tersinkronisasi adalah commit `d0438755dd64d04d04eceb05046e12766ba184d8` (M4F.72). Host test suite: 614/614 PASS, analyze bersih.

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
- **M4C.5 (Controlled Android First Install & Launch Pilot)**: [VERIFIED]
  - APK debug terpasang pada POCO F4 GT (`21121210G`), aplikasi berhasil dibuka ke tampilan onboarding.
  - Ditemukan temuan visual: FAB mikrofon global bocor ke onboarding dan register/login.
- **M4D / M4D.1 (Project Continuity Checkpoint)**: [VERIFIED]
  - Commit lokal `08c2fb5` (`docs/PROJECT_STATE.md` kanonikal & penambahan aturan kontinuitas di `AGENTS.md`).
- **M4E.1 (Fix Global Microphone Overlay Visibility)**: [VERIFIED]
  - Perbaikan visibilitas floating mic reaktif berbasis rute aktif di `VoiceOverlayHost`, `AppNavigationService`, dan `AppNavigationObserver`.
  - `flutter analyze --no-pub`: 0 issues (bersih).
  - `flutter test --no-pub`: 531/531 tests PASS (termasuk 11/11 targeted widget tests di `test/widget_test.dart`).
- **M4E.2 (Safety Review & Local Commit)**: [VERIFIED]
  - Commit lokal `ef92710` (`fix: restrict global microphone overlay to allowed routes`), tepat 7 file patch masuk commit.
- **M4E.3 (Controlled Android Rebuild & Patch Deployment)**: [VERIFIED]
  - APK debug patch berhasil di-build (`164,293,821` bytes, SHA-256 `EDF608ECCF4C78E8BDA3AE71F438E0F88C7B5E02D3D6A1AC4DB1FE617CF3E976`).
  - Pemilik menyetujui pembaruan melalui safety gate (`adb install -r`).
  - Update sukses pada POCO F4 GT (`lastUpdateTime: 2026-10-27 00:17:10`).
  - Verifikasi fisik via `scrcpy` & screencap: Splash/Onboarding/Login/Register: FAB hidden; Dashboard: tepat satu global microphone FAB visible tanpa menutupi navigasi.
  - Status bug visual: **FIX VERIFIED ON DEVICE**.
  - Batasan verifikasi: Hilangnya FAB visual tidak membuktikan lifecycle audio tuntas (voice command, STT/TTS audio, dan runtime permission mic belum diuji).
- **M4F.1 s.d. M4F.35 (QA Run 2 on Isolated QA Package & AppLock Security Challenge)**: [VERIFIED ON DEVICE]
  - Paket terisolasi `com.mikiezy.mikiezy.qa` (APK SHA-256 `A9A111605A5ADBFB752185998FAED7A29210C3E1AD82A638E1446AD03835E3B1`) dipasang pada Android User 0 untuk melindungi instalasi produksi (`com.mikiezy.mikiezy` User 0 dan User 999).
  - Seluruh 10 langkah kanonikal berhasil dieksekusi pada POCO F4 GT:
    - Step 1: App launch & AppLock unlock (PASS).
    - Step 2: Voice navigation ke katalog barang (PASS).
    - Step 3: Voice create product Kopi Susu (REMEDIATED WITH DOCUMENTED DEVIATION: fallback Lain-lain diperbaiki manual via UI ke Minuman pada M4F.25).
    - Step 4: Voice stock increment 20 -> 30 gelas (PASS).
    - Step 5: Voice sale 1 Kopi Susu @ Rp12.000 (PASS; stok 30 -> 29).
    - Step 6: Voice query omzet & laba (PASS WITH DATA QUALITY GAP; HPP Rp0 gap).
    - Step 7: Voice price update Rp12.000 -> Rp14.000 (PASS; mekanisme konfirmasi suara terverifikasi).
    - Step 8: Second voice sale @ Rp14.000 (PASS; stok 29 -> 28; penjualan historis tetap Rp12.000).
    - Step 9: Analitik & voice tanya stok (PASS WITH DATA QUALITY GAP; Miki menjawab 28 gelas; rekonsiliasi omzet Rp94.000 valid).
    - Step 10 & M4F.35: Cold restart business persistence & physical AppLock challenge (PASS; AppLockScreen memblokir UI sebelum unlock PIN pemilik; data bisnis bertahan; verifikasi baris tabel SQLite VoiceActionAudits tetap berstatus open).
- **M4F.60 s.d. M4F.72 (Concurrency Hardening, AppLock Expiry, & Host Regressions)**: [VERIFIED]
  - Ditemukan dan diremediasi deterministik gap konkurensi pada `VoiceActionCoordinator` (konfirmasi ganda, pembatalan bersamaan, race pembatalan awal, dan AppLock/expiry guard).
  - Ditambahkan in-flight guard (`_inFlightActionIds`) dan finalized guard (`_finalizedActionIds`).
  - Target regression tests (31 tests) bertambah hingga total host test suite mencapai 614/614 PASS (analyze bersih).
  - Seluruh checkpoint Git (M4F.65, M4F.68, M4F.70, M4F.72) tersinkronisasi ke remote `origin` hingga commit `d0438755`.
- **M4F.73 (Isolated Diagnostic APK v3 Host Build & Provenance Audit)**: [VERIFIED]
  - Build rilis `--flavor qaAudit --build-number=3` menghasilkan `app-qaaudit-release.apk` (SHA-256 `4857B61B...`).
  - Verifikasi sertifikat penandatanganan via `apksigner`: SHA-256 digest `ed0e0615...` (100% identik dengan v2 dan debug keystore lokal).
  - Badging via `aapt2`: `com.mikiezy.mikiezy.qa.audit`, `versionCode=3`, non-debuggable release build.
- **M4F.74 (In-Place APK v3 Update & Post-Update Durability on POCO F4 GT)**: [VERIFIED ON DEVICE]
  - Pembaruan in-place via `adb install -r` sukses tanpa konflik tanda tangan.
  - Verifikasi `dumpsys package`: `userId=10462` bertahan, `versionCode=3`.
  - AppLock fail-closed terverifikasi (layar terkunci memblokir data bisnis hingga PIN pemilik dimasukkan).
  - Durabilitas data 100% terjaga pasca update: 4 produk katalog dan 6 event audit lokal utuh.
- **M4F.75 (Physical Post-Remediation Concurrency & Voice Verification)**: [VERIFIED ON DEVICE]
  - Uji suara fisik mutasi `createProduct` (`Keripik Singkong`): transisi status `previewed` -> `confirmed` -> `executionStarted` -> `succeeded` dieksekusi tepat satu kali (zero duplicate).
  - Uji suara fisik pembatalan `createProduct` (`Makaroni Pedas`): transisi status `previewed` -> `cancelled` saat pemilik mengucapkan "Batal". Asisten merespons: "Perubahan dibatalkan. Tidak ada data yang diubah" dan produk tidak masuk katalog (zero mutation).
  - Metrik durabilitas `VoiceActionAudits`: 12 total event, 5 aksi unik, 2 berhasil, 1 gagal, 2 penolakan/pembatalan terminal.
- **Hardware Scenarios & Smoke Runs**: [PARTIALLY TESTED] QA Run 2 & QA Run 3 tervalidasi pada paket terisolasi. SMOKE-01 (produksi) belum dijalankan, SMOKE-02 (XSpace) terblokir, dan mayoritas 234 skenario hardware belum dijalankan.

---

## 6. Current Operational State
- **Build & Test Suite**: [VERIFIED] 100% PASS (614 automated tests, clean analyze, APK v3 release valid).
- **Perangkat Fisik**: [VERIFIED] Terhubung via ADB; QA Run 2 & QA Run 3 tuntas pada paket terisolasi `com.mikiezy.mikiezy.qa` & `com.mikiezy.mikiezy.qa.audit` (POCO F4 GT `21121210G`, User 0, versionCode=3); instalasi produksi `com.mikiezy.mikiezy` tetap terlindungi.
- **Demo / Release Readiness**: [REPORTED] **NO-GO** (Tetap ditahan; produksi smoke test 0/3, skenario XSpace SMOKE-02 terblokir, signing masih debug, 234 skenario hardware belum tuntas).
- **SMOKE Runs**: [PARTIALLY TESTED] `SMOKE-01` (produksi User 0) NOT RUN; `SMOKE-02` (XSpace User 999) BLOCKED; `QA-RUN-2` (isolated QA User 0) PASS WITH DOCUMENTED DEVIATIONS (10/10 langkah kanonikal fungsional); `SMOKE-03` NOT RUN.
- **Hardware Matrix (234 skenario)**: [PARTIALLY TESTED] 10 skenario kanonikal + 7 skenario persistence/harga (P6C-13, P6C-14, PERSIST-01..04, PERSIST-08) lulus pada QA terisolasi; mayoritas skenario tetap NOT RUN.
- **Voice/Audio Hardware Runtime**: [VERIFIED ON ISOLATED QA] Voice command, STT/TTS audio (Miki menjawab stok, konfirmasi harga), dan mic permission terbukti berjalan di Android 13; VoiceActionAudits row persistence belum diverifikasi independen.

---

## 7. Known Issues & Blockers
- **Bug Global Voice Overlay Leaking (Pre-Auth)**: [VERIFIED RESOLVED ON DEVICE] FAB tersembunyi pada pre-auth dan tampil tepat satu di dashboard.
- **KI-01 (Voice Engine Stop/TTS)**: [REPORTED] Potensi TTS tetap berbicara saat stop/background; interface `GlobalVoiceEngine` belum memiliki `stopSpeaking` eksplisit.
- **KI-04 (Hardware Matrix Partially Verified)**: [VERIFIED] QA Run 2 (10/10 langkah kanonikal) lulus pada paket QA terisolasi; 234 skenario hardware dan smoke test produksi 0/3 masih belum tuntas.
- **KI-05 (Debug Signing)**: [VERIFIED] Build Android masih menggunakan signing key debug.
- **KI-07 (Local Privacy)**: [VERIFIED] SQLite lokal belum terenkripsi; raw voice transcript tersimpan pada tabel koreksi lokal.
- **KI-08 (Dual Apps XSpace Blocker)**: [VERIFIED] `SMOKE-02` pada Xiaomi Dual Apps User 999 terblokir isu sandbox autentikasi/navigasi.
- **KI-09 (Voice Action Audit Independent Verification)**: [VERIFIED RESOLVED ON DEVICE] Inspeksi independen melalui layar diagnostik internal `Internal Audit QA Diagnostics` pada POCO F4 GT mengonfirmasi pencatatan persisten 12 baris event audit dari 5 aksi unik pada SQLite lokal (`VoiceActionAudits`).
- **KI-10 (Step 3 Voice Category Fallback)**: [VERIFIED GAP] Perintah suara tambah produk tanpa kata kategori otomatis fallback ke Lain-lain; membutuhkan klarifikasi atau edit UI.
- **KI-11 (HPP Data Quality Gap)**: [VERIFIED GAP] HPP Kopi Susu bernilai Rp0 sehingga metriks profitabilitas pada Analitik/Voice bersifat estimasi.
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
2. Mempertahankan pemisahan lingkungan QA terisolasi (`com.mikiezy.mikiezy.qa`) dan instalasi produksi (`com.mikiezy.mikiezy`).
3. Mengkaji resolusi blocker XSpace User 999 (`SMOKE-02`) dan mempersiapkan protokol pengujian smoke produksi bersih (`SMOKE-01`).

---

## 11. Next Recommended Action
- Mengkaji arsitektur penanganan Dual Apps sandbox XSpace (`SMOKE-02`) atau mempersiapkan pengujian smoke produksi terkontrol (`SMOKE-01`) atas izin eksplisit pemilik.

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
