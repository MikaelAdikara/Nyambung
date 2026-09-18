import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/app_state.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../data/scene.dart';
import '../../data/sync/scene_ai_service.dart';
import '../coach/companion_widgets.dart';
import 'scene_geometry.dart';
import '../settings/link_required.dart';

const _uuid = Uuid();

class SceneEditorScreen extends StatefulWidget {
  const SceneEditorScreen({super.key, this.existing});

  final SceneBoard? existing;

  @override
  State<SceneEditorScreen> createState() => _SceneEditorScreenState();
}

class _SceneEditorScreenState extends State<SceneEditorScreen> {
  final _picker = ImagePicker();
  final _title = TextEditingController();
  late AppState _app;
  String? _imagePath;
  Size? _imageSize;
  List<DraftHotspot> _hotspots = const [];
  bool _busy = false;
  String? _error;
  String _source = 'manual';
  String _draftId = _uuid.v4();
  Timer? _draftTimer;
  bool _dependenciesReady = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _title.text = existing.title;
      _imagePath = existing.imagePath;
      _imageSize = Size(existing.imageWidth.toDouble(), existing.imageHeight.toDouble());
      _hotspots = [for (final item in existing.payload.hotspots) DraftHotspot(id: item.id, box: item.box, wordId: item.wordId)];
      _source = existing.source;
    }
    _title.addListener(_scheduleDraft);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    if (!_dependenciesReady) {
      _dependenciesReady = true;
      _restoreLatestDraft();
    }
  }

  @override
  void dispose() {
    _draftTimer?.cancel();
    _title.removeListener(_scheduleDraft);
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    await _persistDraft();
    final file = await _picker.pickImage(source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 88);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    if (!mounted) return;
    final storedPath = await _app.stageSceneDraftImage(_draftId, file.path);
    setState(() {
      _imagePath = storedPath;
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      _hotspots = const [];
      _source = 'manual';
      _error = null;
    });
    _scheduleDraft();
  }

  Future<Size> _decodeSize(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return Size(frame.image.width.toDouble(), frame.image.height.toDouble());
  }

  Future<void> _restoreLatestDraft() async {
    final loaded = await _app.latestSceneDraft(sceneId: widget.existing?.sceneId);
    if (loaded == null || !mounted) {
      return;
    }
    var draft = loaded;
    if (draft.imagePath == null || !File(draft.imagePath!).existsSync()) {
      final lost = await _picker.retrieveLostData();
      final recovered = lost.file;
      if (recovered == null) {
        await _app.deleteSceneDraft(draft.draftId);
        return;
      }
      final storedPath = await _app.stageSceneDraftImage(draft.draftId, recovered.path);
      draft = SceneDraft(
        draftId: draft.draftId,
        childId: draft.childId,
        sceneId: draft.sceneId,
        title: draft.title,
        imagePath: storedPath,
        payload: draft.payload,
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      );
      await _app.saveSceneDraft(draft);
    }
    if (!mounted) return;
    final restore = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lanjutkan draf papan foto?'),
        content: Text(draft.title.trim().isEmpty ? 'Ada draf yang belum selesai.' : 'Lanjutkan “${draft.title}”?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Buang draf')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Lanjutkan')),
        ],
      ),
    );
    if (!mounted) return;
    if (restore != true) {
      await _app.deleteSceneDraft(draft.draftId);
      return;
    }
    final size = await _decodeSize(draft.imagePath!);
    if (!mounted) return;
    setState(() {
      _draftId = draft.draftId;
      _title.text = draft.title;
      _imagePath = draft.imagePath;
      _imageSize = size;
      _hotspots = draft.payload.hotspots;
      _source = draft.payload.source;
      _restored = true;
    });
  }

  void _scheduleDraft() {
    if (!_dependenciesReady) return;
    _draftTimer?.cancel();
    _draftTimer = Timer(const Duration(milliseconds: 250), _persistDraft);
  }

  Future<void> _persistDraft() async {
    final child = _app.child;
    if (child == null) return;
    await _app.saveSceneDraft(
      SceneDraft(
        draftId: _draftId,
        childId: child.childId,
        sceneId: widget.existing?.sceneId,
        title: _title.text,
        imagePath: _imagePath,
        payload: DraftPayload(hotspots: _hotspots, source: _source),
        updatedAt: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  void _setHotspots(List<DraftHotspot> hotspots) {
    setState(() => _hotspots = hotspots);
    _scheduleDraft();
  }

  void _addArea() {
    if (_hotspots.length >= 6) return;
    final offset = 0.08 * _hotspots.length;
    _setHotspots([
      ..._hotspots,
      DraftHotspot(
        id: _uuid.v4(),
        box: SceneBox.checked(x: 0.08 + offset, y: 0.12 + offset, width: 0.3, height: 0.24),
      ),
    ]);
  }

  Future<void> _askAi() async {
    final imagePath = _imagePath;
    final child = _app.child;
    final token = _app.prefs.getString(PrefKeys.deviceToken);
    if (imagePath == null) return;
    if (child == null || token == null) {
      setState(() => _error = 'Bantuan AI butuh kode undangan dari terapis. Atur sendiri tetap tersedia.');
      await showLinkRequiredDialog(context, feature: 'Bantuan AI papan foto');
      return;
    }
    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kirim foto untuk dianalisis?'),
        content: const Text(
          'Foto ini akan dikirim ke server Nyambung dan layanan AI (OpenAI atau Google, sesuai setelan server) untuk membuat usulan area bicara. Nama anak, riwayat ketukan, dan rekaman suara tidak ikut dikirim. Kamu bisa mengatur area sendiri tanpa mengirim foto.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Atur sendiri')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Kirim foto')),
        ],
      ),
    );
    if (consent != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = SceneAiService(baseUrl: _baseUrl, token: token);
      final result = await service.analyze(
        childId: child.childId,
        jpegBytes: await File(imagePath).readAsBytes(),
        allowedSymbols: [for (final symbol in _app.visibleSymbols) (symbol.wordId, symbol.labelDisplay)],
      );
      if (mounted) {
        setState(() {
          _hotspots = result.hotspots;
          _source = 'ai';
          _imageSize = Size(result.width.toDouble(), result.height.toDouble());
          if (_hotspots.isEmpty) {
            _error = 'AI belum menemukan area yang cocok. Tambahkan area sendiri.';
          }
        });
        _scheduleDraft();
      }
    } on SceneAiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String get _baseUrl => ServerConfig.resolve(_app.prefs.getString(PrefKeys.serverUrl));

  Future<void> _save() async {
    final path = _imagePath;
    final size = _imageSize;
    if (path == null || size == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _app.publishScene(
        title: _title.text,
        imagePath: path,
        imageWidth: size.width.round(),
        imageHeight: size.height.round(),
        hotspots: _hotspots,
        source: _source,
        draftId: _draftId,
        existing: widget.existing,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => CompanionPage(
    title: widget.existing == null ? 'Buat papan foto' : 'Edit papan foto',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        TextField(
          controller: _title,
          maxLength: 40,
          decoration: const InputDecoration(labelText: 'Judul kegiatan', hintText: 'Mis. Main mobil'),
        ),
        if (_imagePath == null) ...[
          PrimaryButton(label: 'Ambil foto', icon: Icons.photo_camera_outlined, onPressed: () => _pick(ImageSource.camera)),
          const SizedBox(height: 10),
          EqualOutlineButton(label: 'Pilih dari galeri', onPressed: () => _pick(ImageSource.gallery)),
        ] else ...[
          _EditorCanvas(imagePath: _imagePath!, imageSize: _imageSize!, hotspots: _hotspots, onChanged: _setHotspots),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy || _hotspots.length >= 6 ? null : _addArea,
                icon: const Icon(Icons.add_box_outlined),
                label: const Text('Tambah area'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _askAi,
                icon: const Icon(Icons.auto_awesome),
                label: Text(_busy ? 'Menganalisis…' : 'Bantu pilih dengan AI'),
              ),
              TextButton.icon(
                onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                icon: const Icon(Icons.image_outlined),
                label: const Text('Ganti foto'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < _hotspots.length; i++) _mappingRow(i),
          const SizedBox(height: 12),
          if (_restored)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Draf dipulihkan.', style: AppText.cap),
            ),
          PrimaryButton(label: _busy ? 'Menyimpan…' : 'Simpan untuk dipakai luring', onPressed: _busy ? null : _save),
        ],
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              _error!,
              style: const TextStyle(color: CompanionColors.caution, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    ),
  );

  Widget _mappingRow(int index) {
    final hotspot = _hotspots[index];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: hotspot.wordId != null && _app.visibleSymbols.any((s) => s.wordId == hotspot.wordId) ? hotspot.wordId : null,
                decoration: InputDecoration(
                  labelText: hotspot.observedLabel == null ? 'Area ${index + 1}' : 'AI melihat: ${hotspot.observedLabel}',
                ),
                items: [for (final symbol in _app.visibleSymbols) DropdownMenuItem(value: symbol.wordId, child: Text(symbol.labelDisplay))],
                onChanged: (word) {
                  final next = [..._hotspots];
                  next[index] = hotspot.copyWith(wordId: word, clearWord: word == null);
                  _setHotspots(next);
                },
              ),
            ),
            IconButton(
              tooltip: 'Hapus area',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _setHotspots([..._hotspots]..removeAt(index)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorCanvas extends StatelessWidget {
  const _EditorCanvas({required this.imagePath, required this.imageSize, required this.hotspots, required this.onChanged});
  final String imagePath;
  final Size imageSize;
  final List<DraftHotspot> hotspots;
  final ValueChanged<List<DraftHotspot>> onChanged;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: 4 / 3,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        final imageRect = containedImageRect(imageSize, viewport);
        return Stack(
          children: [
            Positioned.fromRect(
              rect: imageRect,
              child: Image.file(File(imagePath), fit: BoxFit.fill),
            ),
            for (var i = 0; i < hotspots.length; i++)
              Positioned.fromRect(
                rect: sceneBoxToRect(hotspots[i].box, imageRect),
                child: _EagerPan(
                  capture: () => hotspots[i],
                  onDrag: (h, total) {
                    final x = (h.box.x + total.dx / imageRect.width).clamp(0.0, 1 - h.box.width);
                    final y = (h.box.y + total.dy / imageRect.height).clamp(0.0, 1 - h.box.height);
                    final next = [...hotspots];
                    next[i] = h.copyWith(
                      box: SceneBox.checked(x: x, y: y, width: h.box.width, height: h.box.height),
                    );
                    onChanged(next);
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: CompanionColors.tealTint.withValues(alpha: 0.35),
                          border: Border.all(color: CompanionColors.tealDeep, width: 3),
                        ),
                        alignment: Alignment.center,
                        child: Text('${i + 1}', style: AppText.h2),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: _EagerPan(
                          capture: () => hotspots[i],
                          onDrag: (h, total) {
                            final minWidth = (48 / imageRect.width).clamp(0.08, 0.4);
                            final minHeight = (48 / imageRect.height).clamp(0.08, 0.4);
                            final width = (h.box.width + total.dx / imageRect.width).clamp(minWidth, 1 - h.box.x);
                            final height = (h.box.height + total.dy / imageRect.height).clamp(minHeight, 1 - h.box.y);
                            final next = [...hotspots];
                            next[i] = h.copyWith(
                              box: SceneBox.checked(x: h.box.x, y: h.box.y, width: width, height: height),
                            );
                            onChanged(next);
                          },
                          child: const SizedBox(
                            width: 38,
                            height: 38,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: CompanionColors.tealDeep,
                                borderRadius: BorderRadius.only(topLeft: Radius.circular(12)),
                              ),
                              child: Icon(Icons.open_in_full_rounded, size: 20, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    ),
  );
}

/// Geser yang langsung mengklaim sentuhan. Editor berada di dalam ListView; tanpa ini seretan vertikal di atas area
/// direbut gulir halaman. [onDrag] menerima keadaan saat jari turun plus total geseran, jadi beberapa event dalam satu
/// frame tidak saling menimpa dengan nilai yang belum dibangun ulang.
class _EagerPan extends StatefulWidget {
  const _EagerPan({required this.capture, required this.onDrag, required this.child});
  final DraftHotspot Function() capture;
  final void Function(DraftHotspot start, Offset total) onDrag;
  final Widget child;

  @override
  State<_EagerPan> createState() => _EagerPanState();
}

class _EagerPanState extends State<_EagerPan> {
  DraftHotspot? _start;
  Offset _total = Offset.zero;

  @override
  Widget build(BuildContext context) => RawGestureDetector(
    behavior: HitTestBehavior.opaque,
    gestures: {
      _EagerPanRecognizer: GestureRecognizerFactoryWithHandlers<_EagerPanRecognizer>(
        _EagerPanRecognizer.new,
        (r) => r
          ..onDown = (_) {
            _start = widget.capture();
            _total = Offset.zero;
          }
          ..onUpdate = (details) {
            final start = _start;
            if (start == null) return;
            _total += details.delta;
            widget.onDrag(start, _total);
          }
          ..onEnd = ((_) {
            _start = null;
          })
          ..onCancel = () {
            _start = null;
          },
      ),
    },
    child: widget.child,
  );
}

class _EagerPanRecognizer extends PanGestureRecognizer {
  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }
}
