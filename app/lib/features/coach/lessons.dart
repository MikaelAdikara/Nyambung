class LessonContent {
  const LessonContent({required this.title, required this.how, required this.example, required this.why});

  final String title;
  final String how;
  final String example;
  final String why;
}

const lessons = <String, LessonContent>{
  'modeling_dasar': LessonContent(
    title: 'Tekan sambil bicara',
    how: 'Setiap kali Ibu atau Ayah mengucapkan kata target, tekan juga simbolnya di papan. Anak tidak perlu menekan apa pun. Ia sedang melihat bahwa papan ini cara bicara, sama seperti mendengar orang bicara sebelum bisa bicara.',
    example: 'Saat menyendok nasi: tekan MAU sambil berkata "Adik mau makan?" Lalu berikan makanannya. Ulangi saat suapan berikutnya.',
    why: 'Anak belajar kata dari mendengar dan melihat kata itu dipakai berkali-kali sebelum memakainya sendiri. Papan pun begitu.',
  ),
  'tunggu_lima_detik': LessonContent(
    title: 'Tunggu lima detik',
    how: 'Setelah menekan dan mengucapkan kata, diam dan tunggu sampai lima hitungan. Jangan mengisi keheningan. Lihat tangannya, matanya, atau papannya.',
    example: 'Tekan LAGI sambil berkata "lagi?", lalu tahan sendok dan hitung dalam hati: satu, dua, tiga, empat, lima. Kalau anak melirik papan atau menyentuh sel mana pun, itu sudah bagus.',
    why: 'Anak yang memproses bahasa lebih lambat butuh waktu untuk mulai. Kalau kita langsung bicara lagi, kesempatannya hilang.',
  ),
  'tanpa_paksa': LessonContent(
    title: 'Tanpa memaksa, tanpa mengetes',
    how: 'Jangan memegang tangan anak untuk menekan simbol, dan jangan bertanya "mana MAU?" untuk menguji. Cukup contohkan, lalu lanjutkan kegiatan seperti biasa.',
    example: 'Kalau anak mendorong papan, letakkan papan di samping dan lanjutkan makan. Tekan lagi pada suapan berikutnya tanpa komentar.',
    why: 'Papan yang jadi alat tes berubah menjadi tuntutan, dan tuntutan membuat alat ditinggalkan. Kita membangun kebiasaan, bukan kelulusan.',
  ),
  'kata_inti_dulu': LessonContent(
    title: 'Kata inti dulu, kata benda nanti',
    how: 'Pilih kata yang bisa dipakai di banyak situasi: MAU, TIDAK, LAGI, SELESAI. Satu kata inti bisa dipakai saat makan, mandi, dan main. Kata benda seperti NASI hanya berguna saat makan.',
    example:
        'Saat main bola: tekan LAGI ("lagi?"), MAU ("mau bola?"), SELESAI ("selesai main"). Tiga kata yang sama dipakai lagi saat mandi.',
    why: 'Anak-anak memakai sedikit kata yang sama berulang-ulang di semua kegiatan, dan kata-kata itu hampir tidak pernah kata benda. Sedikit kata serbaguna lebih berharga daripada banyak kata benda.',
  ),
  'ulang_lima_kali': LessonContent(
    title: 'Lima kali, satu rutinitas',
    how: 'Target hari ini hanya lima kali menekan satu kata pada satu rutinitas. Bukan sepuluh, bukan seharian. Penghitung di misi terisi sendiri dari ketukan Ibu atau Ayah.',
    example: 'Mandi sore: setiap kali menyiram air, tekan LAGI sambil berkata "lagi?". Lima siraman, lima kali, selesai.',
    why: 'Beban kecil yang dilakukan setiap hari mengalahkan usaha besar yang berhenti setelah tiga hari. Tidak ada hari yang gagal; hanya ada hari yang belum sempat.',
  ),
};
