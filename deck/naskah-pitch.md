# Nyambung — Naskah Pitch Final (5 menit)

Hackathon IFEST 2026 · *Tech for Human Connections* · Tim Teen Tensors

Pasangan berkas: `deck/Nyambung-Pitch-Deck.pptx` (dan `.pdf`). Naskah per slide juga ada di *speaker notes*.
Sumber riset: `docs/hackday/03-basis-ilmiah.md` dan `deck/riset-pendukung.md`. Model bisnis: `deck/model-bisnis.md`.

**Arah naskah ini.** Demo alur lengkap sudah ada di **video demo** (deliverable terpisah). Pitch langsung **tidak
memperagakan aplikasi**; waktunya dipakai untuk empat aspek penilaian: **(1) masalah, solusi, dan realisasi,
(2) fungsionalitas dan ketepatan teknologi, (3) kelayakan dan dampak, (4) penyampaian.** Slide solusi menjelaskan
*apa yang kami ciptakan* dan *kenapa teknologinya tepat*, dengan tangkapan layar asli sebagai bukti.

**Cara pakai.** Hafalkan maksud tiap bagian, bukan kata per kata. Kalimat bercetak tebal harus keluar. Nada: empati di
pembuka dan penutup, klinis di tengah. Sebut sumber, sebut batas, jangan melebih-lebihkan.

---

## Peta waktu

| Waktu | Slide | Bagian | Aspek juri |
|---|---|---|---|
| 0:00–0:10 | Judul *(manual)* | Perkenalan tim | 4 |
| 0:10–0:20 | 1 | Hook: pertanyaan | 1 |
| 0:20–0:45 | 2 | Hook: Ethan | 1 |
| 0:45–1:08 | 3 | Masalah dan data | **1** |
| 1:08–1:22 | 4 | Celah di antara fitur | 1 |
| 1:22–1:42 | 5 | Nyambung: satu loop, bukan sekadar AAC | **1** |
| 1:42–2:10 | 6 | Yang kami ciptakan untuk anak dan keluarga | 1, 2 |
| 2:10–2:25 | 7 | Kenapa misinya dirancang begini (riset) | 1 |
| 2:25–2:47 | 8 | Yang kami ciptakan untuk terapis | 1, 2 |
| 2:47–3:17 | 9 | Ketepatan teknologi dan arsitektur | **2** |
| 3:17–3:32 | 10 | Basis ilmiah dan opini FORMAPI UB | 1, 2 |
| 3:32–3:42 | 11 | Asal aset | 2 |
| 3:42–4:10 | 12 | Kelayakan: teknis, biaya, model bisnis, penerapan | **3** |
| 4:10–4:35 | 13 | Dampak dan metrik | **3** |
| 4:35–4:48 | 14 | Penutup | 4 |
| 4:48–5:00 | | Cadangan 12 detik | |

Slide 15–17 adalah **lampiran Q&A** (12 kata inti, batasan dan roadmap, ringkasan `PERUBAHAN.md`). Jangan ditampilkan
saat pitch.

---

## 0:00–0:10 · Judul *(slide manual)*

> "Selamat pagi, Bapak dan Ibu juri. Kami Teen Tensors: saya Mikael, bersama [nama], [nama], dan [nama]."

## 0:10–0:20 · Slide 1 — Pertanyaan

> "**Bagaimana jika hambatan terbesar hubungan antarmanusia bukan jarak, bukan internet, melainkan dua manusia yang
> tidak bisa saling memahami?**"

`[Diam 2 detik sebelum pindah slide.]`

## 0:20–0:45 · Slide 2 — Ethan

> "Ini Ethan, lima tahun, dari Inggris. Ethan autis dan tidak berbicara. Dulu, caranya meminta sesuatu adalah
> menarik tangan orang dewasa ke arah yang ia mau.
> Hari ini Ethan bisa meminta makanan, memberi tahu saat ia sakit, dan membela dirinya sendiri, lewat papan AAC.
> Tapi yang membuat Ethan berhasil bukan hanya perangkatnya. Ibunya menulis, tugas keluarga adalah
> **'model, model, model'**: ikut berbicara dengan papan itu setiap hari.
> **Ethan punya suara karena orang di sekitarnya belajar menjawab.** Pertanyaannya: berapa banyak anak yang tidak
> seberuntung Ethan?"

*Sumber: kisah Laura dan Ethan, National Autistic Society (autism.org.uk), dimuat di majalah Your Autism. Foto Ethan
tidak dipakai tanpa izin; slide memakai bingkai ilustrasi.*

## 0:45–1:08 · Slide 3 — Masalah

