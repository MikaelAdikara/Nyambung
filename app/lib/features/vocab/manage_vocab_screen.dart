import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/error_log.dart';
import '../../core/motion.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../board/symbol_cell.dart';
import '../coach/companion_widgets.dart';
import 'photo_card_screen.dart';

enum _Mode { tampil, posisi }

/// C2 Kelola kosakata (layar orang tua, bukan papan anak).
///
/// - **Tampil/sembunyi**: ketuk kata untuk menyembunyikan; kata tersembunyi tetap memegang tempatnya (invarian 8).
///   Kartu buatan keluarga (foto, frasa) bisa dihapus; kata bawaan hanya bisa disembunyikan.
/// - **Atur posisi**: tahan lalu geser kata ke slot lain di halaman kategori; bila slot terisi, keduanya bertukar.
///   Halaman inti dan enam sel cermin terkunci karena tangan anak menghafal letaknya (Thistle dkk. 2018, 03 §4).
/// - **Cari**: temukan kata di halaman mana pun, lalu lompat ke halamannya.
class ManageVocabScreen extends StatefulWidget {
  const ManageVocabScreen({super.key});

  @override
  State<ManageVocabScreen> createState() => _ManageVocabScreenState();
}

class _ManageVocabScreenState extends State<ManageVocabScreen> {
  static const _cols = 3;
  static const _categorySlots = 18;

