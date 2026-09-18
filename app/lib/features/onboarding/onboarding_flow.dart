import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import 'family_voice_recorder.dart';
import 'therapist_entry.dart';

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  final _pages = PageController();
  final _name = TextEditingController();
  int _page = 0;
  int? _ageYears;
  String _routine = 'makan';
  AppState? _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
  }

  @override
  void dispose() {
    _pages.dispose();
    _name.dispose();
    super.dispose();
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_page < 5) _pages.nextPage(duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
  }

  Future<void> _finish(AfterOnboarding next) async {
    _app!.afterOnboarding = next;
    await _app!.createChild(nickname: _name.text.trim(), ageYears: _ageYears, routine: _routine);
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: CompanionColors.bg,
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            child: Row(
              children: List.generate(
                6,
                (index) => Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: index == 5 ? 0 : 8),
                    decoration: BoxDecoration(
                      color: index <= _page ? CompanionColors.navy : CompanionColors.line,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _pages,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (value) => setState(() => _page = value),
              children: [
                _IntroPage(onNext: _next),
                _ProfilePage(
                  nameController: _name,
                  ageYears: _ageYears,
                  onAgeChanged: (age) => setState(() => _ageYears = age),
                  onNext: _next,
                ),
                _RoutinePage(routine: _routine, onChanged: (value) => setState(() => _routine = value), onNext: _next),
                _BoardPreviewPage(onNext: _next),
                _FamilyVoicePage(onNext: _next),
                _FinishPage(name: _name.text.trim(), routine: _routine, onFinish: _finish),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _PageShell extends StatelessWidget {
  const _PageShell({required this.title, required this.body, required this.bottom});

  final String title;
  final List<Widget> body;
  final Widget bottom;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 30, height: 1.15, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        Expanded(child: ListView(children: body)),
        const SizedBox(height: 16),
        bottom,
      ],
    ),
  );
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => _PageShell(
    title: 'Nyambung',
    body: const [
      Text(
        'Suara anak, sampai.',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: CompanionColors.teal),
      ),
      SizedBox(height: 24),
      Text(
        'Papan bicara berbahasa Indonesia untuk anak, dan satu misi kecil setiap hari untuk Ibu dan Ayah. Semuanya jalan tanpa internet. Tidak ada akun, surel, atau kata sandi.',
        style: companionBodyStyle,
      ),
    ],
    bottom: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryButton(label: 'Mulai', onPressed: onNext),
        const SizedBox(height: 8),
        // Pintu kedua, sengaja kecil: 90% yang membuka aplikasi adalah keluarga.
        TextButton(
          onPressed: () => showTherapistEntry(context),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: CompanionColors.navy),
          child: const Text('Saya terapis →', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        ),
      ],
    ),
  );
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({required this.nameController, required this.ageYears, required this.onAgeChanged, required this.onNext});

  final TextEditingController nameController;
  final int? ageYears;
  final ValueChanged<int?> onAgeChanged;
  final VoidCallback onNext;

  @override
  State<_ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<_ProfilePage> {
  @override
  void initState() {
    super.initState();
    widget.nameController.addListener(_refresh);
  }

  @override
  void dispose() {
    widget.nameController.removeListener(_refresh);
    super.dispose();
  }

  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) => _PageShell(
    title: 'Siapa nama panggilannya?',
    body: [
      const Text(
        'Hanya dua hal: nama panggilan dan usia. Tidak ada pertanyaan diagnosis atau riwayat medis. Usia dipakai untuk memilih ukuran sel yang nyaman, bukan untuk membatasi kosakata.',
        style: companionBodyStyle,
      ),
      const SizedBox(height: 24),
      TextField(
        controller: widget.nameController,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(labelText: 'Nama panggilan', border: OutlineInputBorder()),
      ),
      const SizedBox(height: 16),
      DropdownButtonFormField<int?>(
        initialValue: widget.ageYears,
        decoration: const InputDecoration(labelText: 'Usia', border: OutlineInputBorder()),
        items: [
          const DropdownMenuItem<int?>(value: null, child: Text('Lewati')),
          ...List.generate(11, (index) => DropdownMenuItem<int?>(value: index + 2, child: Text('${index + 2} tahun'))),
        ],
        onChanged: widget.onAgeChanged,
      ),
    ],
    bottom: PrimaryButton(label: 'Lanjut', onPressed: widget.nameController.text.trim().isEmpty ? null : widget.onNext),
  );
}

class _RoutinePage extends StatelessWidget {
  const _RoutinePage({required this.routine, required this.onChanged, required this.onNext});

