# Phase 7A Real-Device Validation Matrix

Dokumen ini adalah sumber test perangkat nyata Mikiezy. Jangan mengubah status
menjadi `PASS` tanpa menjalankan langkah pada perangkat yang dicatat dan
menyertakan bukti.

## Build Under Test

| Field | Value |
|---|---|
| App | Mikiezy |
| Baseline version | 1.0.0+1 |
| Android application ID | com.mikiezy.mikiezy |
| Baseline APK | build/app/outputs/flutter-apk/app-debug.apk |
| Baseline SHA-256 | EFDD2A1769576D0A1266168C7034AED969595B92FA80DAD9963ADEE036F9CC2E |
| Final debug APK | build/app/outputs/flutter-apk/app-debug.apk |
| Final debug SHA-256 | B5CE7E0DDF26F3073510BA981AC3F100425909A169DF1210AC262AEFF6F62F02 |
| Final candidate date | 2026-07-24 |
| Flutter | 3.44.4 |
| Dart | 3.12.2 |
| Schema | Drift v6 |
| Matrix status | NOT RUN |

## Status Rules

| Status | Meaning |
|---|---|
| NOT RUN | Belum diuji |
| PASS | Actual sama dengan expected dan bukti tersedia |
| FAIL | Actual berbeda dari expected |
| BLOCKED | Tidak dapat diuji; alasan wajib dicatat |
| SKIPPED | Tidak relevan untuk device/build; alasan wajib dicatat |

Severity bug:

- `Critical`: data hilang/salah, mutasi ganda, lock bypass, credential bocor,
  migration merusak data, atau crash pada flow utama.
- `High`: transcript hilang, produk/harga salah, navigation ganda, STT aktif di
  background, TTS masuk ke STT, atau biometric gagal tetapi app terbuka.
- `Medium`: flow demo terganggu, pesan/clarification membingungkan, timeout atau
  overlay menghambat.
- `Low`: kosmetik dan warning build non-blocking.

## Evidence Convention

Gunakan folder lokal di luar data produksi, misalnya:

`evidence/phase_7a/<run-id>/<test-id>/`

Nama bukti:

- `<test-id>-screen.png`
- `<test-id>-screen.mp4`
- `<test-id>-log.txt`
- `<test-id>-db-before.txt`
- `<test-id>-db-after.txt`

Jangan masukkan PIN, token, biometric, saldo sensitif, transcript penuh, atau
database pengguna ke screenshot/log yang akan dibagikan.

## Test Definitions

Kolom `Ucapan` berisi `-` jika test tidak memakai voice. Semua test dijalankan
pada database uji, bukan database penting pengguna.

