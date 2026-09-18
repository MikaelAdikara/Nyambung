import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/error_log.dart';
import '../../core/theme.dart';
import '../../data/models.dart';
import '../../data/repo/vocab_loader.dart';
import 'hold_button.dart';
import 'lock_task.dart';
import 'symbol_cell.dart';

/// Ikon tab per halaman (02 §4).
const pageIcons = <int, IconData>{
  0: Icons.star,
  1: Icons.forum,
  2: Icons.open_with,
  3: Icons.waving_hand,
  4: Icons.directions_run,
  5: Icons.home,
  6: Icons.mood,
  7: Icons.palette,
  8: Icons.restaurant,
  9: Icons.people,
  10: Icons.place,
  11: Icons.category,
  12: Icons.accessibility_new,
};

/// Papan Bicara B4 (halaman kata inti) + B5 (halaman kategori).
///
/// - **Mode anak** (`allowTurnToggle: false`): tanpa teks status, tanpa pengubah giliran, semua ketukan
///   `actor=anak`, tombol kunci TAHAN di kanan atas, tombol kembali Android ditahan. Buka dengan
///   [BoardScreen.childRoute] (tanpa animasi, invarian 11).
/// - **Mode misi** (`allowTurnToggle: true`): dua tombol besar "Giliran pendamping" / "Giliran anak";
///   `context` peristiwa = [missionContext]. Buka dengan `MaterialPageRoute` biasa.
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, this.missionContext, this.allowTurnToggle = false});

  /// `mission_id` bila papan dibuka dari misi; `null` = rutinitas anak.
  final String? missionContext;
  final bool allowTurnToggle;

  bool get childMode => !allowTurnToggle;

  /// Rute papan anak: tanpa animasi masuk/keluar.
  static Route<void> childRoute() => PageRouteBuilder<void>(
    pageBuilder: (_, _, _) => const BoardScreen(),
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
  );

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _utterance = ValueNotifier<List<_Word>>(const []);

  /// Mode misi dimulai dengan giliran pendamping: contoh diberikan dulu di depan anak.
  final _parentTurn = ValueNotifier<bool>(true);
  late AppState _app;
  bool _started = false;
  int _page = 0;

  /// Halaman yang disarankan lewat penanda di tab (N1: sesudah SAKIT → halaman TUBUH). Hanya penanda;
  /// papan tidak pindah sendiri dan tidak ada yang menghalangi ketukan berikutnya.
  final _suggestedPage = ValueNotifier<int?>(null);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    if (!_started) {
      _started = true;
      _app.boardOpen = true;
      _app.startBoardSession();
      if (widget.childMode && _app.childLock) LockTask.start();
      WidgetsBinding.instance.addPostFrameCallback((_) => _precacheBoard());
    }
  }

  /// Sesudah frame pertama: dekode gambar halaman yang terbuka dulu, lalu halaman lain, supaya pindah tab tidak
  /// menampilkan sel kosong sesaat. Semua 120 simbol ± 30 MB, di bawah batas cache gambar (main.dart).
  Future<void> _precacheBoard() async {
    final order = [
      _page,
      for (final p in _app.pages)
        if (p.page != _page) p.page,
    ];
    for (final p in order) {
      if (!mounted) return;
      await precacheSymbols(context, _app.cellsForPage(p), keepGoing: () => mounted);
    }
  }

  @override
  void dispose() {
    _app.boardOpen = false;
    _utterance.dispose();
    _parentTurn.dispose();
    _suggestedPage.dispose();
    super.dispose();
  }

  bool get _byParent => widget.allowTurnToggle && _parentTurn.value;

  void _log(String content, String method) {
    _app.logTap(content: content, method: method, byParent: _byParent, context: widget.missionContext).catchError((
      Object e,
      StackTrace st,
    ) {
      ErrorLog.record('board:log', e, st);
    });
  }

  void _onSelect(WordSymbol s) {
    _utterance.value = [..._utterance.value, _Word(s)];
    _app.speech.speakWord(s, byParent: _byParent);
    _log(s.wordId, s.isCustom ? Method.prs : (_page == 0 ? Method.sel : Method.kat));
    _suggestedPage.value = _suggestionAfter(s);
  }

  /// SAKIT → tandai halaman TUBUH (halaman kata tubuh diambil dari kosakata, bukan nomor tetap).
  int? _suggestionAfter(WordSymbol s) {
    if (s.wordId != 'sakit') return null;
    final bodyPage = _app.symbolById('perut')?.page;
    return bodyPage == null || bodyPage == _page ? null : bodyPage;
  }

  void _openPage(int p) {
    _suggestedPage.value = null;
    setState(() => _page = p);
    _app.speech.preload(_app.cellsForPage(p));
  }

  void _onDelete() {
    final words = _utterance.value;
    if (words.isEmpty) return;
    _utterance.value = words.sublist(0, words.length - 1);
    _suggestedPage.value = null;
    _log(words.last.symbol.wordId, Method.hap);
  }

  /// Geser urutan kata di bilah ujaran. Tidak ada peristiwa baru: UCAPKAN mencatat urutan akhir.
  void _onReorder(int from, int to) {
    final words = [..._utterance.value];
    words.insert(to, words.removeAt(from));
    _utterance.value = words;
  }

  void _onSpeak() {
    final words = [for (final w in _utterance.value) w.symbol];
    if (words.isEmpty) return;
    _app.speech.speakSentence(words, byParent: _byParent);
    _log(words.map((w) => w.wordId).join(' '), Method.ucp);
  }

  Future<void> _exitChildMode() async {
    if (_app.childLock) await LockTask.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Column(
        children: [
          _SpeechBar(
            utterance: _utterance,
            onReorder: _onReorder,
            onDelete: _onDelete,
            onSpeak: _onSpeak,
            leading: widget.childMode
                ? null
                : IconButton(tooltip: 'Kembali', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
            trailing: widget.childMode ? HoldButton(onComplete: _exitChildMode) : null,
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ValueListenableBuilder<int?>(
                  valueListenable: _suggestedPage,
                  builder: (context, suggested, _) =>
                      _PageRail(pages: _app.pages, selected: _page, suggested: suggested, onSelect: _openPage),
                ),
                Expanded(
                  child: _BoardGrid(
                    key: ValueKey(_page),
                    cells: _app.cellsForPage(_page),
                    gridCols: _app.child?.gridCols ?? 3,
                    isCorePage: _page == 0,
                    holdMs: _app.holdMs,
                    onSelect: _onSelect,
                  ),
                ),
              ],
            ),
          ),
          if (widget.allowTurnToggle) _TurnToggle(parentTurn: _parentTurn),
        ],
      ),
    );
    return PopScope(
      canPop: !widget.childMode,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !widget.childMode) return;
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(duration: Duration(seconds: 2), content: Text('Tahan tombol kunci di kanan atas untuk keluar.')));
      },
      child: Theme(
        data: boardTheme(Theme.of(context)),
        child: Scaffold(backgroundColor: AppColors.bg, body: body),
      ),
    );
  }
}

