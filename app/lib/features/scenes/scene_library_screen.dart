import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/theme.dart';
import '../../data/scene.dart';
import '../coach/companion_widgets.dart';
import 'scene_editor_screen.dart';

class SceneLibraryScreen extends StatefulWidget {
  const SceneLibraryScreen({super.key});

  @override
  State<SceneLibraryScreen> createState() => _SceneLibraryScreenState();
}

class _SceneLibraryScreenState extends State<SceneLibraryScreen> {
  late AppState _app;
  List<SceneBoard>? _scenes;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _app = AppScope.of(context);
    _load();
  }

  Future<void> _load() async {
    final rows = await _app.scenes();
    if (mounted) setState(() => _scenes = rows);
  }

  Future<void> _create() async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SceneEditorScreen()));
    await _load();
  }

  Future<void> _edit(SceneBoard scene) async {
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => SceneEditorScreen(existing: scene)));
    await _load();
  }

  @override
  Widget build(BuildContext context) => CompanionPage(
    title: 'Papan dari foto',
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        const Text(
          'Ubah foto kegiatan menjadi papan dengan beberapa area bicara. AI hanya membuat draf; kamu tetap memeriksa hasilnya.',
          style: companionBodyStyle,
        ),
        const SizedBox(height: 16),
        PrimaryButton(label: 'Buat papan dari foto', icon: Icons.add_a_photo_outlined, onPressed: _create),
        const SizedBox(height: 16),
        if (_scenes == null)
          const Center(child: CircularProgressIndicator())
        else if (_scenes!.isEmpty)
          const CompanionCard(child: Text('Belum ada papan foto. Papan biasa tetap dapat digunakan.'))
        else
          for (final scene in _scenes!) ...[
            CompanionCard(
              padding: const EdgeInsets.all(12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(backgroundColor: CompanionColors.skyTint, child: Icon(Icons.photo_outlined)),
                title: Text(scene.title, style: AppText.h3),
                subtitle: Text('${scene.payload.hotspots.length} area · siap luring', style: AppText.cap),
                onTap: () => _edit(scene),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(tooltip: 'Edit papan', icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(scene)),
                    IconButton(
                      tooltip: 'Arsipkan',
                      icon: const Icon(Icons.archive_outlined),
                      onPressed: () async {
                        await _app.archiveScene(scene.sceneId);
                        await _load();
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
      ],
    ),
  );
}
