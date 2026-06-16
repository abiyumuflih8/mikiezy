# Mikiezy

Mikiezy adalah prototype aplikasi mobile Flutter untuk UMKM. Fokus awalnya adalah pencatatan penjualan dan pengeluaran dengan konsep voice assistant, laporan laba/rugi, kelola barang, kelola dompet, struk transaksi, dan arsitektur offline-first yang siap disinkronkan ke Supabase.

## Fitur MVP

- Dashboard penjualan, pengeluaran, laba/rugi, dan dompet.
- Simulasi input suara Bahasa Indonesia untuk penjualan, pemasukan, pengeluaran, modal masuk, diskon, retail, dan grosir.
- Preview transaksi yang bisa diedit sebelum disimpan.
- Kelola barang dengan harga modal, harga retail, harga grosir, stok pcs, pack, dan karton.
- Kelola dompet dan kategori pemasukan/pengeluaran custom.
- Struk transaksi dengan aksi cetak printer dan share WhatsApp sebagai placeholder integrasi.
- Setelan keamanan untuk PIN dan biometrik sebagai placeholder integrasi.
- Schema Supabase awal di `supabase/schema.sql` dengan RLS owner-based.

## Jalankan

```powershell
flutter pub get
flutter run
```

## Rencana Integrasi

Tahap berikutnya adalah mengganti state in-memory dengan database lokal SQLite/Drift, memasang sync queue ke Supabase, lalu mengaktifkan integrasi speech-to-text, text-to-speech, OCR kamera, Supabase Storage untuk bukti transaksi, biometric unlock, export laporan, share WhatsApp, dan printer thermal Bluetooth.
