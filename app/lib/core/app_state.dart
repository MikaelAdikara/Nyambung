import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/db/app_database.dart';
import '../data/db/dao.dart';
import '../data/models.dart';
import '../data/repo/vocab_loader.dart';
import 'constants.dart';
import 'error_log.dart';
import 'speech_service.dart';
import 'time.dart';

const _uuid = Uuid();

/// Satu-satunya keadaan aplikasi. Diakses lewat [AppScope.of].
///
/// API publik yang dijanjikan ke jalur 2 (tanda tangan tidak berubah): [child], [dataVersion],
/// [createChild], [logTap], [logMission], [logTargetAnswer], [symbolsForPage], [speech], [eventDao],
/// [missionDao], [targetDao], [linkDao]. Kebutuhan baru diminta ke jalur 1 lewat status.
///
/// Pakai `ListenableBuilder(listenable: app, ...)` untuk bagian layar yang perlu ikut berubah.
/// [AppScope] sendiri **tidak** membangun ulang dependennya, supaya ketukan papan tidak
/// membangun ulang grid.
class AppState extends ChangeNotifier {
  AppState({SpeechService? speech, AssetBundle? bundle}) : speech = speech ?? SpeechService(), _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;

  /// Layanan suara dua lapis.
  final SpeechService speech;

  late Database _db;
  late ChildDao childDao;
  late SymbolDao symbolDao;
  late EventDao eventDao;
  late MissionDao missionDao;
  late TargetDao targetDao;
  late LinkDao linkDao;
  late SharedPreferences prefs;

  bool _ready = false;
  bool get isReady => _ready;

  Child? _child;

  /// Anak di perangkat ini, atau `null` sebelum pemasangan (A1–A6).
  Child? get child => _child;

  int _dataVersion = 0;

  /// Naik setiap kali data berubah (ketukan, misi, target, anak). Kunci untuk `CachedFuture`.
  int get dataVersion => _dataVersion;

  List<WordSymbol> _symbols = const [];
  Map<String, WordSymbol> _byId = const {};

  /// Halaman papan dari `pages.csv`, urut nomor halaman.
  List<BoardPage> pages = const [];

  String _sessionId = _uuid.v4();

  /// `session_id` papan yang sedang terbuka.
  String get sessionId => _sessionId;

  DateTime? _lastParentTap;

  /// Buka DB → muat CSV bila perlu → muat anak dan simbol → siapkan suara. Aman dipanggil ulang.
  Future<void> bootstrap() async {
    _ready = false;
    prefs = await SharedPreferences.getInstance();
    _db = await AppDatabase.open();
    childDao = ChildDao(_db);
    symbolDao = SymbolDao(_db);
    eventDao = EventDao(_db);
    missionDao = MissionDao(_db);
    targetDao = TargetDao(_db);
    linkDao = LinkDao(_db);
    final loader = VocabLoader(symbolDao, _bundle);
    await loader.ensureLoaded();
    pages = await loader.loadPages();
    await reloadSymbols();
    _child = await childDao.first();
    if (_child != null) {
      final ts = await eventDao.lastParentTapTs(_child!.childId);
      _lastParentTap = ts == null ? null : DateTime.tryParse(ts);
    }
    await speech.init();
    _ready = true;
    _bump();
  }

  /// Muat ulang simbol dari DB (setelah sembunyikan kata atau rekaman keluarga).
  Future<void> reloadSymbols() async {
    _symbols = await symbolDao.all();
    _byId = {for (final s in _symbols) s.wordId: s};
    _bump();
  }

  void _bump() {
    _dataVersion++;
    notifyListeners();
  }

  /// Beri tahu pendengar bahwa data berubah di luar metode `AppState` (mis. setelah sinkron).
  void markDataChanged() => _bump();

  /// Simbol milik satu halaman, urut `position_index`, termasuk yang tersembunyi (`isHidden`).
  /// Untuk halaman kategori, **tidak** termasuk sel cermin 0–5; pakai [cellsForPage] untuk menggambar papan.
  List<WordSymbol> symbolsForPage(int page) => _symbols.where((s) => s.page == page).toList();

  /// Slot papan per posisi: indeks = `position_index`, `null` = slot kosong.
  /// Halaman kategori: slot 0–5 = halaman 0 posisi 0–5 (cermin **berdasarkan posisi**, bukan nama kata).
  List<WordSymbol?> cellsForPage(int page) => buildCells(_symbols, page);

  WordSymbol? symbolById(String wordId) => _byId[wordId];

  /// Semua simbol (untuk D3-seperti daftar atau C2).
  List<WordSymbol> get allSymbols => List.unmodifiable(_symbols);

  /// Pemasangan (A2/A3). `grid_cols` ditetapkan di sini dan tidak punya pengubah.
  Future<Child> createChild({required String nickname, int? ageYears, required String routine, int gridCols = 3}) async {
    final c = Child(
      childId: _uuid.v4(),
      nickname: nickname.trim(),
      ageYears: ageYears,
      gridCols: gridCols,
      routine: routine,
      createdAt: nowIso(),
    );
    await childDao.insert(c);
    _child = c;
    _bump();
    return c;
  }

  Future<void> updateRoutine(String routine) async {
    final c = _child;
    if (c == null) return;
    await childDao.updateRoutine(c.childId, routine);
    _child = await childDao.first();
    _bump();
  }

  /// Mulai sesi papan baru (`session_id` baru setiap papan dibuka, kontrak §3). Dipanggil `BoardScreen`.
  String startBoardSession() => _sessionId = _uuid.v4();

