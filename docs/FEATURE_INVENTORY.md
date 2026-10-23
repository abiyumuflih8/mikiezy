# Feature Inventory

- VERIFIED: Status implemented berarti jalur kode tersedia, bukan sertifikasi produksi atau hardware PASS. Partial/prototype berarti batas runtime masih penting; planned berasal roadmap yang dilaporkan; deprecated berarti bukan jalur utama.

| Fitur | Evidence | Status | Source / batas |
|---|---|---|---|
| POS/manual sale, expense, income | VERIFIED | implemented | screens/preview_transaction_screen.dart, state/app_state.dart; review sebelum save |
| Quantity pecahan, pack/carton, stock-on-sale | VERIFIED | implemented | models, domain/services, state, data source; metadata/unit validation harus dipertahankan |
| Produk, wallet, kategori | VERIFIED | implemented | screens/products_screen.dart, finance_screen.dart; repository CRUD |
| Dashboard, reports/analitik, bar selection | VERIFIED | implemented | dashboard_screen.dart, reports_screen.dart, widget tests; device performance belum dibuktikan |
| Struk | VERIFIED | implemented | screens/receipt_screen.dart; thermal printer/share struk belum integrasi penuh |
| Offline persistence native | VERIFIED | implemented | Drift v6; web memory-only |
| STT/TTS Bahasa Indonesia | VERIFIED | partial | plugin terpasang; hardware reliability dan KI-01 belum tervalidasi |
| Wake word Miki/varian | VERIFIED | partial | wake_word_detector.dart, voice_assistant_manager.dart; foreground, bukan dedicated trained wake model |
| Multi-item, accumulation, silence timeout | VERIFIED | implemented | controller, Parser V2, global controller; hasil STT nyata tetap unknown |
| Product resolver / adaptive aliases | VERIFIED | implemented | resolver, context, dictionary, state learning; bukan retraining model |
| Query bisnis/privacy/navigation | VERIFIED | implemented | business query handler, metrics, privacy guard, navigation service |
| Clarification/dialogue context | VERIFIED | implemented | clarification/conversation modules; expiry dan invalid answer policy |
| Tambah produk, tambah stok, ubah harga voice | VERIFIED | implemented | tiga flags aktif dan executors terdaftar di main.dart |
| Price undo internal | VERIFIED | implemented | voice_price_update_undo_service.dart; jangan dianggap command voice umum |
| Stock undo / cancellation ledger | VERIFIED | partial | undo policy membatasi; ledger/reversal belum tersedia |
| PIN/biometric app lock | VERIFIED | implemented | services/security dan lock gate; hardware test belum dilakukan ulang |
| Login/register cloud | VERIFIED | prototype | AuthScreen menyatakan auth produksi belum aktif |
| Supabase/cloud sync | VERIFIED | prototype | supabase/schema.sql, settings/status; tidak ada client runtime |
| Share laporan WhatsApp | VERIFIED | partial | report_action_service.dart membuka wa.me, fallback clipboard; bukan receipt sharing penuh |
| Export laporan/data | VERIFIED | partial | clipboard text/CSV bundle; belum file export/share sheet penuh |
| OCR, upload bukti, thermal printer | REPORTED | planned | konteks roadmap; jangan menganggap UI sebagai integrasi selesai |
| Legacy parser | VERIFIED | deprecated/main-path alternative | services/voice_transaction_parser.dart masih dipakai test tertentu; runtime utama Parser V2 |
| Old local database schema | VERIFIED | deprecated/removed | dihapus baseline; local/mikiezy_repository.dart hanya re-export |
| LLM runtime/trained intent model | VERIFIED | not found | tidak ditemukan pada inspected source/dependencies; pilihan implementasi berikutnya belum final |

- REPORTED: Semua hasil PASS tetap mengacu validasi Phase 7A, bukan eksekusi fitur nyata pada M1. Detail test dan blocker: PROJECT_HANDOFF.md dan KNOWN_ISSUES.md.
