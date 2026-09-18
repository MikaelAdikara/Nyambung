# Nyambung — Nilai Bisnis, Model Bisnis, dan Skalabilitas

Disusun 18 Sep 2026 untuk slide "Nilai bisnis" dan Q&A. Aturan yang sama dengan `naskah-pitch.md`: angka hanya dari
sumber yang tercatat di bagian "Asal angka". Semua harga jual di dokumen ini adalah **hipotesis tim (tingkat D)** yang
divalidasi di pilot, bukan harga yang sudah disepakati klien.

Kurs yang dipakai: **Rp16.500/US$** (asumsi, belum dicek hari ini), ditambah **±11% PPN** untuk layanan digital luar
negeri (asumsi; cocokkan dengan tagihan pertama).

---

## 1. Slide "Nilai bisnis" (siap tempel)

**Judul:** Keluarga gratis. Institusi yang membayar.

**Tiga kolom:**

| Keluarga (pengguna) | Terapis & institusi (pembayar) | Pemerintah & mitra (skala) |
|---|---|---|
| **Gratis selamanya** untuk papan, suara, misi harian, dan sinkron | Dasbor pantau, usulan kata, ringkasan sesi | Program SLB, layanan tumbuh kembang, CSR |
| Suara anak tidak pernah dikunci di balik langganan | Satu terapis bisa memantau lebih banyak keluarga *(asumsi, diuji di pilot)* | Masuk setelah pilot membuktikan retensi |

**Baris bawah (angka):**
- Biaya tambahan per keluarga untuk papan dan suara 120 kata: **≈ Rp0**. Suaranya dibuat sekali (< US$0,20), dibundel di APK, diputar tanpa internet.
- Fitur premium suara keluarga (klon suara): **± Rp2–4 rb per keluarga per bulan** (target, dengan klon sementara). Dibayar klinik atau sponsor, bukan keluarga.
- Tumbuh lewat terapis: **setiap kode undangan terapis = satu keluarga baru**.

**Naskah (± 25 detik):**

> "Siapa yang membayar? Bukan keluarga. Suara anak tidak boleh bergantung pada kemampuan membayar, jadi papan,
> suara, dan misi harian gratis selamanya. Karena semuanya jalan di HP tanpa internet, biaya tambahan per keluarga
> hampir nol. Yang membayar adalah terapis dan institusi, karena merekalah yang mendapat dasbor pantau dan data dari
> rumah di antara sesi. Kami tumbuh lewat terapis: setiap kode undangan adalah satu keluarga baru. Setelah pilot
> membuktikan retensi, jalurnya ke sekolah luar biasa dan program pemerintah."

---

## 2. Model bisnis: B2B2C lewat institusi, bukan B2C

**Jawaban singkat untuk juri:** Nyambung adalah **B2I** (*business-to-institution*) dengan pola **B2B2C**. Institusi
(klinik tumbuh kembang, praktik terapis wicara, SLB, sekolah inklusi, yayasan) membayar. Keluarga masuk lewat kode
undangan institusinya dan tidak membayar. **B2G** adalah tahap ketiga, bukan pintu masuk.

### Kenapa bukan B2C (keluarga membayar)
1. **Etika AAC:** memungut bayaran untuk "bisa bicara" bertentangan dengan *presume competence*. Kalau langganan
   habis, anak kehilangan suaranya.
2. **Masalah intinya penelantaran alat** (29,3% alat ditinggalkan; Phillips & Zhao 1993). Hambatan harga menambah
   alasan untuk berhenti.
3. **Nilai terbesar dirasakan terapis**: data rumah di antara sesi dan triase beralasan. Yang mendapat nilai, dia
   yang membayar.

### Kenapa tidak langsung B2G
- Pengadaan pemerintah lambat dan butuh bukti. Kami belum punya hasil pilot.
- Syarat teknis belum terpenuhi: HTTPS, enkripsi di perangkat, dan kesiapan UU PDP untuk skala besar (batasan yang
  sudah kami tulis terbuka).
- Setelah pilot memberi bukti retensi, B2G jadi jalur skala, bukan jalur bertahan hidup.

### Siapa membayar apa (hipotesis harga, tingkat D)

