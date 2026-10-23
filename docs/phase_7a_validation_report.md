# Phase 7A Validation Report

Tanggal audit: 2026-07-24

## Executive Decision

| Gate | Decision | Reason |
|---|---|---|
| Automated regression | PASS | `flutter analyze` bersih dan 530/530 test lulus |
| Android build | PASS for internal testing | APK debug dan release internal berhasil dibangun dan signature v2 valid |
| Real-device validation | BLOCKED | Tidak ada perangkat Android/iOS atau emulator Android yang terhubung |
| Demo readiness | NO-GO pending device evidence | Kriteria voice, biometric, migration salinan DB, persistence, dan smoke test tiga kali belum dibuktikan pada hardware |
| Production release | NO-GO | Release masih memakai debug signing, application ID/label belum difinalkan, iOS belum dibuild, dan hardware matrix belum dijalankan |
| Phase 7B | HOLD | Mulai setelah critical demo matrix dan migration salinan database lulus |

Keputusan `NO-GO` bukan indikasi regression otomatis. Keputusan ini menjaga
agar hasil simulator/unit test tidak diklaim sebagai bukti microphone,
biometric, lifecycle OS, atau migration database pengguna nyata.

## Evidence Summary

| Evidence | Result |
|---|---|
| Host | Windows 10 22H2, build 19045.6466 |
| Connected Flutter targets | Windows, Chrome, Edge |
| Android/iOS real device | Tidak tersedia |
| Flutter | 3.44.4 |
| Dart | 3.12.2 |
| App | 1.0.0+1 |
| Drift schema | v6, tidak berubah pada Phase 7A |
| Planned real-device tests | 234 |
| Real-device execution | 0 PASS, 0 FAIL, 1 environment gate BLOCKED, 234 NOT RUN |
| Three-run smoke demo | 0/3, NOT RUN |
| Automated tests | 530 PASS, 0 FAIL |
| Static analysis | PASS, no issues |
| `git diff --check` | PASS |
| Debug APK | 214,956,472 bytes |
| Debug SHA-256 | `B5CE7E0DDF26F3073510BA981AC3F100425909A169DF1210AC262AEFF6F62F02` |
| Internal release APK | 62,739,640 bytes |
| Internal release SHA-256 | `BC205B8DE2258830F4AAA6931450BFFB37BAE13092C828CDD2E123DEE1412CEF` |

Tester `Codex` hanya menjalankan audit host, test otomatis, dan build. Kolom
tester hardware belum dapat diisi.

## Workspace Baseline

Workspace berada pada branch `master`, commit `db61df4`, dengan perubahan
lintas Phase 1-6C yang belum dipisahkan menjadi checkpoint commit. Saat audit
final terdapat 55 tracked modified, 4 tracked deleted, dan 88 entri untracked
menurut `git status --porcelain`.

Empat file database lama yang deleted adalah cleanup yang sudah ada dari phase
sebelumnya. Tidak ada perubahan lama yang di-revert. Pengelompokan phase hanya
dapat diinferensikan dari nama file dan domain karena tidak tersedia commit
checkpoint per phase.

Tidak ditemukan credential, keystore, database lokal, atau APK yang siap ikut
version control. `.gitignore` diperkuat untuk `key.properties`, keystore, env,
SQLite/Drift sidecar, dan folder evidence lokal. Artefak di `build/` tetap
ignored.

Risiko workspace terbesar adalah blast radius review: perubahan valid dari
banyak phase masih berada dalam satu worktree. Buat checkpoint terpisah setelah
review manual, tanpa mencampur credential atau artefak build.

## Toolchain and Release Audit