  final String routine;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => _PageShell(
    title: 'Kegiatan mana yang paling teratur waktunya?',
    body: [
      const Text(
        'Misi harian akan menempel pada kegiatan ini, supaya pendampingan tidak menambah pekerjaan baru. Bisa diganti kapan saja di pengaturan.',
        style: companionBodyStyle,
      ),
      const SizedBox(height: 20),
      for (final option in const [
        ('makan', 'Makan sore', Icons.restaurant),
        ('mandi', 'Mandi sore', Icons.bathtub),
        ('main', 'Main pagi', Icons.toys),
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: CompanionCard(
            color: routine == option.$1 ? CompanionColors.navySoft : CompanionColors.panel,
            child: RadioGroup<String>(
              groupValue: routine,
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              child: RadioListTile<String>(
                value: option.$1,
                secondary: Icon(option.$3, size: 32),
                title: Text(option.$2, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ),
    ],
    bottom: PrimaryButton(label: 'Lanjut', onPressed: onNext),
  );
}

class _BoardPreviewPage extends StatelessWidget {
  const _BoardPreviewPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => _PageShell(
    title: 'Papan awal sudah jadi',
    body: [
      const Text(
        'Dua belas kata inti Bahasa Indonesia langsung tersusun. Anak mengakses seluruh papan sejak hari pertama; tidak ada tingkat yang harus dibuka. Posisi setiap kata tidak akan pernah berpindah.',
        style: companionBodyStyle,
      ),
      const SizedBox(height: 20),
      GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        childAspectRatio: 1.05,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        children: const ['MAU', 'BERHENTI', 'BANTU', 'TIDAK', 'SELESAI', 'SAKIT', 'AKU', 'MAKAN', 'MINUM', 'YA', 'LAGI', 'ITU']
            .map(
              (word) => Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(color: CompanionColors.navySoft, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  word,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            )
            .toList(),
      ),
    ],
    bottom: PrimaryButton(label: 'Lanjut', onPressed: onNext),
  );
}

/// A5: enam kata yang paling sering dicontohkan. Ketuk baris untuk memilih kata, rekam, lalu kata berikutnya yang
/// belum direkam terpilih sendiri. Setiap rekaman langsung tersimpan; "Lewati" tetap setara.
class _FamilyVoicePage extends StatefulWidget {
  const _FamilyVoicePage({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_FamilyVoicePage> createState() => _FamilyVoicePageState();
}

class _FamilyVoicePageState extends State<_FamilyVoicePage> {
  static const _words = ['mau', 'tidak', 'lagi', 'makan', 'minum', 'bantu'];
  String _selected = _words.first;

  Future<void> _saved(String wordId, String? path) async {
    if (path == null) return;
    final app = AppScope.of(context);
    await app.symbolDao.setFamilyAudio(wordId, path);
    await app.reloadSymbols();
    if (!mounted) return;
    final next = _words.where((w) => app.symbolById(w)?.familyAudio == null).firstOrNull;
    setState(() => _selected = next ?? wordId);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final recorded = _words.where((w) => app.symbolById(w)?.familyAudio != null).length;
    return _PageShell(
      title: 'Mau pakai suaramu?',
      body: [
        const Text(
          'Anak biasanya lebih cepat mengenali suara orang tuanya daripada suara bawaan HP. Enam kata saja, bisa juga '
          'nanti. Rekaman tersimpan di HP ini saja dan tidak pernah dikirim ke siapa pun, termasuk terapis.',
          style: companionBodyStyle,
        ),
        const SizedBox(height: 16),
        CompanionCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (final w in _words)
                if (app.symbolById(w) case final s?)
                  InkWell(
                    onTap: () => setState(() => _selected = w),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      decoration: BoxDecoration(
                        color: w == _selected ? CompanionColors.navySoft : null,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Image(
                            image: symbolImage(s.symbolPath),
                            width: 36,
                            height: 36,
                            errorBuilder: (_, _, _) => const SizedBox(width: 36),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(s.labelDisplay, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                          ),
                          Text(
                            s.familyAudio != null ? 'sudah direkam' : 'belum',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: s.familyAudio != null ? CompanionColors.green : CompanionColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        FamilyVoiceRecorder(key: ValueKey(_selected), wordId: _selected, onRecorded: (path) => _saved(_selected, path)),
      ],
      bottom: Column(
        children: [
          PrimaryButton(label: recorded == 0 ? 'Lanjut' : 'Simpan dan lanjut', onPressed: widget.onNext),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: EqualOutlineButton(label: 'Lewati, rekam nanti saja', onPressed: widget.onNext),
          ),
        ],
      ),
    );
  }
}

class _FinishPage extends StatelessWidget {
  const _FinishPage({required this.name, required this.routine, required this.onFinish});

  final String name;
  final String routine;

  /// Dipanggil dengan tujuan setelah pemasangan: misi hari ini atau papan.
  final ValueChanged<AfterOnboarding> onFinish;

  @override
  Widget build(BuildContext context) {
    final selectedRoutineLabel = routineDisplayLabel(routine);
    return _PageShell(
      title: 'Papan $name siap dipakai',
      body: [
        const Text('Semuanya tersimpan di HP ini. Papan tetap jalan walau tidak ada jaringan.', style: companionBodyStyle),
        const SizedBox(height: 16),
        CompanionCard(
          color: CompanionColors.navy,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'MISI HARI PERTAMA',
                style: TextStyle(fontSize: 13, letterSpacing: 1.2, fontWeight: FontWeight.w800, color: Color(0xFFF1E6C8)),
              ),
              const SizedBox(height: 8),
              Text(
                'Saat $selectedRoutineLabel nanti, tekan simbol MAU lima kali sambil mengucapkannya.',
                style: const TextStyle(fontSize: 22, height: 1.3, fontWeight: FontWeight.w800, color: Colors.white),
              ),
              const SizedBox(height: 8),
              Text(
                '$name tidak perlu ikut menekan. Kurang dari lima menit.',
                style: const TextStyle(fontSize: 16, height: 1.4, color: Color(0xFFDCE6F1)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const CompanionCard(
          color: CompanionColors.sand,
          child: Text(
            'Terapis bisa dihubungkan nanti dengan kode undangan. Tanpa itu pun aplikasi tetap berguna. '
            'Tidak ada skor dan tidak ada hari yang gagal.',
            style: companionBodyStyle,
          ),
        ),
      ],
      bottom: Column(
        children: [
          PrimaryButton(label: 'Buka misi hari ini', onPressed: () => onFinish(AfterOnboarding.mission)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: EqualOutlineButton(label: 'Lihat papan dulu', onPressed: () => onFinish(AfterOnboarding.board)),
          ),
        ],
      ),
    );
  }
}
