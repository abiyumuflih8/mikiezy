---
trigger: model_decision
description: Prinsip kesederhanaan, presisi bedah, dan verifikasi terarah (Karpathy principles) saat debugging, code review, dan melakukan perubahan kode Dart/Flutter pada Mikiezy.
---

# Karpathy Principles for Mikiezy

1. **Think Before Coding**: Selidiki mekanisme akar masalah sebelum mengedit. Rumuskan hipotesis teknis dan verifikasi asumsi secara terarah. Dilarang melakukan modifikasi spekulatif atau coba-coba.
2. **Simplicity First**: Pilih solusi Dart paling langsung dan sederhana. Hindari layer abstraksi, wrapper, atau class helper baru kecuali jika ada alasan teknis yang jelas dan disepakati.
3. **Surgical Changes**: Terapkan diff minimum (*minimal viable diff*). Sentuh hanya baris dan berkas yang esensial. Dilarang memformat ulang kode sekitar atau melakukan refactor sampingan.
4. **Preserve Invariants**: Pertahankan arsitektur aktual: custom ChangeNotifier/InheritedNotifier, Drift v6, financial snapshot, lifecycle STT/TTS, dan safety boundaries mutasi suara.
5. **Goal-Driven Verification**: Tetapkan kriteria sukses sebelum eksekusi. Gunakan verifikasi proporsional: prioritaskan targeted diagnostic/test sebelum memperluas ke pengujian menyeluruh.
