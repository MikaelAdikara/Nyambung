import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_state.dart';
import '../../core/brand.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_widgets.dart';
import '../coach/mission_rules.dart';
import '../start/parent_pin.dart';
import 'family_voice_recorder.dart';
import 'therapist_entry.dart';

/// A1–A6. Latar bergantian mint dan tosca, kaki halaman awan, satu tombol lime di setiap layar.
class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key, this.onFinished});

  final VoidCallback? onFinished;

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  static const _count = 7;
  static const _slide = Duration(milliseconds: 420);

  final _pages = PageController();
  final _name = TextEditingController();
  int _page = 0;
  int? _ageYears;
  String _routine = 'makan';
  String? _pin;
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

  void _go(int page) {
    FocusScope.of(context).unfocus();
    final d = Motion.of(context, _slide);
    d == Duration.zero ? _pages.jumpToPage(page) : _pages.animateToPage(page, duration: d, curve: Curves.easeOutCubic);
  }

  void _next() => _go((_page + 1).clamp(0, _count - 1));
  void _back() => _go((_page - 1).clamp(0, _count - 1));

  Future<void> _finish(AfterOnboarding next) async {
    _app!.afterOnboarding = next;
    final pin = _pin;
    if (pin != null) await ParentPin.set(_app!.prefs, pin);
    await _app!.createChild(nickname: _name.text.trim(), ageYears: _ageYears, routine: _routine);
    widget.onFinished?.call();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.bg,
    body: PageView(
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
          onBack: _back,
        ),
        _RoutinePage(routine: _routine, onChanged: (value) => setState(() => _routine = value), onNext: _next, onBack: _back),
        _BoardPreviewPage(onNext: _next, onBack: _back),
        _FamilyVoicePage(onNext: _next, onBack: _back),
        _PinPage(
          name: _name.text.trim(),
          done: _pin != null,
          onPin: (pin) {
            setState(() => _pin = pin);
            _next();
          },
          onBack: _back,
        ),
        _FinishPage(name: _name.text.trim(), routine: _routine, onFinish: _finish, onBack: _back),
      ],
    ),
  );
}

/// Satu layar pemasangan: baris atas (kembali + titik langkah), isi yang bisa digulir, dan kaki awan.
class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.step,
    required this.children,
    required this.footer,
    this.dark = false,
    this.onBack,
    this.trailing,
    this.footerHeight = 150,
    this.background,
  });

  final int step;
  final bool dark;
  final VoidCallback? onBack;
  final Widget? trailing;
  final List<Widget> children;
  final Widget footer;
  final double footerHeight;
  final Widget? background;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    child: ColoredBox(
      color: dark ? AppColors.tosca : AppColors.bg,
      child: Stack(
        children: [
          ?background,
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 16, 0),
                  child: SizedBox(
                    height: 52,
                    child: Row(
                      children: [
                        if (onBack != null)
                          RoundIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Kembali', onDark: dark, onPressed: onBack)
                        else
                          const SizedBox(width: 52),
                        const Spacer(),
                        _StepDots(step: step, dark: dark),
                        const Spacer(),
                        trailing ?? const SizedBox(width: 52),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  children: [for (var i = 0; i < children.length; i++) FadeSlideIn(index: i, child: children[i])],
                ),
              ),
              CloudFooter(color: dark ? Colors.white : AppColors.teal, height: footerHeight, child: footer),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Enam titik langkah; titik aktif memanjang jadi pil.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.dark});

  final int step;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final on = dark ? Colors.white : AppColors.teal;
    final off = dark ? Colors.white.withValues(alpha: 0.35) : AppColors.sandDeep;
    return Semantics(
      label: 'Langkah ${step + 1} dari 7',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 7; i++)
            AnimatedContainer(
              duration: Motion.of(context, Motion.resize),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == step ? 22 : 8,
              height: 8,
              decoration: BoxDecoration(color: i <= step ? on : off, borderRadius: BorderRadius.circular(99)),
            ),
        ],
      ),
    );
  }
}

TextStyle _title(bool dark) => AppText.h1.copyWith(color: dark ? Colors.white : AppColors.ink);
TextStyle _lead(bool dark) => AppText.body.copyWith(color: dark ? Colors.white : AppColors.muted);