| Item | Current state | Assessment |
|---|---|---|
| Android Gradle Plugin | 9.0.1 | Build berhasil |
| Kotlin Gradle Plugin | 2.3.20 | Build berhasil; plugin lama memberi warning built-in Kotlin |
| Gradle wrapper | 9.1.0 | Build berhasil |
| Java target | 17 | Sesuai build |
| compile SDK | 36 | Terverifikasi dari APK |
| target SDK | 36 | Terverifikasi dari APK |
| min SDK | 24 | Terverifikasi dari APK |
| Android application ID | `com.mikiezy.mikiezy` | Masih template-like; finalkan sebelum store |
| Android label | `mikiezy` | Lowercase; final branding sebaiknya `Mikiezy` |
| iOS bundle ID | `com.mikiezy.mikiezy` | Finalkan sebelum signing |
| Version | 1.0.0+1 | Cocok untuk kandidat internal awal |
| Android release signing | Debug key | Tidak production-ready |
| APK signature | v2, `CN=Android Debug` | Valid untuk internal test saja |
| Minify/resource shrink | Tidak dikonfigurasi eksplisit | Jangan ubah menjelang demo tanpa regression |
| Backup | `allowBackup=false`, `fullBackupContent=false` | Defensive |
| Exported components | Launcher activity saja yang exported | Sesuai audit manifest |
| Permissions | Internet, microphone, biometric | Relevan dengan fitur |
| Network security config | Tidak ada custom config | Audit lagi saat cloud sync aktif |
| iOS signing | Automatic, tanpa `DEVELOPMENT_TEAM` | Build/archive iOS BLOCKED di Windows |

Dependency runtime yang diaudit:

| Package | Resolved version |
|---|---|
| `speech_to_text` | 7.4.0 |
| `flutter_tts` | 4.2.5 |
| `local_auth` | 3.0.2 |
| `flutter_secure_storage` | 10.3.1 |
| `drift` | 2.33.0 |
| `permission_handler` | 12.0.1 |
| `url_launcher` | 6.3.2 |

Tidak ada dependency yang di-upgrade. Update minor tersedia untuk beberapa
package, tetapi tidak diperlukan untuk menutup bug demo yang ditemukan.

Android SDK 36.1 tersedia dan build berjalan. `flutter doctor` masih
melaporkan Android command-line tools/license state belum lengkap. Ini belum
memblokir build saat ini, tetapi harus dirapikan sebelum CI/release resmi.

## Safe Diagnostics

`SafeDiagnostics` hanya aktif pada `kDebugMode`. Transcript dicatat sebagai:

- jumlah karakter final, partial, dan combined;
- jumlah kata;
- fingerprint FNV-1a pendek delapan karakter;
- state, intent, route, permission, status, generation, dan durasi yang typed.

Transcript mentah, PIN, secure storage value, biometric data, token, saldo, dan
nilai finansial tidak dicetak oleh instrumentation baru. Verbose logging
internal `speech_to_text` dinonaktifkan pada controller dan wake-word manager
agar payload plugin lintas platform tidak menjadi sumber log mentah.

## Bug Register

| ID | Severity | Reproduction/root cause | Fix | Regression |
|---|---|---|---|---|
| P7A-001 | High | Exception saat meminta permission sebelumnya dianggap granted (`catch` fail-open) | Service permission typed dan fail-closed | Denied/error tidak pernah memulai STT |
| P7A-002 | High | Controller di-dispose saat request permission pending; callback lalu memanggil `notifyListeners` setelah dispose | Listening generation token dan disposed guard pada setiap continuation | Pending permission after dispose completes tanpa exception |
| P7A-003 | High | Callback status/sound/result native dapat datang setelah dispose; init manager dapat selesai terlambat | Callback dan continuation manager/controller mengabaikan generation/disposed state | Late native status dan pending manager permission aman |
| P7A-004 | Medium | Diagnostic lama dapat mencetak transcript voice mentah penuh | Metadata/hash-only diagnostics dan plugin verbose logging off | Captured debug output tidak mengandung transcript rahasia |
| P7A-005 | Medium | Permanent denial tidak mempunyai recovery action yang eksplisit dan feedback error dapat tidak tampil jelas | Typed message dan tombol settings hanya untuk permanent denial | Settings tidak dibuka otomatis; ordinary denial tidak dapat membukanya |

Navigation ganda diuji sebagai hipotesis bug. Dua request target yang sama
menghasilkan tepat satu `navigated` dan satu `alreadyThere`, sehingga tidak ada
runtime patch tambahan untuk navigation.

Tidak ada bug perangkat nyata yang dapat dicatat karena hardware test belum
dimulai.

## Validation by Area

