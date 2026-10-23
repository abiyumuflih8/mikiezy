# Known Issues and Verification Gaps

| ID | Evidence | Temuan | Dampak / next verification |
|---|---|---|---|
| KI-01 | VERIFIED: audit statis | Global stop/background/lock memanggil engine.cancelListening; controller.cancelListening membatalkan STT tetapi tidak TTS; interface engine tidak punya stopSpeaking | Potensi TTS tetap berbicara. PROPOSED: reproduksi saat speaking lalu stop/Home/lock; belum bug hardware terkonfirmasi |
| KI-02 | VERIFIED | README menyebut mutation execution disabled, tetapi main.dart mengaktifkan tiga flags | Agent dapat salah memahami safety boundary; PROPOSED: sinkronkan README dalam scope dokumentasi berikutnya |
| KI-03 | VERIFIED | Laporan Phase 7A menyimpan snapshot worktree dirty sebelum commit | Historis valid; jangan dianggap kondisi Git saat ini atau dihapus untuk membuat hasil tampak baru |
| KI-04 | VERIFIED | 234 hardware scenarios dan smoke 0/3 masih NOT RUN pada matrix | REPORTED: demo/release NO-GO; device saat ini belum dicek M1 |
| KI-05 | VERIFIED: Gradle; REPORTED: signer APK | Release memakai debug signing | Internal candidate saja; signing produksi dan identitas app perlu finalisasi pemilik |
| KI-06 | VERIFIED | Sejumlah executor/query/report handler masih log exception lengkap | Payload error mungkin membawa data sensitif; tidak ada bukti kebocoran aktual dari M1. Jangan kirim log tanpa redaksi |
| KI-07 | VERIFIED | Native SQLite tanpa konfigurasi encryption; VoiceCorrections dapat menyimpan rawText | App lock bukan database encryption. Retention/deletion/export consent untuk learning belum ditetapkan |
| KI-08 | VERIFIED | Auth backend dan cloud sync belum terintegrasi runtime | Placeholder queue/status tidak membuktikan durable mutation queue atau conflict resolution |
| KI-09 | REPORTED | Plugin flutter_tts, speech_to_text, url_launcher_android memberi warning KGP pada build historis | Upgrade terpisah setelah evaluasi, bukan mass upgrade untuk handoff |
| KI-10 | REPORTED | Migration fixture PASS, actual copied-device DB migration belum diuji; iOS build/hardware belum tervalidasi | Uji backup/salinan; jangan destructive fallback atau klaim siap iOS |
| KI-11 | VERIFIED | Web repository memory-only; native memakai Drift | Web demo tidak memvalidasi restart persistence/secure-storage/STT native |
| KI-12 | VERIFIED | Tidak ditemukan pinned Flutter version file pada pencarian M0/M1 | Toolchain drift pada mesin baru; historical SDK bukan bukti SDK aktif di Antigravity |

## Unknowns

- VERIFIED: Belum tersedia bukti M1 untuk perangkat/OS target, SDK aktif Antigravity, login provider produksi, cloud sync design final, retention policy, atau dataset riset yang disetujui.
- REPORTED: Security audit sebelum commit tidak menemukan pola credential dan pemilik mengonfirmasi seed profile dummy; ini bukan jaminan semua ignored file aman dibagikan.
- PROPOSED: Backup database nyata dilakukan pemilik; hanya salinan yang diizinkan digunakan untuk migration test. Jangan menaruhnya pada Git, prompt agent, atau layanan luar.
- PROPOSED: Bedakan severity risiko dari hasil reproduksi. Tidak ada defect hardware baru yang dinyatakan confirmed dalam M1.