/// Kartu mint dengan teks toska tua (kutipan langsung dari desain).
class _MintCard extends StatelessWidget {
  const _MintCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
    decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(24)),
    child: DefaultTextStyle.merge(
      style: AppText.body.copyWith(color: AppColors.mintText, fontWeight: FontWeight.w700),
      child: child,
    ),
  );
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) => _OnboardingPage(
    step: 0,
    background: const Positioned(right: -24, top: 36, child: SunDecoration(size: 170)),
    footer: SizedBox(
      width: 220,
      child: PrimaryButton(label: 'Mulai', onPressed: onNext),
    ),
    children: [
      const SizedBox(height: 12),
      const Align(alignment: Alignment.centerLeft, child: BrandMark(size: 72)),
      const SizedBox(height: 20),
      Text(
        'Nyambung',
        style: AppText.display.copyWith(
          fontSize: 48,
          color: AppColors.tealDeep,
          shadows: const [
            Shadow(color: Colors.white, offset: Offset(2, 2)),
            Shadow(color: Colors.white, offset: Offset(-2, -2)),
            Shadow(color: Colors.white, offset: Offset(2, -2)),
            Shadow(color: Colors.white, offset: Offset(-2, 2)),
            Shadow(color: Color(0x2E038075), offset: Offset(0, 10), blurRadius: 24),
          ],
        ),
      ),
      Text('Suara anak, sampai.', style: AppText.h2.copyWith(color: AppColors.tealText)),
      const SizedBox(height: 20),
      const _MintCard(child: Text('Papan bicara berbahasa Indonesia untuk anak, dan satu misi kecil setiap hari untuk Ibu dan Ayah.')),
      const SizedBox(height: 20),
      // Pintu kedua, sengaja kecil: hampir semua yang membuka aplikasi adalah keluarga.
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: () => showTherapistEntry(context),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          child: const Text('Saya terapis →'),
        ),
      ),
    ],
  );
}

class _ProfilePage extends StatefulWidget {
  const _ProfilePage({
    required this.nameController,
    required this.ageYears,
    required this.onAgeChanged,
    required this.onNext,
    required this.onBack,
  });

  final TextEditingController nameController;
  final int? ageYears;
  final ValueChanged<int?> onAgeChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

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
  Widget build(BuildContext context) => _OnboardingPage(
    step: 1,
    dark: true,
    onBack: widget.onBack,
    footer: SizedBox(
      width: 220,
      child: PrimaryButton(label: 'Lanjut', onPressed: widget.nameController.text.trim().isEmpty ? null : widget.onNext),
    ),
    children: [
      Text('Siapa nama panggilannya?', style: _title(true)),
      const SizedBox(height: 8),
      Text('Nama panggilan dan usia, itu saja.', style: _lead(true)),
      const SizedBox(height: 24),
      const Eyebrow('Nama panggilan', color: Colors.white),
      const SizedBox(height: 8),
      TextField(
        controller: widget.nameController,
        textCapitalization: TextCapitalization.words,
        style: AppText.h3.copyWith(fontSize: 20, color: AppColors.tealText),
        decoration: InputDecoration(
          hintText: 'mis. Naya',
          hintStyle: AppText.body.copyWith(color: AppColors.muted),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.lime, width: 3),
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Eyebrow('Usia (boleh dilewati)', color: Colors.white),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (var age = 2; age <= 12; age++)
            _AgePill(age: age, selected: widget.ageYears == age, onTap: () => widget.onAgeChanged(widget.ageYears == age ? null : age)),
        ],
      ),
    ],
  );
}

class _AgePill extends StatelessWidget {
  const _AgePill({required this.age, required this.selected, required this.onTap});

  final int age;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$age tahun',
    excludeSemantics: true,
    child: PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fade),
          curve: Curves.easeOut,
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.lime : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: selected ? const [BoxShadow(color: Color(0x40000000), blurRadius: 10, offset: Offset(0, 4))] : null,
          ),
          child: Text('$age', style: AppText.h3.copyWith(fontSize: 20, color: selected ? AppColors.limeText : AppColors.tealText)),
        ),
      ),
    ),
  );
}

class _RoutinePage extends StatelessWidget {
  const _RoutinePage({required this.routine, required this.onChanged, required this.onNext, required this.onBack});

  final String routine;
  final ValueChanged<String> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  // Tiga kegiatan yang terjadi setiap hari pada hampir semua anak dan punya giliran berulang (suapan, siraman,
  // giliran main): tempat alami untuk lima contoh sehari (03 §5). Tanpa jam: jam berapa pun kegiatannya, misinya sama.
  static const _options = [
    ('makan', 'Waktu makan', 'Setiap suapan jadi kesempatan', Icons.restaurant_rounded, AppColors.coralDeep, AppColors.coralTint),
    ('mandi', 'Waktu mandi', 'Setiap siraman air jadi kesempatan', Icons.bathtub_rounded, AppColors.skyText, AppColors.skyTint),
    ('main', 'Waktu main', 'Setiap giliran main jadi kesempatan', Icons.toys_rounded, AppColors.sunText, AppColors.sunTint),
  ];