  late AppState _app;
  final _search = TextEditingController();
  int _page = 0;
  _Mode _mode = _Mode.tampil;
  bool _busy = false;
  String? _flash;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action, String failMessage) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e, st) {
      ErrorLog.record('kosakata', e, st);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failMessage)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(WordSymbol s) => _run(() async {
    await _app.symbolDao.setHidden(s.wordId, !s.isHidden);
    await _app.reloadSymbols();
  }, 'Belum tersimpan. Coba lagi.');

  Future<void> _move(int from, int to) => _run(() => _app.moveSymbol(_page, from, to), 'Kata belum pindah. Coba lagi.');

  Future<void> _delete(WordSymbol s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus kartu ${s.labelDisplay}?'),
        content: const Text('Kartu hilang dari papan dan slotnya jadi kosong. Catatan ketukan yang sudah ada tetap tersimpan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus')),
        ],
      ),
    );
    if (ok == true) await _run(() => _app.deleteCard(s), 'Kartu belum terhapus. Coba lagi.');
  }

  Future<void> _addCard() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => PhotoCardScreen(initialPage: _page == 0 ? null : _page)));
    if (mounted) setState(() {});
  }

  void _jumpTo(WordSymbol s) {
    FocusScope.of(context).unfocus();
    setState(() {
      _page = s.page;
      _flash = s.wordId;
      _search.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cells = _app.cellsForPage(_page);
    final slots = _page == 0 ? cells.length : (cells.length > _categorySlots ? cells.length : _categorySlots);
    final rounded = (slots / _cols).ceil() * _cols;
    final hiddenCount = _app.allSymbols.where((s) => s.isHidden).length;
    final query = _search.text.trim().toLowerCase();
    final results = query.isEmpty
        ? const <WordSymbol>[]
        : _app.allSymbols.where((s) => s.labelDisplay.toLowerCase().contains(query)).take(12).toList();
    final arranging = _mode == _Mode.posisi;

    return CompanionPage(
      title: 'Kosakata',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Cari kata',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(tooltip: 'Hapus pencarian', icon: const Icon(Icons.close_rounded), onPressed: () => setState(_search.clear)),
              filled: true,
              fillColor: CompanionColors.panel,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: CompanionColors.line),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(99),
                borderSide: const BorderSide(color: CompanionColors.line),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
          if (query.isNotEmpty) ...[
            const SizedBox(height: 10),
            if (results.isEmpty)
              const Text('Tidak ada kata yang cocok.', style: AppText.muted)
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in results)
                    ActionChip(
                      avatar: const Icon(Icons.north_east_rounded, size: 16),
                      label: Text('${s.labelDisplay} · ${_pageLabel(s.page)}'),
                      onPressed: () => _jumpTo(s),
                    ),
                ],
              ),
          ],
          const SizedBox(height: 14),
          SegmentedButton<_Mode>(
            segments: const [
              ButtonSegment(value: _Mode.tampil, icon: Icon(Icons.visibility_rounded), label: Text('Tampil & hapus')),
              ButtonSegment(value: _Mode.posisi, icon: Icon(Icons.open_with_rounded), label: Text('Atur posisi')),
            ],
            selected: {_mode},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() => _mode = v.first),
          ),
          const SizedBox(height: 12),
          CompanionCard(
            color: arranging ? CompanionColors.sunTint : CompanionColors.sand,
            borderColor: arranging ? CompanionColors.sunLine : CompanionColors.sand,
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  arranging ? Icons.info_outline_rounded : Icons.touch_app_rounded,
                  size: 20,
                  color: arranging ? CompanionColors.sunText : CompanionColors.tealText,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    arranging
                        ? (_page == 0
                              ? 'Halaman inti terkunci: tangan anak menghafal letak 12 kata ini.'
                              : 'Tahan lalu geser kata ke slot lain. Anak belajar dari letak yang tetap, jadi pindahkan seperlunya '
                                    'dan contohkan letak barunya beberapa hari.')
                        : 'Ketuk kata untuk menyembunyikan atau menampilkannya. '
                              '${hiddenCount == 0 ? 'Semua kata tampil.' : '$hiddenCount kata disembunyikan.'}',
                    style: AppText.body.copyWith(fontSize: 14.5, color: arranging ? CompanionColors.sunText : CompanionColors.ink),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _app.pages.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = _app.pages[i];
                return ChoiceChip(
                  label: Text(p.tabLabel),
                  selected: p.page == _page,
                  onSelected: (_) => setState(() {
                    _page = p.page;
                    _flash = null;
                  }),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, box) {
              const gap = 8.0;
              final w = (box.maxWidth - gap * (_cols - 1)) / _cols;
              final h = w * 0.95;
              return Column(
                children: [
                  for (var r = 0; r < rounded ~/ _cols; r++)
                    Padding(
                      padding: EdgeInsets.only(bottom: r == 1 && _page != 0 ? gap + 8 : gap),
                      child: Row(
                        children: [
                          for (var c = 0; c < _cols; c++) ...[if (c > 0) const SizedBox(width: gap), _slot(r * _cols + c, cells, w, h)],
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Tambah kartu dari foto', icon: Icons.add_a_photo_outlined, onPressed: _addCard),
        ],
      ),
    );
  }

  String _pageLabel(int page) => _app.pages.where((p) => p.page == page).map((p) => p.tabLabel).firstOrNull ?? '';

  Widget _slot(int i, List<WordSymbol?> cells, double w, double h) {
    final s = i < cells.length ? cells[i] : null;
    final mirror = _page != 0 && i < mirrorSlots;
    final canArrange = _mode == _Mode.posisi && _page != 0 && !mirror;

    Widget face;
    if (s == null) {
      face = _page == 0 ? SizedBox(width: w, height: h) : EmptySlot(width: w, height: h);
    } else if (mirror) {
      // Sel cermin: kata inti yang sama di setiap halaman, dikelola dari halaman INTI.
      face = Opacity(
        opacity: 0.45,
        child: SymbolFace(symbol: s, width: w, height: h),
      );
    } else {
      face = _Cell(
        symbol: s,
        width: w,
        height: h,
        flash: _flash == s.wordId,
        onTap: _mode == _Mode.tampil ? () => _toggle(s) : null,
        onDelete: _mode == _Mode.tampil && s.isCustom ? () => _delete(s) : null,
      );
    }
    if (mirror && s != null) {
      face = Stack(
        children: [
          face,
          const Positioned(right: 6, bottom: 6, child: Icon(Icons.lock_rounded, size: 16, color: CompanionColors.muted)),
        ],
      );
    }
    if (!canArrange) return face;

    final target = DragTarget<int>(
      onWillAcceptWithDetails: (d) => d.data != i,
      onAcceptWithDetails: (d) => _move(d.data, i),
      // Bingkai sebagai lapisan depan: tidak menambah ukuran sel, jadi kolom tidak meluber.
      builder: (context, candidates, _) => AnimatedContainer(
        duration: Motion.of(context, Motion.press),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: candidates.isNotEmpty ? CompanionColors.tealDeep : Colors.transparent, width: 3),
        ),
        child: face,
      ),
    );
    if (s == null) return target;
    return LongPressDraggable<int>(
      data: i,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: SymbolFace(symbol: s, width: w, height: h),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: face),
      child: target,
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.symbol, required this.width, required this.height, required this.flash, this.onTap, this.onDelete});

  final WordSymbol symbol;
  final double width;
  final double height;
  final bool flash;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onTap != null,
    label: '${symbol.labelSpeech}, ${symbol.isHidden ? 'tersembunyi' : 'tampil'}',
    excludeSemantics: true,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          children: [
            AnimatedOpacity(
              opacity: symbol.isHidden ? 0.35 : 1,
              duration: Motion.of(context, Motion.fade),
              child: SymbolFace(symbol: symbol, width: width, height: height),
            ),
            if (flash)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CompanionColors.tealDeep, width: 3),
                    ),
                  ),
                ),
              ),
            if (symbol.isHidden)
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
            if (onDelete != null)
              Positioned(
                right: 2,
                top: 2,
                child: IconButton(
                  tooltip: 'Hapus kartu',
                  onPressed: onDelete,
                  style: IconButton.styleFrom(backgroundColor: Colors.white, minimumSize: const Size(40, 40)),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: CompanionColors.caution),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