> "Datanya menjawab. **25 sampai 30 persen anak autis tetap minimally verbal setelah usia lima tahun.** AAC sudah
> ada, tapi **29,3 persen alat bantu ditinggalkan sepenuhnya**, paling banyak di tahun pertama. Menurut survei 275
> terapis wicara, penyebabnya **kurang pelatihan dan kurang dukungan**, bukan anaknya.
> Di Indonesia tantangannya bertumpuk: alat berbahasa Inggris, mahal, butuh internet, orang tua tidak pernah dilatih,
> dan terapis tidak tahu apa yang terjadi di rumah di antara sesi."

## 1:08–1:22 · Slide 4 — Celah

> "Solusi yang ada kuat di bagiannya masing-masing: bahasa Indonesia, luring, kustomisasi, atau laporan.
> **Tapi celahnya bukan di satu fitur. Celahnya ada di antara fitur**: belum ada yang menyatukan anak, keluarga,
> dan terapis dalam satu alur."

## 1:22–1:42 · Slide 5 — Nyambung

> "Maka kami membangun **Nyambung**. Nyambung bukan sekadar papan AAC. **Nyambung mengubah AAC dari alat milik anak
> menjadi bahasa bersama satu rumah**: anak berbicara lewat papan, orang tua belajar menjawab lewat misi harian,
> dan terapis melihat apa yang terjadi di rumah lalu mengirim usulan kembali. Satu loop, luring-pertama.
> **Suara anak, sampai.**"

## 1:42–2:10 · Slide 6 — Yang kami ciptakan untuk anak dan keluarga

> "Untuk anak, papan bicara yang **tetap hidup tanpa internet**: dua belas kata inti di posisi tetap, 120 kata
> bersimbol, dan papan dari foto rumahnya sendiri.
> Suaranya berlapis: suara papan yang sama di semua HP, rekaman Ibu atau Ayah yang tetap di HP, dan tiruan suara
> keluarga **hanya dengan persetujuan eksplisit**.
> Untuk orang tua, **satu pelajaran 60 detik dan satu misi di bawah lima menit sehari**, menempel pada rutinitas.
> Penghitungnya terisi sendiri dari ketukan. Tanpa streak, tanpa rasa bersalah, tanpa formulir."

## 2:10–2:25 · Slide 7 — Kenapa misinya dirancang begini

> "Desain misinya tidak kami karang. **Intervensi yang dijalankan orang tua dan disisipkan di rutinitas termasuk
> praktik berbasis bukti** menurut tinjauan 972 studi. Melewatkan satu hari tidak merusak pembentukan kebiasaan, jadi
> kami tidak menghukum hari yang terlewat. Yang belum teruji, seperti pelajaran 60 detik, kami tandai untuk pilot."

## 2:25–2:47 · Slide 8 — Yang kami ciptakan untuk terapis

> "Untuk terapis, kami tidak memberi tumpukan data. Dasbor menandai anak yang perlu ditinjau, **selalu dengan
> alasannya**, lalu menyusun ringkasan rumah sebelum sesi. Terapis mengusulkan kata atau frasa bersuara, dan
> keluarga memilih **Terima atau Tolak, tanpa perlu alasan**.
> **Aturan tetap, alasan tertulis, keputusan tetap di tangan manusia.**"

## 2:47–3:17 · Slide 9 — Ketepatan teknologi

> "Setiap pilihan teknologi berangkat dari kondisi pengguna kami.
> Karena sinyal tidak bisa diandalkan, **data utama tinggal di HP**: setiap ketukan ditulis ke log yang tidak bisa
> diubah bersama antrean kirimnya, **dalam satu transaksi**. Saat jaringan kembali, aplikasi mengirim sendiri, dan
> server mengenali ID yang sama sehingga tidak ada data ganda. Kami menguji ini dengan mematikan proses secara paksa:
> hasilnya identik.
> Karena HP keluarga sederhana, aplikasinya **Flutter untuk Android 8 dengan RAM 2 GB**. Server-nya ringan, FastAPI
> dan SQLite, cukup untuk pilot satu klinik.
> Dan **AI hanya dipakai di server saat membuat konten**, yaitu frasa, tiruan suara, atau draf papan foto. Hasilnya
> diputar luring. Tidak ada model di dalam aplikasi, dan triase terapis memakai aturan yang bisa diperiksa."

## 3:17–3:32 · Slide 10 — Basis ilmiah dan validasi

> "Kami tidak mengklaim Nyambung sudah terbukti efektif; kami merakit praktik yang sudah terbukti. Kami juga meminta
> pendapat **[A], Ketua Umum FORMAPI Universitas Brawijaya**, yang berpengalaman mendampingi anak berkebutuhan khusus:
> *'[kutipan singkat asli dari A]'*. **Validasi klinis bersama terapis wicara adalah bagian dari pilot kami.**"

## 3:32–3:42 · Slide 11 — Asal aset

