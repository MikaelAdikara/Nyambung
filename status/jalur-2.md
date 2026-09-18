# Status jalur 2 — Pendamping
Diperbarui: 13:55

**Mulai 11:20 semua jalur bekerja langsung di `main`** (tidak ada lagi kerja paralel; branch jalur sudah tergabung).

## Sedang dikerjakan
Layar mockup A–C lengkap (18 Sep siang). Belum dibuka di emulator: C3, C5 baru, C6 baru, kartu B1, A5/A6 baru.

## Tonggak selesai (tag)
- (13:55, tanpa tag) C5: kartu profil terapis + lama terhubung, usulan menunggu, daftar dibagikan (kotak) vs tidak
  pernah dikirim (belah ketupat), ringkasan sesi dari terapis (ditarik saat sinkron), catatan UU PDP 27/2022, Cabut akses.
  C6 ditata ulang: susunan sel, Kunci mode anak (screen pinning, bawaan aktif), suara papan, tahan, rutinitas,
  pintasan C4/C2, ukuran data, ekspor, hapus semua, Batas produk, atribusi Mulberry. **Belum dicek di emulator**
- (13:55, tanpa tag) A5 merekam 6 kata yang paling sering dicontohkan (kata berikutnya terpilih sendiri, Lewati
  setara). A6 "Buka misi hari ini" / "Lihat papan dulu", dijalankan sekali oleh beranda. **Belum dicek di emulator**
- (13:55, tanpa tag) B1 kartu "Sepekan ini" (kata berbeda pekan ini, batang 7 pekan, titik misi 7 hari isi/garis) dan
  "Buka Papan Bicara" (4 kata keluarga). B6 menampilkan jumlah modeling kata target hari ini dan status kirim ke
  terapis, teks setara untuk Selesai/Belum sempat. C1 pilihan rentang, kartu kata berbeda, kata terbanyak, porsi
  spontan (legenda berbentuk), hari misi selesai. **Belum dicek di emulator**
- (13:55, tanpa tag) C3 Kartu dari foto: kamera/galeri bawaan (`image_picker`, tanpa izin kamera), foto 512 px
  disalin ke `cards/`, label huruf kapital, pilih halaman, kartu mengisi slot kosong berikutnya; foto dipulihkan bila
  Android menutup aplikasi saat kamera terbuka. Ketukan kartu = `PRS`. B5 slot kosong bergaris putus-putus. C2 tombol
  "Tambah kartu baru"; C4 ikut menampilkan kartu personal. Analyzer + tes lulus, **belum dicek di emulator**
- (11:20, tanpa tag) C2 Kelola kosakata, C4 Suara keluarga per kata inti, pilihan Suara papan cowok/cewek,
  Sekarang → Nanti, "Hari ini" di C1, sinkron otomatis tiap 20 dtk + saat aplikasi aktif. C2 dan C1 diuji di emulator
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