| Area | Automated evidence | Hardware status |
|---|---|---|
| Installation/startup | Widget startup tests pass; APK built | NOT RUN |
| Microphone permission | Typed unit/regression tests pass | NOT RUN |
| STT/transcript accumulation | Buffer, final/partial, 30+ item parser tests pass | NOT RUN |
| Silence timeout | Timer unit tests and persisted setting tests pass | NOT RUN |
| TTS feedback loop | Lifecycle guards present | NOT RUN |
| Wake word | Variant, restart state, dispose tests pass | NOT RUN |
| Global overlay | Controller/widget lifecycle tests pass | NOT RUN |
| Voice transaction | Parser, fractional quantity, pack/carton, stock tests pass | NOT RUN |
| Business query | Metrics/privacy/query tests pass | NOT RUN |
| Navigation | Five navigation tests pass, including duplicate/background/disposed | NOT RUN |
| Clarification | Conversation/context tests pass | NOT RUN |
| PIN | Argon2id, cooldown, persistence, lifecycle tests pass | NOT RUN |
| Biometric | Fake adapter success/fail/cancel/fallback tests pass | NOT RUN |
| Phase 6A create product | Atomicity/confirmation/audit tests pass | NOT RUN |
| Phase 6B stock increment | Atomicity/idempotency/stale/undo-policy tests pass | NOT RUN |
| Phase 6C price update | Atomicity/history/idempotency/undo tests pass | NOT RUN |
| Drift migration | Fixture migrations through v6 pass in suite | BLOCKED for copied device DB |
| Restart persistence | Repository/Drift persistence tests pass | NOT RUN |
| Crash recovery | Async dispose regressions pass | NOT RUN |
| Runtime performance | Build duration recorded only | NOT RUN |

Passing automated tests prove deterministic application logic under test
doubles and fixtures. They do not prove OEM speech service behavior, acoustic
noise handling, biometric hardware, OS process death, storage pressure, or
database migration from a user's actual file.

## Build Evidence

### Debug

- Path: `build/app/outputs/flutter-apk/app-debug.apk`
- Size: 214,956,472 bytes
- SHA-256: `B5CE7E0DDF26F3073510BA981AC3F100425909A169DF1210AC262AEFF6F62F02`
- Final build duration: approximately 23.6 seconds
- Signature: APK Signature Scheme v2, `CN=Android Debug`

### Internal Release

- Path: `build/app/outputs/flutter-apk/app-release.apk`
- Size: 62,739,640 bytes
- SHA-256: `BC205B8DE2258830F4AAA6931450BFFB37BAE13092C828CDD2E123DEE1412CEF`
- Final build duration: approximately 75.7 seconds
- Signature: APK Signature Scheme v2, `CN=Android Debug`
- Status: internal candidate only, not production-ready

Release signing setup is documented in `docs/android_release_signing.md`.
Tidak ada keystore atau password yang dibuat/di-commit.

Build warning non-blocking:

```text
Your app uses the following plugins that apply Kotlin Gradle Plugin (KGP):
flutter_tts, speech_to_text, url_launcher_android
Future versions of Flutter will fail to build if your app uses plugins that
apply KGP.
```

Warning tidak memblokir build Flutter 3.44.4. Rekomendasi: evaluasi upgrade
ketiga plugin sebagai patch terpisah setelah demo, satu kelompok kecil, lalu
ulang full suite dan hardware matrix.

## Phase 7A Files

File baru:

- `docs/phase_7a_device_validation.md`
- `docs/phase_7a_validation_report.md`
- `docs/android_release_signing.md`
- `lib/services/diagnostics/safe_diagnostics.dart`
- `lib/services/voice/microphone_permission_service.dart`
- `test/safe_diagnostics_test.dart`
- `test/voice_permission_hardening_test.dart`

File existing yang disentuh khusus untuk hardening/instrumentation:

- `.gitignore`
- `lib/services/voice_assistant_controller.dart`
- `lib/services/voice/voice_assistant_manager.dart`
- `lib/services/voice/global_voice_controller.dart`
- `lib/services/navigation/app_navigation_service.dart`
- `lib/services/security/app_lock_controller.dart`
- `lib/services/voice/voice_action_coordinator.dart`
- `lib/screens/voice_entry_screen.dart`
- `test/app_navigation_service_test.dart`
- `test/voice_wake_word_test.dart`

Tidak ada package baru, schema change, generated-code regeneration, command
mutasi baru, rumus laporan baru, atau perubahan state management pada Phase 7A.

## Output Checklist 1-38

