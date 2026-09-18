# Demo dan benchmark Papan dari Foto

Gunakan foto benda atau kegiatan yang dibuat khusus untuk demo dan tidak memuat wajah, nama, dokumen, alamat, atau
informasi pribadi. Siapkan satu papan manual sebagai cadangan yang diberi label jelas sebagai hasil manual.

## Demo 120 detik

1. Buka **Pengaturan → Papan dari foto → Buat papan dari foto** dan ambil foto kegiatan.
2. Tekan **Bantu pilih dengan AI**, baca dialog persetujuan, lalu kirim. Tunjukkan bahwa hasilnya masih berupa draf.
3. Geser atau ubah ukuran satu area, perbaiki satu kata, lalu simpan.
4. Matikan koneksi atau aktifkan mode pesawat. Buka mode anak → tab **FOTO**, pilih papan, dan susun pesan dari hotspot
   serta kata inti. Bilah ujaran dan suara tetap bekerja.
5. Keluar dari papan, sinkronkan, lalu muat ulang dashboard untuk menunjukkan bahwa ketukan memakai event KAT/PRS yang
   sama. Jangan menyebut dashboard realtime.

Kalimat demo: **“Foto kegiatan keluarga menjadi papan komunikasi yang diperiksa keluarga dan tetap bisa dipakai tanpa internet.”**

## Benchmark yang dapat direproduksi

Buat manifest lokal sesuai contoh pada docstring `tools/benchmark_scene_ai.py`. Kotak memakai koordinat ternormalisasi
yang ditandai manual. Jalankan server satu worker, lalu:

```powershell
server\.venv\Scripts\python.exe tools\benchmark_scene_ai.py tools\.sim\scene-manifest.json `
  --child <child_id> --token <device_token>
```

Script melaporkan median latensi dan recall pasangan kata+kotak pada IoU ≥ 0,5. Simpan tanggal, model dari respons,
jumlah foto, jenis perangkat/koneksi, dan semua kegagalan. Jangan menampilkan angka benchmark sebelum pengukuran nyata;
repo tidak menyertakan foto pengguna atau hasil yang direkayasa.

## Batas klaim

- AI mempercepat authoring draf; keluarga menentukan papan final.
- Hasil final bisa digunakan luring. Pembuatan draf AI membutuhkan server dan internet.
- Fitur tidak mengenali niat, emosi, hubungan, diagnosis, atau kemampuan anak.
- Benchmark teknis bukan bukti manfaat klinis.
