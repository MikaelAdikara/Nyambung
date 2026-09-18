import 'dart:convert';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/motion.dart';
import '../../core/theme.dart';
import '../coach/companion_widgets.dart';

/// PIN orang tua (4 angka): pagar supaya anak yang membuka aplikasi sendiri tidak masuk ke layar orang tua. Bukan
/// pengaman data. PIN disimpan sebagai SHA-256 bergaram di perangkat, tidak pernah dikirim ke server.
abstract final class ParentPin {
  static const length = 4;
  static const _hashKey = 'parent_pin_hash';
  static const _saltKey = 'parent_pin_salt';

  /// Salah berturut-turut sebelum keypad diganti dua pilihan (coba lagi / kembali ke papan anak).
  static const attemptsPerRound = 3;

  static bool isSet(SharedPreferences prefs) => prefs.getString(_hashKey) != null;

  static String _hash(String salt, String pin) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  static Future<void> set(SharedPreferences prefs, String pin) async {
    final r = math.Random.secure();
    final salt = base64Url.encode(List<int>.generate(16, (_) => r.nextInt(256)));
    await prefs.setString(_saltKey, salt);
    await prefs.setString(_hashKey, _hash(salt, pin));
  }

  static bool check(SharedPreferences prefs, String pin) {
    final salt = prefs.getString(_saltKey);
    final hash = prefs.getString(_hashKey);
    return salt != null && hash != null && _hash(salt, pin) == hash;
  }

  static bool valid(String pin) => RegExp(r'^\d{4}$').hasMatch(pin);
}

/// Titik PIN + papan angka besar (tombol 72 dp). Dipakai saat membuat PIN dan saat masuk.
class PinPad extends StatelessWidget {
  const PinPad({super.key, required this.value, required this.onChanged, this.error = false, this.enabled = true});

  final String value;
  final ValueChanged<String> onChanged;
  final bool error;
  final bool enabled;

