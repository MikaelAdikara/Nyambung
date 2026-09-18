import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/app_state.dart';
import 'core/error_log.dart';
import 'features/coach/home_screen.dart';
import 'features/onboarding/onboarding_flow.dart';
import 'core/theme.dart';

void main() {
  // Tiga penangkap error sejak baris pertama. Semuanya menyimpan 20 entri terakhir ke ErrorLog (C6 Diagnosa).
  FlutterError.onError = (details) {
    ErrorLog.record('flutter', details.exception, details.stack);
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    ErrorLog.record('platform', error, stack);
    return true;
  };
  ErrorWidget.builder = (details) => ReadableError(details: details);

  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  // AppScope DI ATAS MaterialApp: rute Navigator.push ikut menemukannya.
  runApp(AppScope(state: state, child: const NyambungApp()));
}

class NyambungApp extends StatelessWidget {
  const NyambungApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Nyambung', debugShowCheckedModeBanner: false, theme: buildTheme(), home: const BootGate());
  }
}

/// Layar "Menyiapkan papan" → buka DB → muat CSV bila perlu → beranda (atau A1 bila belum ada anak).
class BootGate extends StatefulWidget {
  const BootGate({super.key});

  @override
  State<BootGate> createState() => _BootGateState();
}

class _BootGateState extends State<BootGate> {
  Future<void>? _boot;
  AppState? _app;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = AppScope.of(context);
    if (_app != app) {
      _app = app;
      _boot = app.bootstrap().catchError((Object e, StackTrace st) {
        ErrorLog.record('bootstrap', e, st);
        throw e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _boot,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: SelectableText('Papan belum bisa disiapkan.\n\n${snap.error}\n\n${ErrorLog.asText()}'),
              ),
            ),
          );
        }
        if (snap.connectionState != ConnectionState.done) return const _Preparing();
        final app = _app!;
        // Belum ada anak → pemasangan A1–A6; sudah ada → beranda B1 (keduanya milik jalur 2).
        return ListenableBuilder(listenable: app, builder: (context, _) => app.child == null ? const OnboardingFlow() : const HomeScreen());
      },
    );
  }
}

class _Preparing extends StatelessWidget {
  const _Preparing();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: AppColors.navy),
            SizedBox(height: 16),
            Text('Menyiapkan papan', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

/// Pengganti kotak abu-abu di mode rilis: pesan yang bisa dibaca dan disalin.
class ReadableError extends StatelessWidget {
  const ReadableError({super.key, required this.details});

  final FlutterErrorDetails details;

  @override
  Widget build(BuildContext context) {
    final text = '${details.exceptionAsString()}\n${details.stack.toString().split('\n').take(6).join('\n')}';
    return Material(
      color: const Color(0xFFFFF4D6),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bagian layar ini gagal ditampilkan.',
              style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            SelectableText(text, style: const TextStyle(fontSize: 12, color: AppColors.ink)),
            TextButton(
              onPressed: () => Clipboard.setData(ClipboardData(text: text)),
              child: const Text('Salin'),
            ),
          ],
        ),
      ),
    );
  }
}
