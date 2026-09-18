import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../data/models.dart';
import '../board/symbol_cell.dart';
import 'companion_widgets.dart';

/// Kunci preferensi urutan SEKARANG → NANTI. Hanya keadaan tampilan di perangkat: bukan catatan klinis,
/// bukan peristiwa, dan tidak pernah disinkronkan.
abstract final class NowNextKeys {
  static const now = 'now_next_now';
  static const next = 'now_next_next';
}

/// N2 penyusun (layar orang tua): pilih dua kata dari kosakata yang sudah ada.
class NowNextScreen extends StatefulWidget {
  const NowNextScreen({super.key});

  @override
  State<NowNextScreen> createState() => _NowNextScreenState();
}

class _NowNextScreenState extends State<NowNextScreen> {
  late AppState _app;
  String? _now;
  String? _next;

  /// Slot yang sedang diisi: true = SEKARANG, false = NANTI.
  bool _fillingNow = true;
  int _page = 4;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    if (!_loaded) {
      _loaded = true;
      _now = _app.prefs.getString(NowNextKeys.now);
      _next = _app.prefs.getString(NowNextKeys.next);
      if (_now != null && _next == null) _fillingNow = false;
      if (!_app.pages.any((p) => p.page == _page)) _page = 0;
    }
  }

  Future<void> _pick(WordSymbol s) async {
    final fillingNow = _fillingNow;
    setState(() {
      if (fillingNow) {
        _now = s.wordId;
        _fillingNow = false;
      } else {
        _next = s.wordId;
      }
    });
    await _app.prefs.setString(fillingNow ? NowNextKeys.now : NowNextKeys.next, s.wordId);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _now != null && _next != null;
    final words = _app.symbolsForPage(_page).where((s) => !s.isHidden).toList();
    return CompanionPage(
      title: 'Sekarang → Nanti',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text(
            'Tunjukkan urutan kegiatan dengan dua gambar: apa yang terjadi sekarang, lalu apa yang terjadi nanti. '
            'Tanpa jam, tanpa hadiah, tanpa penilaian.',
            style: companionBodyStyle,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _slot('SEKARANG', _now, _fillingNow, () => setState(() => _fillingNow = true))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_forward, size: 32)),
              Expanded(child: _slot('NANTI', _next, !_fillingNow, () => setState(() => _fillingNow = false))),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Tunjukkan ke anak',
            icon: Icons.fullscreen,
            onPressed: ready ? () => Navigator.of(context).push(NowNextView.route(_now!, _next!)) : null,
          ),
          const SizedBox(height: 20),
          Text('Pilih kata untuk ${_fillingNow ? 'SEKARANG' : 'NANTI'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _app.pages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _app.pages[i];
                return ChoiceChip(label: Text(p.tabLabel), selected: p.page == _page, onSelected: (_) => setState(() => _page = p.page));
              },
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 8.0;
              final w = (box.maxWidth - gap * 2) / 3;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final s in words)
                    Semantics(
                      button: true,
                      label: s.labelSpeech,
                      excludeSemantics: true,
                      child: GestureDetector(
                        onTap: () => _pick(s),
                        child: SymbolFace(symbol: s, width: w, height: w * 0.95),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _slot(String title, String? wordId, bool active, VoidCallback onTap) {
    final s = wordId == null ? null : _app.symbolById(wordId);
    return Semantics(
      button: true,
      selected: active,
      label: '$title ${s?.labelSpeech ?? 'kosong'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active ? CompanionColors.navySoft : CompanionColors.panel,
            border: Border.all(color: active ? CompanionColors.navy : CompanionColors.line, width: active ? 3 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              LayoutBuilder(
                builder: (context, box) => s == null
                    ? SizedBox(
                        height: box.maxWidth * 0.95,
                        child: const Center(
                          child: Text('Ketuk kata di bawah', textAlign: TextAlign.center, style: companionMutedStyle),
                        ),
                      )
                    : SymbolFace(symbol: s, width: box.maxWidth, height: box.maxWidth * 0.95),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// N2 tampilan anak: dua kartu besar, tanpa statistik dan tanpa animasi. Mengetuk kartu membunyikan
/// "sekarang {kata}" / "nanti {kata}" tanpa mencatat peristiwa (bukan ketukan papan).
class NowNextView extends StatelessWidget {
  const NowNextView({super.key, required this.nowId, required this.nextId});

  final String nowId;
  final String nextId;

  static Route<void> route(String nowId, String nextId) => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => NowNextView(nowId: nowId, nextId: nextId),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final now = app.symbolById(nowId);
    final next = app.symbolById(nextId);
    final sekarang = app.symbolById('sekarang');
    final nanti = app.symbolById('nanti');

    void say(WordSymbol? time, WordSymbol? word) {
      final words = [?time, ?word];
      if (words.isNotEmpty) app.speech.speakSentence(words, byParent: false);
    }

    Widget card(String title, WordSymbol? time, WordSymbol? word) => Expanded(
      child: Semantics(
        button: true,
        label: '$title ${word?.labelSpeech ?? ''}',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => say(time, word),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: CompanionColors.ink),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final w = box.maxWidth < box.maxHeight / 0.95 ? box.maxWidth : box.maxHeight / 0.95;
                    final h = w * 0.95;
                    return Center(
                      child: word == null ? const SizedBox.shrink() : SymbolFace(symbol: word, width: w, height: h),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: CompanionColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(tooltip: 'Kembali', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: OrientationBuilder(
                  builder: (context, orientation) {
                    final children = [
                      card('SEKARANG', sekarang, now),
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.arrow_forward, size: 48, color: CompanionColors.muted),
                      ),
                      card('NANTI', nanti, next),
                    ];
                    return orientation == Orientation.landscape ? Row(children: children) : _portrait(children);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Potret: kartu bertumpuk, panah menunjuk ke bawah.
  Widget _portrait(List<Widget> children) => Column(
    children: [
      children[0],
      const Padding(
        padding: EdgeInsets.all(8),
        child: Icon(Icons.arrow_downward, size: 48, color: CompanionColors.muted),
      ),
      children[2],
    ],
  );
}
