---
name: mikiezy-design-system
description: Panduan desain, pengembangan dan review UI/UX Flutter Mikiezy untuk aplikasi produktivitas keuangan UMKM, termasuk design tokens existing, financial clarity, accessibility, dan prinsip anti-AI-slop.
---

# Mikiezy Design System & Financial UI/UX Guide

Panduan ini mengatur perancangan, pengembangan, dan review UI/UX Mikiezy sebagai aplikasi produktivitas keuangan UMKM yang profesional, modern, estetis, natural, dan konsisten dengan identitas visual yang sudah ada.

## 1. Existing System & Token Reusability
- **Design Tokens Utama**: Prioritaskan penggunaan token kanonikal:
  - Warna: `AppColors` (`lib/core/theme/app_theme.dart`), `ColorScheme` M3, palet brand (*Deep Navy* `#161A22`, *Electric Blue* `#315CFF`, *Teal* `#047A72`), serta warna semantik berpasangan (*soft*).
  - Spacing & Radius: `AppSpacing` (4–32dp) dan `AppRadius` (`lib/core/constants/app_dimensions.dart`). Nilai layout khusus diperbolehkan hanya jika dibenarkan oleh kebutuhan responsivitas, aksesibilitas, atau hierarki konten.
  - Motion: `AppDurations` (`fast: 160ms`, `normal: 240ms`).
- **Komponen Reusable**: Maksimalkan `MikiezyCard`, `MetricTile`, `MikiezySectionHeader`, `MikiezyEmptyState`, `MikiezySegmentedControl`, dan `AppShell`. Jangan membuat komponen baru tanpa kebutuhan reuse yang nyata.
- **Batasan Dependensi**: Dilarang menambah library UI, font eksternal, atau dependensi baru tanpa persetujuan pemilik project. Berkas `lib/theme/app_theme.dart` adalah re-export dari core theme.

## 2. Visual Hierarchy & Anti-AI-Slop
- **Fokus Konten Finansial**: Desain ditujukan untuk kejelasan data dan kecepatan operasional kasir, bukan dekorasi berlebihan atau tumpukan kartu generik tanpa fungsi.
- **Penggunaan Elemen Selektif**: Pertahankan gradien khas (`premiumGradient`, `actionGradient`) dan bayangan halus (`softShadow`) untuk memisahkan layer fungsional (misal: Header status vs Konten transaksi). Jangan menghapus atau menambah kartu/gradien secara serampangan.
- **Tipografi Berhirarki**: Terapkan bobot huruf sesuai hirarki visual. Heading utama maupun metrik finansial krusial dapat menggunakan `FontWeight.w900` bila sesuai konteks. Jangan melakukan perubahan font weight atau radius secara massal tanpa review visual.
- **Konsistensi Tema**: Pastikan seluruh tata letak dan kontras visual berfungsi harmonis pada mode terang maupun gelap.

## 3. Financial UX & Keamanan Transaksi
- **Kejelasan Nominal**: Nominal Rupiah, kuantitas, harga, dan stok wajib terbaca jelas tanpa pemotongan teks (*ellipsis*) atau *auto-shrink* berlebihan yang memicu ambiguitas angka.
- **Status Multi-Indikator**: Pasangkan warna semantik dengan label teks dan ikon yang jelas; jangan mengandalkan warna sebagai satu-satunya penanda status.
- **Integritas Pratinjau Transaksi**: Dilarang menyembunyikan rincian barang, koreksi kuantitas, pemilihan dompet, catatan, atau pesan error di `preview_transaction_screen.dart` demi estetika minimalis. Jangan mengubah mekanisme penyimpanan atau konfirmasi transaksi.

## 4. Responsivitas, Aksesibilitas, dan Visual QA
Untuk perubahan UI yang disetujui, lakukan pemeriksaan sesuai cakupan:
- **Layar & Tata Letak**: Layar Android sempit dan lebar, safe area, insets keyboard terbuka, bottom sheet, dan bottom navigation bar.
- **Aksesibilitas & Font Scaling**: Uji skalabilitas teks sistem (termasuk skenario $1.3\times$), rasio kontras, dan label screen reader. Targetkan area sentuh efektif minimal $48 \times 48$ dp untuk kontrol interaktif Android (tombol utama existing $48 \times 52$ dp tetap dipertahankan; ikon visual boleh berukuran lebih kecil jika padding atau area hit-test memenuhi $48 \times 48$ dp). Jangan menyimpulkan ukuran aktual hit-test hanya berdasarkan ukuran ikon atau constraints statis.
- **Audit State Komprehensif**: Periksa kesiapan state loading, error, empty, success, confirmation, dan disabled.
- **Pendeteksian Overflow & Collision**: Periksa potensi overflow, clipping, dan collision secara visual. Jangan mengklaim visual QA PASS hanya berdasarkan analisis source code atau Dart MCP tanpa pengujian visual/render nyata.

## 5. Alur Kerja Desain Disiplin
1. **Identifikasi Kebutuhan**: Definisikan layar target, pengguna, masalah teknis, dan kriteria penerimaan.
2. **Inspeksi Selektif**: Periksa widget dan token terkait tanpa memuat seluruh repositori UI.
3. **Pemisahan Bukti**: Bedakan temuan teknis objektif dari preferensi estetika subjektif.
4. **Perubahan Bedah (Surgical)**: Rancang perubahan minimal sesuai Karpathy Principles; minta persetujuan sebelum perubahan signifikan.
5. **Implementasi & Verifikasi**: Gunakan Official Flutter Skills dan Dart MCP; validasi dengan targeted tests dan visual QA fisik/screenshot bila tersedia. Laporkan bukti serta batasan inspeksi.

## 6. Integrasi UI/UX Pro Max
- **Otoritas Utama vs Referensi**: `mikiezy-design-system` adalah panduan utama identitas visual, design tokens, komponen existing, dan UX finansial Mikiezy. `ui-ux-pro-max` (`.agents/skills/ui-ux-pro-max/`) bertindak murni sebagai referensi tambahan, bukan otoritas yang mengganti `AGENTS.md`, arsitektur Flutter, atau desain existing.
- **Pencarian Terarah & Selektif**: Untuk tugas UI sederhana dengan pola existing, cukup gunakan panduan Mikiezy tanpa memanggil mesin pencari tambahan. Panggil pencarian Python `ui-ux-pro-max` hanya saat memerlukan data mendalam (aksesibilitas lanjutan, visualisasi chart finansial, responsive Flutter, atau usability kompleks) secara terarah (misal: `--domain ux`, `--domain chart`, atau `--stack flutter`), hindari pencarian berulang yang tidak relevan. Jangan mengklaim penghematan token tanpa pengukuran nyata.
- **Larangan Design System Ganda**: Dilarang menjalankan `--design-system --persist`, membuat `MASTER.md` baru, atau membuat design system tandingan tanpa persetujuan eksplisit.
- **Penyaringan Eksternal & Stack Guard**: Abaikan seluruh saran React, Tailwind, shadcn/ui, GSAP, CSS, dan web icon. Dilarang otomatis memasang package/font baru atau mengubah palet dan tipografi yang sudah ada; seluruh ide eksternal wajib disaring terhadap token dan kebutuhan operasional kasir Mikiezy.