  @override
  Widget build(BuildContext context) => _OnboardingPage(
    step: 2,
    onBack: onBack,
    footer: SizedBox(
      width: 220,
      child: PrimaryButton(label: 'Lanjut', onPressed: onNext),
    ),
    children: [
      Text('Kegiatan harian mana yang paling pasti terjadi?', style: _title(false)),
      const SizedBox(height: 8),
      Text(
        'Misi lima contoh sehari menempel pada kegiatan ini, jadi tidak menambah pekerjaan baru. Jam berapa pun boleh. '
        'Bisa diganti kapan saja.',
        style: _lead(false),
      ),
      const SizedBox(height: 20),
      for (final (value, label, hint, icon, color, tint) in _options)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _RoutineCard(
            label: label,
            hint: hint,
            words: routineTurnWords[value] ?? const [],
            icon: icon,
            color: color,
            tint: tint,
            selected: routine == value,
            onTap: () => onChanged(value),
          ),
        ),
    ],
  );
}

class _RoutineCard extends StatelessWidget {
  const _RoutineCard({
    required this.label,
    required this.hint,
    required this.words,
    required this.icon,
    required this.color,
    required this.tint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final List<String> words;
  final IconData icon;
  final Color color;
  final Color tint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = Motion.of(context, Motion.fade);
    final app = AppScope.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: PressScale(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: d,
            curve: Curves.easeOut,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: selected ? AppColors.tealTint : AppColors.panel,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: selected ? AppColors.teal : AppColors.line, width: 2),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: d,
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(color: selected ? color : tint, borderRadius: BorderRadius.circular(15)),
                  child: Icon(icon, color: selected ? Colors.white : color, size: 26),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppText.h3),
                      Text(hint, style: AppText.cap),
                      const SizedBox(height: 8),
                      // Contoh kata yang punya giliran alami di kegiatan ini: gambar simbol sungguhan, bukan teks saja.
                      Row(
                        children: [
                          for (final w in words)
                            if (app.symbolById(w) case final s?)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: SymbolFace(symbol: s, width: 54, height: 54, compact: true),
                              ),
                        ],
                      ),
                    ],
                  ),
                ),
                AnimatedScale(
                  scale: selected ? 1 : 0.4,
                  duration: d,
                  curve: Curves.easeOutBack,
                  child: AnimatedOpacity(
                    opacity: selected ? 1 : 0,
                    duration: d,
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.tealDeep, size: 28),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BoardPreviewPage extends StatelessWidget {
  const _BoardPreviewPage({required this.onNext, required this.onBack});

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final words = AppScope.of(context).symbolsForPage(0).where((s) => !s.isHidden).toList();
    return _OnboardingPage(
      step: 3,
      dark: true,
      onBack: onBack,
      footer: SizedBox(
        width: 220,
        child: PrimaryButton(label: 'Lanjut', onPressed: onNext),
      ),
      children: [
        Text('Papan awal sudah jadi', style: _title(true)),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22)),
          child: LayoutBuilder(
            builder: (context, box) {
              const gap = 8.0;
              final w = (box.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  // Sel masuk bergantian, sekali, saat layar ini pertama tampil.
                  for (var i = 0; i < words.length; i++)
                    FadeSlideIn(
                      index: 2 + i ~/ 3,
                      child: SymbolFace(symbol: words[i], width: w, height: w * 0.92),
                    ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

/// A5: enam kata yang paling sering dicontohkan. Pilih kata, rekam, lalu kata berikutnya yang belum direkam
/// terpilih sendiri. Setiap rekaman langsung tersimpan; "Lewati" tetap setara.
class _FamilyVoicePage extends StatefulWidget {
  const _FamilyVoicePage({required this.onNext, required this.onBack});

  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<_FamilyVoicePage> createState() => _FamilyVoicePageState();
}

class _FamilyVoicePageState extends State<_FamilyVoicePage> {
  static const _words = ['mau', 'tidak', 'lagi', 'makan', 'minum', 'bantu'];
  String _selected = _words.first;

  late AppState _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
  }

  /// Simpan rekaman satu kata. Pindah ke kata berikutnya yang belum direkam hanya bila orang tua masih di kata ini
  /// (rekaman yang tersimpan karena orang tua sudah pindah kata tidak menggeser pilihannya).
  Future<void> _saved(String wordId, String? path) async {
    if (path == null) return;
    await _app.symbolDao.setFamilyAudio(wordId, path);
    await _app.reloadSymbols();
    if (!mounted) return;
    final next = _words.where((w) => _app.symbolById(w)?.familyAudio == null).firstOrNull;
    setState(() {
      if (_selected == wordId) _selected = next ?? wordId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final word = _selected;
    final recorded = _words.where((w) => app.symbolById(w)?.familyAudio != null).length;
    return _OnboardingPage(
      step: 4,
      onBack: widget.onBack,
      trailing: TextButton(
        onPressed: widget.onNext,
        style: TextButton.styleFrom(backgroundColor: AppColors.sand, minimumSize: const Size(48, 44)),
        child: const Text('Lewati'),
      ),
      footer: SizedBox(
        width: 240,
        child: PrimaryButton(label: recorded == 0 ? 'Lanjut' : 'Simpan', onPressed: widget.onNext),
      ),
      children: [
        Text('Rekam suara Ibu atau Ayah', style: _title(false)),
        const SizedBox(height: 8),
        Text('Enam kata saja. Bisa juga nanti.', style: _lead(false)),
        const SizedBox(height: 18),
        FamilyVoiceRecorder(
          key: ValueKey(word),
          wordId: word,
          initialPath: app.symbolById(word)?.familyAudio,
          onRecorded: (path) => _saved(word, path),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final w in _words)
              if (app.symbolById(w) case final s?)
                _WordChip(
                  label: s.labelDisplay,
                  selected: w == _selected,
                  done: s.familyAudio != null,
                  onTap: () => setState(() => _selected = w),
                ),
          ],
        ),
      ],
    );
  }
}

class _WordChip extends StatelessWidget {
  const _WordChip({required this.label, required this.selected, required this.done, required this.onTap});

  final String label;
  final bool selected;
  final bool done;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '$label, ${done ? 'sudah direkam' : 'belum direkam'}',
    excludeSemantics: true,
    child: PressScale(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: Motion.of(context, Motion.fade),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.tealTint : AppColors.panel,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(color: selected ? AppColors.teal : AppColors.line, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (done) ...[const Icon(Icons.check_rounded, size: 18, color: AppColors.leafText), const SizedBox(width: 4)],
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _FinishPage extends StatelessWidget {
  const _FinishPage({required this.name, required this.routine, required this.onFinish, required this.onBack});

  final String name;
  final String routine;

  /// Dipanggil dengan tujuan setelah pemasangan: misi hari ini atau papan.
  final ValueChanged<AfterOnboarding> onFinish;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => _OnboardingPage(
    step: 6,
    dark: true,
    onBack: onBack,
    footerHeight: 190,
    footer: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 260,
          child: PrimaryButton(label: 'Buka misi hari ini', onPressed: () => onFinish(AfterOnboarding.mission)),
        ),
        const SizedBox(height: 4),
        TextButton(onPressed: () => onFinish(AfterOnboarding.board), child: const Text('Lihat papan dulu')),
      ],
    ),
    children: [
      Text('Misi hari pertama', style: _title(true)),
      const SizedBox(height: 16),
      _MintCard(
        child: Text(
          'Saat ${routineDisplayLabel(routine)} nanti: tekan ${defaultTargetForWeek(1, routine: routine).toUpperCase()} sambil berkata '
          '"${defaultTargetForWeek(1, routine: routine)}", lima kali. '
          '${name.isEmpty ? 'Anak' : name} tidak perlu menekan apa pun. Itu saja untuk hari ini.',
        ),
      ),
      const SizedBox(height: 14),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Tidak ada skor. Kalau belum sempat, besok ada lagi.', style: _lead(true))),
        ],
      ),
    ],
  );
}

/// A5b PIN orang tua: menjaga layar orang tua dari ketukan anak. Anak tetap membuka papannya tanpa PIN.
class _PinPage extends StatelessWidget {
  const _PinPage({required this.name, required this.done, required this.onPin, required this.onBack});

  final String name;
  final bool done;
  final ValueChanged<String> onPin;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => _OnboardingPage(
    step: 5,
    onBack: onBack,
    footerHeight: 60,
    footer: const SizedBox.shrink(),
    children: [
      Text('Buat PIN orang tua', style: _title(false)),
      const SizedBox(height: 8),
      Text(
        'Setiap aplikasi dibuka, ${name.isEmpty ? 'anak' : name} bisa langsung ke papannya. Layar orang tua memakai PIN ini.',
        style: _lead(false),
      ),
      const SizedBox(height: 20),
      if (done)
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.tealDeep),
              SizedBox(width: 8),
              Expanded(child: Text('PIN tersimpan. Ketik lagi untuk mengganti.', style: AppText.bodyStrong)),
            ],
          ),
        ),
      Center(child: PinSetup(onDone: onPin)),
    ],
  );
}
