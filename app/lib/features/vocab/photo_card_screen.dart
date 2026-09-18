import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/personal_card.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_widgets.dart';
import 'family_voice_screen.dart';

/// C3 Kartu baru dari foto: 1) foto benda di rumah, 2) label huruf kapital + halaman, 3) tersimpan.
///
/// Foto diambil lewat aplikasi kamera atau galeri bawaan Android (tanpa izin kamera di aplikasi ini), diperkecil
/// ke 512 px, lalu disalin ke folder aplikasi. Foto **tidak pernah** dikirim ke server (invarian 18 diperluas ke
/// foto); yang ikut peristiwa `PRS` hanya `word_id` berisi label. Kartu mengisi slot kosong berikutnya.
class PhotoCardScreen extends StatefulWidget {
  const PhotoCardScreen({super.key, this.initialPage});

  /// Halaman yang sedang dibuka di C2; halaman kata inti diabaikan.
  final int? initialPage;

  @override
  State<PhotoCardScreen> createState() => _PhotoCardScreenState();
}

class _PhotoCardScreenState extends State<PhotoCardScreen> {
  final _picker = ImagePicker();
  final _label = TextEditingController();
  late AppState _app;
  bool _started = false;

  String? _photo;
  int? _page;
  WordSymbol? _saved;
  bool _busy = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    if (!_started) {
      _started = true;
      _page = _defaultPage();
      _recoverLostPhoto();
    }
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  /// Halaman yang sedang dibuka di C2, selain itu halaman BENDA, selain itu halaman kategori pertama.
  int? _defaultPage() {
    final pages = _app.pages.where((p) => p.page != 0).toList();
    if (pages.isEmpty) return null;
    if (pages.any((p) => p.page == widget.initialPage)) return widget.initialPage;
    return pages.firstWhere((p) => p.tabLabel == 'BENDA', orElse: () => pages.first).page;
  }

  /// Di HP RAM 2 GB, Android bisa menutup aplikasi selama kamera terbuka. Foto yang sudah diambil dipulihkan di sini.
  Future<void> _recoverLostPhoto() async {
    if (!Platform.isAndroid) return;
    try {
      final lost = await _picker.retrieveLostData();
      final file = lost.file;
      if (file != null && mounted) setState(() => _photo = file.path);
    } catch (e, st) {
      ErrorLog.record('c3:pulihkan', e, st);
    }
  }