| ID | Area | Kondisi awal | Langkah | Ucapan/perintah | Hasil yang diharapkan |
|---|---|---|---|---|---|
| INST-01 | Instalasi | App belum terpasang | Install APK debug lalu buka | - | Install dan startup berhasil tanpa crash |
| INST-02 | Instalasi | Fresh install | Selesaikan onboarding, tutup, buka lagi | - | Onboarding tidak muncul ulang |
| INST-03 | Instalasi | Data uji tersedia | Upgrade APK tanpa uninstall | - | Data tetap ada dan app dapat dibuka |
| INST-04 | Startup | Process mati | Cold start tiga kali | - | Splash tidak macet; dashboard/lock konsisten |
| INST-05 | Startup | App di recent | Warm start tiga kali | - | Tidak ada controller/overlay ganda |
| PERM-01 | Permission | Mikrofon belum pernah diminta | Tekan mic lalu pilih Allow | - | Satu dialog; voice mulai setelah izin |
| PERM-02 | Permission | Mikrofon belum pernah diminta | Tekan mic lalu pilih Deny | - | Pesan izin diperlukan; tidak ada dialog loop |
| PERM-03 | Permission | Izin pernah ditolak | Tekan mic lalu tolak lagi/permanen | - | Pesan permanent denial dan tombol settings |
| PERM-04 | Permission | Permanent denial | Tekan Buka pengaturan | - | Settings hanya terbuka setelah tindakan user |
| PERM-05 | Permission | Izin granted | Cabut izin di settings lalu kembali | - | Sesi berikutnya ditolak dengan pesan jelas |
| PERM-06 | Permission | App background | Cabut izin lalu resume | - | Tidak auto-listen; status diperbarui saat digunakan |
| PERM-07 | Permission | Mic dipakai app lain | Mulai voice | - | Error aman; tidak crash atau loop |
| PERM-08 | Permission | Speech service disabled | Mulai voice | - | Pesan layanan speech tidak tersedia |
| PERM-09 | Permission | Engine membutuhkan network | Matikan internet lalu mulai | - | Error aman; tidak mengubah data |
| PERM-10 | Permission | Izin granted | Mulai, stop, mulai ulang 5 kali | - | Tidak ada prompt atau recognizer ganda |
| STT-01 | STT | Ruangan tenang | Push-to-talk satu kalimat | jual kopi susu dua gelas | Transcript masuk sekali |
| STT-02 | STT | Noise ringan | Ulangi command tiga kali | jual kopi susu dua gelas | Tidak crash; low confidence dapat direview |
| STT-03 | STT | Jarak 1 meter | Ucapkan command normal | jual kopi susu dua gelas | Hasil wajar atau warning, tidak mengarang item |
| STT-04 | STT | Bicara cepat | Ucapkan tiga item | kopi susu dua gelas air mineral tiga botol mie goreng dua bungkus | Item valid tidak hilang diam-diam |
| STT-05 | STT | Bicara lambat | Beri jeda antarfrasa | ayam bakar sepuluh bungkus dua belas ribu | Buffer tidak ditimpa |
| STT-06 | STT | Listener aktif | Stop manual saat partial | - | Partial dikomit satu kali lalu dapat direview |
| STT-07 | STT | Listener aktif | Tunggu status done/notListening | - | Final buffer tetap tersedia |
| STT-08 | STT | Speech error | Paksa service berhenti | - | Controller masuk error dan dapat retry |
| TTS-01 | TTS | TTS aktif | Jalankan query | berapa omzet hari ini | STT berhenti sebelum TTS |
| TTS-02 | TTS | TTS berbicara | Dekatkan speaker ke mic | - | Ucapan TTS tidak menjadi command baru |
| TTS-03 | TTS | Push-to-talk | Tunggu TTS selesai | - | Tetap idle setelah jawaban |
| TTS-04 | TTS | Conversation mode | Tunggu TTS selesai | - | Relisten hanya setelah TTS selesai |
| TTS-05 | TTS | TTS berbicara | Background app | - | TTS/STT berhenti |
| TTS-06 | TTS | TTS berbicara | Tekan stop | - | TTS berhenti dan callback lama diabaikan |
| TTS-07 | TTS | Engine TTS error | Jalankan query | berapa stok kopi | UI tetap responsif dan dapat retry |
| TTS-08 | TTS | Sesi A selesai | Mulai sesi B cepat | - | Callback sesi A tidak memulai STT |
| TTS-09 | TTS | TTS disabled | Jalankan query | berapa omzet hari ini | Jawaban UI tetap tersedia |
| ACC-01 | Transcript accumulation | Push-to-talk | Ucapkan tiga bagian dengan jeda 1-2 detik | ayam bakar 10 bungkus 12000; nasi goreng 5 bungkus 13000; es teh 3 gelas 5000 | Ketiga item masuk preview |
| ACC-02 | Transcript accumulation | Partial berubah | Koreksi kata sebelum final | - | Partial lama diganti, bukan diduplikasi |
| ACC-03 | Transcript accumulation | Bagian pertama final | Lanjut bicara setelah auto-restart | - | Final lama tidak terhapus |
| ACC-04 | Transcript accumulation | Listener aktif | Tunggu done lalu lanjut | - | Bagian baru digabung satu kali |
| ACC-05 | Transcript accumulation | Transcript panjang | Ucapkan 10 item | Data test 10 item | Seluruh item valid masuk preview |
| ACC-06 | Transcript accumulation | Transcript sangat panjang | Ucapkan lebih dari 30 item | Data test 31+ item | Batas/warning jelas; tidak crash |
| ACC-07 | Transcript accumulation | Conversation mode | Jawab clarification bertahap | - | Jawaban tidak menimpa command awal |
| ACC-08 | Transcript accumulation | Wake word mode | Panggil Miki lalu command panjang | Miki catat ... | Wake word dibuang, command tetap lengkap |
| SIL-01 | Silence timeout | Setting 3 detik | Bicara, diam 2 detik, lanjut | dua item | Tidak diproses terlalu dini |
| SIL-02 | Silence timeout | Setting 3 detik | Bicara lalu diam lebih dari 3 detik | satu item | Beralih ke processing satu kali |
| SIL-03 | Silence timeout | Setting 5 detik | Uji sesi baru | satu item | Timeout sekitar 5 detik |
| SIL-04 | Silence timeout | Setting 10 detik | Uji sesi baru | satu item | UI menunjukkan masih listening |
| SIL-05 | Silence timeout | Setting 15 detik | Uji sesi baru | satu item | Tidak hang; dapat stop manual |
| SIL-06 | Silence timeout | Setting diubah | Restart app | - | Nilai terakhir tetap tersimpan |
| SIL-07 | Silence timeout | Timer aktif | Tutup screen/dispose | - | Timer tidak memproses setelah dispose |
| SIL-08 | Silence timeout | Timer aktif | Ubah transcript berulang | - | Timer lama dibatalkan dan hanya satu proses |
| WAKE-01 | Wake word | Setting aktif, foreground | Panggil variasi wake word | Miki; hey Miki; halo Miki; Miki catat | Satu sesi command terbuka |
| WAKE-02 | Wake word | Setting nonaktif | Panggil Miki | Miki catat penjualan | Tidak ada respons |
| WAKE-03 | Wake word | App locked | Panggil Miki | Miki | Tidak ada mic/voice sensitif |
| WAKE-04 | Wake word | App background | Panggil Miki | Miki | Tidak always-listening |
| WAKE-05 | Wake word | TTS berbicara | Panggil Miki | Miki | Tidak membuat sesi kedua |
| WAKE-06 | Wake word | Standby 15+ menit | Panggil variasi | hey Miki | Watchdog memulihkan listener |
| WAKE-07 | Wake word | Sesi sedang dibuka | Panggil berulang | Miki Miki | Hanya satu VoiceEntry/overlay |
| WAKE-08 | Wake word | Foreground | Ucapkan percakapan tanpa wake word | percakapan biasa | Tidak diproses sebagai command |
| TX-01 | Voice transaction | Produk ada | Buat satu item dengan harga | jual kopi susu dua gelas dua belas ribu | Preview benar |
| TX-02 | Voice transaction | Harga katalog ada | Satu item tanpa harga | jual kopi susu dua gelas | Harga katalog dipakai |
| TX-03 | Voice transaction | Dua produk ada | Multi-item dengan separator | jual kopi susu dua gelas dan air mineral tiga botol | Dua item masuk |
| TX-04 | Voice transaction | Tiga produk ada | Multi-item tanpa separator | kopi susu dua gelas air mineral tiga botol mie goreng dua bungkus | Tiga item masuk |
| TX-05 | Voice transaction | 10 produk ada | Ucapkan 10 item | Data test 10 item | Semua item valid masuk |
| TX-06 | Voice transaction | 31+ produk ada | Ucapkan 31+ item realistis | Data test 31+ item | Tidak crash; limit/warning jelas |
| TX-07 | Voice transaction | Produk kilo ada | Quantity pecahan | jual beras setengah kilo | Quantity 0.5 |
| TX-08 | Voice transaction | packSize terisi | Unit pack | jual kopi sachet dua pack | Multiplier metadata benar |
| TX-09 | Voice transaction | cartonSize terisi | Unit karton | jual air mineral satu karton | Multiplier metadata benar |
| TX-10 | Voice transaction | Preview terbuka | Tekan simpan dua kali cepat | - | Satu transaksi dan satu stok keluar |
| TX-11 | Voice transaction | Preview invalid | Batalkan/tutup | - | Stok tidak berubah |
| TX-12 | Voice transaction | Produk ad-hoc | Simpan transaksi | jual produk uji satu pcs 5000 | Katalog tidak dibuat otomatis |
| RES-01 | Product resolver | Dua Aqua ada | Sebut nama ambigu | Aqua | Clarification, tidak auto-pilih |
| RES-02 | Product resolver | Alias tersimpan | Sebut alias | Alias test | Produk terkait saja yang dipilih |
| RES-03 | Product resolver | Nama mirip | Sebut nama fuzzy dekat | - | Fuzzy konservatif atau clarification |
| RES-04 | Product resolver | Nama berbeda | Sebut produk tidak ada | kopi pandan | Not found; tidak membuat produk |
| RES-05 | Product resolver | Aqua 600 ml ada | Sebut ukuran | Aqua 600 ml | Angka ukuran bagian dari nama |
| RES-06 | Product resolver | Ayam bakar/goreng ada | Sebut masing-masing | ayam bakar; ayam goreng | Tidak disatukan |
| QUERY-01 | Business query | Ada transaksi hari ini | Tanya omzet | berapa omzet hari ini | UI/TTS konsisten |
| QUERY-02 | Business query | Ada transaksi | Tanya laba | berapa laba hari ini | Snapshot cost dipakai |
| QUERY-03 | Business query | Ada expense | Tanya pengeluaran | pengeluaran bulan ini berapa | Periode benar |
| QUERY-04 | Business query | Ada transaksi | Tanya jumlah | berapa jumlah transaksi hari ini | Nilai benar |
| QUERY-05 | Business query | Ada produk terjual | Tanya top produk | produk paling laris apa | Nilai benar |
| QUERY-06 | Business query | Produk ada | Tanya stok | stok kopi susu berapa | Nilai terbaru |
| QUERY-07 | Business query | Low-stock ada | Tanya low stock | barang apa yang stoknya menipis | Daftar benar |
| QUERY-08 | Business query | Satu dompet | Tanya saldo | saldo kas berapa | Privacy policy diterapkan |
| QUERY-09 | Business query | Banyak dompet | Tanya semua saldo | semua saldo dompet | Clarification/privacy aman |
| QUERY-10 | Business query | Ada riwayat | Tanya terbaru | transaksi terakhir apa | Tidak membuka preview |
| QUERY-11 | Business query | Periode kosong | Tanya periode kosong | omzet tahun 1990 | Empty state, bukan error |
| NAV-01 | Navigation | Dashboard | Buka transaksi | buka transaksi | Satu navigation |
| NAV-02 | Navigation | Dashboard | Buka produk | buka produk | Satu navigation |
| NAV-03 | Navigation | Dashboard | Buka analitik | buka analitik | Satu navigation |
| NAV-04 | Navigation | Dashboard | Buka dompet/kategori | buka dompet; buka kategori | Target benar |
| NAV-05 | Navigation | Dashboard | Buka settings/profile | buka pengaturan; edit profil | Target benar |
| NAV-06 | Navigation | Halaman target | Ulangi target | buka produk | Respons already there |
| NAV-07 | Navigation | Dialog terbuka | Beri command | buka laporan | Diblokir; dialog tidak hilang |
| NAV-08 | Navigation | Preview belum disimpan | Beri command | buka produk | Diblokir; preview tetap ada |
| NAV-09 | Navigation | Form edit dirty | Beri command | buka dashboard | Tidak membuang perubahan diam-diam |
| NAV-10 | Navigation | Foreground | Kirim command dua kali cepat | buka produk | Tidak navigation ganda |
| NAV-11 | Navigation | Background | Kirim callback lama | buka produk | Tidak navigation |
| NAV-12 | Navigation | App locked | Command navigation sensitif | edit profil | Diblokir |
| NAV-13 | Navigation | Navigator disposed | Selesaikan callback | - | Tidak crash |
| CLAR-01 | Clarification | Aqua ambigu | Pilih ukuran | yang 600 ml | Candidate benar |
| CLAR-02 | Clarification | Kandidat tersedia | Pilih nomor | nomor dua | Candidate kedua |
| CLAR-03 | Clarification | Kandidat tersedia | Pilih posisi | yang terakhir | Candidate terakhir |
| CLAR-04 | Clarification | Kandidat tersedia | Sebut nama lengkap | Aqua 1,5 liter | Candidate tepat |
| CLAR-05 | Clarification | Pending | Batal | batal | Context dibersihkan |
| CLAR-06 | Clarification | Pending | Jawab invalid tiga kali | jawaban acak | Dibatalkan konservatif |
| CLAR-07 | Clarification | Pending | Tunggu expiry | - | Context expired, tidak commit |
| CLAR-08 | Clarification | Produk pending | Beri command baru eksplisit | buka laporan | Context lama dibersihkan |
| CLAR-09 | Clarification | Dompet BCA ambigu | Pilih kandidat | yang kedua | Dompet benar |
| CLAR-10 | Clarification | Pending | Background lalu resume | - | Tidak commit otomatis |
| PRIV-01 | Privacy | App unlocked, privacy aktif | Tanya satu saldo | saldo BCA berapa | Nilai dimask/ditolak sesuai setting |
| PRIV-02 | Privacy | App locked | Tanya data sensitif | omzet hari ini | Tidak ada nilai bocor |
| PRIV-03 | Privacy | Masking aktif | Periksa UI dan TTS | semua saldo dompet | Keduanya konsisten |
| PRIV-04 | Privacy | Query non-sensitif | Tanya stok | stok kopi berapa | Tetap dapat dijawab |
| PRIV-05 | Privacy | Debug build | Periksa log | - | Tidak ada saldo lengkap/PIN/transcript penuh |
| PIN-01 | PIN | Belum ada PIN | Buat PIN 4 digit | - | Tersimpan sebagai verifier, bukan plaintext |
| PIN-02 | PIN | Belum ada PIN | Buat PIN 6 digit | - | Berhasil |
| PIN-03 | PIN | PIN aktif | Masukkan PIN benar | - | Unlock |
| PIN-04 | PIN | PIN aktif | Masukkan PIN salah | - | Tetap locked |
| PIN-05 | PIN | PIN aktif | Gagal berulang | - | Limit/cooldown bekerja |
| PIN-06 | PIN | Cooldown aktif | Tunggu cooldown | - | Dapat mencoba lagi |
| PIN-07 | PIN | PIN aktif | Restart app | - | Lock tetap aktif |
| PIN-08 | PIN | App terbuka | Manual lock | - | Lock screen menutup konten |
| PIN-09 | PIN | Timeout configured | Background melewati timeout | - | Terkunci saat resume |
| PIN-10 | PIN | Lock screen | Tekan back | - | Dashboard tidak terlihat |
| BIO-01 | Biometric | Terdaftar | Authenticate sukses | - | Unlock |
| BIO-02 | Biometric | Terdaftar | Authenticate gagal | - | Tetap locked |
| BIO-03 | Biometric | Prompt aktif | Cancel | - | Tetap locked; fallback PIN tersedia |
| BIO-04 | Biometric | Tidak terdaftar | Coba biometric | - | Pesan aman; fallback PIN |
| BIO-05 | Biometric | Tidak didukung | Coba aktifkan | - | Tidak crash |
| BIO-06 | Biometric | System lockout | Coba authenticate | - | Tetap locked; fallback PIN |
| BIO-07 | Biometric | Prompt aktif | Dispose/background | - | Callback lama tidak unlock |
| BIO-08 | Biometric | Prompt pernah gagal | Resume | - | Prompt tidak loop |
| BIO-09 | Biometric | App locked | Panggil voice | Miki | Mic dan data sensitif diblokir |
| LIFE-01 | Lifecycle | Voice listening | Tekan Home | - | STT berhenti |
| LIFE-02 | Lifecycle | TTS speaking | Tekan Home | - | TTS/STT berhenti |
| LIFE-03 | Lifecycle | Mutation preview | Background | - | Pending dibatalkan/tidak commit |
| LIFE-04 | Lifecycle | Clarification | Background | - | Tidak commit saat background |
| LIFE-05 | Lifecycle | Unlocked | Background kurang timeout | - | Policy timeout konsisten |
| LIFE-06 | Lifecycle | Unlocked | Background melewati timeout | - | Lock saat resume |
| LIFE-07 | Lifecycle | App inactive karena biometric | Selesaikan prompt | - | Tidak ada controller ganda |
| LIFE-08 | Lifecycle | App detached | Kill process | - | Timer/subscription dibersihkan |
| LIFE-09 | Lifecycle | Resume | Tekan mic | - | Hanya satu listener |
| OVER-01 | Global overlay | Dashboard | Buka overlay | - | Safe area dan tombol tidak tertutup |
| OVER-02 | Global overlay | Transaksi/produk/laporan | Buka overlay tiap halaman | - | Layout stabil |
| OVER-03 | Global overlay | Dompet/kategori/settings | Buka overlay tiap halaman | - | Layout stabil |
| OVER-04 | Global overlay | Keyboard terbuka | Buka overlay | - | Tidak tertutup keyboard secara buruk |
| OVER-05 | Global overlay | Dialog terbuka | Tekan mic | - | Surface sensitif memblokir |
| OVER-06 | Global overlay | Preview terbuka | Tekan mic | - | Preview tidak ditutup |
| OVER-07 | Global overlay | App locked | Periksa overlay | - | Hilang/diblokir |
| OVER-08 | Global overlay | Clarification pending | Pindah route aman | - | Context sesuai policy |
| OVER-09 | Global overlay | Listening | Tekan mic berulang | - | Satu controller/recognizer |
| OVER-10 | Global overlay | Root dispose | Tutup app/test | - | Timer/subscription dibersihkan |
| OVER-11 | Global overlay | Processing | Background cepat | - | Callback lama diabaikan |
| P6A-01 | Tambah produk | Kategori ada | Command lengkap | tambah produk kopi susu harga 12000 | Preview lalu satu produk |
| P6A-02 | Tambah produk | Data belum lengkap | Clarification bertahap | tambah produk kopi susu | Satu field per giliran |
| P6A-03 | Tambah produk | Tracking off/on | Uji tanpa dan dengan stok pecahan | - | Metadata benar |
| P6A-04 | Tambah produk | Distributor mode | Isi modal/grosir | - | Harga benar |
| P6A-05 | Tambah produk | Kategori baru valid | Buat via flow yang didukung | - | Kategori/produk atomik |
| P6A-06 | Tambah produk | Nama sudah ada/mirip | Ulangi command | - | Duplicate ditolak; mirip diperingatkan |
| P6A-07 | Tambah produk | Clarification/confirmation | Batal pada masing-masing tahap | batal | Tidak ada produk |
| P6A-08 | Tambah produk | App locked | Konfirmasi | ya | Tidak ada produk |
| P6A-09 | Tambah produk | Preview aktif | Konfirmasi dua kali | ya; ya | Satu produk/audit success |
| P6A-10 | Tambah produk | Produk tersimpan | Restart dan jual produk | jual kopi susu satu | Resolver menemukan produk |
| P6A-11 | Tambah produk | Action selesai | Periksa audit | - | Event lengkap tanpa transcript/PIN |
| P6B-01 | Tambah stok | Produk tracked | Tambah integer | tambah stok kopi susu 10 gelas | Stok +10 sekali |
| P6B-02 | Tambah stok | Unit kilo/liter | Tambah pecahan | restok beras 2,5 kilo; tambah sirup satu setengah liter | Quantity akurat |
| P6B-03 | Tambah stok | pack/carton metadata ada | Tambah pack/karton | tambah kopi sachet 3 pack; tambah Aqua 2 karton | Multiplier metadata |
| P6B-04 | Tambah stok | Produk ambigu/tidak ada | Jalankan dua skenario | - | Clarification/not-found |
| P6B-05 | Tambah stok | Unit tidak kompatibel | Jalankan command | - | Ditolak |
| P6B-06 | Tambah stok | Tracking off | Konfirmasi enable tracking | - | Perubahan eksplisit |
| P6B-07 | Tambah stok | Pending | Batal, lock, double confirm | - | Tidak berubah/sekali saja |
| P6B-08 | Tambah stok | Preview dibuat | Ubah stok manual sebelum confirm | - | Stale preview baru |
| P6B-09 | Tambah stok | Commit sukses | Restart, query stok/low stock | - | Persist dan query benar |
| P6B-10 | Tambah stok | Action selesai | Periksa audit | - | Started/succeeded satu kali |
| P6C-01 | Ubah harga | Produk ada | Retail generik/eksplisit | ubah harga kopi susu menjadi 12000; ganti harga jual kopi susu jadi 12000 | Retail berubah sekali |
| P6C-02 | Ubah harga | Produk ada | Grosir/modal | ubah harga grosir kopi sachet menjadi 1500; harga modal gula jadi 14000 | Field terpilih saja |
| P6C-03 | Ubah harga | Aqua 600 ml ada | Ubah harga | ubah harga Aqua 600 ml menjadi 5000 | 600 bukan harga baru |
| P6C-04 | Ubah harga | Ambigu/tidak ada | Jalankan dua skenario | - | Clarification/not-found |
| P6C-05 | Ubah harga | Field/nominal hilang | Jalankan clarification | - | Satu field per giliran |
| P6C-06 | Ubah harga | Harga invalid | Negatif/sama/nol | - | Policy terpusat; tidak commit |
| P6C-07 | Ubah harga | Perubahan ekstrem | Konfirmasi pertama dan kedua | - | Baru commit setelah konfirmasi kedua |
| P6C-08 | Ubah harga | Cost/wholesale di atas retail | Konfirmasi warning | - | Warning dan konfirmasi tambahan |
| P6C-09 | Ubah harga | Pending | Batal clarification/confirmation | batal | Tidak berubah |
| P6C-10 | Ubah harga | App locked | Konfirmasi | ya | Tidak berubah |
| P6C-11 | Ubah harga | Preview aktif | Konfirmasi dua kali | ya; ya | Satu update/audit success |
| P6C-12 | Ubah harga | Preview dibuat | Ubah harga manual sebelum commit | - | Stale preview baru |
| P6C-13 | Ubah harga | Commit sukses | Restart | - | Harga tersimpan |
| P6C-14 | Ubah harga | Ada transaksi lama | Transaksi baru/lama dan laba | - | Baru memakai katalog baru; histori tetap |
| P6C-15 | Ubah harga | Action sukses | Uji undo internal aman | - | Undo hanya jika fingerprint cocok |
| P6C-16 | Ubah harga | Banyak produk/field | Command bulk/multi | naikkan semua harga; ubah harga kopi dan teh | Diblokir |
| AUDIT-01 | Audit | Voice action sukses | Baca event | - | Draft sampai succeeded urut |
| AUDIT-02 | Audit | Action gagal | Baca event | - | Failure/rollback benar |
| AUDIT-03 | Audit | Double confirmation | Baca event | - | Satu succeeded |
| AUDIT-04 | Audit | Stale/duplicate | Baca event | - | Rejection tercatat |
| AUDIT-05 | Audit | Undo | Baca event | - | Requested dan terminal event |
| AUDIT-06 | Audit | Debug/release | Periksa payload/log | - | Tidak ada PIN/token/transcript mentah |
| PERSIST-01 | Restart persistence | Produk dibuat | Restart | - | Produk tetap ada |
| PERSIST-02 | Restart persistence | Stok ditambah | Restart | - | Stok tetap |
| PERSIST-03 | Restart persistence | Harga diubah | Restart | - | Harga tetap |
| PERSIST-04 | Restart persistence | Transaksi disimpan | Restart | - | Transaksi/struk tetap |
| PERSIST-05 | Restart persistence | Settings diubah | Restart | - | Silence/privacy/wake setting tetap |
| PERSIST-06 | Restart persistence | Action sukses | Kirim confirmation lama setelah restart | - | Tidak dieksekusi ulang |
| PERSIST-07 | Restart persistence | Pending clarification | Restart | - | Tidak auto-commit |
| PERSIST-08 | Restart persistence | PIN aktif | Restart | - | Lock tetap aktif |
| MIG-01 | Migration | Backup salinan DB | Catat schema/count/record | - | Baseline evidence lengkap |
| MIG-02 | Migration | Salinan DB v1 | Buka dengan app baru | - | Migrasi ke v6 tanpa destructive fallback |
| MIG-03 | Migration | Salinan DB v2-v5 | Uji tiap versi yang tersedia | - | Seluruh step berhasil |
| MIG-04 | Migration | Produk stok nol | Migrasi | - | Nilai tetap masuk akal |
| MIG-05 | Migration | Metadata lama kosong/default | Migrasi | - | baseUnit/minStock/pack/carton aman |
| MIG-06 | Migration | Transaksi lama | Migrasi dan buka struk | - | Snapshot harga/cost/multiplier tetap |
| MIG-07 | Migration | Data banyak | Bandingkan count sebelum/sesudah | - | Tidak ada kehilangan |
| MIG-08 | Migration | Migration gagal simulasi | Buka app | - | Tidak menghapus database |
| PERF-01 | Performance | Fresh process | Ukur cold startup | - | Catat durasi, tidak menetapkan angka palsu |
| PERF-02 | Performance | Data uji | Ukur dashboard/product load | - | Catat durasi |
| PERF-03 | Performance | Voice idle | Ukur start STT | - | Catat durasi |
| PERF-04 | Performance | Final transcript | Ukur final ke preview | - | Catat durasi |
| PERF-05 | Performance | Query data | Ukur business query | omzet hari ini | Catat durasi |
| PERF-06 | Performance | Mutation confirmed | Ukur commit dan reload | - | Catat durasi |
| PERF-07 | Performance | Voice aktif 5 menit | Profil memory | - | Tidak naik tanpa batas |
| PERF-08 | Performance | 100/500/1000 produk | Buka/search/query | - | Catat respons dan jank |
| PERF-09 | Performance | Riwayat besar | Buka laporan/transaksi | - | Catat respons dan memory |
| PERF-10 | Performance | Overlay aktif | Profil rebuild | - | Tidak ada rebuild loop |
| CRASH-01 | Crash recovery | Listening | Force stop dan restart | - | App pulih; tidak ada commit |
| CRASH-02 | Crash recovery | Preview | Force stop dan restart | - | Tidak auto-save |
| CRASH-03 | Crash recovery | Sesudah confirm sebelum commit | Force stop jika dapat direproduksi | - | Tidak ada mutasi parsial |
| CRASH-04 | Crash recovery | Setelah commit | Force stop dan restart | - | Satu mutasi; idempotent |
| CRASH-05 | Crash recovery | TTS/auth prompt | Force stop | - | App dapat dibuka lagi |
| CRASH-06 | Crash recovery | App di recent | Kill process | - | Pending context tidak dieksekusi |
| CRASH-07 | Crash recovery | Action gagal | Restart dan retry | - | Retry aman |
| CRASH-08 | Crash recovery | Storage hampir penuh | Simpan data uji | - | Error jelas; tidak parsial |
| CRASH-09 | Crash recovery | Database locked/error | Jalankan mutation | - | Rollback dan audit konsisten |
| CRASH-10 | Crash recovery | Callback async aktif | Dispose root | - | Tidak crash/setState after dispose |

