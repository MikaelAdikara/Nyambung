# Status jalur 2 — Pendamping
Diperbarui: 10:06

## Sedang dikerjakan
2.5/2.6 Sinkron + terapis — redeem/cabut tertunda/push/pull target selesai ditulis; menunggu uji nyata terhadap server

## Tonggak selesai (tag)
- j2-layar (10:00): seluruh layar terhubung AppState/DAO; analyzer bersih, 15 tes lulus (1 skip simbol), APK debug terbangun

## Perkiraan tonggak berikutnya
j2-misi setelah jalur 1 memasang titik masuk; j2-sinkron setelah uji HP → server

## Terblokir oleh
- j3-auth sudah terbuka; perlu kode undangan/token dan alamat server hidup untuk uji nyata

## Permintaan ke jalur lain
- ke jalur 1: ganti PlaceholderOnboarding dengan `const OnboardingFlow()` dari `features/onboarding/onboarding_flow.dart`
- ke jalur 1: ganti PlaceholderHome dengan `const HomeScreen()` dari `features/coach/home_screen.dart`

## Perubahan API/kontrak yang perlu diketahui
- Mengikuti API j1-kerangka apa adanya; tidak ada perubahan kontrak

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