> "Semua aset punya asal yang jelas: **simbol dari Mulberry Symbols karya Steve Lee, berlisensi CC BY-SA 4.0**,
> kata tanpa padanan digambar tim dengan gaya yang sama, dan semua berkas tercatat lengkap dengan hash-nya."

## 3:42–4:10 · Slide 12 — Kelayakan

> "Apakah layak? Ini sudah berjalan, dibangun dalam 24 jam, dengan **113 tes otomatis lulus**.
> Model bisnisnya: **keluarga gratis selamanya**, karena suara anak tidak boleh dikunci langganan. Biaya per keluarga
> untuk fitur inti hampir nol, karena semuanya berjalan di HP. **Yang membayar adalah terapis dan institusi**, yang
> mendapat dasbor dan data rumah. Kami mulai dengan pilot enam pekan bersama satu terapis wicara, lalu tumbuh lewat
> terapis: **setiap kode undangan adalah satu keluarga baru**.
> Batasannya kami tulis terbuka: belum HTTPS, dan [belum diuji di HP fisik 2 GB — perbarui bila sudah]."

## 4:10–4:35 · Slide 13 — Dampak

> "Dampaknya kami ukur dengan jujur. Masalah intinya alat ditinggalkan, jadi **metrik utama pilot adalah retensi hari
> ke-14, minimal 60 persen**, didukung hari misi terlaksana, usulan yang dijawab keluarga, dan waktu tinjauan terapis
> yang diukur otomatis. Jumlah kata adalah **pola pemakaian, bukan nilai kemampuan anak**.
> Kalau tinjauan cukup lima menit per anak, satu jam terapis memantau dua belas keluarga. **Itu asumsi, dan pilot yang
> akan mengujinya.**"

## 4:35–4:48 · Slide 14 — Penutup

> "Ethan punya suara karena orang di sekitarnya belajar menjawab. Nyambung ingin hal yang sama terjadi di setiap rumah
> di Indonesia.
> Karena hubungan antarmanusia tidak dimulai saat seseorang bisa bicara. **Hubungan dimulai saat ia bisa dipahami.**
> Anak. Keluarga. Terapis. **Nyambung.**"

`[Tahan 2 detik.]`

---

## Yang harus diisi tim sebelum tampil

1. **Slide 10:** nama A, jabatan, dan satu kutipan asli (≤ 25 kata) dari A, dengan izin A. **Jangan mengarang
   kutipan.** A adalah praktisi pendamping ABK dari forum mahasiswa, jadi sebut "masukan praktisi", bukan "validasi
   klinis".
2. **Slide 2:** kalau ingin memakai foto Ethan, minta izin ke National Autistic Society. Tanpa izin, pakai bingkai
   ilustrasi yang sudah ada.
3. **Slide 4:** klaim fitur kompetitor belum dicek ke situs resmi masing-masing.
4. **Slide 12:** status uji HP fisik; hipotesis harga (Rp150–250 rb per terapis per bulan) adalah tingkat D.

---

## Jawaban Q&A yang harus konsisten