| Paket | Isi | Pembayar | Hipotesis harga |
|---|---|---|---|
| **Keluarga** | Papan 120 kata, suara bawaan, rekaman suara keluarga di HP, misi harian, sinkron | — | **Gratis selamanya** |
| **Terapis** | Dasbor D1–D4, usulan kata, catatan sesi, papan pantau hingga ± 20 keluarga | Praktik terapis wicara | Rp150–250 rb / terapis / bulan |
| **Institusi** | Paket terapis untuk banyak terapis + admin + laporan institusi | Klinik, SLB, RS, yayasan | Per terapis aktif, diskon volume |
| **Add-on suara & foto** | Klon suara keluarga, frasa bersuara, draf papan foto dengan AI | Institusi atau sponsor CSR | Dihitung per keluarga aktif (lihat §3) |

Sumber pendapatan lain yang realistis: **hibah dan CSR** (mensponsori add-on suara untuk keluarga), **program startup
penyedia** (mis. ElevenLabs Startup Grants), dan **pelatihan institusi** (modul *aided language modeling* untuk
guru SLB dan kader).

---

## 3. Biaya per keluarga (dicek 18 Sep 2026)

| Komponen | Cara bayar | Biaya | Catatan |
|---|---|---|---|
| Papan, 120 kata, simbol | Sekali | ≈ Rp0 per keluarga | Simbol Mulberry CC BY-SA 4.0; suara 2 × 120 klip < US$0,20 total, dibundel di APK |
| Pemakaian anak sehari-hari | — | Rp0 | Luring penuh; tidak ada panggilan server saat anak bicara |
| Sinkron + dasbor | VPS | ± Rp100–150 rb / bulan untuk pilot satu klinik | **Estimasi**; kapasitas per VPS belum diukur |
| Frasa bersuara (OpenAI `gpt-4o-mini-tts`) | Per frasa | < Rp20 per frasa → < Rp500 / keluarga / bulan (±30 frasa) | Diturunkan dari 240 klip < US$0,20; audio dibuat sekali lalu diputar luring |
| Klon suara keluarga (ElevenLabs) | Langganan | Lihat tabel di bawah | Opsional, atas persetujuan orang tua |
| Draf papan foto (Gemini) | Per foto | **Belum diukur** | Kunci belum dipasang; dibatasi 10 percobaan / anak / hari di server |

### Klon suara ElevenLabs (halaman harga resmi, dibuka 18 Sep 2026)

Satu keluarga memakai satu slot suara. Pemakaian realistis ± 1.000 karakter per keluarga per bulan (frasa maksimal
60 karakter; ± 30 frasa).

| Paket | US$/bulan | Kredit/bulan | Slot suara | **A. Klon permanen** (slot yang membatasi) | **B. Klon sementara** (kredit yang membatasi) |
|---|---|---|---|---|---|
| Starter | 6 | 30 rb | 10 | 10 keluarga · ± Rp11 rb/keluarga | 30 keluarga · ± Rp3,7 rb |
| Creator | 11 | 121 rb | 30 | 30 keluarga · ± Rp6,7 rb | 121 keluarga · ± Rp1,7 rb |
| Pro | 99 | 600 rb | 160 | 160 keluarga · ± Rp11 rb | 600 keluarga · ± Rp3 rb |
| Scale | 299 | 1,8 jt | 660 | 660 keluarga · ± Rp8,3 rb | 1.800 keluarga · ± Rp3 rb |
| Business | 990 | 6 jt | 2.200 | 2.200 keluarga · ± Rp8,2 rb | 6.000 keluarga · ± Rp3 rb |

- **A. Klon permanen** adalah cara server sekarang: satu `voice_id` disimpan per keluarga.
- **B. Klon sementara**: HP mengunggah sampel → server membuat klon → membuat frasa → klon langsung dihapus. Slot
  tidak menumpuk, jadi biaya turun ke **± Rp2–4 rb per keluarga**. Server tetap tidak menyimpan rekaman (invarian 18).
  **Belum dibangun.** Perlu dicek dulu apakah pembuatan klon memotong kredit dan apakah ElevenLabs membatasi
  frekuensi buat-hapus klon.
