# Android Release Signing

## Current Status

Mikiezy belum memiliki production signing configuration. Build type `release`
saat ini memakai Android debug key:

```kotlin
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("debug")
    }
}
```

APK tersebut boleh dipakai sebagai internal release candidate, tetapi tidak
boleh disebut production-ready atau diunggah sebagai build final Play Store.

Jangan membuat keystore palsu untuk melewati pemeriksaan release. Jangan commit
keystore, password, `key.properties`, atau output command yang berisi secret.

## Secret Handling

Pola berikut sudah di-ignore:

- `*.jks`
- `*.keystore`
- `**/key.properties`
- `.env` dan `.env.*`

Simpan keystore produksi di password manager/secure backup organisasi, di luar
repository dan di luar folder sinkronisasi publik. Pastikan minimal dua pemilik
yang berwenang dapat memulihkan keystore.

## Preparation

1. Putuskan application ID final dan pastikan kepemilikannya:
   `com.mikiezy.mikiezy`.
2. Putuskan version name dan version code untuk candidate.
3. Buat keystore melalui proses release resmi organisasi, bukan otomatisasi
   repository ini.
4. Simpan alias dan password di secret manager/CI secret.
5. Buat `android/key.properties` secara lokal dengan placeholder yang diganti
   melalui secret:

```properties
storeFile=C:\\secure-path\\mikiezy-upload.jks
storePassword=<secret>
keyAlias=<secret>
keyPassword=<secret>
```

6. Konfigurasikan `signingConfigs.release` di
   `android/app/build.gradle.kts` setelah credential resmi tersedia.
7. Jangan memberi fallback ke debug signing pada pipeline produksi.

## Validation

Setelah release signing resmi tersedia:

```powershell
flutter clean
flutter pub get
flutter test
flutter analyze
flutter build appbundle --release
flutter build apk --release
```

Verifikasi signer:

```powershell
apksigner verify --verbose --print-certs app-release.apk
```

Acceptance criteria:

- Certificate DN bukan `CN=Android Debug`.
- SHA-256 certificate cocok dengan release record resmi.
- Build dapat di-install sebagai upgrade pada candidate dengan signer yang sama.
- Tidak ada secret pada `git status`, APK log, screenshot, atau artefak CI.
- Backup dan recovery keystore telah diuji oleh pemilik release.

## iOS

Build iOS membutuhkan macOS, Apple development team, certificate, dan
provisioning profile resmi. Project memakai automatic signing tetapi belum
memiliki `DEVELOPMENT_TEAM` yang terkonfigurasi. Jangan mengklaim iOS
release-ready sebelum archive ditandatangani dan diuji pada device iOS nyata.