1. Baseline workspace: dirty lintas Phase 1-6C; 55 modified, 4 deleted, 88 untracked.
2. Device/OS diuji: host Windows saja; Android/iOS real device tidak tersedia.
3. Build diuji: 1.0.0+1, debug dan internal release Android.
4. APK hash: tercatat pada bagian Build Evidence.
5. Test matrix: 234 skenario di `docs/phase_7a_device_validation.md`.
6. Total pass/fail/blocked: automated 530/0/0; hardware 0/0/1 environment gate, 234 NOT RUN.
7. Microphone permission: regression otomatis PASS; hardware NOT RUN.
8. Transcript accumulation: buffer/parser otomatis PASS; acoustic STT NOT RUN.
9. Silence timeout: timer/persistence otomatis PASS; timing hardware NOT RUN.
10. TTS feedback: guard tersedia; engine/device NOT RUN.
11. Wake word: detector/lifecycle otomatis PASS; standby hardware NOT RUN.
12. Global overlay: widget/controller otomatis PASS; route/device matrix NOT RUN.
13. Voice transaction: domain/parser/persistence otomatis PASS; speech hardware NOT RUN.
14. Business query: metrics/privacy otomatis PASS; UI/TTS device NOT RUN.
15. Navigation: duplicate/background/disposed otomatis PASS; dialog/device NOT RUN.
16. Clarification: conversation tests PASS; voice hardware NOT RUN.
17. PIN: secure verifier/cooldown/lifecycle otomatis PASS; device UI NOT RUN.
18. Biometric: fake adapter PASS; hardware biometric NOT RUN.
19. Phase 6A: automated PASS; device flow NOT RUN.
20. Phase 6B: automated PASS; device flow NOT RUN.
21. Phase 6C: automated PASS; device flow NOT RUN.
22. Migration salinan database: fixture PASS; actual copied DB BLOCKED.
23. Crash recovery: dispose races fixed/tested; force-stop/storage scenarios NOT RUN.
24. Performance: build time tersedia; startup/STT/memory/jank NOT RUN.
25. Bug ditemukan: 2 High ter-reproduksi, 1 High preventive lifecycle, 2 Medium.
26. Root cause: fail-open permission, async callback tanpa generation/dispose guard, dan raw diagnostic logging.
27. File diperbaiki: tercatat pada bagian Phase 7A Files.
28. Regression baru: 11 test di atas baseline 519, total menjadi 530.
29. `flutter analyze`: PASS, no issues.
30. Seluruh test: 530/530 PASS.
31. `git diff --check`: PASS.
32. APK debug final: tersedia, hash dan ukuran tercatat.
33. APK release: tersedia untuk internal test, tetapi debug-signed.
34. Warning build: built-in Kotlin warning dari tiga plugin, non-blocking saat ini.
35. Risiko tersisa: seluruh hardware matrix, copied-DB migration, iOS, signing, app ID/label, dirty worktree.
36. Go/no-go demo: NO-GO sampai critical device matrix dan tiga smoke run lulus.
37. Go/no-go release: NO-GO sampai signing, identity, iOS/Android hardware, migration, dan release checklist lulus.
38. Phase 7B: HOLD; setelah GO, lanjut stock movement ledger dan transaction reversal lifecycle.

## Manual Gate Before Demo

Gunakan database uji baru, install APK dengan hash di atas, lalu:

1. Jalankan permission deny, permanent deny, settings return, dan revoke.
2. Jalankan transcript tiga bagian dengan jeda 1-2 detik.
3. Uji wake-word foreground 15+ menit dan pastikan background/locked tidak listening.
4. Uji TTS tidak kembali menjadi input STT.
5. Uji transaction satu item, multi-item, 30+ item, pecahan, pack, dan karton.
6. Tekan save/confirm dua kali untuk memastikan mutasi hanya satu kali.
7. Uji PIN, biometric cancel/fail/success, fallback, dan lifecycle background.
8. Migrasikan salinan database lama setelah backup dan bandingkan count/record.
9. Force-stop pada listening, preview, confirmation, commit, TTS, dan auth.
10. Jalankan smoke demo lengkap tiga kali dan isi evidence matrix.

Phase 7B baru layak dimulai setelah test Critical/High untuk flow demo berstatus
PASS, tidak ada data mismatch, copied database migration lulus, dan tiga smoke
run stabil.
