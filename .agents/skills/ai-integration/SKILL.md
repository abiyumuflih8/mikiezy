---
name: ai-integration
description: Panduan arsitektur AI terkontrol, pemisahan jalur transaksi vs mutasi, keamanan privasi, dan metodologi evaluasi penelitian skripsi Mikiezy.
---

# Controlled AI Integration & Research Evaluation Guide

Panduan ini mengatur perancangan, integrasi terkontrol, dan evaluasi penelitian AI (Rule-Based, LLM, Hybrid) pada Mikiezy. Melengkapi `AGENTS.md`, Karpathy Rule, dan Official Flutter Skills tanpa menggantikannya.

## 1. Arsitektur Terkontrol & Pemisahan Dua Jalur Operasional
Model AI hanya bertindak sebagai *candidate generator* yang menghasilkan structured DTO (bukan pengeksekusi tindakan). Model dilarang menulis langsung ke SQLite/Drift atau mengakses tool execution secara otomatis. Pemetaan schema, adapter, dan validasi DTO AI ke sistem internal wajib dirancang dan diuji eksplisit.

- **Jalur A — Transaksi Finansial (Penjualan/Pengeluaran/Pemasukan)**:
  `Candidate DTO` $\rightarrow$ pemetaan adapter & validasi domain $\rightarrow$ resolusi produk (`VoiceProductResolver`) $\rightarrow$ perakitan `TransactionDraft` $\rightarrow$ verifikasi kasir di `lib/screens/preview_transaction_screen.dart` $\rightarrow$ commit atomik melalui repository transaksi berintegritas.
- **Jalur B — Mutasi Master Data Suara (Produk/Stok/Harga)**:
  `Candidate Action` $\rightarrow$ validasi awal $\rightarrow$ `VoiceActionCoordinator` (`lib/services/voice/voice_action_coordinator.dart`) $\rightarrow$ evaluasi feature flags, confirmation dialog, stale guard, fingerprint anti-duplikasi, auth check $\rightarrow$ eksekusi melalui executor terdaftar dan pencatatan audit.

## 2. Integritas Domain Finansial & Resolusi Data
- Identitas produk, harga katalog, dan konversi satuan harus diverifikasi terhadap sumber data lokal yang tepercaya. Nominal transaksi yang diberikan langsung oleh pengguna (misalnya pengeluaran, pemasukan, atau harga manual yang diizinkan) merupakan input kandidat yang wajib divalidasi sesuai aturan domain dan diperiksa melalui preview. AI dilarang mengarang `productId`, harga, atau nominal yang tidak berasal dari input pengguna maupun sumber data sah.
- `VoiceParseValidator` (`lib/services/voice/voice_parse_validator.dart`) memvalidasi struktur hasil parse dan menghitung confidence heuristik (bukan validator JSON universal).
- `ProductValidator` (`lib/domain/services/product_validator.dart`) memvalidasi keabsahan data entitas produk, bukan seluruh transaksi finansial.
- Hasil ambigu atau item tidak terdaftar pada `VoiceProductResolver` (`lib/services/voice/voice_product_resolver.dart`) wajib diarahkan ke sesi klarifikasi atau layar pratinjau, bukan disimpan otomatis.

## 3. Privasi, Kredensial, dan Reliabilitas Runtime
- **Untrusted Input**: Seluruh transkrip suara dan respons model diperlakukan sebagai input tidak tepercaya; cegah instruksi berbahaya memanipulasi alur transaksi.
- **Keamanan Kredensial**: Dilarang menyimpan API key AI di dalam repositori, source code Flutter, atau paket APK/AAB. Evaluasi backend perantara yang aman jika integrasi cloud disetujui.
- **Minimisasi Data**: Dilarang mengirim data UMKM, identitas pribadi, atau transkrip asli ke pihak ketiga untuk eksperimen tanpa kebijakan privasi dan persetujuan jelas.
- **Reliability & Fallback**: Wajib menetapkan skema terstruktur ketat, validasi tipe/rentang, batas timeout, pembatasan retry, dan fallback eksplisit ke parser teks deterministik saat jaringan/model gagal. Kemampuan STT tetap bergantung pada engine perangkat dan tidak dijamin 100% offline.

## 4. Metodologi Penelitian Skripsi & Evaluasi Ilmiah
- **Preservasi Baseline**: Pipeline *rule-based* V2 saat ini dibekukan per commit sebagai baseline ilmiah pembanding.
- **Isolasi Evaluasi**: Pisahkan evaluasi ASR/STT (WER/CER) dari evaluasi pemahaman bahasa (NLU).
- **Integritas Dataset**: Gunakan dataset teranotasi dengan isolasi ketat antar split (train/dev/test) untuk mencegah kebocoran pembicara, kalimat, dan skenario. Dilarang mengoptimasi prompt/model menggunakan test set. Tabel `VoiceCorrections` adalah memori lokal pengguna, bukan ground truth terverifikasi.
- **Metrik Komparasi Objektif**: Bandingkan rule-based, LLM, dan hybrid secara konsisten dengan metrik: *Intent Macro-F1*, *Slot F1*, *Exact Transaction Match*, *Unsafe Mutation Rate*, *Hallucination*, *Item Omission*, *Latency*, dan *Inference Cost*.
- **Transparansi Metrik**: Laporkan keyakinan parser saat ini sebagai skor heuristik, bukan probabilitas statistik model terlatih. Pemilihan metodologi penelitian final wajib disetujui pembimbing skripsi.