- Model Flash memakai setengah kredit per karakter (API: US$0,05 vs US$0,10 per 1.000 karakter). Mutu untuk Bahasa
  Indonesia harus didengar dulu.

**Untuk hackathon: Starter US$6 (± Rp110 rb termasuk PPN) cukup.** Isinya 10 keluarga demo, lisensi komersial, dan
3 permintaan bersamaan. Kode tidak perlu diubah; kunci yang sama langsung aktif setelah upgrade.

### Ilustrasi unit ekonomi satu terapis (semua asumsi D)

Satu terapis memantau 20 keluarga, dengan semua add-on aktif dan klon sementara (B):

| Biaya / bulan | Perkiraan |
|---|---|
| Klon suara 20 keluarga | ± Rp35–75 rb |
| Frasa bersuara 20 keluarga | < Rp10 rb |
| Bagian server (1 VPS dibagi beberapa terapis) | ± Rp25–50 rb |
| **Total** | **± Rp70–135 rb** |

Dengan hipotesis harga Rp150–250 rb per terapis per bulan, paket ini masih menutup biaya variabel. Dengan klon
permanen (A) di paket Starter, 20 keluarga butuh dua akun (Rp220 rb) dan marginnya habis. **Karena itu klon
sementara (B) adalah syarat sebelum add-on suara dijual.**

---

## 4. Skalabilitas

### Teknis: biaya tidak naik bersama pemakaian anak
- **Local-first:** papan, suara, misi, dan pencatatan jalan di HP. Seribu ketukan anak tidak menambah biaya server.
- **Server hanya menerima peristiwa mentah** berukuran kecil, idempoten per `event_id`. Ringkasan dihitung di server.
- **Audio dibuat sekali lalu diputar luring.** Biaya AI hanya muncul saat frasa dibuat, bukan setiap kali diputar.
- **Hambatan yang sudah diketahui:** server memakai SQLite, cukup untuk pilot satu klinik. Untuk banyak klinik perlu
  pindah ke Postgres (semua SQL server sudah terkumpul di satu tempat, lihat README). HTTPS belum ada.
- Target perangkat Android 8, RAM 2 GB: tidak perlu HP mahal untuk ikut.

### Manusia: masalah sebenarnya adalah jumlah terapis
- Terapis langka dan terpusat (masalah M4). Nyambung memindahkan pekerjaan **mengumpulkan informasi** dari terapis,
  bukan penilaian klinisnya.
- Asumsi yang diuji di pilot: tinjauan 5 menit per anak → **satu jam terapis memantau dua belas keluarga**.
- Orang tua menjadi mitra komunikasi lewat misi < 5 menit sehari, jadi intervensi berjalan di antara sesi.

### Distribusi: tumbuh lewat jaringan yang sudah ada

| Tahap | Waktu (rencana) | Pintu masuk | Bukti yang dibutuhkan |
|---|---|---|---|
| **0. Pilot** | 6 pekan | 1 terapis wicara, beberapa keluarga | Retensi hari ke-14 ≥ 60% |
| **1. B2I awal** | Setelah pilot | Klinik tumbuh kembang dan praktik terapis wicara (berbayar) | Terapis mau membayar; waktu tinjauan per anak |
| **2. B2I luas** | Tahun pertama | SLB, sekolah inklusi, yayasan autisme, kampus terapi wicara | HTTPS, enkripsi, admin institusi, Postgres |
| **3. B2G + CSR** | Setelah ada data multi-institusi | Pemerintah daerah (SLB), layanan tumbuh kembang, sponsor | Hasil pilot, kepatuhan UU PDP, rekam jejak |

Efek jaringan sederhana: **satu terapis membawa banyak keluarga**, satu institusi membawa banyak terapis.

---

## 5. Risiko dan batasan (sebutkan bila ditanya)

1. **Harga jual belum divalidasi.** Rp150–250 rb per terapis adalah hipotesis; pilot harus menanyakan kesediaan
   membayar.
2. **Kapasitas server belum diukur.** Estimasi VPS berasal dari harga VPS kecil, bukan uji beban.
3. **Ketergantungan penyedia AI** (OpenAI, ElevenLabs, Gemini) untuk fitur opsional. Fitur inti tetap jalan tanpa
   penyedia mana pun; rekaman keluarga per kata adalah cadangan gratis.
