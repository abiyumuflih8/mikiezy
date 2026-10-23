# Mikiezy Project Handoff

## Evidence and scope

- VERIFIED (2026-10-24): M1 memeriksa source lokal, Git, dokumen, dan hash APK melalui pembacaan file. Tidak menjalankan analyze, test, build, dependency installation, atau operasi Git mutasi.
- REPORTED: Pemilik secara eksplisit menyetujui penulisan delapan dokumen gabungan M1. Persetujuan menggantikan larangan menulis pada lampiran draft-only, tanpa memperluas scope ke aplikasi/M2.
- VERIFIED: Label VERIFIED berarti bukti langsung dalam scope yang disebut; REPORTED berarti hasil historis atau pernyataan pemilik; PROPOSED berarti rekomendasi belum disetujui. Unknown tidak boleh diisi dengan dugaan.
- VERIFIED: Baseline source sebelum dokumentasi bersih: master, commit `3680e1ae1f8c8e890e57553224855a8a03e44733`, 306 tracked files, tanpa staged/unstaged/nonignored untracked. Origin terkonfigurasi ke `https://github.com/abiyumuflih8/mikiezy.git`.
- REPORTED: Push baseline telah diverifikasi pada percakapan sebelumnya. M1 tidak mengecek jaringan/remote terkini.

## Product and current state

- REPORTED: Mikiezy adalah prototype POS/pembukuan UMKM dan aplikasi skripsi peminatan AI. Kandidat fokus riset adalah pemahaman perintah transaksi Bahasa Indonesia.
- VERIFIED: Aplikasi menyediakan penjualan manual/voice, pengeluaran/pemasukan, produk/stok, dompet/kategori, laporan/analitik, struk, local persistence, app lock, serta query/navigasi voice. Lihat [inventory](FEATURE_INVENTORY.md) untuk batas setiap fitur.
- VERIFIED: Flutter/Dart dengan custom notifier; native persistence Drift/SQLite v6. Web memakai memory repository, sehingga bukan bukti persistence native.
- VERIFIED: Voice memakai STT/TTS plugin serta NLP lokal rule-based. Tidak ditemukan LLM runtime, model training pipeline, atau dataset riset pada source yang diperiksa.

## Main workflows

- VERIFIED: Startup `lib/main.dart` membuka repository, membuat seeded state, hydrate data lokal dan initialize app lock, lalu menghubungkan navigation dan voice root.
- VERIFIED: Transaksi manual/voice menuju `preview_transaction_screen.dart`; user mengoreksi item/quantity/harga, lalu state menghitung transaksi dan stok sebelum repository menyimpan graph secara atomik. Learning dijalankan setelah transaksi tersimpan; kegagalan learning tidak boleh dianggap kegagalan commit transaksi.
- VERIFIED: Query bisnis menggunakan business metrics/privacy; command navigasi memakai navigation service. Command ini tidak diperlakukan sebagai transaksi secara otomatis.
- VERIFIED: Tambah produk/stok/ubah harga melalui ekstraksi, clarification jika perlu, preview, confirmation, pemeriksaan keamanan/fingerprint, executor, repository commit dan audit. Perubahan ekstrem harga dapat memerlukan confirmation tambahan.
- VERIFIED: Global voice berkoordinasi dengan wake-word manager untuk pause/resume. Generation/disposed guards dan timer membatasi callback lama; perilaku OEM tetap memerlukan hardware test.

## Validation evidence

- REPORTED: `phase_7a_validation_report.md` bertanggal 2026-07-24 mencatat Flutter 3.44.4, Dart 3.12.2, 530/530 test PASS, analyze no issues, diff check PASS, dan dua build Android sukses. Ini bukan hasil eksekusi M1.
- VERIFIED: 47 tracked test files tersedia; suite mencakup parser, domain, repository, migration, action atomicity/idempotency/history, permission, lock, navigation, overlay, dan widget.
- VERIFIED: APK lokal ditemukan dan SHA-256/ukuran cocok dengan laporan: debug 214956472 bytes, `B5CE7E0DDF26F3073510BA981AC3F100425909A169DF1210AC262AEFF6F62F02`; release 62739640 bytes, `BC205B8DE2258830F4AAA6931450BFFB37BAE13092C828CDD2E123DEE1412CEF`.
- REPORTED: Signature kedua APK adalah Android Debug. VERIFIED: Gradle release memang memilih debug signing. M1 tidak mengulang verifikasi sertifikat.
- VERIFIED: Matrix perangkat mencatat 234 skenario belum dijalankan dan smoke demo 0/3. REPORTED: Demo/release NO-GO; migration salinan database nyata dan iOS belum tervalidasi.
- VERIFIED: Hash APK membuktikan kecocokan artefak, bukan installability, keberhasilan test saat ini, atau reproducible build pada mesin baru.

## Toolchain and handoff

- VERIFIED: `pubspec.yaml` menetapkan Dart ^3.12.0 dan versi app 1.0.0+1; dependency dan lockfile harus dibawa bersama. Daftar dependency ada di [architecture](ARCHITECTURE.md).
- REPORTED: Toolchain Android terakhir: AGP 9.0.1, KGP 2.3.20, Gradle 9.1.0, Java target 17; SDK APK min 24/target 36/compile 36. Warning plugin KGP non-blocking pada build terdahulu.
- VERIFIED: Riwayat lokal hanya dua commit: `db61df4` (upload awal) dan baseline Phase 7A. Tidak tersedia checkpoint per phase; alasan historis jangan direkonstruksi seolah-olah dari commit granular.
- PROPOSED: Penerima membaca AGENTS, dokumen ini, architecture, decisions, inventory, known issues, research alignment, lalu roadmap. Cocokkan HEAD dan toolchain sebelum perintah yang menulis workspace.
- PROPOSED: Handoff source boleh dilanjutkan; klaim kompatibilitas Antigravity, installability, hardware reliability, dan production readiness menunggu verifikasi yang disetujui.
- VERIFIED: Risiko terpenting dan unknown dirinci di [known issues](KNOWN_ISSUES.md); rencana berikutnya bukan izin eksekusi otomatis, lihat [roadmap](ROADMAP.md).