## Execution Run Log

Tambahkan satu baris untuk setiap test dan setiap device/build. Jangan menimpa
run lama; gunakan `Run ID` berbeda.

| Run ID | Test ID | Hasil aktual | Status | Bukti | Catatan bug/severity | Device | OS/API level | App version/build | Timestamp | Tester |
|---|---|---|---|---|---|---|---|---|---|---|
| P7A-LOCAL-001 | ENV-DEVICE | Tidak ada Android/iOS device terhubung | BLOCKED | `flutter devices` | Hardware validation belum dapat dimulai | Windows host | Windows 10 22H2 | 1.0.0+1 | 2026-07-24 | Codex |
| QA2-STEP-01 | INST-04 / PERSIST-08 | App terbuka dari cold start, AppLock aktif meminta PIN, unlock manual berhasil membuka Dashboard Toko Maju Jaya | PASS | `screen_step1_locked.png`, `screen_step1_dashboard.png` (M4F.23) | Tidak ada bug; gate AppLock beroperasi normal pada fresh install/login | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-27 | Antigravity Pair |
| QA2-STEP-02 | NAV-VOICE | Perintah suara membuka katalog barang berhasil menavigasi ke ProductsScreen | PASS | `screen_step2_catalog.png` (M4F.23) | Navigasi suara ke halaman produk responsif | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-27 | Antigravity Pair |
| QA2-STEP-03 | P6A-01 / P6A-09 | Tambah produk Kopi Susu via suara berhasil dibuat di database; kategori fallback ke Lain-lain karena kata minuman tidak diucapkan | REMEDIATED WITH DOCUMENTED DEVIATION | `screen_step3_preview.png` (M4F.24), `screen_m4f25_post_restart_catalog.png` (M4F.25) | Deviating fallback kategori Lain-lain diperbaiki via UI edit terotorisasi menjadi Minuman pada M4F.25 | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-27 | Antigravity Pair |
| QA2-STEP-04 | P6B-01 / P6B-09 | Tambah stok Kopi Susu via suara berhasil menambah 10 unit (20 -> 30 gelas) | PASS | `screen_m4f26_actual_stock.png` (M4F.26) | Mutasi stok bertambah atomic dan tercermin di UI | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-27 | Antigravity Pair |
| QA2-STEP-05 | TX-VOICE-01 / PERSIST-04 | Penjualan voice 1 Kopi Susu tanpa sebut harga memakai katalog retail Rp12.000; stok berkurang 30 -> 29 | PASS | `screen_m4f27_sale_preview.png`, `screen_m4f27_post_sale_stock.png` (M4F.27) | Transaksi berhasil dicatat; snapshot unitPrice Rp12.000 tersimpan | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-28 | Antigravity Pair |
| QA2-STEP-06 | QUERY-01 / QUERY-02 | Tanya omzet & estimasi laba hari ini via suara; Miki menjawab omzet Rp57.000 dan estimasi laba Rp30.000 | PASS WITH DATA QUALITY GAP | `screen_m4f28_revenue_query.png`, `screen_m4f28_profit_query.png` (M4F.28) | HPP Kopi Susu Rp0 menyebabkan laba bersifat estimasi kasar | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-28 | Antigravity Pair |
| QA2-STEP-07 | P6C-01 / P6C-11 | Ubah harga retail Kopi Susu Rp12.000 -> Rp14.000 via suara melalui mekanisme konfirmasi suara | PASS | `screen_m4f29_price_preview.png`, `screen_m4f29_catalog_post_update.png` (M4F.29) | Retail price terupdate; transaksi historis Step 5 tetap Rp12.000 | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-28 | Antigravity Pair |
| QA2-STEP-08 | P6C-14 | Penjualan voice kedua 1 Kopi Susu memakai retail baru Rp14.000; stok berkurang 29 -> 28; sale lama tetap Rp12.000 | PASS | `report_m4f30_qa_run2_step8.md`, `screen_m4f30_new_receipt.png` (M4F.30) | Immutability snapshot terbukti; Kopi Susu memiliki 2 baris transaksi berbeda harga | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-28 | Antigravity Pair |
| QA2-STEP-09 | QUERY-03 / ANALYTICS-01 | Layar analitik terverifikasi; voice tanya stok Kopi Susu dijawab Miki 28 gelas | PASS WITH DATA QUALITY GAP | `report_m4f31_qa_run2_step9.md` (M4F.31), `report_m4f32_qa_run2_step9b.md` (M4F.32) | Gap kualitas data HPP Rp0 pada laba bersih tercatat; rekonsiliasi revenue Rp94.000 valid | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-28 | Antigravity Pair |
| QA2-STEP-10 | PERSIST-01..04 / PERSIST-08 | Controlled process cold restart membuktikan ketahanan data bisnis dan gate AppLock; row-level internal audit belum diverifikasi independen | PASS WITH AUDIT GAP | `report_m4f33_qa_run2_step10.md` (M4F.33), `report_m4f34_applock_reconciliation.md` (M4F.34), `report_m4f35_applock_challenge.md` (M4F.35) | Data 4 produk, harga Rp14.000, stok 28, 5 transaksi utuh. AppLock memblokir akses sebelum PIN. Audit row SQLite open | POCO F4 GT (21121210G) | Android 13 / MIUI 14 | 1.0.0+1 (QA APK SHA-256 a9a1...3b1) | 2026-10-28 | Antigravity Pair |

