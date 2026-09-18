# Status jalur 2 — Pendamping
Diperbarui: 10:00

## Sedang dikerjakan
2.2 Integrasi j1-papan — B1/B2 membuka BoardScreen nyata; sinkron/outbox dan ekspor JSON sudah ditulis; analyzer bersih, 15 tes lulus (1 skip simbol)

## Tonggak selesai (tag)
- (kosong)

## Perkiraan tonggak berikutnya
j2-layar siap merge ke main; jalur 1 memasang titik masuk sesudahnya

## Terblokir oleh
- Uji sinkron nyata menunggu j3-auth; klien sudah ditulis terhadap EventDao nyata

## Permintaan ke jalur lain
- ke jalur 1: ganti PlaceholderOnboarding dengan `const OnboardingFlow()` dari `features/onboarding/onboarding_flow.dart`
- ke jalur 1: ganti PlaceholderHome dengan `const HomeScreen()` dari `features/coach/home_screen.dart`

## Perubahan API/kontrak yang perlu diketahui
- Mengikuti API j1-kerangka apa adanya; tidak ada perubahan kontrak

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- (kosong)
