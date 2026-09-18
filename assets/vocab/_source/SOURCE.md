# Sumber daftar frekuensi

## id_50k_2018.txt

| Hal | Nilai |
|---|---|
| Berkas | `id_50k_2018.txt` (50.000 baris, format `kata jumlah_kemunculan`, urut menurun) |
| Asal | Repositori GitHub **hermitdave/FrequencyWords**, jalur `content/2018/id/id_50k.txt` |
| URL unduh | https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/id/id_50k.txt |
| Commit sumber | `bd9e23103f0a` (14 Februari 2019, "additional languages until Norwegian excluding French") |
| Diunduh | 2026-09-13 00:11 WIB, oleh agen Claude Code dalam sesi Fase 1 |
| SHA-256 | `f2eea0da9735b7040efbfa813f5f875ec931de5a0ec70a6f28213ea60a87bb38` |
| Ukuran | 588.873 byte |
| Korpus dasar | OpenSubtitles2018 (OPUS, http://opus.nlpl.eu/OpenSubtitles2018.php), subset Bahasa Indonesia |
| Total token 50k | 54.684.802 (daftar penuh 357.441 tipe / 55.528.471 token, tidak dibundel; 4,1 MB) |
| Lisensi | Kode repositori: MIT (Hermit Dave, 2016). Data turunan dari OpenSubtitles lewat OPUS; pemakaian di sini hanya sebagai daftar frekuensi untuk riset, bukan redistribusi teks subtitel. |

## Kenapa korpus ini

Kosakata inti AAC harus mencerminkan bahasa **lisan percakapan**, bukan tulisan.
Subtitel film adalah proksi bahasa lisan yang paling luas tersedia untuk Bahasa
Indonesia. Wikipedia, berita, dan Leipzig `ind_mixed` adalah register tulisan
sehingga sengaja tidak dipakai.

## Keterbatasan yang harus diingat

1. **Translationese.** Sebagian besar subtitel Indonesia di OpenSubtitles adalah
   terjemahan film asing. Akibatnya `kau` berada di peringkat 2 dan `kamu` di 29,
   padahal tutur orang tua ke anak hampir selalu memakai `kamu` atau nama. Peringkat
   dipakai untuk memangkas, bukan untuk membenarkan.
2. **Hanya unigram.** Bigram seperti `kamar mandi` dan `terima kasih` tidak ada.
   Kata semacam itu diberi `freq_rank` kosong, bukan dikarang.
3. **Bukan tutur anak.** Tidak ada korpus tutur anak Indonesia yang terbuka. Kata
   toileting (`pipis`, `pup`) dan kata konteks Indonesia (`ngaji`, `angkot`) hampir
   tak terlihat di korpus film; keberadaannya di daftar dibenarkan oleh kebutuhan
   klinis dan proposal, bukan oleh frekuensi.
4. **Tanpa lematisasi.** `makan` dan `memakan` dihitung terpisah. Kami memakai bentuk
   dasar tanpa imbuhan karena itulah bentuk yang dipakai pada papan AAC.

## Reproduksi

```
python data/vocab/build_core_vocab.py
```