## Three-Run Demo Smoke Test

Jalankan urutan ini tiga kali pada database uji baru. Catat setiap run terpisah.

1. Buka aplikasi dan unlock dengan PIN/biometric.
2. Buka Produk melalui suara.
3. Tambah produk `Kopi Susu`.
4. Tambah stok `Kopi Susu`.
5. Jual `Kopi Susu` tanpa menyebut harga.
6. Tanya omzet dan laba hari ini.
7. Ubah harga `Kopi Susu`.
8. Buat transaksi baru dan verifikasi harga baru.
9. Buka analitik dan tanya stok.
10. Restart aplikasi, verifikasi data, lalu periksa audit.

| Run | Device/build | Start | End | Result | Evidence | Bug |
|---|---|---|---|---|---|---|
| SMOKE-01 | POCO F4 GT / Production package `com.mikiezy.mikiezy` (User 0) | - | - | NOT RUN | - | Menunggu otorisasi pengujian pada database produksi bersih |
| SMOKE-02 | POCO F4 GT / Dual Apps XSpace `com.mikiezy.mikiezy` (User 999) | 2026-10-27 | 2026-10-27 | BLOCKED | `logcat_xspace.txt` | Lingkungan sandbox Xiaomi Dual Apps memblokir navigasi/autentikasi |
| QA-RUN-2 | POCO F4 GT / Isolated QA `com.mikiezy.mikiezy.qa` (User 0) | 2026-10-27 | 2026-10-28 | PASS WITH DOCUMENTED DEVIATIONS | M4F.21 s.d. M4F.35 reports & screens | 10/10 langkah fungsional selesai; Step 3 Lain-lain fallback diremediasi; Step 6/9 HPP Rp0 gap; VoiceActionAudits row unverified |
| SMOKE-03 | - | - | - | NOT RUN | - | - |

