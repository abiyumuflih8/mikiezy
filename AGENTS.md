# Mikiezy Agent Instructions

- REPORTED: Pemilik mengizinkan penulisan delapan dokumen handoff M1 pada 2026-10-24. Izin ini bukan izin perubahan aplikasi atau kelanjutan M2.
- VERIFIED: Baseline historis Phase 7A adalah commit `3680e1ae1f8c8e890e57553224855a8a03e44733`, branch `master`, versi aplikasi 1.0.0+1. Ini titik pembanding historis, bukan kewajiban agar HEAD selamanya sama; pekerjaan berikutnya yang disetujui boleh menghasilkan commit baru.
- REPORTED: Baca `AGENTS.md` sebagai aturan utama. Baca `docs/PROJECT_HANDOFF.md` saat onboarding atau membutuhkan konteks umum.
- REPORTED: Baca `docs/ARCHITECTURE.md`, `docs/DECISIONS.md`, `docs/FEATURE_INVENTORY.md`, `docs/KNOWN_ISSUES.md`, `docs/RESEARCH_ALIGNMENT.md`, dan `docs/ROADMAP.md` hanya saat relevan dengan tugas.
- REPORTED: Gunakan progressive disclosure: jangan memuat seluruh dokumentasi dan source code untuk tugas kecil tanpa alasan; baca bagian dan file yang diperlukan, lalu perluas jika temuan membutuhkan konteks tambahan.
- REPORTED: Scope aplikasi adalah POS/pembukuan UMKM offline-first dengan pemahaman transaksi Bahasa Indonesia; konteks akademis adalah skripsi peminatan AI.
- VERIFIED: Runtime menggunakan custom ChangeNotifier/InheritedNotifier, repository native Drift/SQLite v6, dan voice NLP berbasis aturan/heuristik.
- REPORTED: Pemilik meminta perubahan bertahap, alasan teknis jelas, tanpa refactor besar atau pergantian state management secara sepihak.
- REPORTED: Pertahankan schema v6, migration compatibility, snapshot harga/modal/multiplier, atomic write, idempotency, stale guard, confirmation, authentication, dan privacy.
- REPORTED: Jangan aktifkan mutasi voice baru, delete/cancel, pengurangan/set stok, bulk update, atau cloud sync tanpa scope dan persetujuan baru.
- VERIFIED: Tiga mutasi aktif di `lib/main.dart`: create product, increment stock, update product price. Default flag coordinator sendiri adalah false.
- REPORTED: Jangan gunakan model/LLM untuk langsung menulis database atau melewati domain validation dan confirmation.
- REPORTED: Minta persetujuan untuk schema/dependency/state-management changes, instalasi tool, operasi Git yang mengubah history, dan pengiriman data bisnis ke layanan luar.
- REPORTED: Jangan reset/clean/revert perubahan pengguna, menghapus database, force-push, membuat credential, atau memindahkan signing key secara otomatis.
- REPORTED: Jangan commit APK/AAB, database/WAL/SHM, env, key.properties, signing key, local.properties, log sensitif, atau dokumen pribadi yang diabaikan Git.
- VERIFIED: `VoiceCorrections.rawText` dapat menyimpan ucapan lokal; jangan unggah database atau menganggap learning sebagai dataset penelitian yang sudah disetujui.
- VERIFIED: `SafeDiagnostics` membatasi log baru; jalur exception lain belum semuanya direduksi. Jangan tampilkan payload exception sensitif.
- REPORTED: Gunakan VERIFIED untuk inspeksi langsung dengan batas scope, REPORTED untuk hasil historis/keputusan pemilik, PROPOSED untuk rencana. Tulis unknown secara eksplisit.
- REPORTED: Phase 7A melaporkan 530/530 tests, analyze bersih, dan build Android sukses. Jangan mengubahnya menjadi hasil test baru tanpa menjalankan test.
- VERIFIED: Hardware matrix mencatat 234 skenario NOT RUN dan smoke test 0/3. Demo/release belum memiliki bukti GO.
- PROPOSED: Setelah test diizinkan, jalankan targeted tests sesuai perubahan, kemudian full suite/analyze untuk perubahan berisiko; catat versi toolchain dan hasil sebenarnya.
- REPORTED: Pada audit read-only atau draft-only, jangan menjalankan pub get, test, build, format, build_runner, instalasi, atau operasi Git yang menulis workspace tanpa izin.
- PROPOSED: Untuk perubahan schema yang kelak disetujui, tambahkan migration tests dan uji salinan DB pengguna dengan backup; jangan destructive fallback.
- VERIFIED: README dan laporan lama mengandung snapshot konteks yang tertinggal; source adalah rujukan runtime utama, bukan alasan mengubah laporan historis.
- REPORTED: Selesaikan hanya tahap yang diminta; M1 tidak mengotorisasi M2, instalasi Antigravity, commit, atau push.

## Aturan Kontinuitas & Konteks Jangka Panjang

- REPORTED: **READ PROJECT STATE BEFORE MAJOR WORK**: Untuk perubahan besar, fitur baru, refactor, migrasi, perubahan skema database, atau keputusan arsitektur, baca `docs/PROJECT_STATE.md` terlebih dahulu sebagai kebenaran operasional kanonikal.
- REPORTED: **REUSE BEFORE REBUILD**: Selalu periksa dan manfaatkan arsitektur, state, service, komponen UI, dan utility existing sebelum membuat fungsi atau abstractions baru.
- REPORTED: **VERIFY EXISTING FEATURES BEFORE IMPLEMENTING**: Pastikan status fitur pada `docs/FEATURE_INVENTORY.md` dan `docs/PROJECT_STATE.md` sebelum mengasumsikan suatu kapabilitas belum ada.
- REPORTED: **NEVER ASSUME MISSING CONTEXT MEANS MISSING CODE**: Ketiadaan konteks dalam sesi aktif bukan bukti ketiadaan kode pada codebase; lakukan pencarian selektif sebelum menyimpulkan.
- REPORTED: **DISTINGUISH VERIFIED, REPORTED, NOT TESTED, AND UNVERIFIED**: Gunakan penandaan epistemik yang ketat. Jangan menyamakan pengujian otomatis, build lokal, atau inspeksi statis dengan pengujian perangkat fisik.
- REPORTED: **AVOID UNNECESSARY REPEATED TESTS**: Hindari menjalankan ulang test suite penuh atau build tanpa alasan diagnostik terarah atau perubahan kode yang relevan.
- REPORTED: **PRESERVE EXISTING ARCHITECTURE AND DATA**: Pertahankan custom notifier/InheritedNotifier, skema database Drift v6, dan sifat offline-first aplikasi.
- REPORTED: **PROTECT PRIVATE DATA AND CREDENTIALS**: Jaga kerahasiaan PIN, hash verifier, path personal, rekaman suara, dan data transaksi bisnis lokal.
- REPORTED: **DO NOT COMMIT, PUSH, DEPLOY, OR DELETE WITHOUT APPROVAL**: Seluruh mutasi Git, instalasi ke perangkat, penghapusan file, dan modifikasi dependency wajib mendapatkan otorisasi eksplisit pemilik.
- REPORTED: **PRIORITIZE REAL USER-VISIBLE PROGRESS**: Utamakan kemajuan fungsional nyata yang dapat diverifikasi dibandingkan over-engineering atau refactor kosmetik.
- REPORTED: **PROGRESSIVE DISCLOSURE ACTIVATION**: Terapkan pembacaan dokumen berlapis. Untuk tugas kecil atau pertanyaan spesifik, selesaikan secara terarah tanpa memuat ulang seluruh arsip dokumentasi.