/// Satu kata di bilah ujaran. Identitas objek menjadi kunci, jadi kata yang sama dua kali tetap dua item terpisah.
class _Word {
  _Word(this.symbol);

  final WordSymbol symbol;
}

/// Bilah ujaran (tinggi 88 dp, latar panel) + HAPUS + UCAPKAN. Hanya bagian ini yang dibangun ulang saat ketukan.
///
/// Kata bisa digeser: tahan ± 0,5 detik lalu seret ke tempat baru. Ini satu-satunya gerakan di papan anak
/// (pengecualian invarian 11, lihat PERUBAHAN.md): kata yang diangkat mengikuti jari, kata lain bergeser memberi
/// tempat, dan semua itu hanya terjadi saat jari sedang menyeret.
class _SpeechBar extends StatefulWidget {
  const _SpeechBar({
    required this.utterance,
    required this.onReorder,
    required this.onDelete,
    required this.onSpeak,
    this.leading,
    this.trailing,
  });

  final ValueNotifier<List<_Word>> utterance;
  final void Function(int from, int to) onReorder;
  final VoidCallback onDelete;
  final VoidCallback onSpeak;
  final Widget? leading;
  final Widget? trailing;

  @override
  State<_SpeechBar> createState() => _SpeechBarState();
}

class _SpeechBarState extends State<_SpeechBar> {
  final _scroll = ScrollController();
  int _lastLength = 0;

  @override
  void initState() {
    super.initState();
    widget.utterance.addListener(_followNewWord);
  }

