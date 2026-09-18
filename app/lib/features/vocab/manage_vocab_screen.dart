import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../data/models.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_widgets.dart';

/// C2 Kelola kosakata: sembunyikan atau tampilkan kembali sebuah kata. Posisi tidak bisa dipindahkan;
/// kata yang disembunyikan tetap memegang tempatnya di papan (invarian 8). Kata di halaman kata inti
/// ikut tersembunyi di sel cermin setiap halaman kategori, karena sel itu adalah kata yang sama.
class ManageVocabScreen extends StatefulWidget {
  const ManageVocabScreen({super.key});

  @override
  State<ManageVocabScreen> createState() => _ManageVocabScreenState();
}

class _ManageVocabScreenState extends State<ManageVocabScreen> {
  late AppState _app;
  int _page = 0;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
  }

  Future<void> _toggle(WordSymbol s) async {
    if (_busy) return;
    setState(() => _busy = true);
    await _app.symbolDao.setHidden(s.wordId, !s.isHidden);
    await _app.reloadSymbols();
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final words = _app.symbolsForPage(_page);
    final hiddenCount = _app.allSymbols.where((s) => s.isHidden).length;
    return CompanionPage(
      title: 'Kelola kosakata',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const Text(
            'Ketuk kata untuk menyembunyikan atau menampilkannya lagi. Posisinya tidak bisa dipindahkan: kata yang '
            'disembunyikan tetap memegang tempatnya, supaya letaknya tidak berubah bila ditampilkan kembali. '
            'Anak mengingat letak kata, bukan hanya gambarnya.',
            style: companionBodyStyle,
          ),
          const SizedBox(height: 8),
          Text(hiddenCount == 0 ? 'Semua kata tampil.' : '$hiddenCount kata sedang disembunyikan.', style: companionMutedStyle),
          const SizedBox(height: 12),
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
              const cols = 3;
              const gap = 8.0;
              final w = (box.maxWidth - gap * (cols - 1)) / cols;
              return Wrap(spacing: gap, runSpacing: gap, children: [for (final s in words) _cell(s, w)]);
            },
          ),
        ],
      ),
    );
  }

  Widget _cell(WordSymbol s, double w) {
    final h = w * 0.95;
    return Semantics(
      button: true,
      label: '${s.labelSpeech}, ${s.isHidden ? 'tersembunyi' : 'tampil'}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => _toggle(s),
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Opacity(
                opacity: s.isHidden ? 0.35 : 1,
                child: SymbolFace(symbol: s, width: w, height: h),
              ),
              if (s.isHidden)
                Positioned(
                  left: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: CompanionColors.ink, borderRadius: BorderRadius.circular(8)),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_off, size: 14, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Tersembunyi',
                          style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
