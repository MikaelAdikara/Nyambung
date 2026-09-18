# Riset Pendukung Deck: Misi Harian dan Aset

Tambahan untuk deck dan Q&A, diriset 18 Sep 2026. Sumber yang dipakai sebelumnya tetap dari
`docs/hackday/03-basis-ilmiah.md`. Sumber baru di bawah **sudah dicek ke halaman penerbit, PubMed, atau PDF aslinya**.
Usulan: jalur 3 menyalin tabel ini ke `03-basis-ilmiah.md` setelah disepakati berempat, supaya tetap ada satu sumber
kutipan.

Tingkat bukti mengikuti `03` §0: **A** uji acak terkontrol, meta-analisis, atau tinjauan sistematis · **B** studi
eksperimental atau observasional terbatas · **C** standar atau konvensi praktik · **D** asumsi tim yang belum diuji.

---

## 1. Kenapa misi harian dirancang seperti ini

| Elemen misi di Nyambung | Bukti | Tingkat | Batas jujur |
|---|---|---|---|
| **Orang tua yang menjalankan**, bukan hanya terapis | *Parent-Implemented Intervention* termasuk 28 praktik berbasis bukti untuk autisme; didukung 55 artikel (NCAEP; Steinbrenner dkk., 2020, tinjauan 972 artikel 1990–2017) | A | Tinjauan umum autisme, bukan khusus AAC |
| | RCT 82 balita autis: pelatihan orang tua untuk menyisipkan strategi komunikasi di **kegiatan sehari-hari** meningkatkan komunikasi sosial, perilaku adaptif, dan tingkat perkembangan, dengan sedikit waktu profesional (Wetherby dkk., 2014, *Pediatrics*) | A | Balita 16–20 bulan dengan pelatihan langsung di rumah; Nyambung memakai pelajaran mikro, bukan kunjungan |
| **Tekan sambil bicara** (contoh di papan) | Tinjauan sistematis 48 studi, 267 anak: intervensi *aided AAC modeling* umumnya efektif meningkatkan komunikasi ekspresif (Biggs, Carter & Gilson, 2018, *AJIDD*) | A | Prosedur antarstudi beragam |
| | Meta-analisis O'Neill, Light & Pope (2018) dan Kent-Walsh dkk. (2015), sudah ada di `03` §2 | A | Memakai pelatihan langsung |
| **Menempel pada rutinitas** (makan, mandi, main) | *Naturalistic Intervention* (strategi yang disisipkan di kegiatan dan rutinitas anak) termasuk praktik berbasis bukti; 75 artikel (NCAEP, 2020) | A | — |
| | Rencana "jika X, maka Y" meningkatkan pencapaian tujuan, d = 0,65 (meta-analisis 94 studi; Gollwitzer & Sheeran, 2006) | A | Populasi umum, bukan orang tua anak autis |
| **Tunggu lima detik** sesudah contoh | *Time Delay* termasuk praktik berbasis bukti; 31 artikel (NCAEP, 2020) | A | Angka "lima detik" tetap angka praktis (D) |
| **Setiap hari, tanpa streak**, "belum sempat" tidak dihukum | 96 orang membangun satu kebiasaan harian: median **66 hari** (18–254) sampai otomatis; **melewatkan satu kesempatan tidak berpengaruh berarti** (Lally dkk., 2010, *Eur. J. Soc. Psychol.*) | B | Kebiasaan makan, minum, dan olahraga orang dewasa |
| | RCT 192 orang: mengaitkan perilaku ke rutinitas atau ke jam sama efektifnya; **pengulangan rencana** adalah prediktor utama otomatisitas; median 59 hari (Keller dkk., 2021, *Br. J. Health Psychol.*) | A/B | Perilaku gizi orang dewasa; tidak membuktikan rutinitas lebih unggul dari jam |
| | Stres pengasuhan orang tua anak *minimally verbal* lebih tinggi (Guerrera dkk., 2025, sudah di `03` §1) | B | — |
| Pelajaran **60 detik**, **5 contoh sehari** | **Belum ada bukti langsung.** NCAEP mencatat cara melatih orang tua meliputi instruksi, contoh, *coaching*, dan umpan balik; pelajaran mikro Nyambung adalah bentuk paling ringan dari instruksi | **D** | Pertanyaan pilot |

**Implikasi untuk pilot.** Kebiasaan butuh sekitar dua bulan (Lally 2010; Keller 2021), jadi retensi hari ke-14
adalah sinyal awal, bukan bukti kebiasaan terbentuk. Pilot 6 pekan (42 hari) belum menjangkau median 59–66 hari;
sebut ini jujur bila ditanya.

## 2. AAC tidak menghambat bicara (pertanyaan orang tua yang sering muncul)

| Klaim | Bukti | Tingkat |
|---|---|---|
| AAC tidak menghambat bicara, bahkan bisa menambah produksi bicara | Tinjauan 23 studi, 67 individu (Millar, Light & Schlosser, 2006, *JSLHR*) | B (17 dari 23 studi tanpa kontrol eksperimental) |
| AAC tidak butuh prasyarat usia atau kemampuan | Romski & Sevcik (2005), sudah di `03` §2 | C |

## 3. Asal aset yang dipakai aplikasi

