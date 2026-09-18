/// Future yang hanya dimuat ulang saat kuncinya berubah (biasanya `AppState.dataVersion`).
///
/// `FutureBuilder` **tidak pernah** boleh menerima future yang dibuat di dalam `build()`: setiap
/// rebuild memicu kueri SQLite baru. Pakai ini:
///
/// ```dart
/// final _summary = CachedFuture<int>();
/// ...
/// Widget build(BuildContext context) {
///   final app = AppScope.of(context);
///   return FutureBuilder(
///     future: _summary.get(app.dataVersion, () => app.eventDao.outboxCount()),
///     builder: ...,
///   );
/// }
/// ```
class CachedFuture<T> {
  Object? _key;
  Future<T>? _future;
  bool _hasKey = false;

  Future<T> get(Object? key, Future<T> Function() load) {
    if (!_hasKey || key != _key || _future == null) {
      _key = key;
      _hasKey = true;
      _future = load();
    }
    return _future!;
  }

  /// Paksa muat ulang pada panggilan [get] berikutnya.
  void invalidate() => _future = null;
}