  /// Catat satu peristiwa papan (SEL/KAT/PRS/HAP/UCP). `context` bawaan = rutinitas anak;
  /// di papan misi isi dengan `mission_id`. `prompt_level` ditentukan di sini (kontrak §3).
  Future<void> logTap({required String content, required String method, required bool byParent, String? context}) async {
    final c = _child;
    if (c == null) return;
    final now = DateTime.now();
    final isTap = Method.taps.contains(method);
    final String level;
    if (byParent) {
      level = PromptLevel.terpancing;
    } else {
      final last = _lastParentTap;
      level = last != null && now.difference(last) <= Limits.promptWindow ? PromptLevel.terpancing : PromptLevel.spontan;
    }
    if (byParent && isTap) _lastParentTap = now;
    await _append(
      content: content,
      method: method,
      actor: byParent ? Actor.pendamping : Actor.anak,
      level: level,
      context: context ?? c.routine,
      at: now,
    );
  }

  /// Konfirmasi misi harian (B6): tulis `mission_log` (dengan `reps_counted` dihitung dari ketukan)
  /// dan satu peristiwa `MIS`. Menekan lagi di hari yang sama memperbarui log dan menambah peristiwa baru.
  Future<void> logMission(String missionId, String status) async {
    final c = _child;
    if (c == null) return;
    final now = DateTime.now();
    final date = localDate(now);
    final reps = await missionReps(missionId, date);
    await missionDao.upsertLog(missionId, date, status, reps);
    await _append(content: status, method: Method.mis, actor: Actor.pendamping, level: PromptLevel.terpancing, context: missionId, at: now);
  }

  /// Penghitung misi (02 §5): ketukan pendamping hari itu pada kata target, di papan misi itu.
  /// Butuh baris `mission` (simpan dulu lewat `missionDao.upsert`); tanpa itu hasilnya 0.
  Future<int> missionReps(String missionId, String date) async {
    final c = _child;
    final m = await missionDao.byId(missionId);
    if (c == null || m == null) return 0;
    return eventDao.countOnDate(
      c.childId,
      date,
      actor: Actor.pendamping,
      methods: const {Method.sel, Method.kat},
      content: m.targetWord,
      context: missionId,
    );
  }

  /// Jawaban keluarga atas usulan terapis (C5): status lokal + peristiwa `TGT` lewat outbox yang sama.
  Future<void> logTargetAnswer(String targetId, bool accepted) async {
    final c = _child;
    if (c == null) return;
    final status = accepted ? TargetStatus.diterima : TargetStatus.ditolak;
    await targetDao.setStatus(targetId, status);
    await _append(
      content: status,
      method: Method.tgt,
      actor: Actor.pendamping,
      level: PromptLevel.terpancing,
      context: targetId,
      at: DateTime.now(),
    );
  }

  Future<void> _append({
    required String content,
    required String method,
    required String actor,
    required String level,
    required String? context,
    required DateTime at,
  }) async {
    final e = UtteranceEvent(
      eventId: _uuid.v4(),
      childId: _child!.childId,
      tsDevice: isoWithOffset(at),
      content: content,
      method: method,
      actor: actor,
      promptLevel: level,
      context: context,
      sessionId: _sessionId,
    );
    try {
      await eventDao.append(e);
    } catch (err, st) {
      ErrorLog.record('logEvent', err, st);
      rethrow;
    }
    _bump();
  }

  /// "Tahan untuk memilih" (C6): 0 = ketuk biasa.
  int get holdMs => prefs.getInt(PrefKeys.holdMs) ?? 0;

  Future<void> setHoldMs(int ms) async {
    await prefs.setInt(PrefKeys.holdMs, ms);
    _bump();
  }

  /// "Hapus semua data" (C6): hapus berkas basis data, preferensi, dan semua berkas buatan aplikasi
  /// (rekaman suara keluarga, ekspor sementara), lalu bootstrap ulang.
  Future<void> deleteAllData() async {
    await speech.stop();
    await AppDatabase.deleteFile(_db);
    await prefs.clear();
    for (final dir in [await getApplicationDocumentsDirectory(), await getTemporaryDirectory()]) {
      try {
        for (final entry in dir.listSync()) {
          await entry.delete(recursive: true);
        }
      } catch (e, st) {
        ErrorLog.record('hapusData', e, st);
      }
    }
    _child = null;
    _lastParentTap = null;
    await bootstrap();
  }
}

/// Slot papan (lihat [AppState.cellsForPage]). Terpisah supaya bisa dites tanpa sqflite.
List<WordSymbol?> buildCells(List<WordSymbol> symbols, int page) {
  final own = symbols.where((s) => s.page == page).toList();
  final mirror = page == 0 ? const <WordSymbol>[] : symbols.where((s) => s.page == 0 && s.positionIndex < mirrorSlots).toList();
  final all = [...mirror, ...own];
  if (all.isEmpty) return const [];
  final maxPos = all.map((s) => s.positionIndex).reduce((a, b) => a > b ? a : b);
  final cells = List<WordSymbol?>.filled(maxPos + 1, null);
  for (final s in all) {
    cells[s.positionIndex] = s;
  }
  return cells;
}

/// Jumlah sel cermin di halaman kategori (baris 1–2 halaman 0).
const mirrorSlots = 6;

/// Akses [AppState]. Dipasang **di atas** `MaterialApp` supaya setiap rute yang dibuka lewat
/// `Navigator.push` menemukannya. Tidak membangun ulang dependen saat data berubah.
class AppScope extends InheritedWidget {
  const AppScope({super.key, required this.state, required super.child});

  final AppState state;

  /// Hanya di `build` atau `didChangeDependencies`, tidak pernah di `initState`.
  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(
      scope != null,
      'AppScope tidak ditemukan. AppScope harus dipasang DI ATAS MaterialApp (di main.dart), '
      'bukan di dalam home:, supaya rute Navigator.push juga menemukannya.',
    );
    return scope!.state;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) => oldWidget.state != state;
}