4. **Klon sementara belum dibangun.** Tanpa itu, add-on suara hanya ekonomis untuk puluhan keluarga.
5. **Ukuran pasar belum dihitung dengan data resmi.** Jangan menyebut jumlah anak autis di Indonesia sebelum ada sumber
   yang dicek.
6. **B2G bergantung pada bukti pilot** dan kesiapan keamanan (HTTPS, enkripsi, UU PDP).

---

## 6. Jawaban Q&A

| Pertanyaan | Jawaban |
|---|---|
| Model bisnisnya apa? | B2I dengan pola B2B2C. Institusi dan terapis membayar dasbor dan add-on; keluarga gratis selamanya. B2G tahap tiga setelah pilot. |
| Kenapa keluarga tidak bayar? | Suara anak tidak boleh dikunci langganan, dan hambatan harga menambah alasan alat ditinggalkan. Biaya tambahan per keluarga hampir nol karena semuanya luring. |
| Kalau penggunanya jutaan, biayanya meledak? | Tidak untuk fitur inti: pemakaian anak tidak memanggil server. Yang bertambah hanya fitur opsional (klon suara ± Rp2–4 rb per keluarga per bulan dengan klon sementara), dibayar institusi atau sponsor. |
| Kenapa pakai ElevenLabs, tidak mahal? | Hanya untuk fitur opsional dengan persetujuan orang tua. Untuk demo cukup US$6 per bulan. Untuk skala kami menghapus klon setelah frasa dibuat sehingga biaya per keluarga ± Rp2–4 rb. Rekaman keluarga per kata tetap gratis dan tidak meninggalkan HP. |
| Siapa kompetitor yang membayar? | Klaim fitur kompetitor belum dicek ke situs resmi (lihat `naskah-pitch.md`). Jangan dibandingkan dengan harga kompetitor sebelum dicek. |
| Bagaimana masuk ke pemerintah? | Setelah pilot memberi data retensi dan keamanan sudah siap. Pintu pertama: SLB dan layanan tumbuh kembang di daerah pilot. |

---

## Asal angka

| Angka | Sumber |
|---|---|
| Starter US$6, Creator US$11, Pro US$99, Scale US$299, Business US$990; kredit 30 rb / 121 rb / 600 rb / 1,8 jt / 6 jt | elevenlabs.io/pricing, dibuka 18 Sep 2026 |
| Slot suara kustom 10 / 30 / 160 / 660 / 2.200; Starter sudah termasuk Instant Voice Cloning | Tabel perbandingan elevenlabs.io/pricing, 18 Sep 2026 |
| API TTS v2 Multilingual US$0,10 per 1.000 karakter; Flash US$0,05 | elevenlabs.io/pricing/api, 18 Sep 2026 |
| Akun free ditolak klon suara (`paid_plan_required`) | Uji langsung server ke API ElevenLabs, 18 Sep 2026 |
| Startup Grants: 12 bulan, 33 jt karakter | elevenlabs.io/pricing, 18 Sep 2026 |
| `gpt-4o-mini-tts`: US$0,60 per 1 jt token teks, US$12 per 1 jt token audio | developers.openai.com/api/docs/pricing, 18 Sep 2026 |
| Suara 2 × 120 klip < US$0,20 | `PERUBAHAN.md` entri 3 |
| Server pilot ± Rp100–150 rb/bulan | **Estimasi** dari `naskah-pitch.md`, belum harga penyedia nyata |
| Frasa maksimal 60 karakter, batas 30 frasa per anak per hari, 10 analisis foto per anak per hari | `server/app/schemas.py`, `server/app/main.py`, `server/app/routes/scene_ai.py` |
| 29,3% alat ditinggalkan | Phillips & Zhao (1993), `03-basis-ilmiah.md` §1 |
| 12 keluarga per jam terapis | **Asumsi** di `naskah-pitch.md` slide 12 |
| Rp16.500/US$, PPN ±11% | **Asumsi**, cocokkan sebelum tampil |
| Harga jual Rp150–250 rb per terapis per bulan; 20 keluarga per terapis | **Hipotesis tim (D)** |