### QA Run 2 Retrospective & Hardware Matrix Mapping (POCO F4 GT)

#### A. Parameter Eksekusi QA Run 2
- **Perangkat**: Xiaomi POCO F4 GT (`21121210G` / `ingres_id`), Android 13, MIUI 14 (`V140`).
- **Paket Terisolasi**: `com.mikiezy.mikiezy.qa` (Android User 0).
- **Target APK SHA-256**: `A9A111605A5ADBFB752185998FAED7A29210C3E1AD82A638E1446AD03835E3B1`.
- **Paket Produksi Terlindungi**: `com.mikiezy.mikiezy` (User 0 dan User 999) tidak dimodifikasi dan tetap terisolasi.

#### B. Koreksi & Klarifikasi Historis
1. **H1 - Ucapan Step 3 & Kategori Fallback**:
   - Perintah suara asli: `"Tambah produk kopi susu harga dua belas ribu stok dua puluh gelas"`.
   - Parser suara tidak mengekstrak kategori karena kata "minuman" tidak diucapkan; sistem mengarahkan fallback aman ke kategori `"Lain-lain"`.
   - Kategori diperbaiki secara manual melalui edit UI terotorisasi pada M4F.25 menjadi `"Minuman"`. Status resmi: **REMEDIATED WITH DOCUMENTED DEVIATION**.