  Future<void> _pick(ImageSource source) async {
    setState(() => _error = null);
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 80);
      if (file != null && mounted) setState(() => _photo = file.path);
    } catch (e, st) {
      ErrorLog.record('c3:foto', e, st);
      if (mounted) setState(() => _error = 'Kamera atau galeri tidak bisa dibuka. Coba lagi.');
    }
  }

  Future<void> _save() async {
    final photo = _photo;
    final page = _page;
    if (photo == null || page == null || normalizePersonalLabel(_label.text).isEmpty) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final card = await _app.addPersonalCard(label: _label.text, page: page, photoPath: photo);
      if (mounted) setState(() => _saved = card);
    } catch (e, st) {
      ErrorLog.record('c3:simpan', e, st);
      if (mounted) setState(() => _error = 'Kartu belum tersimpan. Coba sekali lagi.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  int get _step => _saved != null ? 3 : (_photo == null ? 1 : 2);

  @override
  Widget build(BuildContext context) => CompanionPage(
    title: 'Kartu baru dari foto',
    body: AnimatedSwitcher(
      duration: Motion.of(context, Motion.fade),
      child: KeyedSubtree(
        key: ValueKey(_step),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            _Stepper(step: _step),
            const SizedBox(height: 18),
            ...switch (_step) {
              1 => _stepPhoto(),
              2 => _stepLabel(),
              _ => _stepDone(),
            },
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: CompanionColors.caution, fontWeight: FontWeight.w700),
              ),
            ],
          ],
        ),
      ),
    ),
  );

  List<Widget> _stepPhoto() => [
    Container(
      height: 180,
      decoration: BoxDecoration(color: CompanionColors.sand, borderRadius: BorderRadius.circular(20)),
      child: const Center(child: Icon(Icons.photo_camera_outlined, size: 48, color: CompanionColors.muted)),
    ),
    const SizedBox(height: 12),
    const Text('Foto benda milik anak: gelas kesayangannya, boneka, sepeda.', style: companionMutedStyle),
    const SizedBox(height: 16),
    PrimaryButton(label: 'Ambil foto', icon: Icons.photo_camera_outlined, onPressed: () => _pick(ImageSource.camera)),
    const SizedBox(height: 12),
    SizedBox(
      width: double.infinity,
      child: EqualOutlineButton(label: 'Pilih dari galeri', onPressed: () => _pick(ImageSource.gallery)),
    ),
  ];

  List<Widget> _stepLabel() {
    final page = _page;
    final pageLabel = _app.pages.where((p) => p.page == page).map((p) => p.tabLabel).firstOrNull ?? '';
    final label = normalizePersonalLabel(_label.text);
    return [
      CompanionCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 4 / 3,
                child: Image.file(File(_photo!), fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            const Text('LABEL YANG DIUCAPKAN', style: _eyebrow),
            const SizedBox(height: 6),
            TextField(
              controller: _label,
              autofocus: true,
              maxLength: personalLabelMax,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [_UpperCase()],
              style: AppText.h2,
              decoration: const InputDecoration(hintText: 'mis. GELAS', border: OutlineInputBorder()),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const Text('HALAMAN', style: _eyebrow),
      const SizedBox(height: 6),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final p in _app.pages.where((p) => p.page != 0))
            ChoiceChip(label: Text(p.tabLabel), selected: p.page == page, onSelected: (_) => setState(() => _page = p.page)),
        ],
      ),
      const SizedBox(height: 16),
      const Text('HASILNYA DI PAPAN', style: _eyebrow),
      const SizedBox(height: 6),
      Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SymbolFace(
            symbol: WordSymbol(
              wordId: 'pratinjau',
              labelDisplay: label.isEmpty ? '…' : label,
              labelSpeech: '',
              pos: 'benda',
              category: 'personal',
              page: page ?? 0,
              positionIndex: 0,
              symbolPath: _photo!,
              isCustom: true,
            ),
            width: 104,
            height: 100,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(page == null ? '' : 'Halaman $pageLabel, posisi ${_app.nextCardSlot(page) + 1}', style: companionMutedStyle),
          ),
        ],
      ),
      const SizedBox(height: 20),
      PrimaryButton(label: _busy ? 'Menyimpan…' : 'Simpan kartu', onPressed: _busy || label.isEmpty || page == null ? null : _save),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: EqualOutlineButton(label: 'Ambil ulang foto', onPressed: _busy ? null : () => setState(() => _photo = null)),
      ),
    ];
  }

  List<Widget> _stepDone() {
    final card = _saved!;
    final pageLabel = _app.pages.where((p) => p.page == card.page).map((p) => p.tabLabel).firstOrNull ?? '';
    return [
      Row(
        children: [
          PopIn(child: SymbolFace(symbol: card, width: 104, height: 100)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${card.labelDisplay} sudah ada di halaman $pageLabel, posisi ${card.positionIndex + 1}.',
              style: const TextStyle(fontSize: 18, height: 1.3, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
      const SizedBox(height: 24),
      PrimaryButton(label: 'Selesai', onPressed: () => Navigator.of(context).pop()),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: EqualOutlineButton(
          label: 'Rekam suaramu untuk ${card.labelDisplay}',
          onPressed: () =>
              Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => const FamilyVoiceScreen(showPersonal: true))),
        ),
      ),
      const SizedBox(height: 12),
      Center(
        child: TextButton(
          onPressed: () => setState(() {
            _saved = null;
            _photo = null;
            _label.clear();
          }),
          child: const Text('Buat kartu lain'),
        ),
      ),
    ];
  }
}

const _eyebrow = AppText.eyebrow;

/// Tiga langkah (Foto → Label → Simpan): lingkaran terisi toska dengan centang bila sudah lewat.
class _Stepper extends StatelessWidget {
  const _Stepper({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    const labels = ['Foto', 'Label', 'Simpan'];
    return Row(
      children: [
        for (var i = 0; i < 3; i++) ...[
          if (i > 0)
            Expanded(
              child: AnimatedContainer(
                duration: Motion.of(context, Motion.resize),
                height: 3,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: i < step ? CompanionColors.teal : CompanionColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
          AnimatedContainer(
            duration: Motion.of(context, Motion.resize),
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: i < step ? CompanionColors.tealDeep : CompanionColors.sand, shape: BoxShape.circle),
            child: i < step - 1 || (step == 3 && i == 2)
                ? const Icon(Icons.check_rounded, size: 18, color: Colors.white)
                : Text(
                    '${i + 1}',
                    style: TextStyle(fontWeight: FontWeight.w900, color: i < step ? Colors.white : CompanionColors.muted),
                  ),
          ),
          const SizedBox(width: 6),
          Text(labels[i], style: AppText.cap.copyWith(color: i < step ? CompanionColors.ink : CompanionColors.muted)),
        ],
      ],
    );
  }
}

class _UpperCase extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}
