# Decisions and Provenance

- VERIFIED: Dokumen ini membedakan keputusan pemilik yang tersedia dalam percakapan dari pilihan implementasi yang hanya dapat dibuktikan lewat source. Tidak ada ADR lama atau history per phase yang membuktikan semua motivasi awal.

| ID | Status/sumber | Keputusan atau pilihan | Alasan yang diketahui / batas bukti |
|---|---|---|---|
| D01 | REPORTED: instruksi pemilik | Fondasi data lebih dahulu; perubahan bertahap, tanpa mengganti state management | Akurasi transaksi/stok/laporan dan risiko regression menjadi prioritas |
| D02 | VERIFIED: main.dart, app_state.dart | Custom notifier dan scope tetap runtime | Bukti implementasi; bukan klaim bahwa alternatif telah dibenchmark |
| D03 | VERIFIED: repository factory, core/database | Drift/SQLite canonical, v6; compatibility export tetap ada | Hindari salah memilih schema lama; alasan cleanup didukung konteks percakapan |
| D04 | REPORTED: instruksi pemilik; VERIFIED: model/domain | Quantity pecahan dan multiplier pack/carton dari metadata | Memperbaiki pembulatan dan multiplier hardcoded yang pernah dilaporkan |
| D05 | REPORTED: instruksi pemilik; VERIFIED: data source/tests | Atomic write, snapshot historis, duplicate/stale guard | Mencegah data parsial, mutasi ganda dan perubahan laba historis |
| D06 | REPORTED: batas fase; VERIFIED: flags | Hanya create product, increment stock, update price voice aktif | Delete/cancel, pengurangan/set stok dan bulk update menunggu fondasi ledger/reversal |
| D07 | VERIFIED: coordinator/security | Preview dan confirmation mendahului mutation; auth requirement tidak boleh dilewati | Pilihan implementasi yang menjaga batas eksekusi; hardware evidence belum lengkap |
| D08 | REPORTED: Phase 7A; VERIFIED: permission/controller | Permission fail-closed, generation/disposed guards, diagnostic teredaksi | Menutup fail-open dan async lifecycle race yang tercatat pada Phase 7A |
| D09 | REPORTED: instruksi pemilik | Tunda Supabase sync sampai local data, mutation queue dan sync status siap | Schema SQL bukan integrasi cloud runtime |
| D10 | REPORTED: klarifikasi pemilik | Identitas profil seed adalah dummy | Tidak berarti database pengguna atau transcript boleh dipublikasikan |
| D11 | REPORTED: persetujuan M1 2026-10-24 | Tulis delapan dokumen gabungan sekarang | Tidak mengizinkan perubahan source, test, schema, instalasi, commit/push atau M2 |
| D12 | PROPOSED | Pertahankan model/LLM kelak hanya sebagai penghasil struktur kandidat | Integrasi tetap melewati validator, resolver, preview, confirmation dan executor deterministik |

## Historical fixes

- REPORTED: Percakapan dan laporan Phase 7A mencatat perbaikan quantity pecahan, metadata pack/carton, stock-on-sale, transcript accumulation, filler/multi-item parsing, wake-word variants/restart, analitik, dan voice action safety. Commit gabungan tidak memberi attribution per perubahan.
- VERIFIED: Regression tests dan source mendukung keberadaan mekanisme tersebut; M1 tidak mereproduksi bug lama atau menjalankan test.
- REPORTED: Register Phase 7A mencatat permission fail-open, pending permission after dispose, late STT callbacks, raw transcript logging dan recovery permanent denial. Lihat laporan asli untuk severity dan hasil historis.
- VERIFIED: Potensi TTS stop di M0 masih temuan statis, bukan perbaikan selesai. Jangan masukkan ke daftar fixed.

## Change boundaries

- REPORTED: Jangan mengubah schema/migration, financial snapshots, confirmation, security, feature flags atau state framework tanpa scope baru.
- PROPOSED: Proposal perubahan harus menyebut trigger masalah, invariant terdampak, perubahan minimum, regression evidence, dan rollback yang tidak menghapus data.
- VERIFIED: Motivasi pemilihan threshold NLP, detail kebutuhan dosen, pilihan model/dataset, dan target Antigravity version belum diketahui. Jangan mengisinya sebagai keputusan final.