  @override
  void dispose() {
    widget.utterance.removeListener(_followNewWord);
    _scroll.dispose();
    super.dispose();
  }

  /// Kata baru selalu terlihat: lompat (tanpa animasi) ke ujung kanan setiap kali kata bertambah.
  void _followNewWord() {
    final length = widget.utterance.value.length;
    final grew = length > _lastLength;
    _lastLength = length;
    if (!grew) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
    });
  }

  /// Kata yang sedang diangkat: sedikit membesar dengan bayangan tipis, supaya jelas sedang dipegang.
  Widget _lifted(Widget child, int index, Animation<double> animation) => AnimatedBuilder(
    animation: animation,
    builder: (context, child) {
      final t = Curves.easeOut.transform(animation.value);
      return Transform.scale(
        scale: 1 + 0.05 * t,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: [BoxShadow(color: Color.fromRGBO(0, 0, 0, 0.18 * t), blurRadius: 8 * t, offset: Offset(0, 3 * t))],
          ),
          child: child,
        ),
      );
    },
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final leading = widget.leading;
    final trailing = widget.trailing;
    return Container(
      color: AppColors.panel,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        children: [
          SizedBox(
            height: 88,
            child: Row(
              children: [
                ?leading,
                Expanded(
                  // Jalur kalimat: bidang cekung tempat kata-kata berbaris, supaya terbaca sebagai satu kalimat.
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      border: Border.all(color: AppColors.line, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ValueListenableBuilder<List<_Word>>(
                      valueListenable: widget.utterance,
                      builder: (context, words, _) => ReorderableListView.builder(
                        scrollController: _scroll,
                        scrollDirection: Axis.horizontal,
                        itemCount: words.length,
                        onReorderItem: widget.onReorder,
                        proxyDecorator: _lifted,
                        itemBuilder: (_, i) => Padding(
                          key: ObjectKey(words[i]),
                          padding: EdgeInsets.only(right: i == words.length - 1 ? 0 : 4),
                          child: SymbolFace(symbol: words[i].symbol, width: 68, height: 80, compact: true),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Semantics(
                  button: true,
                  label: 'Hapus',
                  child: Tooltip(
                    message: 'Hapus',
                    child: InkResponse(
                      onTap: widget.onDelete,
                      child: const SizedBox(width: 64, height: 72, child: Icon(Icons.backspace_outlined, size: 32, color: AppColors.ink)),
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 4), trailing],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.4,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 140),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(140, 64)),
                  onPressed: widget.onSpeak,
                  icon: const Icon(Icons.volume_up, size: 28),
                  label: const FittedBox(fit: BoxFit.scaleDown, child: Text('UCAPKAN')),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Grid posisi tetap. Dibangun sekali per halaman; ketukan tidak membangun ulang grid.
class _BoardGrid extends StatelessWidget {
  const _BoardGrid({
    super.key,
    required this.cells,
    required this.gridCols,
    required this.isCorePage,
    required this.holdMs,
    required this.onSelect,
  });

  final List<WordSymbol?> cells;
  final int gridCols;
  final bool isCorePage;
  final int holdMs;
  final ValueChanged<WordSymbol> onSelect;

  /// Halaman kategori: 18 slot (6 cermin + 12 konten).
  static const categorySlots = 18;
  static const gap = 6.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        const pad = 8.0;
        final cellW = (box.maxWidth - pad * 2 - gap * (gridCols - 1)) / gridCols;
        final cellH = cellW * 0.95;
        final minSlots = isCorePage ? cells.length : categorySlots;
        final slots = ((cells.length > minSlots ? cells.length : minSlots) / gridCols).ceil() * gridCols;
        final rows = slots ~/ gridCols;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(pad),
          child: Column(
            children: [
              for (var r = 0; r < rows; r++)
                Padding(
                  // Pemisah visual cermin: jarak 8 dp setelah baris ke-2, di semua halaman supaya posisi tidak bergeser.
                  padding: EdgeInsets.only(bottom: r == 1 ? gap + 8 : gap),
                  child: Row(
                    children: [
                      for (var c = 0; c < gridCols; c++) ...[if (c > 0) const SizedBox(width: gap), _slot(r * gridCols + c, cellW, cellH)],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _slot(int i, double w, double h) {
    final s = i < cells.length ? cells[i] : null;
    // Simbol tersembunyi tetap memegang tempatnya tanpa tampil (invarian 8). Slot yang belum terisi di halaman
    // kategori diberi garis putus-putus: tempat kartu baru berikutnya (B5). Keduanya tidak bisa diketuk.
    if (s != null && s.isHidden) return SizedBox(width: w, height: h);
    if (s == null) return isCorePage ? SizedBox(width: w, height: h) : EmptySlot(width: w, height: h);
    return SymbolCell(key: ValueKey(s.wordId), symbol: s, width: w, height: h, holdMs: holdMs, onSelect: onSelect);
  }
}

/// Rel tab halaman di kiri: satu kolom tetap (ikon + label), urutannya tidak pernah berubah sehingga tangan anak
/// hafal letaknya. Tinggi tab 64 dp (≥ 10 mm). Tab [suggested] diberi garis toska tebal dan digulir ke tampilan
/// tanpa animasi (invarian 11).
class _PageRail extends StatefulWidget {
  const _PageRail({required this.pages, required this.selected, required this.onSelect, this.suggested});

  final List<BoardPage> pages;
  final int selected;
  final int? suggested;
  final ValueChanged<int> onSelect;

  static const width = 92.0;

  @override
  State<_PageRail> createState() => _PageRailState();
}

class _PageRailState extends State<_PageRail> {
  // 13 tab: semuanya dibangun (Column, bukan ListView malas) supaya tab yang disarankan selalu bisa digulir ke tampilan.
  final _keys = <int, GlobalKey>{};

  @override
  void didUpdateWidget(_PageRail old) {
    super.didUpdateWidget(old);
    final target = widget.suggested;
    if (target != null && target != old.suggested) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _keys[target]?.currentContext;
        if (ctx != null && ctx.mounted) Scrollable.ensureVisible(ctx, alignment: 0.5);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _PageRail.width,
      decoration: const BoxDecoration(
        color: AppColors.sand,
        border: Border(right: BorderSide(color: AppColors.line)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Column(
          children: [
            for (var i = 0; i < widget.pages.length; i++) ...[if (i > 0) const SizedBox(height: 6), _tab(widget.pages[i])],
          ],
        ),
      ),
    );
  }

  Widget _tab(BoardPage p) {
    final active = p.page == widget.selected;
    final suggested = !active && p.page == widget.suggested;
    return Semantics(
      key: _keys.putIfAbsent(p.page, GlobalKey.new),
      button: true,
      selected: active,
      label: p.tabLabel,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onSelect(p.page),
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          decoration: BoxDecoration(
            color: active ? AppColors.navySoft : AppColors.panel,
            border: Border.all(
              color: active
                  ? AppColors.navy
                  : suggested
                  ? AppColors.teal
                  : AppColors.line,
              width: active || suggested ? 3 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(pageIcons[p.page] ?? Icons.grid_view, color: suggested ? AppColors.teal : AppColors.navy, size: 24),
              const SizedBox(height: 4),
              Text(
                p.tabLabel,
                maxLines: 2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.15,
                  fontWeight: active || suggested ? FontWeight.w800 : FontWeight.w600,
                  color: AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dua tombol giliran di papan misi. Yang aktif bergaris navy 3 dp.
class _TurnToggle extends StatelessWidget {
  const _TurnToggle({required this.parentTurn});

  final ValueNotifier<bool> parentTurn;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: ValueListenableBuilder<bool>(
        valueListenable: parentTurn,
        builder: (context, parent, _) => Row(
          children: [
            Expanded(
              child: _TurnButton(
                label: 'Giliran pendamping',
                icon: Icons.record_voice_over,
                accent: AppColors.coral,
                active: parent,
                onTap: () => parentTurn.value = true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _TurnButton(
                label: 'Giliran anak',
                icon: Icons.child_care,
                accent: AppColors.teal,
                active: !parent,
                onTap: () => parentTurn.value = false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TurnButton extends StatelessWidget {
  const _TurnButton({required this.label, required this.icon, required this.accent, required this.active, required this.onTap});

  final String label;
  final IconData icon;
  final Color accent;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: active ? AppColors.navySoft : AppColors.panel,
            border: Border.all(color: active ? AppColors.navy : AppColors.line, width: active ? 3 : 1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: accent, size: 26),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: AppColors.ink),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
