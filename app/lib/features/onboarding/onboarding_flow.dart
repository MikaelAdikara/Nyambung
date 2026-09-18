import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import 'family_voice_recorder.dart';

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

  Future<void> _finish() async {
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
    bottom: PrimaryButton(label: 'Mulai', onPressed: onNext),
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

class _FamilyVoicePage extends StatefulWidget {
  const _FamilyVoicePage({required this.onNext});

  final VoidCallback onNext;

  @override
  State<_FamilyVoicePage> createState() => _FamilyVoicePageState();
}

class _FamilyVoicePageState extends State<_FamilyVoicePage> {
  String? _recording;

  Future<void> _save() async {
    final path = _recording;
    if (path == null) return;
    final app = AppScope.of(context);
    await app.symbolDao.setFamilyAudio('mau', path);
    await app.reloadSymbols();
    widget.onNext();
  }

  @override
  Widget build(BuildContext context) => _PageShell(
    title: 'Rekam suara Ibu atau Ayah (boleh dilewati)',
    body: [
      const Text(
        'Suara ini dipakai saat Ibu atau Ayah memberi contoh di papan, supaya anak mendengar orang yang dikenalnya. Saat anak sendiri yang menekan, papan bicara dengan suara anak, karena itu suaranya. Rekaman tersimpan di perangkat ini saja dan tidak pernah dikirim ke siapa pun, termasuk terapis.',
        style: companionBodyStyle,
      ),
      const SizedBox(height: 16),
      FamilyVoiceRecorder(onRecorded: (path) => setState(() => _recording = path)),
    ],
    bottom: Row(
      children: [
        Expanded(
          child: EqualOutlineButton(label: 'Lewati', onPressed: widget.onNext),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: EqualOutlineButton(label: 'Simpan', onPressed: _recording == null ? null : _save),
        ),
      ],
    ),
  );
}

class _FinishPage extends StatelessWidget {
  const _FinishPage({required this.name, required this.routine, required this.onFinish});

  final String name;
  final String routine;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final selectedRoutineLabel = routineDisplayLabel(routine);
    return _PageShell(
      title: 'Misi hari pertama',
      body: [
        Text(
          'Saat $selectedRoutineLabel nanti: tekan MAU sambil berkata "mau", lima kali. $name tidak perlu menekan apa pun. Itu saja untuk hari ini.',
          style: companionBodyStyle,
        ),
        const SizedBox(height: 16),
        const Text('Tidak ada skor. Tidak ada hari yang gagal. Kalau belum sempat, besok ada lagi.', style: companionMutedStyle),
      ],
      bottom: PrimaryButton(label: 'Ke beranda', onPressed: onFinish),
    );
  }
}