2. **H2 - Snapshot Diskon Es Teh Manis (`tx-002`)**:
   - Transaksi seeded `tx-002` mencatat: Unit Price `Rp 5.000`, Quantity `5`, Diskon Transaksi `Rp 2.000`, Total Bersih `Rp 23.000`.
   - Nilai `Rp 4.600` adalah rata-rata efektif per unit pasca diskon (`23.000 / 5`), bukan stored unit price line item.
3. **H3 - Koreksi Inferensi AppLock M4F.33 via Physical Challenge M4F.35**:
   - Laporan M4F.33 sempat menyimpulkan PIN non-aktif karena salah menafsirkan inisialisasi source code `bool pinEnabled = false;` di `AppState`.
   - Investigasi forensik M4F.34 dan uji tantangan fisik M4F.35 membuktikan:
     - PIN verifier tersimpan aktif di `FlutterSecureStorage` (`"Verifier PIN aman sudah aktif"`).
     - Pada cold restart resmi, `AppLockScreen` (`"Mikiezy terkunci"`) secara ketat menahan seluruh navigator dan menyembunyikan data bisnis dari UI accessibility tree sebelum pemilik membuka dengan PIN.
     - Terbukanya Dashboard pada dump M4F.33 merupakan anomali timing/race condition dump UI (4 detik dump window) atau unlock awal pemilik, bukan ketiadaan proteksi PIN.
