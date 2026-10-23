# Mikiezy

Mikiezy adalah prototype aplikasi mobile Flutter untuk UMKM. Fokus awalnya adalah pencatatan penjualan dan pengeluaran dengan konsep voice assistant, laporan laba/rugi, kelola barang, kelola dompet, struk transaksi, dan arsitektur offline-first yang siap disinkronkan ke Supabase.

## Fitur MVP

- Dashboard penjualan, pengeluaran, laba/rugi, dan dompet.
- Simulasi input suara Bahasa Indonesia untuk penjualan, pemasukan, pengeluaran, modal masuk, diskon, retail, dan grosir.
- Preview transaksi yang bisa diedit sebelum disimpan.
- Kelola barang dengan harga modal, harga retail, harga grosir, metadata pelacakan stok, satuan dasar, batas minimum, pack, dan karton.
- Kelola dompet dan kategori pemasukan/pengeluaran custom.
- Persistence lokal offline-first menggunakan SQLite/Drift di `lib/core/database/app_database.dart`.
- Struk transaksi dengan aksi cetak printer dan share WhatsApp sebagai placeholder integrasi.
- Kunci aplikasi berbasis PIN ter-hash, secure storage, biometric native, cooldown percobaan, dan timeout saat kembali dari background.
- Schema Supabase awal di `supabase/schema.sql` dengan RLS owner-based.
- Global push-to-talk voice overlay untuk transaksi, query bisnis, clarification, dan navigasi saat aplikasi berada di foreground.
- Preview aman untuk perintah voice tambah/ubah produk. Eksekusi mutasi masih sengaja dinonaktifkan sampai Phase 6.

## Catatan Fondasi Data

- Runtime Flutter memakai Drift/SQLite canonical di `lib/core/database/app_database.dart`.
- Schema Drift aktif saat ini adalah v6. Migration mempertahankan database lama sekaligus menambahkan multiplier pecahan dan audit tindakan voice.
- Schema Drift lama di `lib/data/local/app_database.dart` sudah tidak dipakai dan sudah dibersihkan agar tidak membingungkan `build_runner`.
- Quantity transaksi dan stok produk mendukung pecahan, misalnya `0.5` kilo atau `1.25` pcs.
- Normalisasi satuan terpusat mendukung berat, volume, panjang, count, dan packaging. Konversi lintas dimensi ditolak, sedangkan pack/karton wajib memakai metadata produk.
- Perhitungan pack/karton memakai `packSize` dan `cartonSize` produk, bukan multiplier hardcoded.
- Produk memiliki `trackStock`, `baseUnit`, dan `minStock`. Stok nol yang dilacak berarti habis, sedangkan produk dengan `trackStock = false` tetap dapat dijual tanpa pengendalian jumlah.
- Stok produk berkurang otomatis saat transaksi sale disimpan dan transaksi diblokir jika stok produk yang dilacak tidak cukup.
- Low-stock memakai `minStock` setiap produk; produk yang tidak dilacak tidak masuk daftar stok habis/menipis.
- Audit command voice hanya menyimpan status, fingerprint, dan ringkasan perubahan yang dibatasi; transcript mentah, PIN, token, dan data biometrik tidak disimpan di tabel audit.
- Microphone global tidak berjalan diam-diam dan dihentikan ketika aplikasi masuk background, terkunci, atau membuka surface sensitif.
- Schema Supabase masih kontrak persiapan sync, belum dipakai runtime Flutter.

## Jalankan

```powershell
flutter pub get
flutter run
```

## Rencana Integrasi

Database lokal SQLite/Drift sudah aktif untuk produk, dompet, kategori, transaksi, profil usaha, setting, voice learning, dan audit tindakan voice. Tahap berikutnya adalah mengaktifkan command mutasi satu jenis per patch dengan idempotency dan reversal, lalu merapikan queue mutation/sync status sebelum memasang Supabase. OCR kamera, upload bukti, export/share nyata, dan printer thermal Bluetooth tetap berada di roadmap.