| Aset | Asal | Lisensi dan catatan |
|---|---|---|
| **85 simbol** | **Mulberry Symbols** v3.6.1 © **Steve Lee**. Digambar desainer grafis Claire Barge dan ditinjau terapis wicara. Diunduh 13 Sep 2026 dari rilis resmi GitHub (SHA-256 tercatat). SVG asli tidak diubah, hanya dirasterkan ke PNG 256 px | **CC BY-SA 4.0**: boleh dipakai komersial, wajib atribusi, turunan berlisensi sama; simbolnya sendiri tidak boleh dijual. Mulberry dirancang untuk **pengguna dewasa**; kecocokan untuk anak Indonesia diuji di pilot |
| **35 simbol buatan tim** | Kata tanpa padanan jujur di Mulberry (mis. TIDAK, YA, BERHENTI, SAKIT, AKU, ITU), digambar tim dengan gaya dan konvensi yang sama (`05-kosakata-dan-simbol.md` §6) | CC BY-SA 4.0. **Belum selesai digambar**; sementara tampil sebagai huruf pertama. Belum diuji pada anak |
| **120 kata** | Riset tim: Banajee dkk. (2003), Project Core Universal Core, frekuensi OpenSubtitles 2018 (hermitdave/FrequencyWords, kode MIT; data OPUS) | Frekuensi dari dialog film dewasa, hanya pemecah seri |
| **Suara papan** 2 × 120 klip | Dibuat sekali saat Hack Day dengan OpenAI TTS (`gpt-4o-mini-tts`, suara *fable* dan *marin*), dibundel di APK, diputar luring | Suara **sintetis buatan AI**; pendengar wajib diberi tahu. Lafal belum ditinjau satu per satu |
| **Font** Fredoka, Nunito | Google Fonts | SIL Open Font License 1.1 |
| **Logo, awan, matahari** | Buatan tim | Milik tim |
| **Jejak audit** | 175 berkas aset diverifikasi SHA-256 (`assets/PROVENANCE.md`, `PROVENANCE.sha256`) | Yang dibawa sebelum acara hanya konten, bukan kode (ketentuan panitia 9) |

**Kenapa simbol bergambar dan diberi warna.** Simbol yang lebih transparan (mudah ditebak maknanya) lebih mudah
dipelajari: anak 3 tahun lebih mudah menebak dan mempelajari PCS dan Picsyms daripada Blissymbols (Mizuko, 1987,
*AAC* 3(3), 129–136) (tingkat B). Warna per jenis kata mengikuti Modified Fitzgerald Key (C) dan selalu dipasangkan dengan
penanda bentuk supaya warna bukan satu-satunya pembawa makna (WCAG 1.4.1, C). Pengelompokan warna membantu menemukan
simbol lebih cepat (Wilkinson dkk., 2008, sudah di `03` §4, B).

---

## Daftar pustaka tambahan

- Biggs, E. E., Carter, E. W., & Gilson, C. B. (2018). Systematic review of interventions involving aided AAC modeling for children with complex communication needs. *American Journal on Intellectual and Developmental Disabilities*, 123(5), 443–473. https://doi.org/10.1352/1944-7558-123.5.443
- Gollwitzer, P. M., & Sheeran, P. (2006). Implementation intentions and goal achievement: A meta-analysis of effects and processes. *Advances in Experimental Social Psychology*, 38, 69–119. https://doi.org/10.1016/S0065-2601(06)38002-1
- Keller, J., Kwasnicka, D., Klaiber, P., Sichert, L., Lally, P., & Fleig, L. (2021). Habit formation following routine-based versus time-based cue planning: A randomized controlled trial. *British Journal of Health Psychology*. https://doi.org/10.1111/bjhp.12504
- Lally, P., van Jaarsveld, C. H. M., Potts, H. W. W., & Wardle, J. (2010). How are habits formed: Modelling habit formation in the real world. *European Journal of Social Psychology*, 40(6), 998–1009. https://doi.org/10.1002/ejsp.674
- Millar, D. C., Light, J. C., & Schlosser, R. W. (2006). The impact of augmentative and alternative communication intervention on the speech production of individuals with developmental disabilities: A research review. *Journal of Speech, Language, and Hearing Research*, 49(2), 248–264. https://pubmed.ncbi.nlm.nih.gov/16671842/
- Mizuko, M. (1987). Transparency and ease of learning of symbols represented by Blissymbols, PCS, and Picsyms. *Augmentative and Alternative Communication*, 3(3), 129–136. https://doi.org/10.1080/07434618712331274409
- Mulberry Symbols. https://mulberrysymbols.org · lisensi CC BY-SA 4.0
- Steinbrenner, J. R., Hume, K., Odom, S. L., Morin, K. L., Nowell, S. W., Tomaszewski, B., Szendrey, S., McIntyre, N. S., Yücesoy-Özkan, S., & Savage, M. N. (2020). *Evidence-based practices for children, youth, and young adults with autism*. FPG Child Development Institute, University of North Carolina, National Clearinghouse on Autism Evidence and Practice. https://eric.ed.gov/?id=ED609029
- Wetherby, A. M., Guthrie, W., Woods, J., Schatschneider, C., Holland, R. D., Morgan, L., & Lord, C. (2014). Parent-implemented social intervention for toddlers with autism: An RCT. *Pediatrics*, 134(6), 1084–1093. https://publications.aap.org/pediatrics/article-abstract/134/6/1084/33191/