4. **H4 - Rekonsiliasi Produk Terlaris (Dashboard vs Analitik)**:
   - Dashboard menampilkan `"Terlaris: Nasi Goreng"`, sedangkan Analitik menampilkan `"Produk Terlaris: Es Teh Manis"`.
   - Hasil audit kode sumber (`lib/screens/dashboard_screen.dart`, `lib/screens/reports_screen.dart`, `lib/domain/services/business_metrics_service.dart`):
     - Dashboard menerapkan filter periode `ReportPeriodType.today` (Hari ini). Pada hari pengujian, hanya Nasi Goreng (3 porsi) dan Kopi Susu (2 gelas) yang terjual. Maka terlaris hari ini = **Nasi Goreng** (3 unit).
     - Analitik menerapkan filter periode `ReportPeriodType.thisWeek` / `thisMonth` (Minggu ini). Transaksi seeded `tx-002` (Es Teh Manis, 5 porsi) masuk ke dalam minggu ini. Maka terlaris minggu ini = **Es Teh Manis** (5 unit).
     - Keduanya menggunakan ranking kuantitas (`BusinessTopProductRanking.quantity`). Perbedaan peringkat murni disebabkan oleh perbedaan jendela waktu agregasi (Hari ini vs Minggu ini) dan **bukan merupakan bug**.

