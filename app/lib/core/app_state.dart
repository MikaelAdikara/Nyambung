import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import '../data/db/app_database.dart';
import '../data/db/dao.dart';
import '../data/db/scene_dao.dart';
import '../data/models.dart';
import '../data/personal_card.dart';
import '../data/phrase.dart';
import '../data/repo/vocab_loader.dart';
import '../data/repo/scene_repository.dart';
import '../data/scene.dart';
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
  late SummaryDao summaryDao;
  late PhraseDao phraseDao;
  late SceneDao sceneDao;
  late SceneRepository sceneRepository;
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

  /// Papan sedang terbuka. Sinkron berkala di beranda menunggu sampai papan ditutup, supaya HTTP dan
  /// kueri DB tidak berebut CPU dengan ketukan di HP berspesifikasi rendah.
  bool boardOpen = false;

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
    summaryDao = SummaryDao(_db);
    phraseDao = PhraseDao(_db);
    sceneDao = SceneDao(_db);
    sceneRepository = SceneRepository(dao: sceneDao, speech: speech, symbolById: symbolById);
    final loader = VocabLoader(symbolDao, _bundle);
    await loader.ensureLoaded();
    pages = await loader.loadPages();
    await reloadSymbols();
    _child = await childDao.first();
    if (_child != null) {
      await sceneRepository.cleanup(_child!.childId);
      final ts = await eventDao.lastParentTapTs(_child!.childId);
      _lastParentTap = ts == null ? null : DateTime.tryParse(ts);
    }
    speech.voiceSet = prefs.getString(PrefKeys.voiceSet) ?? SpeechService.voiceSets.first;
    await speech.init();
    // Klip kata inti dimuat di latar supaya ketukan pertama di papan langsung berbunyi.
    unawaited(speech.preload(cellsForPage(0)));
    _ready = true;
    _bump();
  }

  /// Muat ulang simbol dari DB (setelah sembunyikan kata atau rekaman keluarga).
  Future<void> reloadSymbols() async {
    _symbols = await symbolDao.all();
    _byId = {for (final s in _symbols) s.wordId: s};
    _bump();
  }

  /// Kosakata aktif yang boleh dipetakan ke area foto.
  List<WordSymbol> get visibleSymbols => _symbols.where((symbol) => !symbol.isHidden).toList(growable: false);

  Future<List<SceneBoard>> scenes() async {
    final child = _child;
    return child == null ? const [] : sceneRepository.list(child.childId);
  }

  Future<SceneBoard> publishScene({
    required String title,
    required String imagePath,
    required int imageWidth,
    required int imageHeight,
    required List<DraftHotspot> hotspots,
    required String source,
    String? draftId,
    SceneBoard? existing,
  }) async {
    final child = _child;
    if (child == null) throw StateError('Belum ada profil anak.');
    final result = await sceneRepository.publish(
      childId: child.childId,
      title: title,
      imagePath: imagePath,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      hotspots: hotspots,
      source: source,
      draftId: draftId,
      existing: existing,
    );
    _bump();
    return result;
  }

  Future<String> stageSceneDraftImage(String draftId, String sourcePath) => sceneRepository.stageDraftImage(draftId, sourcePath);

  Future<void> saveSceneDraft(SceneDraft draft) => sceneDao.saveDraft(draft);

  Future<SceneDraft?> latestSceneDraft({String? sceneId}) async {
    final child = _child;
    return child == null ? null : sceneDao.latestDraft(child.childId, sceneId: sceneId);
  }

  Future<void> deleteSceneDraft(String draftId) => sceneDao.deleteDraft(draftId);

  Future<void> archiveScene(String sceneId) async {
    await sceneDao.archive(sceneId, DateTime.now().toUtc().toIso8601String());
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

  /// Posisi kartu baru berikutnya di halaman kategori [page] (C3, B5): slot kosong pertama sesudah sel cermin.
  int nextCardSlot(int page) => nextFreeSlot(cellsForPage(page), firstContentSlot: mirrorSlots);

  /// Kartu personal dari foto (C3). Foto disalin ke folder aplikasi `cards/` dan tidak pernah dikirim; hanya
  /// `word_id` (berisi label) yang ikut peristiwa `PRS`. Kartu masuk ke slot kosong berikutnya di [page];
  /// sel lain tidak bergeser (invarian 8).
  Future<WordSymbol> addPersonalCard({required String label, required int page, required String photoPath}) async {
    final display = normalizePersonalLabel(label);
    if (display.isEmpty || page == 0) {
      throw ArgumentError('label kosong atau halaman kata inti');
    }
    final wordId = personalWordId(display);
    final dir = Directory('${(await getApplicationDocumentsDirectory()).path}${Platform.pathSeparator}cards');
    await dir.create(recursive: true);
    final dest = '${dir.path}${Platform.pathSeparator}$wordId.jpg';
    await File(photoPath).copy(dest);
    final card = WordSymbol(
      wordId: wordId,
      labelDisplay: display,
      labelSpeech: display.toLowerCase(),
      pos: 'benda',
      category: 'personal',
      page: page,
      positionIndex: nextCardSlot(page),
      symbolPath: dest,
      isCustom: true,
    );
    try {
      await symbolDao.insertCustom(card);
    } catch (_) {
      try {
        await File(dest).delete();
      } catch (_) {}
      rethrow;
    }
    await reloadSymbols();
    return card;
  }

  /// Halaman bawaan kartu frasa: TANYA & SAPA bila ada, selain itu halaman kategori pertama.
  int? get defaultPhrasePage {
    final pages = this.pages.where((p) => p.page != 0).toList();
    if (pages.isEmpty) return null;
    return pages.firstWhere((p) => p.tabLabel.startsWith('TANYA'), orElse: () => pages.first).page;
  }

  /// Kartu frasa di papan, atau null bila frasa itu belum ditaruh.
  WordSymbol? phraseCard(Phrase p) => _byId[p.wordId];

  /// Taruh frasa (yang klipnya sudah terunduh) sebagai kartu di slot kosong berikutnya di [page]. Kartu yang
  /// sudah ada tidak digandakan. Sel lain tidak bergeser (invarian 8).
  Future<WordSymbol> addPhraseCard(Phrase p, {int? page}) async {
    final existing = phraseCard(p);
    if (existing != null) return existing;
    final target = page ?? defaultPhrasePage;
    if (target == null || target == 0) {
      throw ArgumentError('halaman kategori tidak ada');
    }
    final card = WordSymbol(
      wordId: p.wordId,
      labelDisplay: p.text.toUpperCase(),
      labelSpeech: p.text,
      pos: 'sosial',
      category: 'frasa',
      page: target,
      positionIndex: nextCardSlot(target),
      symbolPath: '',
      audioPath: p.audioPath,
      isCustom: true,
    );
    await symbolDao.insertCustom(card);
    await reloadSymbols();
    return card;
  }

  /// Jawaban keluarga atas frasa dari terapis: status lokal + peristiwa `TGT` (context = phrase_id), sama seperti
  /// usulan kata. Diterima → kartu ditaruh di papan. Menolak tidak butuh alasan (invarian 19).
  Future<void> answerPhrase(Phrase p, bool accepted, {int? page}) async {
    final c = _child;
    if (c == null) return;
    if (accepted) await addPhraseCard(p, page: page);
    final status = accepted ? PhraseStatus.diterima : PhraseStatus.ditolak;
    await phraseDao.setStatus(p.phraseId, status);
    await _append(
      content: status,
      method: Method.tgt,
      actor: Actor.pendamping,
      level: PromptLevel.terpancing,
      context: p.phraseId,
      at: DateTime.now(),
    );
  }

  /// Pindahkan kata di halaman kategori [page] dari posisi [from] ke [to] (bertukar bila terisi). Halaman inti dan
  /// enam sel cermin tidak bisa dipindah: tangan anak menghafal letaknya (invarian 8, 03 §4).
  Future<void> moveSymbol(int page, int from, int to) async {
    if (page == 0 || from < mirrorSlots || to < mirrorSlots) {
      throw ArgumentError('halaman inti dan sel cermin terkunci');
    }
    await symbolDao.moveWithinPage(page, from, to);
    await reloadSymbols();
  }

  /// Hapus kartu foto atau kartu frasa beserta fotonya. Rekaman keluarga untuk kartu itu ikut dihapus.
  Future<void> deleteCard(WordSymbol s) async {
    if (!s.isCustom) {
      throw ArgumentError('kata bawaan hanya bisa disembunyikan');
    }
    await symbolDao.deleteCustom(s.wordId);
    for (final path in [if (s.symbolPath.startsWith('/')) s.symbolPath, ?s.familyAudio]) {
      try {
        final f = File(path);
        if (f.existsSync()) await f.delete();
      } catch (e, st) {
        ErrorLog.record('hapusKartu', e, st);
      }
    }
    await reloadSymbols();
  }

  /// Tujuan yang dipilih di A6; beranda membukanya sekali setelah pemasangan, lalu mengosongkannya.
  AfterOnboarding? afterOnboarding;

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

  /// Kunci mode anak (C6): papan anak memakai screen pinning Android. Bawaan aktif.
  bool get childLock => prefs.getBool(PrefKeys.childLock) ?? true;

  Future<void> setChildLock(bool on) async {
    await prefs.setBool(PrefKeys.childLock, on);
    _bump();
  }

  /// "Tahan untuk memilih" (C6): 0 = ketuk biasa.
  int get holdMs => prefs.getInt(PrefKeys.holdMs) ?? 0;

  Future<void> setHoldMs(int ms) async {
    await prefs.setInt(PrefKeys.holdMs, ms);
    _bump();
  }

  /// Set suara audio bundel papan: `cowo` atau `cewe`.
  String get voiceSet => speech.voiceSet;

  Future<void> setVoiceSet(String set) async {
    if (!SpeechService.voiceSets.contains(set)) return;
    speech.voiceSet = set;
    unawaited(speech.preload(cellsForPage(0)));
    await prefs.setString(PrefKeys.voiceSet, set);
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

/// Tombol di A6: buka misi hari ini atau lihat papan dulu.
enum AfterOnboarding { mission, board }

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
