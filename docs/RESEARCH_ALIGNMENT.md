# AI Research Alignment

## Established scope

- REPORTED: Pemilik menyatakan Mikiezy merupakan skripsi peminatan Artificial Intelligence; pemahaman perintah transaksi Bahasa Indonesia kandidat fokus utama. Rumusan masalah, metode final, dataset dan acceptance criteria akademis belum ditetapkan pada konteks tersedia.
- VERIFIED: `voice_intent_classifier.dart` menggunakan pencocokan frasa/regex dengan confidence tetap. `voice_slot_extractor.dart` dan extractor khusus membaca quantity, unit, nominal, produk, kategori/dompet dengan aturan serta parser angka Indonesia.
- VERIFIED: Product resolver memakai exact/alias/fuzzy similarity dan ambiguity thresholds. Adaptive Voice Learning menyimpan alias/koreksi lokal setelah transaksi; tidak ada bukti gradient training, learned weights atau calibrated probabilities.
- VERIFIED: Speech-to-text dan text-to-speech menggunakan engine plugin eksternal. Akurasi ASR tidak sama dengan akurasi NLP transaksi; prototype tidak melatih acoustic/wake-word model sendiri.
- VERIFIED: Tidak ditemukan LLM runtime, inference model artifact, training/evaluation pipeline penelitian, atau dataset berlabel pada source yang diperiksa. Unit/regression tests bukan pengganti evaluasi generalisasi model.

## Proposed research design, not approved decisions

- PROPOSED: Jadikan parser rule-based saat ini baseline yang dibekukan per commit. Bandingkan dengan kandidat LLM structured extraction dan hybrid resolver/validator jika disetujui dosen dan pemilik.
- PROPOSED: Definisikan output terstruktur: intent, item boundaries, nama produk, quantity, unit, harga satuan/total, diskon, wallet/kategori dan ambiguity. Output model hanya kandidat; domain guard tetap pemegang otoritas eksekusi.
- PROPOSED: Pisahkan eksperimen NLP pada transcript ground truth dari eksperimen end-to-end pada output STT. Ini membedakan kegagalan ASR, intent, slot, resolver, dan adapter preview.
- PROPOSED: Dataset mencakup angka kata/digit/pecahan, multi-item tanpa separator, filler, harga sebelum quantity, produk bernomor/ukuran, ambiguity, out-of-scope, dan command berbahaya. Ini daftar kebutuhan cakupan, bukan corpus yang sudah tersedia.
- PROPOSED: Annotator menyusun ground truth dan adjudication; pisahkan train/dev/test berdasarkan speaker/skenario serta hindari kebocoran alias/koreksi/test templates. Bekukan test set sebelum tuning.
- PROPOSED: Ukur intent macro-F1, slot/entity F1, exact structured transaction accuracy, item recall/drop rate, akurasi resolver/abstention, unsafe execution rate, latency dan resource/cost. Tambahkan WER/CER hanya untuk evaluasi ASR dengan pasangan referensi.
- PROPOSED: Laporkan confidence heuristik sebagai score, bukan probabilitas terkalibrasi. Jika menilai calibration, gunakan model dan prosedur evaluasi yang memang mendukungnya.
- PROPOSED: Semua model menerima input yang diizinkan dan direduksi; jangan mengunggah transaksi/transcript pengguna tanpa consent. Learning DB bukan dataset otomatis dan prompt/model version harus dicatat untuk reproduksibilitas.

## Questions requiring owner/advisor decision

- PROPOSED: Konfirmasi rumusan masalah, target intent/slot, model offline/cloud, Bahasa Indonesia/dialek, budget, consent/dataset ownership, annotation protocol, split policy dan metrik keberhasilan.
- PROPOSED: Konfirmasi apakah LLM comparison masuk scope skripsi atau hanya kandidat. Tidak ada integrasi LLM yang diotorisasi oleh dokumentasi M1.
