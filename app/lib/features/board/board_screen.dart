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
  1: Icons.star_half,
  2: Icons.star_outline,
  3: Icons.waving_hand,
  4: Icons.directions_run,
  5: Icons.sports_soccer,
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
  final _utterance = ValueNotifier<List<WordSymbol>>(const []);

  /// Mode misi dimulai dengan giliran pendamping: contoh diberikan dulu di depan anak.
  final _parentTurn = ValueNotifier<bool>(true);
  late AppState _app;
  bool _started = false;
  int _page = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    if (!_started) {
      _started = true;
      _app.startBoardSession();
      if (widget.childMode) LockTask.start();
    }
  }

  @override
  void dispose() {
    _utterance.dispose();
    _parentTurn.dispose();
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
    _utterance.value = [..._utterance.value, s];
    _app.speech.speakWord(s, byParent: _byParent);
    _log(s.wordId, _page == 0 ? Method.sel : Method.kat);
  }

  void _onDelete() {
    final words = _utterance.value;
    if (words.isEmpty) return;
    _utterance.value = words.sublist(0, words.length - 1);
    _log(words.last.wordId, Method.hap);
  }

  void _onSpeak() {
    final words = _utterance.value;
    if (words.isEmpty) return;
    _app.speech.speakSentence(words, byParent: _byParent);
    _log(words.map((w) => w.wordId).join(' '), Method.ucp);
  }

  Future<void> _exitChildMode() async {
    await LockTask.stop();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final body = SafeArea(
      child: Column(
        children: [
          _SpeechBar(
            utterance: _utterance,
            onDelete: _onDelete,
            onSpeak: _onSpeak,
            leading: widget.childMode
                ? null
                : IconButton(tooltip: 'Kembali', icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.of(context).maybePop()),
            trailing: widget.childMode ? HoldButton(onComplete: _exitChildMode) : null,
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
          _PageTabs(pages: _app.pages, selected: _page, onSelect: (p) => setState(() => _page = p)),
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
      child: Scaffold(backgroundColor: AppColors.bg, body: body),
    );
  }
}

/// Bilah ujaran (tinggi 88 dp, latar panel) + HAPUS + UCAPKAN. Hanya bagian ini yang dibangun ulang saat ketukan.
class _SpeechBar extends StatelessWidget {
  const _SpeechBar({required this.utterance, required this.onDelete, required this.onSpeak, this.leading, this.trailing});

  final ValueNotifier<List<WordSymbol>> utterance;
  final VoidCallback onDelete;
  final VoidCallback onSpeak;
  final Widget? leading;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
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
                  child: ValueListenableBuilder<List<WordSymbol>>(
                    valueListenable: utterance,
                    builder: (context, words, _) => ListView.separated(
                      scrollDirection: Axis.horizontal,
                      reverse: true,
                      itemCount: words.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 4),
                      itemBuilder: (_, i) => SymbolFace(symbol: words[words.length - 1 - i], width: 72, height: 84, compact: true),
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
                      onTap: onDelete,
                      child: const SizedBox(width: 64, height: 72, child: Icon(Icons.backspace_outlined, size: 32, color: AppColors.ink)),
                    ),
                  ),
                ),
                if (trailing != null) ...[const SizedBox(width: 4), trailing!],
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
                  onPressed: onSpeak,
                  icon: const Icon(Icons.volume_up),
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
    // Slot kosong atau simbol tersembunyi tetap memegang tempatnya (invarian 8).
    if (s == null || s.isHidden) return SizedBox(width: w, height: h);
    return SymbolCell(key: ValueKey(s.wordId), symbol: s, width: w, height: h, holdMs: holdMs, onSelect: onSelect);
  }
}

/// Tab halaman bergulir horizontal, ikon + label, tinggi 64 dp.
class _PageTabs extends StatelessWidget {
  const _PageTabs({required this.pages, required this.selected, required this.onSelect});

  final List<BoardPage> pages;
  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      color: AppColors.sand,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: pages.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final p = pages[i];
          final active = p.page == selected;
          return Semantics(
            button: true,
            selected: active,
            label: p.tabLabel,
            excludeSemantics: true,
            child: GestureDetector(
              onTap: () => onSelect(p.page),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: active ? AppColors.navySoft : AppColors.panel,
                  border: Border.all(color: active ? AppColors.navy : AppColors.line, width: active ? 3 : 1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(pageIcons[p.page] ?? Icons.grid_view, color: AppColors.navy, size: 22),
                    const SizedBox(width: 6),
                    Text(
                      p.tabLabel,
                      style: TextStyle(fontSize: 14, fontWeight: active ? FontWeight.w800 : FontWeight.w600, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
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