#### C. Pemetaan Skenario Matrix Terpilih (POCO F4 GT Isolated QA)
- `P6C-13` (Price update persistence): **PASS** (Retail Kopi Susu Rp14.000 bertahan melewati force-stop dan restart).
- `P6C-14` (Second sale after price update): **PASS** (Transaksi kedua Rp14.000 tercatat, transaksi pertama Rp12.000 tetap tidak berubah).
- `PERSIST-01` (Product persistence): **PASS** (4 produk lengkap bertahan pasca cold restart).
- `PERSIST-02` (Stock persistence): **PASS** (Stok Kopi Susu 28 gelas bertahan pasca cold restart).
- `PERSIST-03` (Retail price persistence): **PASS** (Harga Rp14.000 bertahan pasca cold restart).
- `PERSIST-04` (Transaction & receipt persistence): **PASS** (5 transaksi buku kas Rp94.000 bertahan utuh).
- `PERSIST-05` (Settings persistence): **NOT TESTED / GAP** (Siklus modifikasi setelan silence/privacy dan verifikasi pasca restart belum diuji secara formal).
- `PERSIST-08` (AppLock persistence): **PASS** (Terbukti secara empiris pada M4F.35; `AppLockScreen` memblokir akses sebelum PIN dimasukkan).
- `AUDIT-01` s.d. `AUDIT-06` (Internal voice action audit): **NOT INDEPENDENTLY VERIFIED** (Pencatatan event pada tabel SQLite `voice_action_audits` belum diinspeksi secara baris data independen pada uji fisik read-only ini).

#### D. Status Kesiapan Rilis Phase 7A
- Status Rilis: **NO-GO**.
- Alasan: Pengujian pada paket terisolasi `com.mikiezy.mikiezy.qa` membuktikan fungsi bisnis inti dan voice immutability berjalan baik, namun smoke test produksi pada `com.mikiezy.mikiezy` (0/3), pengujian XSpace (`SMOKE-02 BLOCKED`), dan mayoritas dari 234 skenario hardware belum tuntas. Build APK masih menggunakan signing debug.
