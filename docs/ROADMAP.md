# Roadmap and Approval Gates

- VERIFIED: Dokumen ini mengurutkan pekerjaan yang diketahui dan usulan. Nomor migrasi M0-M8 berbeda dari feature Phase 7A/7B; jangan menyamakan keduanya.
- REPORTED: Pemilik mengotorisasi M1 berupa delapan dokumen, kemudian M1.1 berupa koreksi terbatas AGENTS.md dan ROADMAP.md. Tidak ada persetujuan untuk menjalankan langkah berikutnya otomatis.

| Tahap | Evidence | Scope / exit condition |
|---|---|---|
| Phase 7A source baseline | VERIFIED | Commit 3680e1a adalah baseline historis; bukan kewajiban agar HEAD selamanya sama. Schema v6 dan integritas source tetap dijaga |
| Phase 7A validation | REPORTED | 530 tests/analyze/build lulus historis; hardware/demo gates belum selesai |
| M0: Repository Audit | REPORTED | Selesai; audit read-only telah disampaikan, tidak membuat laporan file |
| M1: Context Handoff | VERIFIED | Selesai setelah koreksi dokumentasi M1.1; delapan dokumen ditulis setelah persetujuan eksplisit, belum commit/push |
| Penerimaan handoff | PROPOSED | Pemilik review dokumen, unknown, dan batas izin sebelum melanjutkan migrasi |
| M2: Safe Migration Preparation | REPORTED | Rencana pemilik: backup, checkpoint, dan workspace Git worktree; belum dikerjakan dan perlu izin eksekusi |
| M3: Antigravity Environment | REPORTED | Rencana pemilik: instalasi, izin agent, dan Dart/Flutter tooling; belum dikerjakan dan perlu izin eksekusi |
| M4: Migration Verification | REPORTED | Rencana pemilik: verifikasi environment, tests, analyze dan build; cocokkan baseline historis/lockfile/toolchain dan catat hasil baru setelah izin |
| M5: Controlled Pilot | REPORTED | Rencana pemilik: tugas kecil dengan review, setelah verifikasi migrasi; belum dikerjakan |
| M6: AI Research Planning | REPORTED | Rencana pemilik: dataset, baseline, metodologi dan evaluasi; keputusan penelitian final masih perlu persetujuan |
| M7: UI/UX Design System & Progressive Refinement | REPORTED | Rencana pemilik: design system dan penyempurnaan UI/UX bertahap; bukan kewajiban redesign keseluruhan |
| M8: Hybrid AI Implementation & Evaluation | REPORTED | Rencana pemilik: implementasi dan evaluasi hybrid AI hanya setelah scope penelitian disetujui; belum dikerjakan |
| Device stabilization | PROPOSED | Reproduksi KI-01; jalankan matrix kritis, migration DB salinan dan tiga smoke run pada DB uji |
| Phase 7B | REPORTED | Rekomendasi terdahulu: stock movement ledger, lifecycle/cancel transaction, reversal stok/wallet, idempotent cancellation dan audit; mulai hanya setelah demo GO |
| Production integrations | REPORTED | Auth, sync, OCR, upload bukti, thermal printer, file export/share penuh masih roadmap; urutan/tanggal final belum diputuskan |
| Research evaluation | PROPOSED | Mendukung M6/M8: rumusan masalah/dataset/metrik disetujui sebelum eksperimen rule-based vs LLM vs hybrid |

- REPORTED: Setelah stabilisasi, pengembangan UI/UX dan penelitian AI boleh berjalan paralel. Urutan nomor M6/M7 tidak menjadikan redesign keseluruhan sebagai prasyarat penelitian; M8 tetap bergantung pada persetujuan scope penelitian.

## Constraints to carry forward

- REPORTED: Jangan lanjut Supabase sync sebelum local data, mutation queue, sync status dan conflict policy dirapikan. Schema SQL sendiri belum memenuhi gate.
- REPORTED: Jangan mengaktifkan pengurangan/set stok, cancellation/delete melalui voice sebelum ledger/reversal dan safety terkait tersedia.
- PROPOSED: Upgrade dependency/KGP, finalisasi signing/app ID, enkripsi/retention, dan iOS validation ditangani sebagai scope terpisah dengan bukti regression.
- PROPOSED: Perbaiki inkonsistensi README melalui izin dokumentasi lanjutan; laporan Phase 7A tetap menjadi evidence historis, bukan ditimpa sebagai hasil baru.
- VERIFIED: Belum ada tanggal release, pilihan LLM, backend auth final, model sync conflict resolution, atau environment Antigravity yang disepakati. Tidak ada estimasi jadwal yang bisa dinyatakan sebagai keputusan lama.
