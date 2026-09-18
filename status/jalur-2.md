# Status jalur 2 — Pendamping
Diperbarui: 10:45

## Sedang dikerjakan
2.8 sisa: C2 sembunyikan kata dan C3 kartu foto tidak dikerjakan (urutan buang #1). Pengerasan bersama jalur 1.

## Tonggak selesai (tag)
- j2-layar (10:00): seluruh layar terhubung AppState/DAO
- j2-misi: B1 → B2 → papan bersama → pendamping tekan MAU 2× → "2 dari 5"; B6 Selesai → 1 peristiwa MIS + `mission_log`
  (`reps_counted` dari ketukan); B3 lima pelajaran dari 02 §6
- j2-pemasangan: A1–A6 di emulator; A5 merekam suara keluarga sungguhan (`record`, izin mikrofon; tolak izin → pesan
  tenang, tanpa crash). Rekaman dipakai saat pendamping mengetuk MAU (MediaPlayer, bukan TTS), tidak pernah disinkronkan
- j2-sinkron: tebus kode → token tersimpan → kirim otomatis; 9 ketukan → server `accepted 9, duplicates 0`, lokal = server;
  server mati → kartu "Tidak ada jaringan saat ini. 1 catatan…" (tanpa kata gagal). Uji mati paksa/duplikat: simulator jalur 3
- j2-terapis: usulan BERHENTI dari server → kartu usulan di B1 + C5 → Terima → TGT lewat outbox → misi berganti ke BERHENTI;
  cabut akses saat luring → tertunda → terkirim otomatis saat tersambung (server: 0 keluarga, token dihapus)
- j2-pengaturan: C6 Uji alamat server memanggil `/v1/health` sungguhan; Uji suara dua nada berurutan + ketersediaan TTS id-ID
  + jeda ms; tahan-untuk-memilih; ganti rutinitas; ekspor JSON; Diagnosa; Hapus semua data dua langkah → kembali ke A1
- C1 Perkembangan: 6 pekan terakhir, terbaru di atas, kata baru dengan simbol

## Perkiraan tonggak berikutnya
Integrasi `int-1-hp-ke-d2` menunggu dasbor jalur 4 (D2)

## Terblokir oleh
- (kosong)

## Permintaan ke jalur lain
- ke jalur 1: "Hapus semua data" juga harus menghapus folder rekaman keluarga (`app_flutter/family/`) — privasi invarian 18.

## Perubahan API/kontrak yang perlu diketahui
- Tidak mengubah kontrak. Kirim otomatis: saat beranda dibuka, kembali dari papan/misi, setelah tebus kode, setelah
  konfirmasi misi dan jawaban usulan (maks sekali per 10 detik untuk pemicu otomatis).

## Perubahan terhadap proposal (untuk PERUBAHAN.md, dibaca jalur 4)
- C2 kelola kosakata dan C3 kartu foto tidak dikerjakan (urutan buang #1 di rencana). Rekaman keluarga (S14) dibuat untuk
  satu kata (MAU, kata misi pertama) di A5; C4 rekaman per kata belum ada.