  void _press(String key) {
    HapticFeedback.selectionClick();
    if (key == '⌫') {
      if (value.isNotEmpty) onChanged(value.substring(0, value.length - 1));
    } else if (value.length < ParentPin.length) {
      onChanged(value + key);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Semantics(
        label: '${value.length} dari ${ParentPin.length} angka',
        excludeSemantics: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < ParentPin.length; i++)
              AnimatedContainer(
                duration: Motion.of(context, Motion.press),
                width: 18,
                height: 18,
                margin: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < value.length ? (error ? AppColors.coralDeep : AppColors.tealDeep) : Colors.transparent,
                  border: Border.all(color: error ? AppColors.coralDeep : AppColors.tealDeep, width: 2),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 24),
      for (final row in const [
        ['1', '2', '3'],
        ['4', '5', '6'],
        ['7', '8', '9'],
        ['', '0', '⌫'],
      ])
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final k in row)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: k.isEmpty
                      ? const SizedBox(width: 72, height: 72)
                      : PressScale(
                          child: Material(
                            color: k == '⌫' ? Colors.transparent : AppColors.panel,
                            shape: const CircleBorder(side: BorderSide(color: AppColors.line)),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: enabled ? () => _press(k) : null,
                              child: SizedBox(
                                width: 72,
                                height: 72,
                                child: Center(
                                  child: k == '⌫'
                                      ? const Icon(Icons.backspace_outlined, color: AppColors.ink, semanticLabel: 'Hapus')
                                      : Text(k, style: AppText.h1.copyWith(fontSize: 30)),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
    ],
  );
}

/// Buat PIN baru: ketik, lalu ketik ulang. [onDone] menerima PIN yang sudah cocok (belum disimpan).
class PinSetup extends StatefulWidget {
  const PinSetup({super.key, required this.onDone, this.dark = false});

  final ValueChanged<String> onDone;
  final bool dark;

  @override
  State<PinSetup> createState() => _PinSetupState();
}

class _PinSetupState extends State<PinSetup> {
  String _first = '';
  String _value = '';
  bool _confirming = false;
  bool _mismatch = false;

  void _changed(String v) {
    setState(() {
      _value = v;
      _mismatch = false;
    });
    if (v.length < ParentPin.length) return;
    if (!_confirming) {
      setState(() {
        _first = v;
        _value = '';
        _confirming = true;
      });
    } else if (v == _first) {
      widget.onDone(v);
    } else {
      setState(() {
        _mismatch = true;
        _value = '';
        _first = '';
        _confirming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AnimatedSwitcher(
        duration: Motion.of(context, Motion.fade),
        child: Text(
          _mismatch ? 'PIN tidak sama. Ulangi dari awal.' : (_confirming ? 'Ketik sekali lagi' : 'Ketik 4 angka'),
          key: ValueKey('$_confirming$_mismatch'),
          style: AppText.bodyStrong.copyWith(color: _mismatch ? AppColors.coralText : AppColors.ink),
        ),
      ),
      const SizedBox(height: 16),
      PinPad(value: _value, onChanged: _changed, error: _mismatch),
    ],
  );
}

/// Layar masuk orang tua. Setelah [ParentPin.attemptsPerRound] kali salah, keypad diganti dua tombol setara:
/// "Coba lagi" dan "Aku {nama}" (kembali ke papan anak). Setiap putaran salah berikutnya menambah jeda 30 detik
/// sebelum "Coba lagi" aktif, supaya menebak acak tidak berguna.
class ParentPinScreen extends StatefulWidget {
  const ParentPinScreen({
    super.key,
    required this.prefs,
    required this.childName,
    required this.onUnlocked,
    required this.onChild,
    required this.onForgot,
  });

  final SharedPreferences prefs;
  final String childName;
  final VoidCallback onUnlocked;
  final VoidCallback onChild;
  final VoidCallback onForgot;

  @override
  State<ParentPinScreen> createState() => _ParentPinScreenState();
}

class _ParentPinScreenState extends State<ParentPinScreen> {
  String _value = '';
  int _wrong = 0;
  int _rounds = 0;
  bool _error = false;
  DateTime? _waitUntil;

  bool get _locked => _wrong >= ParentPin.attemptsPerRound;

  void _changed(String v) {
    setState(() {
      _value = v;
      _error = false;
    });
    if (v.length < ParentPin.length) return;
    if (ParentPin.check(widget.prefs, v)) {
      widget.onUnlocked();
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _wrong++;
      _error = true;
      _value = '';
      if (_locked) {
        _rounds++;
        _waitUntil = _rounds > 1 ? DateTime.now().add(Duration(seconds: 30 * (_rounds - 1))) : null;
      }
    });
  }

  void _retry() {
    final wait = _waitUntil;
    if (wait != null && DateTime.now().isBefore(wait)) {
      final s = wait.difference(DateTime.now()).inSeconds + 1;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Tunggu $s detik lagi.')));
      return;
    }
    setState(() {
      _wrong = 0;
      _error = false;
    });
  }

  @override
  Widget build(BuildContext context) => CompanionPage(
    title: 'Masuk orang tua',
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.fade),
          child: _locked
              ? Column(
                  key: const ValueKey('terkunci'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 56, color: AppColors.muted),
                    const SizedBox(height: 12),
                    Text('PIN belum cocok', style: AppText.h2, textAlign: TextAlign.center),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: EqualOutlineButton(label: 'Coba lagi', icon: Icons.replay_rounded, onPressed: _retry),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: EqualOutlineButton(label: 'Aku ${widget.childName}', icon: Icons.grid_view_rounded, onPressed: widget.onChild),
                    ),
                    const SizedBox(height: 16),
                    TextButton(onPressed: widget.onForgot, child: const Text('Lupa PIN?')),
                  ],
                )
              : Column(
                  key: const ValueKey('pin'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _error ? 'PIN salah. Sisa ${ParentPin.attemptsPerRound - _wrong} kali.' : 'Ketik PIN orang tua',
                      style: AppText.bodyStrong.copyWith(color: _error ? AppColors.coralText : AppColors.ink),
                    ),
                    const SizedBox(height: 16),
                    PinPad(value: _value, onChanged: _changed, error: _error),
                    const SizedBox(height: 4),
                    TextButton(onPressed: widget.onChild, child: Text('Bukan orang tua? Aku ${widget.childName}')),
                  ],
                ),
        ),
      ),
    ),
  );
}

/// Pengaturan → Ganti PIN orang tua.
class ChangePinScreen extends StatelessWidget {
  const ChangePinScreen({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) => CompanionPage(
    title: 'Ganti PIN orang tua',
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: PinSetup(
          onDone: (pin) async {
            await ParentPin.set(prefs, pin);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('PIN baru tersimpan.')));
            Navigator.of(context).pop();
          },
        ),
      ),
    ),
  );
}
