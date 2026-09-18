import 'package:flutter/material.dart';

import 'companion_widgets.dart';
import 'companion_controller.dart';

/// Temporary board used only until lane 1 publishes `j1-papan`.
class FakeBoardScreen extends StatefulWidget {
  const FakeBoardScreen({super.key, required this.state, this.missionContext, this.allowTurnToggle = false});

  final CompanionController state;
  final String? missionContext;
  final bool allowTurnToggle;

  @override
  State<FakeBoardScreen> createState() => _FakeBoardScreenState();
}

class _FakeBoardScreenState extends State<FakeBoardScreen> {
  bool _parentTurn = true;

  @override
  Widget build(BuildContext context) {
    final words = [widget.state.mission.targetWord, 'tidak', 'bantu'];
    return Scaffold(
      backgroundColor: CompanionColors.bg,
      appBar: AppBar(
        backgroundColor: CompanionColors.bg,
        title: const Text('Papan tiruan'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kembali'))],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (widget.allowTurnToggle) ...[
              Row(
                children: [
                  Expanded(
                    child: _TurnButton(
                      label: 'Giliran pendamping',
                      selected: _parentTurn,
                      onPressed: () => setState(() => _parentTurn = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TurnButton(label: 'Giliran anak', selected: !_parentTurn, onPressed: () => setState(() => _parentTurn = false)),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
            Expanded(
              child: GridView.count(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  for (final word in words)
                    Semantics(
                      button: true,
                      label: word,
                      child: FilledButton(
                        onPressed: () => widget.state.logTap(
                          content: word,
                          method: 'SEL',
                          byParent: widget.allowTurnToggle ? _parentTurn : false,
                          context: widget.missionContext,
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: CompanionColors.navySoft,
                          foregroundColor: CompanionColors.ink,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: FittedBox(
                          child: Text(word.toUpperCase(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Text('Layar sementara sampai papan jalur 1 tersedia.', style: companionMutedStyle),
          ],
        ),
      ),
    );
  }
}

class _TurnButton extends StatelessWidget {
  const _TurnButton({required this.label, required this.selected, required this.onPressed});

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 64,
    child: OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: selected ? CompanionColors.navy : CompanionColors.line, width: selected ? 3 : 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: Text(label, textAlign: TextAlign.center),
    ),
  );
}