| Pertanyaan | Jawaban |
|---|---|
| Kenapa tidak demo langsung? | Alur lengkapnya ada di video demo. Di pitch kami fokus ke masalah, ketepatan solusi, kelayakan, dan dampak. Kami siap menunjukkan aplikasi saat Q&A. |
| Siapa Ethan? Apakah pengguna Nyambung? | Bukan. Ethan dari Inggris, kisahnya dimuat National Autistic Society. Kami memakainya karena kisah itu menunjukkan hal yang kami bangun: anak berhasil karena keluarganya ikut memodelkan AAC. |
| Apa kebaruannya kalau AAC sudah ada? | Integrasinya: AAC Bahasa Indonesia yang luring, pelatihan orang tua di dalam rutinitas, bukti otomatis dari rumah, triase beralasan, dan usulan yang bisa ditolak keluarga, dalam satu loop. |
| Sudah ada terapis yang memverifikasi? | Pemilihan kata berbasis literatur dan sudah dikonsultasikan dengan FORMAPI UB; opini [A] sebagai praktisi. Validasi klinis bersama terapis wicara adalah pilot enam pekan kami. Daftar kata belum ditinjau terapis wicara. |
| Katanya luring, tapi pakai AI? | Komunikasi anak selalu luring. AI hanya dipanggil **server** saat pendamping **membuat** konten (frasa, tiruan suara, draf papan foto), dan hanya bila fitur itu dipakai. Hasilnya disimpan di HP dan diputar tanpa internet. Tanpa kunci AI, fitur inti tetap jalan. |
| Rekaman suara keluarga dikirim ke mana? | Rekaman per kata tidak pernah meninggalkan HP. Tiruan suara hanya aktif setelah orang tua menyetujui empat butir; server meneruskan sampel ke ElevenLabs tanpa menyimpannya dan hanya menyimpan `voice_id`. Bisa dicabut kapan saja. Risiko yang kami akui: suara tiruan disimpan penyedia selama belum dicabut. |
| Foto papan dikirim ke AI? | Hanya bila pendamping meminta draf AI dan menyetujui pada permintaan itu. Server tidak menyimpan foto. AI hanya membuat draf; keluarga wajib memeriksa sebelum menyimpan. |
| Bukti misi harian berhasil? | Komponennya berbasis bukti (NCAEP 2020; Wetherby 2014; Biggs 2018; O'Neill 2018). Paket misi Nyambung sendiri belum diuji; itu tujuan pilot. |
| Berapa lama sampai jadi kebiasaan? | Median 59–66 hari (Keller 2021; Lally 2010). Retensi hari ke-14 hanya sinyal awal. |
| Model bisnisnya? | B2I dengan pola B2B2C: institusi dan terapis membayar dasbor dan add-on; keluarga gratis selamanya. B2G setelah pilot. Rincian di `deck/model-bisnis.md`. |
| Kenapa keluarga tidak bayar? | Suara anak tidak boleh dikunci langganan, dan hambatan harga menambah alasan alat ditinggalkan. |
| AAC bikin anak malas bicara? | Tidak. Tinjauan 23 studi: AAC tidak menghambat dan bisa menambah produksi bicara (Millar 2006). |
| Simbolnya dari mana? | Mulberry Symbols © Steve Lee, CC BY-SA 4.0. Kata tanpa padanan digambar tim; simbol tim belum diuji pada anak. |
| Apakah menggantikan terapis? | Tidak. Nyambung memindahkan beban mengumpulkan informasi, bukan penilaian klinisnya. |
| Data anak, persetujuannya? | Data keluar HP hanya setelah orang tua menebus kode undangan (UU PDP Pasal 25). Hanya ketukan simbol; tidak ada audio ruangan, video, atau lokasi. Belum: HTTPS dan enkripsi di perangkat. |

---

## Yang diubah dari naskah sebelumnya

1. **Tanpa demo langsung.** Video demo sudah memperagakan alur; waktu pitch dipindah ke aspek penilaian.
   Slide solusi kini menjelaskan apa yang diciptakan dan kenapa teknologinya tepat.
2. **Hook dua slide:** pertanyaan tentang saling memahami, lalu Ethan sebagai subjek. Ethan dipakai sebagai bukti
   bahwa lingkungan yang belajar memodelkan AAC-lah yang membuat anak berhasil.
3. **Slide ketepatan teknologi** menggantikan slide arsitektur: setiap pilihan teknologi dikaitkan ke kondisi
   pengguna.
4. **Fitur yang dibangun sore–malam masuk:** papan dari foto, frasa bersuara, tiruan suara dengan persetujuan,
   generator misi, dan simbol berwarna lengkap. Tiruan suara bukan lagi roadmap.
5. **Kelayakan memakai model bisnis tim** (`deck/model-bisnis.md`): keluarga gratis, institusi membayar.
6. **Penutup kembali ke Ethan** supaya cerita melingkar.

## Asal angka

| Angka | Sumber |
|---|---|
| Ethan 5 tahun, non-speaking, *hand-leading*, "model, model, model" | Kisah Laura dan Ethan, autism.org.uk |
| 25–30% tetap *minimally verbal* setelah 5 tahun | Tager-Flusberg & Kasari (2013) |
| 29,3% alat bantu ditinggalkan | Phillips & Zhao (1993) |
| Kurang pelatihan dan dukungan, 275 terapis wicara | Johnson dkk. (2006) |
| 972 artikel, 28 praktik berbasis bukti | Steinbrenner dkk. (2020), NCAEP |
| Melewatkan satu kesempatan tidak berpengaruh berarti | Lally dkk. (2010) |
| 64 tes server lulus | `pytest`, 18 Sep 21:45 |
| 49 tes aplikasi lulus | `status/jalur-1.md`, 18 Sep 21:35 |
| APK rilis 18,2 MB (armeabi-v7a) / 20,7 MB (arm64-v8a) | `README.md` (diukur sebelum fitur malam) |
| Suara 120 kata < US$0,20 | `PERUBAHAN.md` entri 3 |
| Keluarga gratis; Rp150–250 rb per terapis per bulan | `deck/model-bisnis.md`, **hipotesis (D)** |
| Add-on suara ± Rp2–4 rb per keluarga per bulan | `deck/model-bisnis.md`, target dengan klon sementara (**belum dibangun**) |
| Retensi hari ke-14 ≥ 60% | `03-basis-ilmiah.md` §6 |
| 12 keluarga per jam terapis | **asumsi**, diuji di pilot |
| 99 simbol Mulberry, 21 simbol tim | `PERUBAHAN.md` entri 18 (85 + 14 padanan Mulberry) |
| Riset lain | `deck/riset-pendukung.md` |
